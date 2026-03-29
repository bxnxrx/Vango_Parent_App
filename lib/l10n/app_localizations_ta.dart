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

  @override
  String get addChildTitle => 'புதிய மாணவரைச் சேர்';

  @override
  String get editChildTitle => 'மாணவர் விவரங்களைத் திருத்து';

  @override
  String get addChildSubtitle => 'சுயவிவரத்தை அமைக்க விவரங்களை நிரப்பவும்.';

  @override
  String get addPhotoLabel => 'புகைப்படம் சேர்';

  @override
  String get personalInfoSection => 'தனிப்பட்ட தகவல்';

  @override
  String get studentNameLabel => 'மாணவரின் முழு பெயர்';

  @override
  String get studentNameRequired => 'பெயர் தேவை';

  @override
  String get ageLabel => 'வயது (2-21)';

  @override
  String get ageRequired => 'வயது தேவை';

  @override
  String get ageInvalid => '2 முதல் 21 வரை சரியான எண்ணாக இருக்க வேண்டும்';

  @override
  String get emergencyContactSection => 'அவசர தொடர்பு எண்';

  @override
  String get useParentProfileNumber => 'பெற்றோர் சுயவிவர எண்ணைப் பயன்படுத்துக';

  @override
  String get previouslyUsedNumber => 'முன்பு பயன்படுத்தப்பட்டது';

  @override
  String get addNewNumber => 'புதிய எண்ணைச் சேர்';

  @override
  String get newEmergencyContactLabel => 'புதிய அவசர தொடர்பு';

  @override
  String get invalidSlNumber => 'தவறான இலங்கை எண் (உ.ம் 712345678)';

  @override
  String get tapVerifyConfirm => 'உறுதிப்படுத்த Verify ஐ அழுத்தவும்';

  @override
  String get schoolRouteDetailsSection => 'பள்ளி மற்றும் பாதை விவரங்கள்';

  @override
  String get schoolNameLabel => 'பள்ளியின் பெயர்';

  @override
  String get schoolNameHint => 'பள்ளியின் பெயரை உள்ளிடவும்...';

  @override
  String get schoolRequired => 'பள்ளி தேவை';

  @override
  String get pickupLocationLabel => 'ஏற்றும் இடம்';

  @override
  String get tapToSetOnMap => 'வரைபடத்தில் அமைக்க தட்டவும்';

  @override
  String get pickupRequired => 'ஏற்றும் இடம் தேவை';

  @override
  String get dropLocationLabel => 'இறக்கும் இடம்';

  @override
  String get dropRequired => 'இறக்கும் இடம் தேவை';

  @override
  String get etaSchoolLabel => 'பள்ளிக்கு வந்தடையும் நேரம்';

  @override
  String get etaRequired => 'வந்தடையும் நேரம் தேவை';

  @override
  String get distanceLabel => 'தூரம்';

  @override
  String get trafficDelayLabel => 'போக்குவரத்து தாமதம்';

  @override
  String get suggestedLeaveByLabel => 'புறப்பட பரிந்துரைக்கப்படும் நேரம்';

  @override
  String get confirmPickupTimeLabel => 'ஏற்றும் நேரத்தை உறுதிப்படுத்தவும்';

  @override
  String get pickupTimeRequired => 'ஏற்றும் நேரம் தேவை';

  @override
  String get smallDescriptionLabel => 'சிறிய விளக்கம் (விருப்பத்தேர்வு)';

  @override
  String get smallDescriptionHint => 'சாரதிக்கான குறிப்புகள்...';

  @override
  String get saveStudentBtn => 'மாணவர் விவரங்களைச் சேமி';

  @override
  String get updateProfileBtn => 'சுயவிவரத்தைப் புதுப்பி';

  @override
  String get savingStatus => 'சேமிக்கப்படுகிறது...';

  @override
  String errorSaving(String error) {
    return 'பிழை: $error';
  }

  @override
  String studentSavedSuccess(String name) {
    return '$name வெற்றிகரமாக சேமிக்கப்பட்டது!';
  }

  @override
  String get duplicateStudentError =>
      'இந்த மாணவர் ஏற்கனவே சேர்க்கப்பட்டுள்ளார்.';

  @override
  String get verifyContactError => 'புதிய எண்ணை உறுதிப்படுத்தவும்.';

  @override
  String get verifyDriverError => 'சாரதி குறியீட்டை உறுதிப்படுத்தவும்.';

  @override
  String get cameraDeniedError => 'க্যামரா அனுமதி மறுக்கப்பட்டது.';

  @override
  String get alreadyHaveDriver => 'ஏற்கனவே சாரதி இருக்கிறாரா?';

  @override
  String get enterInviteCodeBelow =>
      'அவர்களின் அழைப்பு குறியீட்டை கீழே உள்ளிடவும்';

  @override
  String get findDriverLater => 'நான் பின்னர் ஒரு சாரதியைக் கண்டுபிடிப்பேன்';

  @override
  String get driverInviteCode => 'சாரதி அழைப்பு குறியீடு';

  @override
  String get scanQRCodeTooltip => 'QR குறியீட்டை ஸ்கேன் செய்யவும்';

  @override
  String get codeRequired => 'குறியீடு தேவை';

  @override
  String get codeLengthError =>
      'குறியீடு சரியாக 8 எழுத்துகளைக் கொண்டிருக்க வேண்டும்';

  @override
  String get verifyCodeFirst =>
      'தயவுசெய்து குறியீட்டை முதலில் உறுதிப்படுத்தவும்';

  @override
  String get verifyBtn => 'உறுதிப்படுத்து';

  @override
  String get driverFoundValidated =>
      'சாரதி கண்டுபிடிக்கப்பட்டு உறுதிப்படுத்தப்பட்டார்!';

  @override
  String get driverNameLabel => 'பெயர்';

  @override
  String get driverVehicleLabel => 'வாகனம்';

  @override
  String get driverAreaLabel => 'இயங்கும் பகுதி';

  @override
  String get verifyEmergencyContact => 'அவசர தொடர்பை உறுதிப்படுத்தவும்';

  @override
  String sentCodeTo(String phone) {
    return 'நாங்கள் $phone க்கு 6 இலக்க குறியீட்டை அனுப்பியுள்ளோம்';
  }

  @override
  String get sixDigitSmsCode => '6-இலக்க SMS குறியீடு';

  @override
  String get resendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String resendIn(int seconds) {
    return '$seconds வினாடிகளில் மீண்டும் அனுப்பு';
  }

  @override
  String get confirmCodeBtn => 'குறியீட்டை உறுதிப்படுத்து';

  @override
  String get codeResentSuccess =>
      'குறியீடு வெற்றிகரமாக மீண்டும் அனுப்பப்பட்டது!';

  @override
  String get failedToResendCode => 'குறியீட்டை மீண்டும் அனுப்ப முடியவில்லை';

  @override
  String get invalidCodeTryAgain => 'தவறான குறியீடு. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get cancelBtnText => 'ரத்துசெய்';

  @override
  String get doneBtnText => 'முடிந்தது';

  @override
  String get selectArrivalTime => 'வந்தடையும் நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get scanQrCodeTitle => 'QR குறியீட்டை ஸ்கேன் செய்யவும்';

  @override
  String get failedToSendOtp => 'OTP அனுப்ப முடியவில்லை';

  @override
  String get failedToVerifyOtp => 'OTP உறுதிப்படுத்த முடியவில்லை';

  @override
  String get otpVerificationSuccess =>
      'அவசர தொடர்பு வெற்றிகரமாக உறுதிப்படுத்தப்பட்டது';

  @override
  String get driverNotFound => 'சாரதி காணப்படவில்லை அல்லது தவறான குறியீடு';

  @override
  String get pickupLocation => 'ஏற்றும் இடம்';

  @override
  String get dropLocation => 'இறக்கும் இடம்';

  @override
  String get moveMapToAdjust => 'இடத்தை மாற்ற வரைபடத்தை நகர்த்தவும்';

  @override
  String get confirmLocation => 'இடத்தை உறுதிப்படுத்தவும்';

  @override
  String get pickupTimeExample => 'உ.ம். 06:45 AM';

  @override
  String get defaultPickupTime => '06:45 AM';
}
