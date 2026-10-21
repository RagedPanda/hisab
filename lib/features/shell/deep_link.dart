/// Rewrites custom-scheme links such as `hisab://sms?text=...` to an in-app
/// location (`/sms?text=...`).
///
/// Android delivers the link with host `sms` and a path that is either empty
/// or `/` depending on the launcher; both mean "no path" here.
String? deepLinkLocation(Uri uri) {
  final hasNoPath = uri.path.isEmpty || uri.path == '/';
  if (uri.host.isEmpty || !hasNoPath) return null;
  return Uri(path: '/${uri.host}', queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters).toString();
}
