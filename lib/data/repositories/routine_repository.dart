import 'package:hive/hive.dart';

import '../models/models.dart';

class RoutineRepository {
  RoutineRepository(this._box);

  final Box<Routine> _box;

  List<Routine> getAll() {
    final routines = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return routines;
  }

  Stream<List<Routine>> watchAll() async* {
    yield getAll();
    yield* _box.watch().map((_) => getAll());
  }

  Routine? getById(String id) => _box.get(id);

  Future<void> put(Routine routine) => _box.put(routine.id, routine);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> setActive(String id, bool active) async {
    final routine = _box.get(id);
    if (routine == null) return;
    await _box.put(id, routine.copyWith(active: active));
  }
}
