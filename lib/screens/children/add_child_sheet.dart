import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:flutter_google_maps_webservices/places.dart' as places;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/repositories/children_repository.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';
import 'package:vango_parent_app/widgets/otp_bottom_sheet.dart';
import 'package:vango_parent_app/widgets/driver_section.dart';

import 'widgets/contact_section.dart';
import 'widgets/route_section.dart';

class AddChildSheet extends ConsumerStatefulWidget {
  final ChildProfile? existingChild;
  final List<ChildProfile> existingChildren;

  const AddChildSheet({
    super.key,
    this.existingChild,
    required this.existingChildren,
  });

  @override
  ConsumerState<AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final ParentDataService _dataService = ParentDataService.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _schoolController;
  late final TextEditingController _pickupLocationController;
  late final TextEditingController _dropLocationController;
  late final TextEditingController _etaSchoolController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _inviteCodeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pickupTimeController;

  File? _selectedImage;
  bool _isSaving = false;

  String _parentPhone = '';
  List<String> _previouslyUsedNumbers = [];
  String _selectedEmergencyOption = 'parent';
  bool _isCustomContactVerified = false;
  bool _isSendingOtp = false;

  bool _hasDriver = false;
  bool _isCalculatingRoute = false;

  bool _isValidatingCode = false;
  DriverProfile? _verifiedDriverDetails;
  String? _inviteCodeError;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  String? _routeDistance;
  String? _routeDuration;

  bool get _isEditing => widget.existingChild != null;

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(
      name: 'open_add_child_sheet',
      parameters: {'is_editing': _isEditing.toString()},
    );

    _nameController = TextEditingController(
      text: widget.existingChild?.name ?? '',
    );
    _ageController = TextEditingController(
      text: widget.existingChild?.age?.toString() ?? '',
    );
    _schoolController = TextEditingController(
      text: widget.existingChild?.school ?? '',
    );
    _pickupLocationController = TextEditingController(
      text: widget.existingChild?.pickupLocation ?? '',
    );
    _dropLocationController = TextEditingController(
      text: widget.existingChild?.dropLocation ?? '',
    );
    _emergencyContactController = TextEditingController(text: '');
    _inviteCodeController = TextEditingController(text: '');
    _descriptionController = TextEditingController(
      text: widget.existingChild?.description ?? '',
    );
    _pickupTimeController = TextEditingController(
      text: widget.existingChild?.pickupTime ?? '',
    );

    _pickupLat = widget.existingChild?.pickupLat;
    _pickupLng = widget.existingChild?.pickupLng;
    _dropLat = widget.existingChild?.dropLat;
    _dropLng = widget.existingChild?.dropLng;

    _etaSchoolController = TextEditingController(
      text: widget.existingChild?.etaSchool ?? '07:00 AM',
    );

    _hasDriver = false;

    _previouslyUsedNumbers = widget.existingChildren
        .map((c) => c.emergencyContact)
        .where((c) => c != null && c.isNotEmpty)
        .map((c) => _normalizePhone(c!))
        .toSet()
        .toList();

    _fetchParentProfileForEmergencyContact();

