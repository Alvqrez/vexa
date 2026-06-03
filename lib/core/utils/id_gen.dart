import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Returns a random UUID v4 string for use as a unique ID.
String generateId() => _uuid.v4();
