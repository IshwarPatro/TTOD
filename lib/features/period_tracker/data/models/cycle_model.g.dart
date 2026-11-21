// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleModelAdapter extends TypeAdapter<CycleModel> {
  @override
  final int typeId = 0;

  @override
  CycleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleModel(
      hiveId: fields[0] as String,
      hiveStartDate: fields[1] as DateTime,
      hiveEndDate: fields[2] as DateTime,
      flowIntensityIndex: fields[3] as int,
      hiveSymptoms: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CycleModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.hiveId)
      ..writeByte(1)
      ..write(obj.hiveStartDate)
      ..writeByte(2)
      ..write(obj.hiveEndDate)
      ..writeByte(3)
      ..write(obj.flowIntensityIndex)
      ..writeByte(4)
      ..write(obj.hiveSymptoms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
