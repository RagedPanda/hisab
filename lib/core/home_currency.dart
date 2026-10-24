import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's home currency as an ISO 4217 code. The only place the app
/// reads it from. Fixed to INR until the currency picker reads it from
/// settings.
final homeCurrencyCodeProvider = Provider<String>((ref) => 'INR');
