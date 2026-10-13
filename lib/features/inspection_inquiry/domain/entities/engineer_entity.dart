/// # EngineerEntity
///
/// Immutable domain entity for an engineer record from the generics lookup.
///
/// **SOAP Method**: `GetGenericsDataTable`
/// **Query**: `DataType:73,Major:721`
/// **Fields**: `SYS_DESCL` (employee number), `SYS_DESC` (display name)
library;

import 'package:equatable/equatable.dart';

class EngineerEntity extends Equatable {
  /// Engineer employee number (SYS_DESCL).
  final String empNumber;

  /// Engineer display name (SYS_DESC).
  final String name;

  const EngineerEntity({required this.empNumber, required this.name});

  @override
  List<Object?> get props => [empNumber, name];

  @override
  String toString() => name;
}
