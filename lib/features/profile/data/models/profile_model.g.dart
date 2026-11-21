// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  @override
  final int typeId = 2;

  @override
  ProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileModel(
      hiveName: fields[0] as String,
      hiveDateOfBirth: fields[1] as DateTime,
      hiveAverageCycleLengthInput: fields[2] as int,
      hiveHistoricalCycleCount: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.hiveName)
      ..writeByte(1)
      ..write(obj.hiveDateOfBirth)
      ..writeByte(2)
      ..write(obj.hiveAverageCycleLengthInput)
      ..writeByte(3)
      ..write(obj.hiveHistoricalCycleCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
