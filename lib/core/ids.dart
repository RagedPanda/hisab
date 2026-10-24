import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New random id for any entity. UUID v4 keeps ids mergeable across devices.
String newId() => _uuid.v4();

/// Deterministic id derived from [name]: the same name always yields the same
/// UUID (v5), so a write that may run twice (app start and resume racing)
/// lands on one row instead of two.
String stableId(String name) => _uuid.v5(Namespace.url.value, 'hisab:$name');