    if (_pickupLat != null && _dropLat != null) {
      _calculateRoute();
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    String? hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Image Picker Failed',
      );
    }
  }

  String _normalizePhone(String phone) {
    String p = phone.trim();
    if (p.startsWith('+94')) return p;
    if (p.startsWith('07')) return '+94${p.substring(1)}';
    if (p.startsWith('7')) return '+94$p';
    return p;
  }

  Future<void> _fetchParentProfileForEmergencyContact() async {
    try {
      final profile = await _dataService.fetchProfile();
      if (mounted) {
        setState(() {
          _parentPhone = _normalizePhone(profile['phone'] ?? '');
          _previouslyUsedNumbers.remove(_parentPhone);
          if (_isEditing && widget.existingChild!.emergencyContact != null) {
            final childContact = _normalizePhone(
              widget.existingChild!.emergencyContact!,
            );
            if (childContact == _parentPhone) {
              _selectedEmergencyOption = 'parent';
            } else if (_previouslyUsedNumbers.contains(childContact)) {
              _selectedEmergencyOption = childContact;
            } else if (childContact.isNotEmpty) {
              _previouslyUsedNumbers.add(childContact);
              _selectedEmergencyOption = childContact;
            }
          } else {
            _selectedEmergencyOption = 'parent';
          }
        });
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed fetching profile for contacts',
      );
    }
  }

  Future<void> _verifyNewEmergencyContact(AppLocalizations l10n) async {
    final phoneInput = _emergencyContactController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!RegExp(r'^7\d{8}$').hasMatch(phoneInput)) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.invalidSlNumber),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final formattedPhone = '+94$phoneInput';
    if (formattedPhone == _parentPhone ||
        _previouslyUsedNumbers.contains(formattedPhone)) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.previouslyUsedNumber),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _isSendingOtp = true);

    try {
      await ref
          .read(childrenRepositoryProvider)
          .sendEmergencyContactOtp(formattedPhone);

      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bool? isVerified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => OtpBottomSheet(
          phone: formattedPhone,
          onResend: () async {
            await ref
                .read(childrenRepositoryProvider)
                .sendEmergencyContactOtp(formattedPhone);
          },
          onVerify: (otp) async {
            await ref
                .read(childrenRepositoryProvider)
                .verifyEmergencyContactOtp(formattedPhone, otp);
          },
        ),
      );

      if (isVerified == true) {
        HapticFeedback.mediumImpact();
        setState(() => _isCustomContactVerified = true);
        if (mounted)
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.otpVerificationSuccess),
              backgroundColor: Colors.green,
            ),
          );
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'OTP process failed completely',
      );
      if (mounted) {
        setState(() => _isSendingOtp = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.genericError),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDark) async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;

    DateTime initialTime = DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext builderContext) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : AppColors.stroke,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(builderContext),
                      child: Text(
                        l10n.cancelBtnText,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      l10n.selectArrivalTime,
                      style: AppTypography.title.copyWith(
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(builderContext),
                      child: Text(
                        l10n.doneBtnText,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialTime,
                    onDateTimeChanged: (DateTime newDate) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        int h = newDate.hour;
                        String ampm = h >= 12 ? 'PM' : 'AM';
                        if (h == 0) {
                          h = 12;
                        }
                        if (h > 12) {
                          h -= 12;
                        }
                        _etaSchoolController.text =
                            '${h.toString().padLeft(2, '0')}:${newDate.minute.toString().padLeft(2, '0')} $ampm';
                        if (_pickupLat != null && _dropLat != null) {
                          _calculateRoute();
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanQRCode(AppLocalizations l10n) async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    bool hasScanned = false;

    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          // ✅ SECURE CONTEXT FIX: Pass the distinct scannerContext to prevent Navigator tree conflicts
          builder: (scannerContext) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text(
                l10n.scanQrCodeTitle,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: MobileScanner(
              onDetect: (capture) {
                if (hasScanned) {
                  return;
                }

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    hasScanned = true;
                    HapticFeedback.heavyImpact();
                    // ✅ Pop specific to the scanner's context
                    Navigator.pop(scannerContext, barcode.rawValue);
                    break;
                  }
                }
              },
            ),
          ),
        ),
      );

      if (scannedCode != null && scannedCode.trim().isNotEmpty) {
        setState(
          () => _inviteCodeController.text = scannedCode.trim().toUpperCase(),
        );
        _verifyCode(l10n);
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'QR Scan failure',
      );
      if (mounted)
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.cameraDeniedError),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  Future<void> _verifyCode(AppLocalizations l10n) async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCode = true;
      _verifiedDriverDetails = null;
      _inviteCodeError = null;
    });

    try {
      final driverModel = await ref
          .read(childrenRepositoryProvider)
          .verifyInviteCode(code);
      if (mounted) {
        setState(() {
          _isValidatingCode = false;
          if (driverModel != null) {
            HapticFeedback.mediumImpact();
            _verifiedDriverDetails = driverModel;
          } else {
            HapticFeedback.heavyImpact();
            _inviteCodeError = l10n.driverNotFound;
          }
        });
        _formKey.currentState?.validate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingCode = false;
          HapticFeedback.heavyImpact();
          _inviteCodeError = l10n.driverNotFound;
        });
        _formKey.currentState?.validate();
      }
    }
  }

  String? _getSuggestedDepartureTime(int durationSeconds) {
    final text = _etaSchoolController.text.trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    final regex = RegExp(r'(\d{1,2})[:.]?(\d{2})?\s*(am|pm)?');
    final match = regex.firstMatch(text);
    if (match == null) {
      return null;
    }

    try {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String? ampm = match.group(3);

      if (ampm == 'pm' && hour < 12) {
        hour += 12;
      }
      if (ampm == 'am' && hour == 12) {
        hour = 0;
      }

      DateTime targetTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      );
      DateTime leaveTime = targetTime.subtract(
        Duration(seconds: durationSeconds),
      );

      int h = leaveTime.hour;
      int m = leaveTime.minute;
      String period = h >= 12 ? 'PM' : 'AM';

      if (h == 0) {
        h = 12;
      }
      if (h > 12) {
        h -= 12;
      }

      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return null;
    }
  }

  Future<void> _calculateRoute() async {
    if (_pickupLat == null ||
        _pickupLng == null ||
        _dropLat == null ||
        _dropLng == null) {
      return;
    }
    setState(() => _isCalculatingRoute = true);

    try {
      final data = await ref
          .read(childrenRepositoryProvider)
          .calculateRouteProxied(
            _pickupLat!,
            _pickupLng!,
            _dropLat!,
            _dropLng!,
          );
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        if (mounted) {
          setState(() {
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration_in_traffic'] != null
                ? leg['duration_in_traffic']['text']
                : leg['duration']['text'];

            final durationSecs = leg['duration_in_traffic'] != null
                ? leg['duration_in_traffic']['value']
                : leg['duration']['value'];
            final suggestedTime = _getSuggestedDepartureTime(durationSecs);
            if (suggestedTime != null) {
              _pickupTimeController.text = suggestedTime;
            }
          });
        }
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Route calc proxy failed',
      );
    } finally {
      if (mounted) {
        setState(() => _isCalculatingRoute = false);
      }
    }
  }

  Future<void> _pickLocation({
    required TextEditingController controller,
    bool isPickup = false,
    bool isDrop = false,
  }) async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final apiKey = await ref
        .read(childrenRepositoryProvider)
        .getSecureMapsKey();
    if (apiKey == null || apiKey.isEmpty || !mounted) {
      return;
    }

    final PickResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        // ✅ SECURE CONTEXT FIX: Pass placeContext to safely isolate navigation
        builder: (placeContext) => Theme(
          data: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: AppColors.accent,
            scaffoldBackgroundColor: isDark
                ? const Color(0xFF121212)
                : Colors.white,
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accent,
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(
                    primary: AppColors.accent,
                    surface: Colors.white,
                  ),
          ),
          child: PlacePicker(
            apiKey: apiKey,
            autocompleteComponents: [
              places.Component(places.Component.country, "lk"),
            ],
            initialPosition: const LatLng(6.9271, 79.8612),
            useCurrentLocation: true,
            selectInitialPosition: true,
            selectedPlaceWidgetBuilder:
                (innerContext, selectedPlace, state, isSearchBarFocused) {
                  if (isSearchBarFocused) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white10 : AppColors.stroke,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.5 : 0.1,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPickup
                                          ? "Pickup Location"
                                          : "Drop-off Location",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedPlace?.formattedAddress ??
                                          "Move map to adjust location",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed:
                                  (state == SearchingState.Searching ||
                                      selectedPlace == null ||
                                      selectedPlace.geometry == null)
                                  ? null
                                  : () => Navigator.pop(
                                      placeContext,
                                      selectedPlace,
                                    ), // ✅ Pop the exact map layer
                              child: state == SearchingState.Searching
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm Location',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
            pinBuilder: (innerContext, state) {
              if (state == PinState.Preparing) {
                return const SizedBox.shrink();
              }
              return const Icon(
                Icons.location_on_rounded,
                size: 50,
                color: AppColors.accent,
              );
            },
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      controller.text = result.formattedAddress ?? result.name ?? '';
      if (isPickup) {
        _pickupLat = result.geometry?.location.lat;
        _pickupLng = result.geometry?.location.lng;
      } else if (isDrop) {
        _dropLat = result.geometry?.location.lat;
        _dropLng = result.geometry?.location.lng;
      }
    });

    if (_pickupLat != null && _dropLat != null) {
      _calculateRoute();
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEditing) {
      final isDuplicate = widget.existingChildren.any(
        (c) =>
            c.name.trim().toLowerCase() ==
                _nameController.text.trim().toLowerCase() &&
            c.school.trim().toLowerCase() ==
                _schoolController.text.trim().toLowerCase(),
      );
      if (isDuplicate) {
        HapticFeedback.heavyImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.duplicateStudentError),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    String finalEmergencyContact = '';
    if (_selectedEmergencyOption == 'parent') {
      finalEmergencyContact = _parentPhone;
    } else if (_selectedEmergencyOption == 'new') {
      if (!_isCustomContactVerified) {
        HapticFeedback.heavyImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.verifyContactError),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      finalEmergencyContact = '+94${_emergencyContactController.text.trim()}';
    } else {
      finalEmergencyContact = _selectedEmergencyOption;
    }

    if (_hasDriver && _verifiedDriverDetails == null) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.verifyDriverError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = widget.existingChild?.imageUrl;
      if (_selectedImage != null) {
        final uploadedPath = await _dataService.uploadChildPhoto(
          _selectedImage!,
        );
        if (uploadedPath != null) {
          finalImageUrl = uploadedPath;
        }
      }

      if (!_isEditing) {
        await _dataService.createChild(
          childName: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          school: _schoolController.text.trim(),
          pickupLocation: _pickupLocationController.text.trim(),
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropLocation: _dropLocationController.text.trim(),
          dropLat: _dropLat,
          dropLng: _dropLng,
          pickupTime: _pickupTimeController.text.trim().isEmpty
              ? '06:45 AM'
              : _pickupTimeController.text.trim(),
          etaSchool: _etaSchoolController.text.trim(),
          emergencyContact: finalEmergencyContact,
          description: _descriptionController.text.trim(),
          inviteCode: _hasDriver ? _inviteCodeController.text.trim() : '',
          imageUrl: finalImageUrl,
        );
      } else {
        await _dataService.updateChild(
          childId: widget.existingChild!.id,
          childName: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          school: _schoolController.text.trim(),
          pickupLocation: _pickupLocationController.text.trim(),
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropLocation: _dropLocationController.text.trim(),
          dropLat: _dropLat,
          dropLng: _dropLng,
          pickupTime: _pickupTimeController.text.trim().isEmpty
              ? widget.existingChild!.pickupTime
              : _pickupTimeController.text.trim(),
          etaSchool: _etaSchoolController.text.trim(),
          emergencyContact: finalEmergencyContact,
          description: _descriptionController.text.trim(),
          inviteCode: _hasDriver ? _inviteCodeController.text.trim() : '',
          imageUrl: finalImageUrl,
        );
      }

      _analytics.logEvent(
        name: 'save_child_success',
        parameters: {'is_edit': _isEditing.toString()},
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.studentSavedSuccess(_nameController.text.trim()),
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
        navigator.pop(true);
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed saving child record',
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.genericError),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ImageProvider? currentAvatar;
    if (_selectedImage != null) {
      currentAvatar = FileImage(_selectedImage!);
    } else if (widget.existingChild?.imageUrl != null &&
        widget.existingChild!.imageUrl!.isNotEmpty) {
      currentAvatar = CachedNetworkImageProvider(
        widget.existingChild!.imageUrl!,
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Added Premium Back Button Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? l10n.editChildTitle
                                : l10n.addChildTitle,
                            style: AppTypography.headline.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.addChildSubtitle,
                            style: AppTypography.body.copyWith(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey.shade100,
                      backgroundImage: currentAvatar,
                      child: currentAvatar == null
                          ? const Icon(
                              Icons.add_a_photo,
                              color: AppColors.accent,
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.addPhotoLabel,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  l10n.personalInfoSection,
                  style: AppTypography.title.copyWith(
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration(
                    l10n.studentNameLabel,
                    null,
                    Icons.person_outline,
                    isDark,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.studentNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration(
                    l10n.ageLabel,
                    null,
                    Icons.cake_outlined,
                    isDark,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.ageRequired;
                    }
                    final age = int.tryParse(v);
                    if (age == null || age < 2 || age > 21) {
                      return l10n.ageInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ContactSection(
                  emergencyContactController: _emergencyContactController,
                  parentPhone: _parentPhone,
                  previouslyUsedNumbers: _previouslyUsedNumbers,
                  selectedEmergencyOption: _selectedEmergencyOption,
                  isCustomContactVerified: _isCustomContactVerified,
                  isSendingOtp: _isSendingOtp,
                  onOptionChanged: (val) {
                    setState(() {
                      _selectedEmergencyOption = val;
                      if (!_isCustomContactVerified && val == 'new') {
                        _emergencyContactController.clear();
                      }
                    });
                  },
                  onVerifyRequested: () => _verifyNewEmergencyContact(l10n),
                  onResetVerification: () =>
                      setState(() => _isCustomContactVerified = false),
                ),

                const SizedBox(height: 24),

                RouteSection(
                  schoolController: _schoolController,
                  pickupLocationController: _pickupLocationController,
                  dropLocationController: _dropLocationController,
                  etaSchoolController: _etaSchoolController,
                  pickupTimeController: _pickupTimeController,
                  searchSchools: (query) => ref
                      .read(childrenRepositoryProvider)
                      .searchSchoolsProxied(query),
                  onPickupTap: () => _pickLocation(
                    controller: _pickupLocationController,
                    isPickup: true,
                  ),
                  onDropTap: () => _pickLocation(
                    controller: _dropLocationController,
                    isDrop: true,
                  ),
                  onEtaTap: () => _selectTime(context, isDark),
                  routeDistance: _routeDistance,
                  routeDuration: _routeDuration,
                  isCalculatingRoute: _isCalculatingRoute,
                ),

                const SizedBox(height: 24),

                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      labelStyle: TextStyle(color: Colors.white54),
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),
                  child: DriverSection(
                    hasDriver: _hasDriver,
                    onHasDriverChanged: (val) =>
                        setState(() => _hasDriver = val),
                    inviteCodeController: _inviteCodeController,
                    inviteCodeError: _inviteCodeError,
                    isValidatingCode: _isValidatingCode,
                    verifiedDriverDetails: _verifiedDriverDetails,
                    onVerifyCode: () => _verifyCode(l10n),
                    onScanQRCode: () => _scanQRCode(l10n),
                    onCodeChanged: () {
                      if (_verifiedDriverDetails != null) {
                        setState(() => _verifiedDriverDetails = null);
                      }
                      if (_inviteCodeError != null) {
                        setState(() => _inviteCodeError = null);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _buildInputDecoration(
                        l10n.smallDescriptionLabel,
                        l10n.smallDescriptionHint,
                        Icons.notes,
                        isDark,
                      ).copyWith(
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(
                            Icons.notes,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                ),

                const SizedBox(height: 32),
                GradientButton(
                  label: _isSaving
                      ? l10n.savingStatus
                      : (_isEditing
                            ? l10n.updateProfileBtn
                            : l10n.saveStudentBtn),
                  onPressed: _isSaving ? null : () => _submit(l10n),
                  expanded: true,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
