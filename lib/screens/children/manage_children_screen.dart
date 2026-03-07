import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:flutter_google_maps_webservices/places.dart' as places;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/services/auth_service.dart'; // For SMS OTP
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class ManageChildrenScreen extends StatefulWidget {
  const ManageChildrenScreen({super.key});

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  List<ChildProfile> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    try {
      final children = await _dataService.fetchChildren();
      if (mounted) {
        setState(() {
          _children = children;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteChild(ChildProfile child) async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove ${child.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await _dataService.deleteChild(child.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${child.name} removed successfully.')),
        );
        _loadChildren();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing student: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openChildSheet({ChildProfile? existingChild}) async {
    HapticFeedback.selectionClick();
    final request = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: _AddChildSheet(
              existingChild: existingChild,
              existingChildren: _children,
            ),
          ),
        );
      },
    );

    if (request != null) {
      try {
        setState(() => _loading = true);
        final int? parsedAge = int.tryParse(request['age'].toString());

        if (existingChild == null) {
          await _dataService.createChild(
            childName: request['fullName'],
            age: parsedAge,
            school: request['school'],
            pickupLocation: request['pickupLocation'],
            pickupLat: request['pickupLat'],
            pickupLng: request['pickupLng'],
            dropLocation: request['dropLocation'],
            dropLat: request['dropLat'],
            dropLng: request['dropLng'],
            pickupTime: request['pickupTime'] ?? '06:45 AM',
            etaSchool: request['etaSchool'],
            emergencyContact: request['emergencyContact'],
            description: request['description'],
            inviteCode: request['inviteCode'] ?? '',
          );
        } else {
          await _dataService.updateChild(
            childId: existingChild.id,
            childName: request['fullName'],
            age: parsedAge,
            school: request['school'],
            pickupLocation: request['pickupLocation'],
            pickupLat: request['pickupLat'],
            pickupLng: request['pickupLng'],
            dropLocation: request['dropLocation'],
            dropLat: request['dropLat'],
            dropLng: request['dropLng'],
            pickupTime: request['pickupTime'] ?? existingChild.pickupTime,
            etaSchool: request['etaSchool'],
            emergencyContact: request['emergencyContact'],
            description: request['description'],
            inviteCode: request['inviteCode'] ?? '',
          );
        }
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${request['fullName']} saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving student: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        _loadChildren();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Children'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChildSheet(),
        label: const Text('Add Student'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accent,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _children.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.subtle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentLow,
                      child: Text(
                        child.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(child.name, style: AppTypography.title),
                    subtitle: Text(child.school),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.accent,
                          ),
                          onPressed: () =>
                              _openChildSheet(existingChild: child),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                          onPressed: () => _deleteChild(child),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.accentLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care,
              size: 64,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text('No students added yet', style: AppTypography.headline),
          const SizedBox(height: 8),
          Text(
            'Add your children to start tracking their rides.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openChildSheet(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Student'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  final ChildProfile? existingChild;
  final List<ChildProfile> existingChildren;
  const _AddChildSheet({this.existingChild, required this.existingChildren});

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  static const platform = MethodChannel('com.vango.app/apikey');
  String? _cachedApiKey;

  final ParentDataService _dataService = ParentDataService.instance;
  final AuthService _authService = AuthService.instance;

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

  String _parentPhone = '';
  bool _useCustomEmergencyContact = false;
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

    _fetchParentProfileForEmergencyContact();

    if (_pickupLat != null && _dropLat != null) {
      _calculateRoute();
    }
  }

  Future<void> _fetchParentProfileForEmergencyContact() async {
    try {
      final profile = await _dataService.fetchProfile();
      if (mounted) {
        setState(() {
          _parentPhone = profile['phone'] ?? '';

          if (_isEditing &&
              widget.existingChild!.emergencyContact != null &&
              widget.existingChild!.emergencyContact != _parentPhone) {
            _useCustomEmergencyContact = true;
            _isCustomContactVerified = true;
            _emergencyContactController.text =
                widget.existingChild!.emergencyContact!;
          } else {
            _emergencyContactController.text = _parentPhone;
          }
        });
      }
    } catch (_) {}
  }

  // --- SMS OTP VERIFICATION FOR EMERGENCY CONTACT ---
  Future<void> _verifyNewEmergencyContact() async {
    final phone = _emergencyContactController.text.trim();
    if (!RegExp(r'^(?:0|\+94)7\d{8}$').hasMatch(phone)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid SL number to verify'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _isSendingOtp = true);

    try {
      await _authService.requestPhoneOtp(phone);
      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      final otpController = TextEditingController();
      final bool? isVerified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Emergency Contact',
                style: AppTypography.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $phone',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '6-Digit SMS Code',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (otpController.text.length != 6) return;
                    HapticFeedback.lightImpact();
                    try {
                      await _authService.verifyPhoneOtp(
                        phone: phone,
                        token: otpController.text.trim(),
                      );
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid code entered.'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm Code'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );

      if (isVerified == true) {
        HapticFeedback.mediumImpact();
        setState(() => _isCustomContactVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency Contact Verified!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _isSendingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
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
    if (_pickupLat != null && _dropLat != null) _calculateRoute();
  }

  Future<void> _selectTime(BuildContext context) async {
    HapticFeedback.selectionClick();
    int initialHour = int.parse(_selectedHour);
    if (_selectedAmPm == 'PM' && initialHour < 12) initialHour += 12;
    if (_selectedAmPm == 'AM' && initialHour == 12) initialHour = 0;
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
                      if (h == 0) h = 12;
                      if (h > 12) h -= 12;
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

  // --- QR SCANNER ---
  Future<void> _scanQRCode() async {
    HapticFeedback.selectionClick();
    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Scan Driver QR Code')),
            body: MobileScanner(
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
          ),
        ),
      );

      if (scannedCode != null && scannedCode.trim().isNotEmpty) {
        setState(
          () => _inviteCodeController.text = scannedCode.trim().toUpperCase(),
        );
        _verifyCode(); // Auto verify
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera access denied or unavailable. Please check permissions.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<String?> _getNativeApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    try {
      _cachedApiKey = await platform.invokeMethod('getApiKey');
      return _cachedApiKey;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _searchSchools(String query) async {
    if (query.isEmpty) return [];
    final apiKey = await _getNativeApiKey();
    if (apiKey == null) return [];

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
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

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

  Widget _buildDriverDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null null')
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getSuggestedDepartureTime() {
    if (_routeDurationSeconds == null) return null;
    final text = _etaSchoolController.text.trim().toLowerCase();
    if (text.isEmpty) return null;

    final regex = RegExp(r'(\d{1,2})[:.]?(\d{2})?\s*(am|pm)?');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    try {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String? ampm = match.group(3);

      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

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
      if (h == 0) h = 12;
      if (h > 12) h -= 12;

      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return null;
    }
  }

  Future<void> _calculateRoute() async {
    if (_pickupLat == null ||
        _pickupLng == null ||
        _dropLat == null ||
        _dropLng == null)
      return;
    final apiKey = await _getNativeApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

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
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  Future<void> _pickLocation({
    required TextEditingController controller,
    bool isPickup = false,
    bool isDrop = false,
  }) async {
    HapticFeedback.lightImpact();
    final apiKey = await _getNativeApiKey();
    if (apiKey == null || apiKey.isEmpty) return;
    if (!mounted) return;

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
              if (state == PinState.Preparing) return const SizedBox.shrink();
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
                  if (isSearchBarFocused) return const SizedBox.shrink();
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

    if (!mounted || result == null) return;

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

    if (_pickupLat != null && _dropLat != null) _calculateRoute();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    final emergencyContact = _useCustomEmergencyContact
        ? _emergencyContactController.text.trim()
        : _parentPhone;

    // Reject form submission if new emergency contact is typed but not verified yet.
    if (_useCustomEmergencyContact && !_isCustomContactVerified) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please tap Verify to confirm the new emergency contact number.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_hasDriver && _verifiedDriverDetails == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify the driver invite code.'),
          backgroundColor: AppColors.danger,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This student is already added to this school.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    Navigator.of(context).pop({
      'fullName': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'school': _schoolController.text.trim(),
      'pickupLocation': _pickupLocationController.text.trim(),
      'pickupLat': _pickupLat,
      'pickupLng': _pickupLng,
      'dropLocation': _dropLocationController.text.trim(),
      'dropLat': _dropLat,
      'dropLng': _dropLng,
      'etaSchool': _etaSchoolController.text.trim(),
      'pickupTime': _pickupTimeController.text.trim(),
      'emergencyContact': emergencyContact,
      'hasDriver': _hasDriver,
      'inviteCode': _hasDriver ? _inviteCodeController.text.trim() : null,
      'description': _descriptionController.text.trim(),
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _pickupLocationController.dispose();
    _dropLocationController.dispose();
    _etaSchoolController.dispose();
    _emergencyContactController.dispose();
    _inviteCodeController.dispose();
    _descriptionController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
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
                  if (v == null || v.isEmpty) return 'Age is required';
                  final age = int.tryParse(v);
                  if (age == null) return 'Must be a valid number';
                  if (age < 2 || age > 21)
                    return 'Age must be between 2 and 21';
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
                    RadioListTile<bool>(
                      title: Text(
                        'Use Parent Profile Number\n($_parentPhone)',
                        style: AppTypography.body,
                      ),
                      value: false,
                      groupValue: _useCustomEmergencyContact,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _useCustomEmergencyContact = val!;
                          _emergencyContactController.text = _parentPhone;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: Text(
                        'Use Another Number',
                        style: AppTypography.body,
                      ),
                      value: true,
                      groupValue: _useCustomEmergencyContact,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _useCustomEmergencyContact = val!;
                          if (!_isCustomContactVerified)
                            _emergencyContactController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_useCustomEmergencyContact) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emergencyContactController,
                        keyboardType: TextInputType.phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'New Emergency Contact',
                          hintText: '07XXXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        onChanged: (val) {
                          if (_isCustomContactVerified)
                            setState(() => _isCustomContactVerified = false);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^(?:0|\+94)7\d{8}$').hasMatch(v.trim()))
                            return 'Invalid SL number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isSendingOtp
                            ? null
                            : _verifyNewEmergencyContact,
                        style: FilledButton.styleFrom(
                          backgroundColor: _isCustomContactVerified
                              ? AppColors.success
                              : AppColors.accent,
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
                                    ? Icons.check
                                    : Icons.verified_user,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
                if (!_isCustomContactVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
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
                  if (textEditingValue.text.isEmpty)
                    return const Iterable<String>.empty();
                  return await _searchSchools(textEditingValue.text);
                },
                onSelected: (String selection) =>
                    _schoolController.text = selection,
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'School is required'
                            : null,
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
                  suffixIcon: Icon(Icons.map_outlined, color: AppColors.accent),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Pickup location is required'
                    : null,
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
                  suffixIcon: Icon(Icons.map_outlined, color: AppColors.accent),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Drop location is required'
                    : null,
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
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Arrival time is required'
                    : null,
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
                      // REMOVED iOS CRASHING STATIC MAP PREVIEW
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
                    prefixIcon: Icon(Icons.alarm_on, color: AppColors.success),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Pickup time is required'
                      : null,
                ),
              ],

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: SwitchListTile(
                  title: const Text('Already have a driver?'),
                  subtitle: Text(
                    _hasDriver
                        ? 'Enter their invite code below'
                        : 'I will find a driver later',
                  ),
                  value: _hasDriver,
                  activeThumbColor: AppColors.accent,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _hasDriver = val);
                  },
                  secondary: Icon(
                    _hasDriver ? Icons.local_taxi : Icons.person_search,
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (_hasDriver) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: 'Driver Invite Code',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: AppColors.accent,
                            ),
                            onPressed: _scanQRCode,
                            tooltip: 'Scan QR Code',
                          ),
                          errorText: _inviteCodeError,
                        ),
                        onChanged: (val) {
                          if (_verifiedDriverDetails != null)
                            setState(() => _verifiedDriverDetails = null);
                          if (_inviteCodeError != null)
                            setState(() => _inviteCodeError = null);
                        },
                        validator: (v) {
                          if (!_hasDriver) return null;
                          if (v == null || v.isEmpty) return 'Code is required';
                          if (v.trim().length != 8)
                            return 'Code must be exactly 8 characters';
                          if (_verifiedDriverDetails == null)
                            return 'Please verify the code first';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isValidatingCode ? null : _verifyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isValidatingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                    ),
                  ],
                ),

                if (_verifiedDriverDetails != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Driver Found & Validated!',
                              style: AppTypography.title.copyWith(
                                color: AppColors.success,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.stroke),
                        ),
                        _buildDriverDetailRow(
                          Icons.person_outline,
                          'Name',
                          _verifiedDriverDetails!['driverName'],
                        ),
                        _buildDriverDetailRow(
                          Icons.directions_car_outlined,
                          'Vehicle',
                          '${_verifiedDriverDetails!['vehicleMake']} ${_verifiedDriverDetails!['vehicleModel']}',
                        ),
                        _buildDriverDetailRow(
                          Icons.location_on_outlined,
                          'Operating Area',
                          '${_verifiedDriverDetails!['city'] ?? ''}, ${_verifiedDriverDetails!['district'] ?? ''}',
                        ),
                      ],
                    ),
                  ),
              ],

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
                label: _isEditing ? 'Update Profile' : 'Save Student Details',
                onPressed: _submit,
                expanded: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
