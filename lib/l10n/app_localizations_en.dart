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

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingTitle1 => 'Track every ride';

  @override
  String get onboardingBody1 =>
      'Live GPS, ETA predictions, and safety checks keep you in control.';

  @override
  String get onboardingBtn1 => 'Let\'s go!';

  @override
  String get onboardingTitle2 => 'Mark attendance instantly';

  @override
  String get onboardingBody2 =>
      'Smart toggles sync with the driver and optimize the route.';

  @override
  String get onboardingBtn2 => 'Set attendance';

  @override
  String get onboardingTitle3 => 'Payments & finder in one app';

  @override
  String get onboardingBody3 =>
      'Pay van fees, discover new drivers, and chat securely.';

  @override
  String get onboardingBtn3 => 'Get started';

  @override
  String get manageChildrenTitle => 'Manage Children';

  @override
  String get addStudentBtn => 'Add Student';

  @override
  String get removeStudentTitle => 'Secure: Remove Student';

  @override
  String removeStudentConfirmation(String childName) {
    return 'Are you sure you want to remove $childName? This action cannot be undone and will permanently delete tracking history.';
  }

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get removeBtn => 'Remove Permanently';

  @override
  String studentRemovedSuccess(String childName) {
    return '$childName removed successfully.';
  }

  @override
  String errorRemovingStudent(String error) {
    return 'Error removing student: $error';
  }

  @override
  String get connectionErrorTitle => 'Connection Error';

  @override
  String get retryConnectionBtn => 'Retry Connection';

  @override
  String get noStudentsAddedTitle => 'No students added yet';

  @override
  String get addChildrenSubtitle =>
      'Add your children to start tracking their rides securely.';

  @override
  String get addFirstStudentBtn => 'Add First Student';

  @override
  String get editProfileBtn => 'Edit Profile';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get genericError =>
      'Something went wrong securely fetching data. Please try again.';

  @override
  String get deleteError =>
      'Could not remove the student securely. Please try again.';

  @override
  String get addChildTitle => 'Add New Student';

  @override
  String get editChildTitle => 'Edit Student Details';

  @override
  String get addChildSubtitle =>
      'Fill in the details below to set up the student profile.';

  @override
  String get addPhotoLabel => 'Add Photo';

  @override
  String get personalInfoSection => 'Personal Information';

  @override
  String get studentNameLabel => 'Student Full Name';

  @override
  String get studentNameRequired => 'Name is required';

  @override
  String get ageLabel => 'Age (2-21)';

  @override
  String get ageRequired => 'Age is required';

  @override
  String get ageInvalid => 'Must be a valid number between 2 and 21';

  @override
  String get emergencyContactSection => 'Emergency Contact Number';

  @override
  String get useParentProfileNumber => 'Use Parent Profile Number';

  @override
  String get previouslyUsedNumber => 'Previously Used';

  @override
  String get addNewNumber => 'Add a New Number';

  @override
  String get newEmergencyContactLabel => 'New Emergency Contact';

  @override
  String get invalidSlNumber => 'Invalid SL number (e.g. 712345678)';

  @override
  String get tapVerifyConfirm => 'Tap Verify to confirm this number';

  @override
  String get schoolRouteDetailsSection => 'School & Route Details';

  @override
  String get schoolNameLabel => 'School Name';

  @override
  String get schoolNameHint => 'Start typing school name...';

  @override
  String get schoolRequired => 'School is required';

  @override
  String get pickupLocationLabel => 'Pickup Location';

  @override
  String get tapToSetOnMap => 'Tap to set on Map';

  @override
  String get pickupRequired => 'Pickup location is required';

  @override
  String get dropLocationLabel => 'Drop Location';

  @override
  String get dropRequired => 'Drop location is required';

  @override
  String get etaSchoolLabel => 'Estimated Time Arriving at School';

  @override
  String get etaRequired => 'Arrival time is required';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get trafficDelayLabel => 'Traffic Delay';

  @override
  String get suggestedLeaveByLabel => 'Suggested Leave By';

  @override
  String get confirmPickupTimeLabel => 'Confirm Pickup Time (Driver sees this)';

  @override
  String get pickupTimeRequired => 'Pickup time is required';

  @override
  String get smallDescriptionLabel =>
      'Small Description / Special Notes (Optional)';

  @override
  String get smallDescriptionHint =>
      'Any allergies, special needs, or notes for the driver...';

  @override
  String get saveStudentBtn => 'Save Student Details';

  @override
  String get updateProfileBtn => 'Update Profile';

  @override
  String get savingStatus => 'Saving...';

  @override
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String studentSavedSuccess(String name) {
    return '$name saved successfully!';
  }

  @override
  String get duplicateStudentError =>
      'This student is already added to this school.';

  @override
  String get verifyContactError =>
      'Please tap Verify to confirm the new emergency contact number.';

  @override
  String get verifyDriverError => 'Please verify the driver invite code.';

  @override
  String get cameraDeniedError =>
      'Camera access denied. Please check permissions.';

  @override
  String get alreadyHaveDriver => 'Already have a driver?';

  @override
  String get enterInviteCodeBelow => 'Enter their invite code below';

  @override
  String get findDriverLater => 'I will find a driver later';

  @override
  String get driverInviteCode => 'Driver Invite Code';

  @override
  String get scanQRCodeTooltip => 'Scan QR Code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get codeLengthError => 'Code must be exactly 8 characters';

  @override
  String get verifyCodeFirst => 'Please verify the code first';

  @override
  String get verifyBtn => 'Verify';

  @override
  String get driverFoundValidated => 'Driver Found & Validated!';

  @override
  String get driverNameLabel => 'Name';

  @override
  String get driverVehicleLabel => 'Vehicle';

  @override
  String get driverAreaLabel => 'Operating Area';

  @override
  String get verifyEmergencyContact => 'Verify Emergency Contact';

  @override
  String sentCodeTo(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get sixDigitSmsCode => '6-Digit SMS Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get confirmCodeBtn => 'Confirm Code';

  @override
  String get codeResentSuccess => 'Code resent successfully!';

  @override
  String get failedToResendCode => 'Failed to resend code';

  @override
  String get invalidCodeTryAgain => 'Invalid code. Please try again.';

  @override
  String get cancelBtnText => 'Cancel';

  @override
  String get doneBtnText => 'Done';

  @override
  String get selectArrivalTime => 'Select Arrival Time';

  @override
  String get scanQrCodeTitle => 'Scan QR Code';

  @override
  String get failedToSendOtp => 'Failed to send OTP';

  @override
  String get failedToVerifyOtp => 'Failed to verify OTP';

  @override
  String get otpVerificationSuccess =>
      'Emergency Contact Verified Successfully';

  @override
  String get driverNotFound => 'Driver not found or invalid code';
}
