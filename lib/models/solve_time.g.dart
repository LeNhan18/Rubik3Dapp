// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_time.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SolveTimeAdapter extends TypeAdapter<SolveTime> {
  @override
  final int typeId = 0;

  @override
  SolveTime read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SolveTime(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      milliseconds: fields[2] as int,
      scramble: fields[3] as String,
      status: fields[4] as SolveStatus,
      sessionId: fields[5] as String,
      comment: fields[6] as String?,
      penalty: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SolveTime obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.milliseconds)
      ..writeByte(3)
      ..write(obj.scramble)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.sessionId)
      ..writeByte(6)
      ..write(obj.comment)
      ..writeByte(7)
      ..write(obj.penalty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolveTimeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SolveStatusAdapter extends TypeAdapter<SolveStatus> {
  @override
  final int typeId = 1;

  @override
  SolveStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SolveStatus.normal;
      case 1:
        return SolveStatus.dnf;
      case 2:
        return SolveStatus.plusTwo;
      default:
        return SolveStatus.normal;
    }
  }

  @override
  void write(BinaryWriter writer, SolveStatus obj) {
    switch (obj) {
      case SolveStatus.normal:
        writer.writeByte(0);
        break;
      case SolveStatus.dnf:
        writer.writeByte(1);
        break;
      case SolveStatus.plusTwo:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolveStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
