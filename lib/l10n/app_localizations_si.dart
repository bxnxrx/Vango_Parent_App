// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get otpTitle => 'ගිණුම තහවුරු කරන්න';

  @override
  String otpSubtitlePhone(String id) {
    return '$id වෙත යැවූ ඉලක්කම් 6ක කේතය ඇතුළත් කරන්න';
  }

  @override
  String otpSubtitleEmail(String id) {
    return '$id වෙත යැවූ ඉලක්කම් 6ක කේතය ඇතුළත් කරන්න';
  }

  @override
  String get otpResendQ => 'කේතය ලැබුණේ නැද්ද? ';

  @override
  String otpResendIn(String sec) {
    return 'තත්පර $sec කින් නැවත යවන්න';
  }

  @override
  String get otpResendBtn => 'නැවත යවන්න';

  @override
  String get otpVerifyBtn => 'තහවුරු කර ඉදිරියට';

  @override
  String get otpErrReq => 'කරුණාකර ඉලක්කම් 6ම ඇතුළත් කරන්න';

  @override
  String get otpSuccessResend => 'තහවුරු කිරීමේ කේතය සාර්ථකව නැවත යවන ලදී';

  @override
  String get resetTitle => 'නව මුරපදයක් සාදන්න';

  @override
  String get resetSubtitle =>
      'ඔබගේ විද්‍යුත් තැපෑලට යැවූ OTP කේතය සහ නව මුරපදය ඇතුළත් කරන්න.';

  @override
  String get resetOtpLabel => 'යළි පිහිටුවීමේ කේතය (OTP)';

  @override
  String get resetOtpHint => 'ඉලක්කම් 6ක කේතය';

  @override
  String get resetNewPassLabel => 'නව මුරපදය';

  @override
  String get resetNewPassHint => '********';

  @override
  String get resetConfirmPassLabel => 'මුරපදය තහවුරු කරන්න';

  @override
  String get resetConfirmPassHint => '********';

  @override
  String get resetBtn => 'නව මුරපදය සකසන්න';

  @override
  String get resetErrOtpReq => 'OTP කේතය අවශ්‍යයි';

  @override
  String get resetErrPassReq => 'මුරපදය අවශ්‍යයි';

  @override
  String get resetErrPassLen => 'මුරපදය අවම වශයෙන් අකුරු 8ක් විය යුතුය';

  @override
  String get resetErrPassUp => 'අවම වශයෙන් එක් කැපිටල් අකුරක් අඩංගු විය යුතුය';

  @override
  String get resetErrPassLow => 'අවම වශයෙන් එක් සිම්පල් අකුරක් අඩංගු විය යුතුය';

  @override
  String get resetErrConfirmReq => 'කරුණාකර ඔබගේ මුරපදය තහවුරු කරන්න';

  @override
  String get resetErrPassMismatch => 'මුරපද නොගැලපේ';

  @override
  String get resetSuccess =>
      'මුරපදය සාර්ථකව යළි පිහිටුවන ලදී! කරුණාකර ලොග් වන්න.';

  @override
  String get loginWelcome => 'ආයුබෝවන්';

  @override
  String get loginGetStarted => 'ආරම්භ කරන්න';

  @override
  String get loginSubtitle =>
      'ලොග් වීමට හෝ ලියාපදිංචි වීමට තොරතුරු ඇතුලත් කරන්න';

  @override
  String get loginPhoneTab => 'දුරකථනය';

  @override
  String get loginEmailTab => 'විද්‍යුත් තැපෑල';

  @override
  String get loginPhoneLabel => 'දුරකථන අංකය';

  @override
  String get loginPhoneHint => '7X XXX XXXX';

  @override
  String get loginEmailLabel => 'විද්‍යුත් තැපැල් ලිපිනය';

  @override
  String get loginEmailHint => 'name@example.com';

  @override
  String get loginPassLabel => 'මුරපදය';

  @override
  String get loginPassHint => '********';

  @override
  String get loginForgotPass => 'මුරපදය අමතකද?';

  @override
  String get loginContinueBtn => 'ඉදිරියට';

  @override
  String get loginOr => 'හෝ';

  @override
  String get loginSecureBadge => 'ආරක්ෂිතව සංකේතනය කර ඇත';

  @override
  String loginResetSent(String email) {
    return 'මුරපද යළි පිහිටුවීමේ සබැඳිය යවන ලදී';
  }

  @override
  String get loginErrPhoneReq => 'දුරකථන අංකය අවශ්‍යයි';

  @override
  String get loginErrPhoneInv => 'වැරදි ආකෘතියකි';

  @override
  String get loginErrEmailReq => 'විද්‍යුත් තැපෑල අවශ්‍යයි';

  @override
  String get loginErrEmailInv => 'නිවැරදි විද්‍යුත් තැපෑලක් ඇතුලත් කරන්න';

  @override
  String get loginErrPassReq => 'මුරපදය අවශ්‍යයි';

  @override
  String get loginErrPassMin => 'මුරපදය අවම වශයෙන් අකුරු 8ක් විය යුතුය';

  @override
  String get loginErrUserNotFound =>
      'මෙම විද්‍යුත් තැපෑල සඳහා ගිණුමක් හමු නොවීය.';

  @override
  String get createTitle => 'පැතිකඩ සම්පූර්ණ කරන්න';

  @override
  String get createHeader => 'ඔබ ගැන අපට කියන්න';

  @override
  String get createSubtitle =>
      'ඔබගේ ගිණුම සැකසීමට අපට විස්තර කිහිපයක් අවශ්‍යයි.';

  @override
  String get createSectionPersonal => 'පුද්ගලික විස්තර';

  @override
  String get createFullName => 'සම්පූර්ණ නම';

  @override
  String get createFullNameHint => 'උදා: කසුන් පෙරේරා';

  @override
  String get createMobile => 'ජංගම දුරකථන අංකය';

  @override
  String get createMobileHint => '7X XXX XXXX';

  @override
  String get createRelationship => 'සම්බන්ධතාවය';

  @override
  String get createRelParent => 'දෙමාපියන්';

  @override
  String get createRelGuardian => 'භාරකරු';

  @override
  String get createRelOther => 'වෙනත්';

  @override
  String get createRelHint => 'වර්ගය තෝරන්න';

  @override
  String get createEmailOpt => 'විද්‍යුත් තැපෑල (විකල්ප)';

  @override
  String get createEmailHint => 'name@example.com';

  @override
  String get createContinueBtn => 'ඉදිරියට';

  @override
  String get createSignOutTitle => 'අවලංගු කරන්නද?';

  @override
  String get createSignOutBody => 'මෙය ඔබගේ ගිණුම සම්පූර්ණයෙන්ම මකා දමනු ඇත.';

  @override
  String get createStay => 'රැඳී සිටින්න';

  @override
  String get createSignOut => 'මකා ඉවත් වන්න';

  @override
  String get createErrNameReq => 'සම්පූර්ණ නම අවශ්‍යයි';

  @override
  String get createErrNameMin => 'නම අවම වශයෙන් අකුරු 3ක් විය යුතුය';

  @override
  String get createErrPhoneReq => 'දුරකථන අංකය අවශ්‍යයි';

  @override
  String get createErrPhoneInv => 'වැරදි ආකෘතියකි';

  @override
  String get createErrEmailInv => 'නිවැරදි විද්‍යුත් තැපෑලක් ඇතුලත් කරන්න';

  @override
  String get createErrRelReq => 'කරුණාකර සම්බන්ධතා වර්ගය තෝරන්න.';

  @override
  String get createErrForm => 'කරුණාකර පෝරමයේ දෝෂ පරීක්ෂා කරන්න.';

  @override
  String get createErrGeneric => 'දෝෂයක් සිදුවිය.';
}
