import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:flutter_google_maps_webservices/places.dart' as places;
import 'package:google_api_headers/google_api_headers.dart'; // NATIVE API HEADERS
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
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

  Future<void> _openChildSheet({ChildProfile? existingChild}) async {
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
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _AddChildSheet(existingChild: existingChild),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${request['fullName']} saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _openChildSheet(existingChild: child),
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
        ],
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  final ChildProfile? existingChild;
  const _AddChildSheet({this.existingChild});

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();

  static const platform = MethodChannel('com.vango.app/apikey');

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _schoolController;
  late final TextEditingController _pickupLocationController;
  late final TextEditingController _dropLocationController;
  late final TextEditingController _etaSchoolController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _inviteCodeController;
  late final TextEditingController _descriptionController;

  bool _hasDriver = false;
  bool _isCalculatingRoute = false;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  String? _routeDistance;
  String? _routeDuration;
  int? _routeDurationSeconds;

  // Custom Time Selector Variables
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
    _ageController = TextEditingController(text: '');
    _schoolController = TextEditingController(
      text: widget.existingChild?.school ?? '',
    );
    _pickupLocationController = TextEditingController(text: '');
    _dropLocationController = TextEditingController(text: '');
    _emergencyContactController = TextEditingController(text: '');
    _inviteCodeController = TextEditingController(text: '');
    _descriptionController = TextEditingController(text: '');

    // Initialize Time Selector values
    String initialEta = widget.existingChild?.etaSchool ?? '07:00 AM';
    _parseInitialEta(initialEta);
    _etaSchoolController = TextEditingController(text: initialEta);

    // Watch ETA changes to trigger UI rebuild for departure time recalculation
    _etaSchoolController.addListener(() {
      setState(() {});
    });
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

        // Ensure minute is a valid dropdown selection
        if (![
          '00',
          '05',
          '10',
          '15',
          '20',
          '25',
          '30',
          '35',
          '40',
          '45',
          '50',
          '55',
        ].contains(_selectedMinute)) {
          _selectedMinute = '00';
        }
      }
    } catch (_) {}
  }

  void _updateEtaController() {
    _etaSchoolController.text =
        '$_selectedHour:$_selectedMinute $_selectedAmPm';
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
    super.dispose();
  }

  Future<String?> _getNativeApiKey() async {
    try {
      final String apiKey = await platform.invokeMethod('getApiKey');
      return apiKey;
    } on PlatformException catch (e) {
      debugPrint("Failed to get API key from Native channel: '${e.message}'.");
      return null;
    }
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

      final now = DateTime.now();
      DateTime targetTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Calculate departure time by subtracting the live traffic duration
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
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$_pickupLat,$_pickupLng&destination=$_dropLat,$_dropLng'
        '&departure_time=now&key=$apiKey',
      );

      // Get Native App Headers (Bypasses HTTP Restrictions for Android/iOS)
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
          });
        }
      } else {
        if (mounted) {
          final errorMessage = data['error_message'] ?? data['status'];
          debugPrint("Google Maps API Error: $errorMessage");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route Error: $errorMessage'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  Future<void> _pickLocation(bool isPickup) async {
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
              onSurface: AppColors.textPrimary,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
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
            selectedPlaceWidgetBuilder:
                (context, selectedPlace, state, isSearchBarFocused) {
                  if (isSearchBarFocused) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.accentLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.accent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedPlace?.formattedAddress ??
                                "Drag map to select a location...",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed:
                                  (state == SearchingState.Searching ||
                                      selectedPlace == null)
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pop(selectedPlace),
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

    bool isSriLanka = false;
    if (result.addressComponents != null) {
      for (var component in result.addressComponents!) {
        if (component.types.contains('country') &&
            (component.shortName == 'LK' ||
                component.longName == 'Sri Lanka')) {
          isSriLanka = true;
          break;
        }
      }
    } else if (result.formattedAddress != null &&
        result.formattedAddress!.toLowerCase().contains("sri lanka")) {
      isSriLanka = true;
    }

    if (!isSriLanka) {
      ScaffoldMessenger.of(context).showSnackBar(
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

    setState(() {
      if (isPickup) {
        _pickupLocationController.text = result.formattedAddress ?? '';
        _pickupLat = result.geometry?.location.lat;
        _pickupLng = result.geometry?.location.lng;
      } else {
        _dropLocationController.text = result.formattedAddress ?? '';
        _dropLat = result.geometry?.location.lat;
        _dropLng = result.geometry?.location.lng;
      }
    });

    if (_pickupLat != null && _dropLat != null) {
      _calculateRoute();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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
      'emergencyContact': _emergencyContactController.text.trim(),
      'hasDriver': _hasDriver,
      'inviteCode': _hasDriver ? _inviteCodeController.text.trim() : null,
      'description': _descriptionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestedDeparture = _getSuggestedDepartureTime();

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
                decoration: const InputDecoration(
                  labelText: 'Student Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Age is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Emergency contact is required' : null,
              ),

              const SizedBox(height: 24),
              Text(
                'School & Route Details',
                style: AppTypography.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'School is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pickupLocationController,
                readOnly: true,
                onTap: () => _pickLocation(true),
                decoration: const InputDecoration(
                  labelText: 'Pickup Location',
                  hintText: 'Tap to set on Map',
                  prefixIcon: Icon(Icons.home_outlined),
                  suffixIcon: Icon(Icons.map_outlined, color: AppColors.accent),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Pickup location is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dropLocationController,
                readOnly: true,
                onTap: () => _pickLocation(false),
                decoration: const InputDecoration(
                  labelText: 'Drop Location',
                  hintText: 'Tap to set on Map',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                  suffixIcon: Icon(Icons.map_outlined, color: AppColors.accent),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Drop location is required' : null,
              ),
              const SizedBox(height: 16),

              // --- CUSTOM MODERN TIME SELECTOR ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Estimated Time Arriving at School',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.accent),
                        const SizedBox(width: 12),

                        // Hour Dropdown
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedHour,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                              ),
                              isExpanded: true,
                              items: List.generate(12, (index) {
                                final hr = (index + 1).toString().padLeft(
                                  2,
                                  '0',
                                );
                                return DropdownMenuItem(
                                  value: hr,
                                  child: Text(hr, style: AppTypography.body),
                                );
                              }),
                              onChanged: (val) {
                                setState(() => _selectedHour = val!);
                                _updateEtaController();
                              },
                            ),
                          ),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Minute Dropdown
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMinute,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                              ),
                              isExpanded: true,
                              items:
                                  [
                                    '00',
                                    '05',
                                    '10',
                                    '15',
                                    '20',
                                    '25',
                                    '30',
                                    '35',
                                    '40',
                                    '45',
                                    '50',
                                    '55',
                                  ].map((min) {
                                    return DropdownMenuItem(
                                      value: min,
                                      child: Text(
                                        min,
                                        style: AppTypography.body,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedMinute = val!);
                                _updateEtaController();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Custom AM/PM Segmented Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceStrong,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedAmPm = 'AM');
                                  _updateEtaController();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedAmPm == 'AM'
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _selectedAmPm == 'AM'
                                        ? AppShadows.subtle
                                        : null,
                                  ),
                                  child: Text(
                                    'AM',
                                    style: TextStyle(
                                      color: _selectedAmPm == 'AM'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedAmPm = 'PM');
                                  _updateEtaController();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedAmPm == 'PM'
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _selectedAmPm == 'PM'
                                        ? AppShadows.subtle
                                        : null,
                                  ),
                                  child: Text(
                                    'PM',
                                    style: TextStyle(
                                      color: _selectedAmPm == 'PM'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- MODERN ROUTE INFO CARD ---
              if (_isCalculatingRoute)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (_routeDistance != null && _routeDuration != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Distance:',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _routeDistance!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.traffic, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Est. Travel Time:',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _routeDuration!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (suggestedDeparture != null) ...[
                        const Divider(height: 24, color: AppColors.stroke),
                        Row(
                          children: [
                            const Icon(
                              Icons.departure_board,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Suggested Departure:',
                              style: AppTypography.body.copyWith(
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
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                suggestedDeparture,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

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
                  onChanged: (val) => setState(() => _hasDriver = val),
                  secondary: Icon(
                    _hasDriver ? Icons.local_taxi : Icons.person_search,
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (_hasDriver) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _inviteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Invite Code',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (v) => _hasDriver && v!.isEmpty
                      ? 'Code is required if you have a driver'
                      : null,
                ),
              ],

              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Small Description / Special Notes',
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
