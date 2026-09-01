import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/dates.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/checkin_repository.dart';
import '../../../data/repositories/routine_repository.dart';

sealed class CheckinEvent {}

class CheckinToggleStep extends CheckinEvent {
  CheckinToggleStep(this.routineId, this.stepId);

  final String routineId;
  final String stepId;
}

class CheckinToggleWholeRoutine extends CheckinEvent {
  CheckinToggleWholeRoutine(this.routineId);

  final String routineId;
}

class CheckinCompleteRoutine extends CheckinEvent {
  CheckinCompleteRoutine(this.routineId);

  final String routineId;
}

class _CheckinDataChanged extends CheckinEvent {}

class CheckinState {
  CheckinState({
    required this.dateKey,
    required this.routines,
    required this.checkins,
  });

  final String dateKey;
  final List<Routine> routines;
  final Map<String, Checkin> checkins;

  int get totalRoutines => routines.length;

  int get completedRoutines => routines
      .where((r) => checkins[r.id]?.isCompleted ?? false)
      .length;

  int get totalSteps =>
      routines.fold(0, (sum, r) => sum + (r.stepCount > 0 ? r.stepCount : 1));

  int get completedSteps {
    var done = 0;
    for (final r in routines) {
      final c = checkins[r.id];
      if (c == null) continue;
      done += r.stepCount > 0
          ? (c.completedSteps > r.stepCount ? r.stepCount : c.completedSteps)
          : (c.isCompleted ? 1 : 0);
    }
    return done;
  }

  double get overallProgress =>
      totalSteps == 0 ? 0.0 : (completedSteps / totalSteps).clamp(0.0, 1.0);
}

class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  CheckinBloc({
    required RoutineRepository routineRepository,
    required CheckinRepository checkinRepository,
    DateTime Function()? now,
  })  : _routineRepository = routineRepository,
        _checkinRepository = checkinRepository,
        _now = now ?? DateTime.now,
        super(CheckinState(
          dateKey: dayKey((now ?? DateTime.now)()),
          routines: const [],
          checkins: const {},
        )) {
    _routinesSub = _routineRepository.watchAll().listen(
          (_) => add(_CheckinDataChanged()),
          onError: (Object e) {},
        );
    _checkinsSub =
        _checkinRepository.watchForDate(state.dateKey).listen(
              (_) => add(_CheckinDataChanged()),
              onError: (Object e) {},
            );

    on<_CheckinDataChanged>((event, emit) => emit(_buildState()));

    on<CheckinToggleStep>((event, emit) async {
      final routine = _routineRepository.getById(event.routineId);
      if (routine == null || routine.stepCount == 0) return;
      final current = _currentCheckin(event.routineId);
      final validIds = routine.steps.map((s) => s.id).toSet();
      final completed = current.completedStepIds.where(validIds.contains).toSet();
      if (!completed.remove(event.stepId)) completed.add(event.stepId);
      final allDone = completed.length >= routine.stepCount;
      await _checkinRepository.save(Checkin(
        routineId: routine.id,
        dateKey: state.dateKey,
        completedStepIds: completed.toList(),
        completedAt: allDone ? _now() : null,
        totalSteps: routine.stepCount,
      ));
    });

    on<CheckinToggleWholeRoutine>((event, emit) async {
      final routine = _routineRepository.getById(event.routineId);
      if (routine == null || routine.stepCount > 0) return;
      final current = _currentCheckin(event.routineId);
      final done = !current.wholeRoutineDone;
      await _checkinRepository.save(Checkin(
        routineId: routine.id,
        dateKey: state.dateKey,
        wholeRoutineDone: done,
        completedAt: done ? _now() : null,
        totalSteps: 0,
      ));
    });

    on<CheckinCompleteRoutine>((event, emit) async {
      final routine = _routineRepository.getById(event.routineId);
      if (routine == null || routine.stepCount == 0) return;
      await _checkinRepository.save(Checkin(
        routineId: routine.id,
        dateKey: state.dateKey,
        completedStepIds: routine.steps.map((s) => s.id).toList(),
        completedAt: _now(),
        totalSteps: routine.stepCount,
      ));
    });
  }

  final RoutineRepository _routineRepository;
  final CheckinRepository _checkinRepository;
  final DateTime Function() _now;
  late final StreamSubscription<List<Routine>> _routinesSub;
  late final StreamSubscription<List<Checkin>> _checkinsSub;

  Checkin _currentCheckin(String routineId) =>
      _checkinRepository.getFor(routineId, state.dateKey) ??
      Checkin(routineId: routineId, dateKey: state.dateKey);

  CheckinState _buildState() => CheckinState(
        dateKey: state.dateKey,
        routines: _routineRepository
            .getAll()
            .where((r) => r.active)
            .toList(),
        checkins: {
          for (final c in _checkinRepository.getForDate(state.dateKey))
            c.routineId: c,
        },
      );

  @override
  Future<void> close() {
    _routinesSub.cancel();
    _checkinsSub.cancel();
    return super.close();
  }
}
