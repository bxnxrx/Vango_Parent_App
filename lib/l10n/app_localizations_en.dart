// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get otpTitle => 'Verify Account';

  @override
  String otpSubtitlePhone(String id) {
    return 'Enter the 6-digit code sent to\n$id';
  }

  @override
  String otpSubtitleEmail(String id) {
    return 'Enter the 6-digit code sent to\n$id';
  }

  @override
  String get otpResendQ => 'Didn\'t receive the code? ';

  @override
  String otpResendIn(String sec) {
    return 'Resend in $sec s';
  }

  @override
  String get otpResendBtn => 'Resend Code';

  @override
  String get otpVerifyBtn => 'Verify & Proceed';

  @override
  String get otpErrReq => 'Please enter all 6 digits';

  @override
  String get otpSuccessResend => 'Verification code resent successfully';

  @override
  String get resetTitle => 'Create New Password';

  @override
  String get resetSubtitle =>
      'Enter the OTP sent to your email and your new secure password.';

  @override
  String get resetOtpLabel => 'Reset Code (OTP)';

  @override
  String get resetOtpHint => '6-digit code';

  @override
  String get resetNewPassLabel => 'New Password';

  @override
  String get resetNewPassHint => '********';

  @override
  String get resetConfirmPassLabel => 'Confirm Password';

  @override
  String get resetConfirmPassHint => '********';

  @override
  String get resetBtn => 'Set New Password';

  @override
  String get resetErrOtpReq => 'OTP code is required';

  @override
  String get resetErrPassReq => 'Password is required';

  @override
  String get resetErrPassLen => 'Password must be at least 8 characters';

  @override
  String get resetErrPassUp => 'Must contain at least one uppercase letter';

  @override
  String get resetErrPassLow => 'Must contain at least one lowercase letter';

  @override
  String get resetErrConfirmReq => 'Please confirm your password';

  @override
  String get resetErrPassMismatch => 'Passwords do not match';

  @override
  String get resetSuccess => 'Password successfully reset! Please log in.';

  @override
  String get loginWelcome => 'Welcome to';

  @override
  String get loginGetStarted => 'Get Started';

  @override
  String get loginSubtitle => 'Enter your details to log in or sign up';

  @override
  String get loginPhoneTab => 'Phone';

  @override
  String get loginEmailTab => 'Email';

  @override
  String get loginPhoneLabel => 'Phone Number';

  @override
  String get loginPhoneHint => '7X XXX XXXX';

  @override
  String get loginEmailLabel => 'Email Address';

  @override
  String get loginEmailHint => 'name@example.com';

  @override
  String get loginPassLabel => 'Password';

  @override
  String get loginPassHint => '********';

  @override
  String get loginForgotPass => 'Forgot Password?';

  @override
  String get loginContinueBtn => 'Continue';

  @override
  String get loginOr => 'Or';

  @override
  String get loginSecureBadge => 'End-to-end encrypted';

  @override
  String loginResetSent(String email) {
    return 'Reset link sent to $email';
  }

  @override
  String get loginErrPhoneReq => 'Phone number is required';

  @override
  String get loginErrPhoneInv => 'Invalid format';

  @override
  String get loginErrEmailReq => 'Email is required';

  @override
  String get loginErrEmailInv => 'Enter a valid email address';

  @override
  String get loginErrPassReq => 'Password is required';

  @override
  String get loginErrPassMin => 'Password must be at least 8 characters';

  @override
  String get loginErrUserNotFound => 'No account found with this email.';

  @override
  String get createTitle => 'Complete Profile';

  @override
  String get createHeader => 'Tell us about yourself';

  @override
  String get createSubtitle =>
      'We need a few details to set up your parent account.';

  @override
  String get createSectionPersonal => 'Personal Details';

  @override
  String get createFullName => 'Full Name';

  @override
  String get createFullNameHint => 'e.g. John Doe';

  @override
  String get createMobile => 'Mobile Number';

  @override
  String get createMobileHint => '7X XXX XXXX';

  @override
  String get createRelationship => 'Relationship';

  @override
  String get createRelParent => 'Parent';

  @override
  String get createRelGuardian => 'Guardian';

  @override
  String get createRelOther => 'Other';

  @override
  String get createRelHint => 'Select Type';

  @override
  String get createEmailOpt => 'Email Address (Optional)';

  @override
  String get createEmailHint => 'name@example.com';

  @override
  String get createContinueBtn => 'Continue';

  @override
  String get createSignOutTitle => 'Cancel Setup?';

  @override
  String get createSignOutBody =>
      'This will completely delete your account and you will need to register again.';

  @override
  String get createStay => 'Stay';

  @override
  String get createSignOut => 'Delete & Sign Out';

  @override
  String get createErrNameReq => 'Full Name is required';

  @override
  String get createErrNameMin => 'Name must be at least 3 characters';

  @override
  String get createErrPhoneReq => 'Mobile Number is required';

  @override
  String get createErrPhoneInv => 'Invalid format';

  @override
  String get createErrEmailInv => 'Enter a valid email address';

  @override
  String get createErrRelReq => 'Please select your relationship type.';

  @override
  String get createErrForm => 'Please check the form for errors.';

  @override
  String get createErrGeneric => 'Something went wrong.';
}
