import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:app_rotina/core/dates.dart';
import 'package:app_rotina/data/models/models.dart';
import 'package:app_rotina/data/repositories/checkin_repository.dart';
import 'package:app_rotina/data/repositories/routine_repository.dart';
import 'package:app_rotina/features/checkin/bloc/checkin_bloc.dart';
import 'package:app_rotina/features/metrics/bloc/metrics_bloc.dart';

void main() {
  late Directory tempDir;
  late Box<Routine> routineBox;
  late Box<Checkin> checkinBox;
  late RoutineRepository routineRepository;
  late CheckinRepository checkinRepository;

  final now = DateTime(2026, 9, 1, 10);

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_bloc_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RoutineStepAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RoutineAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CheckinAdapter());
    }
    routineBox = await Hive.openBox<Routine>('routines');
    checkinBox = await Hive.openBox<Checkin>('checkins');
    routineRepository = RoutineRepository(routineBox);
    checkinRepository = CheckinRepository(checkinBox);
  });

  setUp(() async {
    await routineBox.clear();
    await checkinBox.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });

  Routine buildRoutine({String name = 'Rotina', int steps = 2}) => Routine(
        id: 'r-$name',
        name: name,
        steps: [
          for (var i = 0; i < steps; i++)
            RoutineStep(id: 's-$i', title: 'Passo $i'),
        ],
        createdAt: now.subtract(const Duration(days: 10)),
      );

  group('CheckinBloc', () {
    test('marca passo e conclui rotina ao completar todos', () async {
      final routine = buildRoutine();
      await routineRepository.put(routine);

      final bloc = CheckinBloc(
        routineRepository: routineRepository,
        checkinRepository: checkinRepository,
        now: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(CheckinToggleStep(routine.id, 's-0'));
      await Future<void>.delayed(Duration.zero);

      var state = bloc.state;
      expect(state.checkins[routine.id]!.completedStepIds, ['s-0']);
      expect(state.checkins[routine.id]!.isCompleted, isFalse);
      expect(state.overallProgress, 0.5);

      bloc.add(CheckinToggleStep(routine.id, 's-1'));
      await Future<void>.delayed(Duration.zero);

      state = bloc.state;
      expect(state.checkins[routine.id]!.isCompleted, isTrue);
      expect(state.checkins[routine.id]!.completedAt, isNotNull);
      expect(state.completedRoutines, 1);

      bloc.add(CheckinToggleStep(routine.id, 's-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.checkins[routine.id]!.isCompleted, isFalse);

      await bloc.close();
    });

    test('rotina sem passos usa marcação única', () async {
      final routine = buildRoutine(steps: 0);
      await routineRepository.put(routine);

      final bloc = CheckinBloc(
        routineRepository: routineRepository,
        checkinRepository: checkinRepository,
        now: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(CheckinToggleWholeRoutine(routine.id));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.checkins[routine.id]!.isCompleted, isTrue);
      expect(bloc.state.completedRoutines, 1);

      await bloc.close();
    });
  });

  group('MetricsBloc', () {
    test('calcula sequência, totais e taxa por rotina', () async {
      final routine = buildRoutine();
      await routineRepository.put(routine);

      for (var daysAgo = 3; daysAgo >= 0; daysAgo--) {
        final key = dayKey(now.subtract(Duration(days: daysAgo)));
        await checkinRepository.save(Checkin(
          routineId: routine.id,
          dateKey: key,
          completedStepIds: ['s-0', 's-1'],
          completedAt: now.subtract(Duration(days: daysAgo)),
          totalSteps: 2,
        ));
      }

      final bloc = MetricsBloc(
        routineRepository: routineRepository,
        checkinRepository: checkinRepository,
        now: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state;
      expect(state.currentStreak, 4);
      expect(state.bestStreak, 4);
      expect(state.totalCompleted, 4);
      expect(state.last7DaysCounts[6], 1);
      expect(state.perRoutine.single.completions, 4);

      await bloc.close();
    });
  });
}
