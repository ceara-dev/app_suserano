import 'package:hive/hive.dart';

class RoutineStep {
  RoutineStep({required this.id, required this.title, this.note = ''});

  final String id;
  String title;
  String note;

  RoutineStep copyWith({String? title, String? note}) => RoutineStep(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
      );
}

class RoutineStepAdapter extends TypeAdapter<RoutineStep> {
  @override
  final int typeId = 0;

  @override
  RoutineStep read(BinaryReader reader) => RoutineStep(
        id: reader.readString(),
        title: reader.readString(),
        note: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, RoutineStep obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.note);
  }
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    this.description = '',
    this.colorValue = 0xFF6750A4,
    this.iconIndex = 0,
    required this.steps,
    required this.createdAt,
    this.active = true,
  });

  final String id;
  String name;
  String description;
  int colorValue;
  int iconIndex;
  List<RoutineStep> steps;
  DateTime createdAt;
  bool active;

  int get stepCount => steps.length;

  Routine copyWith({
    String? name,
    String? description,
    int? colorValue,
    int? iconIndex,
    List<RoutineStep>? steps,
    bool? active,
  }) =>
      Routine(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        colorValue: colorValue ?? this.colorValue,
        iconIndex: iconIndex ?? this.iconIndex,
        steps: steps ?? this.steps,
        createdAt: createdAt,
        active: active ?? this.active,
      );
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 1;

  @override
  Routine read(BinaryReader reader) => Routine(
        id: reader.readString(),
        name: reader.readString(),
        description: reader.readString(),
        colorValue: reader.readInt(),
        iconIndex: reader.readInt(),
        steps: reader
            .readList()
            .map((e) => (e as RoutineStep))
            .toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
        active: reader.readBool(),
      );

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeInt(obj.colorValue);
    writer.writeInt(obj.iconIndex);
    writer.writeList(obj.steps);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.active);
  }
}

class Checkin {
  Checkin({
    required this.routineId,
    required this.dateKey,
    List<String>? completedStepIds,
    this.wholeRoutineDone = false,
    this.completedAt,
    this.totalSteps = 0,
  }) : completedStepIds = completedStepIds ?? [];

  String routineId;
  String dateKey;
  List<String> completedStepIds;
  bool wholeRoutineDone;
  DateTime? completedAt;
  int totalSteps;

  String get storageKey => '${dateKey}__$routineId';

  int get completedSteps => completedStepIds.length;

  bool get isCompleted =>
      wholeRoutineDone ||
      (totalSteps > 0 && completedStepIds.length >= totalSteps);

  double get progress {
    if (wholeRoutineDone) return 1.0;
    if (totalSteps == 0) return 0.0;
    return (completedStepIds.length / totalSteps).clamp(0.0, 1.0);
  }
}

class CheckinAdapter extends TypeAdapter<Checkin> {
  @override
  final int typeId = 2;

  @override
  Checkin read(BinaryReader reader) {
    final completedAtMillis = reader.readInt();
    return Checkin(
      routineId: reader.readString(),
      dateKey: reader.readString(),
      completedStepIds: reader.readList().map((e) => e as String).toList(),
      wholeRoutineDone: reader.readBool(),
      completedAt: completedAtMillis < 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedAtMillis),
      totalSteps: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Checkin obj) {
    writer.writeString(obj.routineId);
    writer.writeString(obj.dateKey);
    writer.writeList(obj.completedStepIds);
    writer.writeBool(obj.wholeRoutineDone);
    writer.writeInt(obj.completedAt?.millisecondsSinceEpoch ?? -1);
    writer.writeInt(obj.totalSteps);
  }
}
