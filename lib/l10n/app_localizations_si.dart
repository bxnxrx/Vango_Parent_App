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

  @override
  String get onboardingSkip => 'මඟ හරින්න';

  @override
  String get onboardingTitle1 => 'සෑම ගමනක්ම නිරීක්ෂණය කරන්න';

  @override
  String get onboardingBody1 =>
      'සජීවී GPS, ETA අනාවැකි සහ ආරක්ෂක පරීක්ෂාවන් මඟින් ඔබව දැනුවත් කරයි.';

  @override
  String get onboardingBtn1 => 'අපි යමු!';

  @override
  String get onboardingTitle2 => 'පැමිණීම ක්ෂණිකව සටහන් කරන්න';

  @override
  String get onboardingBody2 =>
      'රියදුරු සමඟ සමමුහුර්ත වී ගමන් මාර්ගය ප්‍රශස්ත කරයි.';

  @override
  String get onboardingBtn2 => 'පැමිණීම සටහන් කරන්න';

  @override
  String get onboardingTitle3 => 'ගෙවීම් සහ සෙවුම් එකම යෙදුමකින්';

  @override
  String get onboardingBody3 =>
      'ගාස්තු ගෙවන්න, නව රියදුරන් සොයන්න, සහ ආරක්ෂිතව කතාබස් කරන්න.';

  @override
  String get onboardingBtn3 => 'ආරම්භ කරන්න';

  @override
  String get manageChildrenTitle => 'ළමුන් කළමනාකරණය';

  @override
  String get addStudentBtn => 'සිසුවා එකතු කරන්න';

  @override
  String get removeStudentTitle => 'ආරක්ෂිතයි: සිසුවා ඉවත් කරන්න';

  @override
  String removeStudentConfirmation(String childName) {
    return 'ඔබට $childName ඉවත් කිරීමට අවශ්‍ය බව විශ්වාසද? මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.';
  }

  @override
  String get cancelBtn => 'අවලංගු කරන්න';

  @override
  String get removeBtn => 'ස්ථිරවම ඉවත් කරන්න';

  @override
  String studentRemovedSuccess(String childName) {
    return '$childName සාර්ථකව ඉවත් කරන ලදී.';
  }

  @override
  String errorRemovingStudent(String error) {
    return 'ඉවත් කිරීමේ දෝෂයකි: $error';
  }

  @override
  String get connectionErrorTitle => 'සම්බන්ධතා දෝෂයකි';

  @override
  String get retryConnectionBtn => 'නැවත උත්සාහ කරන්න';

  @override
  String get noStudentsAddedTitle => 'තවමත් සිසුන් එකතු කර නොමැත';

  @override
  String get addChildrenSubtitle =>
      'ඔවුන්ගේ ගමන් නිරීක්ෂණය කිරීමට ඔබේ දරුවන් එකතු කරන්න.';

  @override
  String get addFirstStudentBtn => 'පළමු සිසුවා එකතු කරන්න';

  @override
  String get editProfileBtn => 'පැතිකඩ සංස්කරණය';

  @override
  String get removeTooltip => 'ඉවත් කරන්න';

  @override
  String get genericError =>
      'දත්ත ලබා ගැනීමේදී දෝෂයක් ඇති විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get deleteError =>
      'සිසුවා ඉවත් කිරීමට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get addChildTitle => 'නව සිසුවා එකතු කරන්න';

  @override
  String get editChildTitle => 'සිසු තොරතුරු සංස්කරණය';

  @override
  String get addChildSubtitle => 'සිසු පැතිකඩ සැකසීමට පහත තොරතුරු පුරවන්න.';

  @override
  String get addPhotoLabel => 'ඡායාරූපය එකතු කරන්න';

  @override
  String get personalInfoSection => 'පුද්ගලික තොරතුරු';

  @override
  String get studentNameLabel => 'සිසුවාගේ සම්පූර්ණ නම';

  @override
  String get studentNameRequired => 'නම අවශ්‍යයි';

  @override
  String get ageLabel => 'වයස (2-21)';

  @override
  String get ageRequired => 'වයස අවශ්‍යයි';

  @override
  String get ageInvalid => '2 ත් 21 ත් අතර වලංගු අංකයක් විය යුතුය';

  @override
  String get emergencyContactSection => 'හදිසි ඇමතුම් අංකය';

  @override
  String get useParentProfileNumber => 'දෙමාපිය පැතිකඩ අංකය භාවිතා කරන්න';

  @override
  String get previouslyUsedNumber => 'පෙර භාවිතා කළ';

  @override
  String get addNewNumber => 'නව අංකයක් එක් කරන්න';

  @override
  String get newEmergencyContactLabel => 'නව හදිසි ඇමතුම් අංකය';

  @override
  String get invalidSlNumber => 'අවලංගු ශ්‍රී ලංකා අංකයකි (උදා. 712345678)';

  @override
  String get tapVerifyConfirm => 'මෙම අංකය තහවුරු කිරීමට Verify ඔබන්න';

  @override
  String get schoolRouteDetailsSection => 'පාසල සහ ගමන් මාර්ගය';

  @override
  String get schoolNameLabel => 'පාසලේ නම';

  @override
  String get schoolNameHint => 'පාසලේ නම ටයිප් කරන්න...';

  @override
  String get schoolRequired => 'පාසල අවශ්‍යයි';

  @override
  String get pickupLocationLabel => 'නැංවීමේ ස්ථානය';

  @override
  String get tapToSetOnMap => 'සිතියම මත සැකසීමට ඔබන්න';

  @override
  String get pickupRequired => 'නැංවීමේ ස්ථානය අවශ්‍යයි';

  @override
  String get dropLocationLabel => 'බැස්සවීමේ ස්ථානය';

  @override
  String get dropRequired => 'බැස්සවීමේ ස්ථානය අවශ්‍යයි';

  @override
  String get etaSchoolLabel => 'පාසලට ළඟා වන ඇස්තමේන්තුගත කාලය';

  @override
  String get etaRequired => 'පැමිණීමේ වේලාව අවශ්‍යයි';

  @override
  String get distanceLabel => 'දුර';

  @override
  String get trafficDelayLabel => 'මාර්ග තදබදය';

  @override
  String get suggestedLeaveByLabel => 'පිටවිය යුතු යෝජිත වේලාව';

  @override
  String get confirmPickupTimeLabel => 'නැංවීමේ වේලාව තහවුරු කරන්න';

  @override
  String get pickupTimeRequired => 'නැංවීමේ වේලාව අවශ්‍යයි';

  @override
  String get smallDescriptionLabel => 'කුඩා විස්තරයක් (විකල්ප)';

  @override
  String get smallDescriptionHint => 'රියදුරා සඳහා සටහන්...';

  @override
  String get saveStudentBtn => 'සිසු තොරතුරු සුරකින්න';

  @override
  String get updateProfileBtn => 'පැතිකඩ යාවත්කාලීන කරන්න';

  @override
  String get savingStatus => 'සුරකිමින්...';

  @override
  String errorSaving(String error) {
    return 'දෝෂයකි: $error';
  }

  @override
  String studentSavedSuccess(String name) {
    return '$name සාර්ථකව සුරකින ලදී!';
  }

  @override
  String get duplicateStudentError => 'මෙම සිසුවා දැනටමත් එකතු කර ඇත.';

  @override
  String get verifyContactError => 'කරුණාකර නව අංකය තහවුරු කරන්න.';

  @override
  String get verifyDriverError => 'කරුණාකර රියදුරු කේතය තහවුරු කරන්න.';

  @override
  String get cameraDeniedError => 'කැමරා ප්‍රවේශය ප්‍රතික්ෂේප විය.';

  @override
  String get alreadyHaveDriver => 'දැනටමත් රියදුරෙකු සිටීද?';

  @override
  String get enterInviteCodeBelow => 'ඔවුන්ගේ ආරාධනා කේතය පහතින් ඇතුලත් කරන්න';

  @override
  String get findDriverLater => 'මම පසුව රියදුරෙකු සොයා ගනිමි';

  @override
  String get driverInviteCode => 'රියදුරු ආරාධනා කේතය';

  @override
  String get scanQRCodeTooltip => 'QR කේතය ස්කෑන් කරන්න';

  @override
  String get codeRequired => 'කේතය අවශ්‍යයි';

  @override
  String get codeLengthError => 'කේතය අක්ෂර 8 කින් සමන්විත විය යුතුය';

  @override
  String get verifyCodeFirst => 'කරුණාකර පළමුව කේතය තහවුරු කරන්න';

  @override
  String get verifyBtn => 'තහවුරු කරන්න';

  @override
  String get driverFoundValidated => 'රියදුරු හමුවී තහවුරු කරන ලදී!';

  @override
  String get driverNameLabel => 'නම';

  @override
  String get driverVehicleLabel => 'වාහනය';

  @override
  String get driverAreaLabel => 'මෙහෙයුම් ප්‍රදේශය';

  @override
  String get verifyEmergencyContact => 'හදිසි ඇමතුම් අංකය තහවුරු කරන්න';

  @override
  String sentCodeTo(String phone) {
    return 'අපි $phone වෙත ඉලක්කම් 6 ක කේතයක් යැව්වෙමු';
  }

  @override
  String get sixDigitSmsCode => 'ඉලක්කම් 6ක SMS කේතය';

  @override
  String get resendCode => 'නැවත කේතය යවන්න';

  @override
  String resendIn(int seconds) {
    return 'තත්පර $seconds කින් නැවත යවන්න';
  }

  @override
  String get confirmCodeBtn => 'කේතය තහවුරු කරන්න';

  @override
  String get codeResentSuccess => 'කේතය සාර්ථකව නැවත යවන ලදී!';

  @override
  String get failedToResendCode => 'කේතය නැවත යැවීමට නොහැකි විය';

  @override
  String get invalidCodeTryAgain => 'අවලංගු කේතයකි. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get cancelBtnText => 'අවලංගු කරන්න';

  @override
  String get doneBtnText => 'අවසන්';

  @override
  String get selectArrivalTime => 'පැමිණීමේ වේලාව තෝරන්න';

  @override
  String get scanQrCodeTitle => 'QR කේතය ස්කෑන් කරන්න';

  @override
  String get failedToSendOtp => 'OTP යැවීමට නොහැකි විය';

  @override
  String get failedToVerifyOtp => 'OTP තහවුරු කිරීමට නොහැකි විය';

  @override
  String get otpVerificationSuccess =>
      'හදිසි ඇමතුම් අංකය සාර්ථකව තහවුරු කරන ලදී';

  @override
  String get driverNotFound => 'රියදුරු හමු නොවීය හෝ අවලංගු කේතයකි';

  @override
  String get pickupLocation => 'නැංවීමේ ස්ථානය';

  @override
  String get dropLocation => 'බැස්සවීමේ ස්ථානය';

  @override
  String get moveMapToAdjust => 'ස්ථානය වෙනස් කිරීමට සිතියම ගෙන යන්න';

  @override
  String get confirmLocation => 'ස්ථානය තහවුරු කරන්න';

  @override
  String get pickupTimeExample => 'උදා. 06:45 AM';

  @override
  String get defaultPickupTime => '06:45 AM';

  @override
  String get searchHint => 'නම හෝ පාසල මගින් සොයන්න...';

  @override
  String get filterAll => 'සියල්ල';

  @override
  String get filterPaid => 'ගෙවා ඇත';

  @override
  String get filterUnpaid => 'ගෙවා නැත';

  @override
  String get noResults => 'ප්‍රතිඵල හමු නොවීය';

  @override
  String get tryAdjustFilters => 'ඔබගේ සෙවුම හෝ පෙරහන් වෙනස් කර බලන්න.';

  @override
  String get pickupLabel => 'නැංවීම';

  @override
  String get timeLabel => 'වේලාව';

  @override
  String get statusPaid => 'ගෙවා ඇත';

  @override
  String get statusDue => 'ගෙවිය යුතුයි';
}
