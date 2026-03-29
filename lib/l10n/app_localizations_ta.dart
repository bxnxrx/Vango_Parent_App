// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get otpTitle => 'கணக்கை சரிபார்க்கவும்';

  @override
  String otpSubtitlePhone(String id) {
    return '$id க்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்';
  }

  @override
  String otpSubtitleEmail(String id) {
    return '$id க்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்';
  }

  @override
  String get otpResendQ => 'குறியீடு கிடைக்கவில்லையா? ';

  @override
  String otpResendIn(String sec) {
    return '$sec வினாடிகளில் மீண்டும் அனுப்பு';
  }

  @override
  String get otpResendBtn => 'மீண்டும் அனுப்பு';

  @override
  String get otpVerifyBtn => 'சரிபார்த்து தொடரவும்';

  @override
  String get otpErrReq => 'அனைத்து 6 இலக்கங்களையும் உள்ளிடவும்';

  @override
  String get otpSuccessResend =>
      'சரிபார்ப்புக் குறியீடு வெற்றிகரமாக மீண்டும் அனுப்பப்பட்டது';

  @override
  String get resetTitle => 'புதிய கடவுச்சொல்லை உருவாக்கு';

  @override
  String get resetSubtitle =>
      'மின்னஞ்சலுக்கு அனுப்பப்பட்ட OTP மற்றும் புதிய கடவுச்சொல்லை உள்ளிடவும்.';

  @override
  String get resetOtpLabel => 'மீட்டமைப்பு குறியீடு (OTP)';

  @override
  String get resetOtpHint => '6 இலக்க குறியீடு';

  @override
  String get resetNewPassLabel => 'புதிய கடவுச்சொல்';

  @override
  String get resetNewPassHint => '********';

  @override
  String get resetConfirmPassLabel => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get resetConfirmPassHint => '********';

  @override
  String get resetBtn => 'கடவுச்சொல்லை அமைக்கவும்';

  @override
  String get resetErrOtpReq => 'OTP குறியீடு தேவை';

  @override
  String get resetErrPassReq => 'கடவுச்சொல் தேவை';

  @override
  String get resetErrPassLen =>
      'கடவுச்சொல் குறைந்தது 8 எழுத்துகளைக் கொண்டிருக்க வேண்டும்';

  @override
  String get resetErrPassUp => 'குறைந்தது ஒரு பெரிய எழுத்து இருக்க வேண்டும்';

  @override
  String get resetErrPassLow => 'குறைந்தது ஒரு சிறிய எழுத்து இருக்க வேண்டும்';

  @override
  String get resetErrConfirmReq => 'உங்கள் கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get resetErrPassMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get resetSuccess =>
      'கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது! உள்நுழையவும்.';

  @override
  String get loginWelcome => 'நல்வரவு';

  @override
  String get loginGetStarted => 'தொடங்கவும்';

  @override
  String get loginSubtitle =>
      'உள்நுழைய அல்லது பதிவு செய்ய விவரங்களை உள்ளிடவும்';

  @override
  String get loginPhoneTab => 'தொலைபேசி';

  @override
  String get loginEmailTab => 'மின்னஞ்சல்';

  @override
  String get loginPhoneLabel => 'தொலைபேசி எண்';

  @override
  String get loginPhoneHint => '7X XXX XXXX';

  @override
  String get loginEmailLabel => 'மின்னஞ்சல் முகவரி';

  @override
  String get loginEmailHint => 'name@example.com';

  @override
  String get loginPassLabel => 'கடவுச்சொல்';

  @override
  String get loginPassHint => '********';

  @override
  String get loginForgotPass => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginContinueBtn => 'தொடரவும்';

  @override
  String get loginOr => 'அல்லது';

  @override
  String get loginSecureBadge => 'பாதுகாப்பாக குறியாக்கம் செய்யப்பட்டது';

  @override
  String loginResetSent(String email) {
    return 'கடவுச்சொல் மீட்டமைப்பு இணைப்பு அனுப்பப்பட்டது';
  }

  @override
  String get loginErrPhoneReq => 'தொலைபேசி எண் தேவை';

  @override
  String get loginErrPhoneInv => 'தவறான வடிவம்';

  @override
  String get loginErrEmailReq => 'மின்னஞ்சல் தேவை';

  @override
  String get loginErrEmailInv => 'சரியான மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get loginErrPassReq => 'கடவுச்சொல் தேவை';

  @override
  String get loginErrPassMin =>
      'கடவுச்சொல் குறைந்தது 8 எழுத்துகளைக் கொண்டிருக்க வேண்டும்';

  @override
  String get loginErrUserNotFound =>
      'இந்த மின்னஞ்சலுக்கு கணக்கு எதுவும் கிடைக்கவில்லை.';

  @override
  String get createTitle => 'சுயவிவரத்தை முடிக்கவும்';

  @override
  String get createHeader => 'உங்களை பற்றி கூறுங்கள்';

  @override
  String get createSubtitle => 'உங்கள் கணக்கை அமைக்க சில விவரங்கள் தேவை.';

  @override
  String get createSectionPersonal => 'தனிப்பட்ட விவரங்கள்';

  @override
  String get createFullName => 'முழு பெயர்';

  @override
  String get createFullNameHint => 'எ.கா: ஜான் டோ';

  @override
  String get createMobile => 'கைபேசி எண்';

  @override
  String get createMobileHint => '7X XXX XXXX';

  @override
  String get createRelationship => 'உறவு';

  @override
  String get createRelParent => 'பெற்றோர்';

  @override
  String get createRelGuardian => 'பாதுகாவலர்';

  @override
  String get createRelOther => 'மற்றவை';

  @override
  String get createRelHint => 'வகையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get createEmailOpt => 'மின்னஞ்சல் (விருப்பத்திற்குரியது)';

  @override
  String get createEmailHint => 'name@example.com';

  @override
  String get createContinueBtn => 'தொடரவும்';

  @override
  String get createSignOutTitle => 'ரத்து செய்யவா?';

  @override
  String get createSignOutBody => 'இது உங்கள் கணக்கை முழுமையாக நீக்கிவிடும்.';

  @override
  String get createStay => 'தொடர்க';

  @override
  String get createSignOut => 'நீக்கி வெளியேறு';

  @override
  String get createErrNameReq => 'முழு பெயர் தேவை';

  @override
  String get createErrNameMin =>
      'பெயர் குறைந்தது 3 எழுத்துகளைக் கொண்டிருக்க வேண்டும்';

  @override
  String get createErrPhoneReq => 'தொலைபேசி எண் தேவை';

  @override
  String get createErrPhoneInv => 'தவறான வடிவம்';

  @override
  String get createErrEmailInv => 'சரியான மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get createErrRelReq => 'உங்கள் உறவு வகையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get createErrForm => 'படிவத்தில் உள்ள பிழைகளை சரிபார்க்கவும்.';

  @override
  String get createErrGeneric => 'ஏதோ தவறு நடந்துவிட்டது.';

  @override
  String get onboardingSkip => 'தவிர்';

  @override
  String get onboardingTitle1 => 'ஒவ்வொரு பயணத்தையும் கண்காணிக்கவும்';

  @override
  String get onboardingBody1 =>
      'நேரலை GPS, ETA கணிப்புகள் மற்றும் பாதுகாப்பு சோதனைகள் உங்களை கட்டுப்பாட்டில் வைக்கும்.';

  @override
  String get onboardingBtn1 => 'போகலாம்!';

  @override
  String get onboardingTitle2 => 'வருகையை உடனடியாக குறிக்கவும்';

  @override
  String get onboardingBody2 =>
      'ஓட்டுநருடன் ஒத்திசைக்கப்பட்டு பயண வழியை மேம்படுத்துகிறது.';

  @override
  String get onboardingBtn2 => 'வருகையை அமைக்கவும்';

  @override
  String get onboardingTitle3 => 'கொடுப்பனவுகள் மற்றும் தேடல் ஒரே செயலியில்';

  @override
  String get onboardingBody3 =>
      'கட்டணம் செலுத்துங்கள், புதிய ஓட்டுநர்களைக் கண்டறியுங்கள், பாதுகாப்பாக அரட்டையடிக்கவும்.';

  @override
  String get onboardingBtn3 => 'தொடங்கவும்';

  @override
  String get manageChildrenTitle => 'குழந்தைகளை நிர்வகி';

  @override
  String get addStudentBtn => 'மாணவரைச் சேர்';

  @override
  String get removeStudentTitle => 'பாதுகாப்பானது: மாணவரை அகற்று';

  @override
  String removeStudentConfirmation(String childName) {
    return '$childName ஐ அகற்ற விரும்புகிறீர்களா? இந்த செயலை மாற்ற முடியாது.';
  }

  @override
  String get cancelBtn => 'ரத்துசெய்';

  @override
  String get removeBtn => 'நிரந்தரமாக அகற்று';

  @override
  String studentRemovedSuccess(String childName) {
    return '$childName வெற்றிகரமாக அகற்றப்பட்டார்.';
  }

  @override
  String errorRemovingStudent(String error) {
    return 'மாணவரை அகற்றுவதில் பிழை: $error';
  }

  @override
  String get connectionErrorTitle => 'இணைப்பு பிழை';

  @override
  String get retryConnectionBtn => 'மீண்டும் இணைக்க முயற்சிக்கவும்';

  @override
  String get noStudentsAddedTitle => 'இன்னும் மாணவர்கள் சேர்க்கப்படவில்லை';

  @override
  String get addChildrenSubtitle =>
      'சவாரிகளைக் கண்காணிக்க உங்கள் குழந்தைகளைச் சேர்க்கவும்.';

  @override
  String get addFirstStudentBtn => 'முதல் மாணவரைச் சேர்';

  @override
  String get editProfileBtn => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get removeTooltip => 'அகற்று';

  @override
  String get genericError =>
      'தரவைப் பெறுவதில் பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get deleteError =>
      'மாணவரை அகற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';
}
