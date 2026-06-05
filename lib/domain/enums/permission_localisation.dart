/// State of the user's grant for accessing the device location.
///
/// Domain-level mirror of the platform permission, kept independent of any
/// geolocation plugin so the Domain stays infrastructure-agnostic. Geolocation
/// is **opt-out and disabled by default** (privacy by design); the Application
/// layer decides whether to even request it. See `docs/11-parametres-et-opt-outs.md`.
enum PermissionLocalisation {
  /// Permission granted (foreground and/or background).
  accordee,

  /// Permission denied, but can be requested again.
  refusee,

  /// Permission denied permanently — must be changed in the OS settings.
  refuseeDefinitivement,

  /// Not yet determined (never requested).
  indeterminee,
}
