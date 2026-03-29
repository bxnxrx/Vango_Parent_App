import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:flutter_google_maps_webservices/places.dart' as places;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

// Import our newly extracted widgets
import 'package:vango_parent_app/widgets/otp_bottom_sheet.dart';
import 'package:vango_parent_app/widgets/driver_section.dart';

class AddChildSheet extends StatefulWidget {
  final ChildProfile? existingChild;
  final List<ChildProfile> existingChildren;

  const AddChildSheet({
    super.key,
    this.existingChild,
    required this.existingChildren,
  });

  @override
  State<AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  static const platform = MethodChannel('com.vango.app/apikey');
  String? _cachedApiKey;

  final ParentDataService _dataService = ParentDataService.instance;

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
  Map<String, dynamic>? _verifiedDriverDetails;
  String? _inviteCodeError;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  String? _routeDistance;
  String? _routeDuration;
  int? _routeDurationSeconds;

  String _selectedHour = '07';
  String _selectedMinute = '00';
  String _selectedAmPm = 'AM';

  bool get _isEditing => widget.existingChild != null;

  @override
  void initState() {
    super.initState();
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

    String initialEta = widget.existingChild?.etaSchool ?? '07:00 AM';
    _parseInitialEta(initialEta);
    _etaSchoolController = TextEditingController(text: initialEta);

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
    } catch (e) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String _normalizePhone(String phone) {
    String p = phone.trim();
    if (p.startsWith('+94')) {
      return p;
    }
    if (p.startsWith('07')) {
      return '+94${p.substring(1)}';
    }
    if (p.startsWith('7')) {
      return '+94$p';
    }
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
            } else {
              if (childContact.isNotEmpty) {
                _previouslyUsedNumbers.add(childContact);
                _selectedEmergencyOption = childContact;
              }
            }
          } else {
            _selectedEmergencyOption = 'parent';
          }
        });
      }
    } catch (_) {}
  }

  String _generateOtp() => (100000 + Random().nextInt(900000)).toString();

  Future<void> _invokeSendSmsFunction(String phone, String otp) async {
    await Supabase.instance.client.functions.invoke(
      'send-sms',
      body: {'phone': phone, 'otp': otp},
    );
  }

  Future<void> _verifyNewEmergencyContact() async {
    final phoneInput = _emergencyContactController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!RegExp(r'^7\d{8}$').hasMatch(phoneInput)) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 9-digit number starting with 7'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final formattedPhone = '+94$phoneInput';

    if (formattedPhone == _parentPhone) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This is your Parent Profile Number. Please select it from the options above.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_previouslyUsedNumbers.contains(formattedPhone)) {
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('This number is already in your list above.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _isSendingOtp = true);

    try {
      String currentOtp = _generateOtp();
      await _invokeSendSmsFunction(formattedPhone, currentOtp);

      if (!mounted) {
        return;
      }
      setState(() => _isSendingOtp = false);

      // Using the newly extracted OtpBottomSheet widget
      final bool? isVerified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => OtpBottomSheet(
          phone: formattedPhone,
          initialOtp: currentOtp,
          onResend: () async {
            String newOtp = _generateOtp();
            await _invokeSendSmsFunction(formattedPhone, newOtp);
            return newOtp;
          },
        ),
      );

      if (isVerified == true) {
        HapticFeedback.mediumImpact();
        setState(() => _isCustomContactVerified = true);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Emergency Contact Verified!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _isSendingOtp = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _parseInitialEta(String eta) {
    try {
      final text = eta.trim().toLowerCase();
      final regex = RegExp(r'(\d{1,2})[:.]?(\d{2})?\s*(am|pm)?');
      final match = regex.firstMatch(text);
      if (match != null) {
        _selectedHour = match.group(1)!.padLeft(2, '0');
        _selectedMinute = match.group(2)?.padLeft(2, '0') ?? '00';
        _selectedAmPm = match.group(3)?.toUpperCase() ?? 'AM';
      }
    } catch (_) {}
  }

  void _updateEtaController() {
    _etaSchoolController.text =
        '$_selectedHour:$_selectedMinute $_selectedAmPm';
    if (_pickupLat != null && _dropLat != null) {
      _calculateRoute();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    int initialHour = int.parse(_selectedHour);
    if (_selectedAmPm == 'PM' && initialHour < 12) {
      initialHour += 12;
    }
    if (_selectedAmPm == 'AM' && initialHour == 12) {
      initialHour = 0;
    }
    DateTime initialTime = DateTime(
      2024,
      1,
      1,
      initialHour,
      int.parse(_selectedMinute),
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.stroke)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(builderContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      'Select Arrival Time',
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(builderContext),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialTime,
                  onDateTimeChanged: (DateTime newDate) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      int h = newDate.hour;
                      _selectedAmPm = h >= 12 ? 'PM' : 'AM';
                      if (h == 0) {
                        h = 12;
                      }
                      if (h > 12) {
                        h -= 12;
                      }
                      _selectedHour = h.toString().padLeft(2, '0');
                      _selectedMinute = newDate.minute.toString().padLeft(
                        2,
                        '0',
                      );
                      _updateEtaController();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanQRCode() async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text(
                'Scan Driver QR Code',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context, barcode.rawValue);
                        break;
                      }
                    }
                  },
                ),
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black54,
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Align QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (scannedCode != null && scannedCode.trim().isNotEmpty) {
        setState(
          () => _inviteCodeController.text = scannedCode.trim().toUpperCase(),
        );
        _verifyCode();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Camera access denied. Please check permissions.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<String?> _getNativeApiKey() async {
    if (_cachedApiKey != null) {
      return _cachedApiKey;
    }
    try {
      _cachedApiKey = await platform.invokeMethod('getApiKey');
      return _cachedApiKey;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _searchSchools(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final apiKey = await _getNativeApiKey();
    if (apiKey == null) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&components=country:lk&types=establishment&key=$apiKey',
      );
      final headers = await const GoogleApiHeaders().getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final keywords = [
          "school",
          "college",
          "university",
          "campus",
          "institute",
          "academy",
          "international",
          "vidyalaya",
          "vidyalayam",
          "maha vidyalaya",
          "balika",
          "nursery",
          "preschool",
          "montessori",
        ];
        return (data['predictions'] as List)
            .map<String>((p) => p['description'] as String)
            .where(
              (description) =>
                  keywords.any((k) => description.toLowerCase().contains(k)),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Autocomplete Error: $e');
    }
    return [];
  }

  Future<void> _verifyCode() async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _verifiedDriverDetails = null;
      _inviteCodeError = null;
    });

    try {
      final result = await _dataService.verifyInviteCode(code);
      if (mounted) {
        setState(() {
          _isValidatingCode = false;
          if (result['valid'] == true) {
            HapticFeedback.mediumImpact();
            _verifiedDriverDetails = result;
          } else {
            HapticFeedback.heavyImpact();
            _inviteCodeError = result['message'] ?? 'Invalid code';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isValidatingCode = false;
          _inviteCodeError = e.toString().replaceAll('Exception: ', '').trim();
        });
      }
    }
  }

  String? _getSuggestedDepartureTime() {
    if (_routeDurationSeconds == null) {
      return null;
    }
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
        Duration(seconds: _routeDurationSeconds!),
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
    final apiKey = await _getNativeApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    setState(() => _isCalculatingRoute = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$_pickupLat,$_pickupLng&destination=$_dropLat,$_dropLng&departure_time=now&key=$apiKey',
      );
      final headers = await const GoogleApiHeaders().getHeaders();
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        if (mounted) {
          setState(() {
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration_in_traffic'] != null
                ? leg['duration_in_traffic']['text']
                : leg['duration']['text'];
            _routeDurationSeconds = leg['duration_in_traffic'] != null
                ? leg['duration_in_traffic']['value']
                : leg['duration']['value'];
            _pickupTimeController.text = _getSuggestedDepartureTime() ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
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

    final apiKey = await _getNativeApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    final PickResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData(
            primaryColor: AppColors.accent,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              surface: AppColors.surface,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
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

            pinBuilder: (context, state) {
              if (state == PinState.Preparing) {
                return const SizedBox.shrink();
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 68,
                    color: AppColors.accent,
                  ),
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              );
            },

            selectedPlaceWidgetBuilder:
                (context, selectedPlace, state, isSearchBarFocused) {
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                                decoration: const BoxDecoration(
                                  color: AppColors.accentLow,
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
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedPlace?.formattedAddress ??
                                          "Move map to adjust location",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
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
                                      selectedPlace == null)
                                  ? null
                                  : () {
                                      bool isSriLanka = false;
                                      if (selectedPlace.addressComponents !=
                                          null) {
                                        for (var component
                                            in selectedPlace
                                                .addressComponents!) {
                                          if (component.types.contains(
                                                'country',
                                              ) &&
                                              (component.shortName == 'LK' ||
                                                  component.longName ==
                                                      'Sri Lanka')) {
                                            isSriLanka = true;
                                            break;
                                          }
                                        }
                                      } else if (selectedPlace
                                                  .formattedAddress !=
                                              null &&
                                          selectedPlace.formattedAddress!
                                              .toLowerCase()
                                              .contains("sri lanka")) {
                                        isSriLanka = true;
                                      }

                                      if (!isSriLanka) {
                                        HapticFeedback.heavyImpact();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Sorry, we can't provide services for the selected region. Please select a location in Sri Lanka.",
                                            ),
                                            backgroundColor: AppColors.danger,
                                            duration: Duration(seconds: 4),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.of(context).pop(selectedPlace);
                                    },
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
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Future<void> _submit() async {
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
          const SnackBar(
            content: Text('This student is already added to this school.'),
            backgroundColor: AppColors.danger,
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
          const SnackBar(
            content: Text(
              'Please tap Verify to confirm the new emergency contact number.',
            ),
            backgroundColor: AppColors.danger,
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
        const SnackBar(
          content: Text('Please verify the driver invite code.'),
          backgroundColor: AppColors.danger,
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

      if (mounted) {
        HapticFeedback.lightImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildCustomRadio({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTypography.body)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Student Details' : 'Add New Student',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the details below to set up the student profile.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accentLow,
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
                const Center(
                  child: Text(
                    'Add Photo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Personal Information',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Student Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Age (2-21)',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Age is required';
                    }
                    final age = int.tryParse(v);
                    if (age == null) {
                      return 'Must be a valid number';
                    }
                    if (age < 2 || age > 21) {
                      return 'Age must be between 2 and 21';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Emergency Contact Number',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Column(
                    children: [
                      _buildCustomRadio(
                        title: 'Use Parent Profile Number\n($_parentPhone)',
                        isSelected: _selectedEmergencyOption == 'parent',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedEmergencyOption = 'parent');
                        },
                      ),
                      ..._previouslyUsedNumbers.map(
                        (phone) => _buildCustomRadio(
                          title: 'Previously Used\n($phone)',
                          isSelected: _selectedEmergencyOption == phone,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedEmergencyOption = phone);
                          },
                        ),
                      ),
                      _buildCustomRadio(
                        title: 'Add a New Number',
                        isSelected: _selectedEmergencyOption == 'new',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedEmergencyOption = 'new';
                            if (!_isCustomContactVerified) {
                              _emergencyContactController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (_selectedEmergencyOption == 'new') ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyContactController,
                          readOnly: _isCustomContactVerified,
                          keyboardType: TextInputType.phone,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'New Emergency Contact',
                            hintText: '7XXXXXXXX',
                            prefixText: '+94 ',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Required';
                            }
                            if (!RegExp(r'^7\d{8}$').hasMatch(v.trim())) {
                              return 'Invalid SL number (e.g. 712345678)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isCustomContactVerified
                              ? () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _isCustomContactVerified = false,
                                  );
                                }
                              : (_isSendingOtp
                                    ? null
                                    : _verifyNewEmergencyContact),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isCustomContactVerified
                                ? AppColors.surfaceStrong
                                : AppColors.accent,
                            foregroundColor: _isCustomContactVerified
                                ? AppColors.textPrimary
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isCustomContactVerified
                                      ? Icons.edit
                                      : Icons.verified_user,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isCustomContactVerified)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 16),
                      child: Text(
                        'Tap Verify to confirm this number',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 24),
                Text(
                  'School & Route Details',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),

                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _schoolController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return await _searchSchools(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _schoolController.text = selection;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        controller.addListener(
                          () => _schoolController.text = controller.text,
                        );
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          textCapitalization: TextCapitalization.words,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'School Name',
                            hintText: 'Start typing school name...',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'School is required';
                            }
                            return null;
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 250,
                            maxWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(
                                  Icons.school,
                                  color: AppColors.accent,
                                ),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _pickupLocationController,
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onTap: () => _pickLocation(
                    controller: _pickupLocationController,
                    isPickup: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Pickup Location',
                    hintText: 'Tap to set on Map',
                    prefixIcon: Icon(Icons.home_outlined),
                    suffixIcon: Icon(
                      Icons.map_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Pickup location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _dropLocationController,
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onTap: () => _pickLocation(
                    controller: _dropLocationController,
                    isDrop: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Drop Location',
                    hintText: 'Tap to set on Map',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                    suffixIcon: Icon(
                      Icons.map_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Drop location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _etaSchoolController,
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onTap: () => _selectTime(context),
                  decoration: const InputDecoration(
                    labelText: 'Estimated Time Arriving at School',
                    hintText: 'Tap to select time',
                    prefixIcon: Icon(
                      Icons.access_time_filled,
                      color: AppColors.accent,
                    ),
                    suffixIcon: Icon(
                      Icons.edit_calendar,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Arrival time is required';
                    }
                    return null;
                  },
                ),

                if (_isCalculatingRoute)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                else if (_routeDistance != null && _routeDuration != null)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.map_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Distance',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _routeDistance!,
                                    style: AppTypography.title.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: AppColors.stroke,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.hourglass_bottom_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Traffic Delay',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _routeDuration!,
                                    style: AppTypography.title.copyWith(
                                      fontSize: 14,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: AppColors.stroke,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_bus_filled_outlined,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Suggested Leave By',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getSuggestedDepartureTime() ?? '--:--',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_routeDistance != null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pickupTimeController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Pickup Time (Driver sees this)',
                      hintText: 'e.g. 06:45 AM',
                      prefixIcon: Icon(
                        Icons.alarm_on,
                        color: AppColors.success,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Pickup time is required';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // --- Replaced huge block with Extracted DriverSection Widget ---
                DriverSection(
                  hasDriver: _hasDriver,
                  onHasDriverChanged: (val) => setState(() => _hasDriver = val),
                  inviteCodeController: _inviteCodeController,
                  inviteCodeError: _inviteCodeError,
                  isValidatingCode: _isValidatingCode,
                  verifiedDriverDetails: _verifiedDriverDetails,
                  onVerifyCode: _verifyCode,
                  onScanQRCode: _scanQRCode,
                  onCodeChanged: () {
                    if (_verifiedDriverDetails != null)
                      setState(() => _verifiedDriverDetails = null);
                    if (_inviteCodeError != null)
                      setState(() => _inviteCodeError = null);
                  },
                ),

                // --------------------------------------------------------------
                const SizedBox(height: 24),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Small Description / Special Notes (Optional)',
                    hintText:
                        'Any allergies, special needs, or notes for the driver...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                GradientButton(
                  label: _isSaving
                      ? 'Saving...'
                      : (_isEditing
                            ? 'Update Profile'
                            : 'Save Student Details'),
                  onPressed: _isSaving ? null : _submit,
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
