import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/dates.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/checkin_repository.dart';
import '../../../data/repositories/routine_repository.dart';

class RoutineMetrics {
  RoutineMetrics({
    required this.routine,
    required this.completions,
    required this.completionRate,
    required this.last7Days,
  });

  final Routine routine;
  final int completions;
  final double completionRate;
  final List<bool> last7Days;
}

class MetricsState {
  MetricsState({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompleted,
    required this.overallRate,
    required this.last7DaysCounts,
    required this.perRoutine,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final double overallRate;
  final List<int> last7DaysCounts;
  final List<RoutineMetrics> perRoutine;
}

sealed class MetricsEvent {}

class _MetricsDataChanged extends MetricsEvent {}

class MetricsBloc extends Bloc<MetricsEvent, MetricsState> {
  MetricsBloc({
    required RoutineRepository routineRepository,
    required CheckinRepository checkinRepository,
    DateTime Function()? now,
  })  : _routineRepository = routineRepository,
        _checkinRepository = checkinRepository,
        _now = now ?? DateTime.now,
        super(MetricsState(
          currentStreak: 0,
          bestStreak: 0,
          totalCompleted: 0,
          overallRate: 0,
          last7DaysCounts: List.filled(7, 0),
          perRoutine: const [],
        )) {
    _routinesSub = _routineRepository.watchAll().listen(
          (_) => add(_MetricsDataChanged()),
          onError: (Object e) {},
        );
    _checkinsSub = _checkinRepository.watchAll().listen(
          (_) => add(_MetricsDataChanged()),
          onError: (Object e) {},
        );

    on<_MetricsDataChanged>((event, emit) => emit(_compute()));
  }

  final RoutineRepository _routineRepository;
  final CheckinRepository _checkinRepository;
  final DateTime Function() _now;
  late final StreamSubscription<List<Routine>> _routinesSub;
  late final StreamSubscription<List<Checkin>> _checkinsSub;

  MetricsState _compute() {
    final routines = _routineRepository.getAll();
    final checkins = _checkinRepository.getAll();
    final completed = checkins.where((c) => c.isCompleted).toList();
    final completedDays = completed.map((c) => c.dateKey).toSet();
    final todayKey = dayKey(_now());
    final today = parseDayKey(todayKey);

    var currentStreak = 0;
    var cursor = completedDays.contains(todayKey)
        ? today
        : today.subtract(const Duration(days: 1));
    while (completedDays.contains(dayKey(cursor))) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var bestStreak = 0;
    final sortedDays = completedDays.toList()..sort();
    if (sortedDays.isNotEmpty) {
      var run = 1;
      for (var i = 1; i < sortedDays.length; i++) {
        final previous = parseDayKey(sortedDays[i - 1]);
        final current = parseDayKey(sortedDays[i]);
        if (current.difference(previous).inDays == 1) {
          run++;
        } else {
          if (run > bestStreak) bestStreak = run;
          run = 1;
        }
      }
      if (run > bestStreak) bestStreak = run;
    }

    final totalCompleted = completed.length;

    final last7DaysCounts = List<int>.generate(7, (i) {
      final key = dayKey(today.subtract(Duration(days: 6 - i)));
      return completed.where((c) => c.dateKey == key).length;
    });

    final perRoutine = <RoutineMetrics>[];
    var possibleDays = 0;
    for (final routine in routines) {
      final completions = completed.where((c) => c.routineId == routine.id).length;
      final daysSince =
          daysBetween(routine.createdAt, today) + 1;
      possibleDays += daysSince;
      final last7 = List<bool>.generate(7, (i) {
        final key = dayKey(today.subtract(Duration(days: 6 - i)));
        return completed.any((c) => c.routineId == routine.id && c.dateKey == key);
      });
      perRoutine.add(RoutineMetrics(
        routine: routine,
        completions: completions,
        completionRate: daysSince == 0 ? 0 : completions / daysSince,
        last7Days: last7,
      ));
    }

    return MetricsState(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalCompleted: totalCompleted,
      overallRate: possibleDays == 0 ? 0 : totalCompleted / possibleDays,
      last7DaysCounts: last7DaysCounts,
      perRoutine: perRoutine,
    );
  }

  @override
  Future<void> close() {
    _routinesSub.cancel();
    _checkinsSub.cancel();
    return super.close();
  }
}
