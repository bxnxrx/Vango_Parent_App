import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get otpTitle;

  /// No description provided for @otpSubtitlePhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to\n{id}'**
  String otpSubtitlePhone(String id);

  /// No description provided for @otpSubtitleEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to\n{id}'**
  String otpSubtitleEmail(String id);

  /// No description provided for @otpResendQ.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get otpResendQ;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {sec} s'**
  String otpResendIn(String sec);

  /// No description provided for @otpResendBtn.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResendBtn;

  /// No description provided for @otpVerifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify & Proceed'**
  String get otpVerifyBtn;

  /// No description provided for @otpErrReq.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get otpErrReq;

  /// No description provided for @otpSuccessResend.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent successfully'**
  String get otpSuccessResend;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to your email and your new secure password.'**
  String get resetSubtitle;

  /// No description provided for @resetOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset Code (OTP)'**
  String get resetOtpLabel;

  /// No description provided for @resetOtpHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get resetOtpHint;

  /// No description provided for @resetNewPassLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetNewPassLabel;

  /// No description provided for @resetNewPassHint.
  ///
  /// In en, this message translates to:
  /// **'********'**
  String get resetNewPassHint;

  /// No description provided for @resetConfirmPassLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get resetConfirmPassLabel;

  /// No description provided for @resetConfirmPassHint.
  ///
  /// In en, this message translates to:
  /// **'********'**
  String get resetConfirmPassHint;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get resetBtn;

  /// No description provided for @resetErrOtpReq.
  ///
  /// In en, this message translates to:
  /// **'OTP code is required'**
  String get resetErrOtpReq;

  /// No description provided for @resetErrPassReq.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get resetErrPassReq;

  /// No description provided for @resetErrPassLen.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get resetErrPassLen;

  /// No description provided for @resetErrPassUp.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one uppercase letter'**
  String get resetErrPassUp;

  /// No description provided for @resetErrPassLow.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one lowercase letter'**
  String get resetErrPassLow;

  /// No description provided for @resetErrConfirmReq.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get resetErrConfirmReq;

  /// No description provided for @resetErrPassMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get resetErrPassMismatch;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password successfully reset! Please log in.'**
  String get resetSuccess;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get loginWelcome;

  /// No description provided for @loginGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get loginGetStarted;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to log in or sign up'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneTab.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginPhoneTab;

  /// No description provided for @loginEmailTab.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailTab;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get loginPhoneLabel;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'7X XXX XXXX'**
  String get loginPhoneHint;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginPassLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassLabel;

  /// No description provided for @loginPassHint.
  ///
  /// In en, this message translates to:
  /// **'********'**
  String get loginPassHint;

  /// No description provided for @loginForgotPass.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPass;

  /// No description provided for @loginContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinueBtn;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get loginOr;

  /// No description provided for @loginSecureBadge.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get loginSecureBadge;

  /// No description provided for @loginResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String loginResetSent(String email);

  /// No description provided for @loginErrPhoneReq.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get loginErrPhoneReq;

  /// No description provided for @loginErrPhoneInv.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get loginErrPhoneInv;

  /// No description provided for @loginErrEmailReq.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginErrEmailReq;

  /// No description provided for @loginErrEmailInv.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get loginErrEmailInv;

  /// No description provided for @loginErrPassReq.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginErrPassReq;

  /// No description provided for @loginErrPassMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get loginErrPassMin;

  /// No description provided for @loginErrUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginErrUserNotFound;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get createTitle;

  /// No description provided for @createHeader.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get createHeader;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need a few details to set up your parent account.'**
  String get createSubtitle;

  /// No description provided for @createSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get createSectionPersonal;

  /// No description provided for @createFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get createFullName;

  /// No description provided for @createFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get createFullNameHint;

  /// No description provided for @createMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get createMobile;

  /// No description provided for @createMobileHint.
  ///
  /// In en, this message translates to:
  /// **'7X XXX XXXX'**
  String get createMobileHint;

  /// No description provided for @createRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get createRelationship;

  /// No description provided for @createRelParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get createRelParent;

  /// No description provided for @createRelGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get createRelGuardian;

  /// No description provided for @createRelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createRelOther;

  /// No description provided for @createRelHint.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get createRelHint;

  /// No description provided for @createEmailOpt.
  ///
  /// In en, this message translates to:
  /// **'Email Address (Optional)'**
  String get createEmailOpt;

  /// No description provided for @createEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get createEmailHint;

  /// No description provided for @createContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createContinueBtn;

  /// No description provided for @createSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Setup?'**
  String get createSignOutTitle;

  /// No description provided for @createSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'This will completely delete your account and you will need to register again.'**
  String get createSignOutBody;

  /// No description provided for @createStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get createStay;

  /// No description provided for @createSignOut.
  ///
  /// In en, this message translates to:
  /// **'Delete & Sign Out'**
  String get createSignOut;

  /// No description provided for @createErrNameReq.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get createErrNameReq;

  /// No description provided for @createErrNameMin.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get createErrNameMin;

  /// No description provided for @createErrPhoneReq.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number is required'**
  String get createErrPhoneReq;

  /// No description provided for @createErrPhoneInv.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get createErrPhoneInv;

  /// No description provided for @createErrEmailInv.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get createErrEmailInv;

  /// No description provided for @createErrRelReq.
  ///
  /// In en, this message translates to:
  /// **'Please select your relationship type.'**
  String get createErrRelReq;

  /// No description provided for @createErrForm.
  ///
  /// In en, this message translates to:
  /// **'Please check the form for errors.'**
  String get createErrForm;

  /// No description provided for @createErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get createErrGeneric;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Track every ride'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Live GPS, ETA predictions, and safety checks keep you in control.'**
  String get onboardingBody1;

  /// No description provided for @onboardingBtn1.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get onboardingBtn1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance instantly'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Smart toggles sync with the driver and optimize the route.'**
  String get onboardingBody2;

  /// No description provided for @onboardingBtn2.
  ///
  /// In en, this message translates to:
  /// **'Set attendance'**
  String get onboardingBtn2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Payments & finder in one app'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Pay van fees, discover new drivers, and chat securely.'**
  String get onboardingBody3;

  /// No description provided for @onboardingBtn3.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingBtn3;

  /// No description provided for @manageChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Children'**
  String get manageChildrenTitle;

  /// No description provided for @addStudentBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudentBtn;

  /// No description provided for @removeStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure: Remove Student'**
  String get removeStudentTitle;

  /// No description provided for @removeStudentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {childName}? This action cannot be undone and will permanently delete tracking history.'**
  String removeStudentConfirmation(String childName);

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @removeBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove Permanently'**
  String get removeBtn;

  /// No description provided for @studentRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{childName} removed successfully.'**
  String studentRemovedSuccess(String childName);

  /// No description provided for @errorRemovingStudent.
  ///
  /// In en, this message translates to:
  /// **'Error removing student: {error}'**
  String errorRemovingStudent(String error);

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionErrorTitle;

  /// No description provided for @retryConnectionBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnectionBtn;

  /// No description provided for @noStudentsAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'No students added yet'**
  String get noStudentsAddedTitle;

  /// No description provided for @addChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your children to start tracking their rides securely.'**
  String get addChildrenSubtitle;

  /// No description provided for @addFirstStudentBtn.
  ///
  /// In en, this message translates to:
  /// **'Add First Student'**
  String get addFirstStudentBtn;

  /// No description provided for @editProfileBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileBtn;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong securely fetching data. Please try again.'**
  String get genericError;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the student securely. Please try again.'**
  String get deleteError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
