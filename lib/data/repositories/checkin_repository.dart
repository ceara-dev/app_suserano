import 'package:hive/hive.dart';

import '../models/models.dart';

class CheckinRepository {
  CheckinRepository(this._box);

  final Box<Checkin> _box;

  Checkin? getFor(String routineId, String dateKey) =>
      _box.get(Checkin(
        routineId: routineId,
        dateKey: dateKey,
      ).storageKey);

  List<Checkin> getForDate(String dateKey) => _box.values
      .where((c) => c.dateKey == dateKey)
      .toList();

  List<Checkin> getAll() => _box.values.toList();

  Stream<List<Checkin>> watchForDate(String dateKey) async* {
    yield getForDate(dateKey);
    yield* _box.watch().map((_) => getForDate(dateKey));
  }

  Stream<List<Checkin>> watchAll() async* {
    yield getAll();
    yield* _box.watch().map((_) => getAll());
  }

  Future<void> save(Checkin checkin) =>
      _box.put(checkin.storageKey, checkin);

  Future<void> delete(String routineId, String dateKey) => _box.delete(Checkin(
        routineId: routineId,
        dateKey: dateKey,
      ).storageKey);
}
