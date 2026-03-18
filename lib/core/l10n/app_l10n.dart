import 'package:flutter/widgets.dart';
import 'package:local_vault/l10n/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
