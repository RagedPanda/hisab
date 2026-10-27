/// Pure helpers for the personal People list: everyone the user has added to a
/// group with an email. The email, lowercased, is the person's id, so the same
/// friend added on two devices merges into one row when data syncs.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// [raw] trimmed and lowercased when it looks like an email, else null.
String? normaliseEmail(String? raw) {
  final email = raw?.trim().toLowerCase() ?? '';
  return _emailPattern.hasMatch(email) ? email : null;
}

/// Whether [raw] is non-blank but not an email, for the member sheet's error.
bool isInvalidEmail(String raw) => raw.trim().isNotEmpty && normaliseEmail(raw) == null;

/// The fields of a People row that matter for suggestions.
typedef PersonContact = ({String name, String email});

/// People whose name or email contains [query], best first: a match at the
/// start of the name or email ranks ahead of one inside it, then by name.
/// Skips [excludeEmails] (people already in the group) and returns at most
/// [limit]. A blank query suggests nobody.
List<PersonContact> matchingPeople(
  Iterable<PersonContact> people,
  String query, {
  Set<String> excludeEmails = const {},
  int limit = 3,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  int? rank(PersonContact person) {
    final name = person.name.toLowerCase();
    if (name.startsWith(needle) || person.email.startsWith(needle)) return 0;
    if (name.contains(needle) || person.email.contains(needle)) return 1;
    return null;
  }

  final ranked = [
    for (final person in people)
      if (!excludeEmails.contains(person.email))
        if (rank(person) case final score?) (person: person, score: score),
  ]..sort((left, right) {
      final byScore = left.score.compareTo(right.score);
      return byScore != 0 ? byScore : left.person.name.toLowerCase().compareTo(right.person.name.toLowerCase());
    });
  return [for (final match in ranked.take(limit)) match.person];
}
