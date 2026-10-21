import 'package:flutter/widgets.dart';

/// Language of the displayed content, from the active locale.
extension LangueContexte on BuildContext {
  /// Language code of the active locale (`fr`, `en`).
  String get langue => Localizations.localeOf(this).languageCode;
}
