enum AuthResult {
  /// Valid token obtained — user is fully authenticated.
  authenticated,

  /// Stored credentials exist but token couldn't be obtained right now
  /// (e.g. network issue). The app can proceed and retry lazily.
  deferred,

  /// No credentials or credentials were rejected (401). Show login page.
  unauthenticated,
}
