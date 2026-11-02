import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/udhaar_repository.dart';
import '../../data/udhaar/udhaar_backup.dart';
import '../../domain/udhaar/udhaar.dart';

export '../../data/udhaar/udhaar_backup.dart' show kMyUpiIdPref;

final udhaarRepositoryProvider = Provider((ref) => UdhaarRepository(ref.watch(databaseProvider)));

/// Every live udhaar entry, for balances.
final udhaarLinesProvider = StreamProvider((ref) => ref.watch(udhaarRepositoryProvider).watchLines());

/// Person id -> what they owe me (positive) or I owe them (negative).
final udhaarBalancesProvider = Provider<AsyncValue<Map<String, int>>>((ref) => ref.watch(udhaarLinesProvider).whenData(udhaarBalances));

/// One person's udhaar entries, newest first.
final personUdhaarEntriesProvider = StreamProvider.family<List<Entry>, String>((ref, personId) => ref.watch(udhaarRepositoryProvider).watchPersonEntries(personId));

/// One People row as it changes.
final personProvider = StreamProvider.family<Person?, String>((ref, personId) => ref.watch(peopleRepositoryProvider).watchPerson(personId));

/// The user's own UPI ID (VPA): null until they are first asked, empty when
/// they chose to leave it out.
class MyUpiIdNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(kMyUpiIdPref);

  Future<void> set(String upiId) async {
    state = upiId;
    await ref.read(sharedPreferencesProvider).setString(kMyUpiIdPref, upiId);
  }
}

final myUpiIdProvider = NotifierProvider<MyUpiIdNotifier, String?>(MyUpiIdNotifier.new);
