/// # GenericType
///
/// A row of the shared `GetGenericsDataTable` lookup (major 324 = record types
/// that can be geo-stamped).
///
/// Equality is defined on [minor] only, because that is the value the dropdown
/// uses and the service occasionally returns the same code twice.
library;

class GenericType {
  /// Arabic description shown in the dropdown (`SYS_DESC`).
  final String description;

  /// Lookup group (`SYS_MAJOR`).
  final String major;

  /// Lookup code (`SYS_MINOR`) — drives which `dataType` the search sends.
  final String minor;

  const GenericType({
    required this.description,
    required this.major,
    required this.minor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenericType &&
          runtimeType == other.runtimeType &&
          minor == other.minor;

  @override
  int get hashCode => minor.hashCode;

  @override
  String toString() => 'GenericType($minor: $description)';
}
