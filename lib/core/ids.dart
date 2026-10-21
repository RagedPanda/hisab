import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New random id for any entity. UUID v4 keeps ids mergeable across devices.
String newId() => _uuid.v4();
