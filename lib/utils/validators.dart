import 'package:vango_parent_app/l10n/app_localizations.dart';

class AppValidators {
  static String? validatePhone(String? value, AppLocalizations loc) {
    if (value == null || value.trim().isEmpty)
      return loc.loginErrPhoneReq; // Works for create account too
    final cleanPhone = value.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) return loc.loginErrPhoneInv;
    return null;
  }

  static String? validateEmail(
    String? value,
    AppLocalizations loc, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : loc.loginErrEmailReq;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return loc.loginErrEmailInv;
    return null;
  }

  static String? validatePassword(String? value, AppLocalizations loc) {
    if (value == null || value.isEmpty) return loc.loginErrPassReq;
    if (value.length < 8) return loc.loginErrPassMin;
    return null;
  }

  static String? validateNewPassword(String? value, AppLocalizations loc) {
    if (value == null || value.isEmpty) return loc.resetErrPassReq;
    if (value.length < 8) return loc.resetErrPassLen;
    if (!value.contains(RegExp(r'[A-Z]'))) return loc.resetErrPassUp;
    if (!value.contains(RegExp(r'[a-z]'))) return loc.resetErrPassLow;
    return null;
  }

  static String? validateName(String? value, AppLocalizations loc) {
    if (value == null || value.trim().isEmpty) return loc.createErrNameReq;
    if (value.trim().length < 3) return loc.createErrNameMin;
    return null;
  }
}
