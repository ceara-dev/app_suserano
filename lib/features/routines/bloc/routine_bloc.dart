import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/routine_repository.dart';

sealed class RoutineEvent {}

class RoutineSaveRequested extends RoutineEvent {
  RoutineSaveRequested(this.routine, {this.isNew = false});

  final Routine routine;
  final bool isNew;
}

class RoutineDeleteRequested extends RoutineEvent {
  RoutineDeleteRequested(this.routineId);

  final String routineId;
}

class RoutineToggleActiveRequested extends RoutineEvent {
  RoutineToggleActiveRequested(this.routineId);

  final String routineId;
}

class _RoutineListChanged extends RoutineEvent {
  _RoutineListChanged(this.routines);

  final List<Routine> routines;
}

class _RoutineLoadFailed extends RoutineEvent {}

sealed class RoutineState {}

class RoutineLoading extends RoutineState {}

class RoutineLoaded extends RoutineState {
  RoutineLoaded(this.routines);

  final List<Routine> routines;
}

class RoutineFailure extends RoutineState {
  RoutineFailure(this.message);

  final String message;
}

class RoutineBloc extends Bloc<RoutineEvent, RoutineState> {
  RoutineBloc(this._repository) : super(RoutineLoading()) {
    _subscription = _repository.watchAll().listen(
          (routines) => add(_RoutineListChanged(routines)),
          onError: (Object e) => add(_RoutineLoadFailed()),
        );

    on<_RoutineListChanged>((event, emit) => emit(RoutineLoaded(event.routines)));

    on<RoutineSaveRequested>((event, emit) async {
      await _repository.put(event.routine);
    });

    on<RoutineDeleteRequested>((event, emit) async {
      await _repository.delete(event.routineId);
    });

    on<RoutineToggleActiveRequested>((event, emit) async {
      final routine = _repository.getById(event.routineId);
      if (routine == null) return;
      await _repository.setActive(event.routineId, !routine.active);
    });

    on<_RoutineLoadFailed>((event, emit) =>
        emit(RoutineFailure('Erro ao carregar rotinas')));
  }

  final RoutineRepository _repository;
  late final StreamSubscription<List<Routine>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
