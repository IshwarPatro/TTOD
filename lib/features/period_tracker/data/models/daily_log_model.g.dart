// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogModelAdapter extends TypeAdapter<DailyLogModel> {
  @override
  final int typeId = 1;

  @override
  DailyLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLogModel(
      hiveId: fields[0] as String,
      hiveDate: fields[1] as DateTime,
      flowIntensityIndex: fields[2] as int?,
      hiveSymptoms: (fields[3] as List).cast<String>(),
      hiveWaterIntakeMl: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.hiveId)
      ..writeByte(1)
      ..write(obj.hiveDate)
      ..writeByte(2)
      ..write(obj.flowIntensityIndex)
      ..writeByte(3)
      ..write(obj.hiveSymptoms)
      ..writeByte(4)
      ..write(obj.hiveWaterIntakeMl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
