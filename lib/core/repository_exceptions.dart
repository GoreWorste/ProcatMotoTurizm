class ReferenceInUseException implements Exception {
  ReferenceInUseException(this.message, {this.count = 0});

  final String message;
  final int count;

  @override
  String toString() => message;
}
