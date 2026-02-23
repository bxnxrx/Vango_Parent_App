import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class FinderScreen extends StatefulWidget {
  const FinderScreen({super.key});

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  List<DriverProfile> _services = const <DriverProfile>[];
  String _pickup = 'Home - Bambalapitiya';
  String _drop = 'Royal Primary School';
  String _selectedFilter = 'All';
  String _sortBy = 'rating';
  bool _loading = true;
  String? _error;

  static const List<String> _filters = ['All', 'Van', 'Car', 'Mini Bus'];
  static const List<String> _recentLocations = [
    'Home - Bambalapitiya',
    'Royal Primary School',
    'Gateway College - Nugegoda',
    'Musaeus College - Colombo 7',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _dataService.fetchFinderServices(
        vehicleType: _selectedFilter == 'All' ? null : _selectedFilter,
        sortBy: _sortBy,
      );
      if (!mounted) return;
      setState(() {
        _services = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _swapLocations() {
    setState(() {
      final String previousPickup = _pickup;
      _pickup = _drop;
      _drop = previousPickup;
    });
  }

  void _updateFilter(String value) {
    if (value == _selectedFilter) return;
    setState(() => _selectedFilter = value);
    _loadServices();
  }

  void _updateSortBy(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() => _sortBy = value);
    _loadServices();
  }

  List<DriverProfile> _getVisibleServices() {
    final List<DriverProfile> filtered = _services.where((driver) {
      return _selectedFilter == 'All' || driver.vehicleType == _selectedFilter;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'rating') return b.rating.compareTo(a.rating);
      if (_sortBy == 'price') return a.price.compareTo(b.price);
      return a.distance.compareTo(b.distance);
    });

    return filtered;
  }

  Future<void> _selectLocation({required bool isPickup}) async {
    final String initialValue = isPickup ? _pickup : _drop;
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _LocationPickerSheet(
        title: isPickup ? 'Pickup location' : 'Drop location',
        initialValue: initialValue,
        recentLocations: _recentLocations,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        if (isPickup) {
          _pickup = selected;
        } else {
          _drop = selected;
        }
      });
    }
  }

  void _showBookingSheet(DriverProfile service) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(service.vehicleImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: AppTypography.headline.copyWith(fontSize: 20),
                      ),
                      Text(
                        '${service.vehicleType} - ${service.seats} seats',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(icon: Icons.route, label: 'Route', value: service.route),
            _InfoRow(
              icon: Icons.star,
              label: 'Rating',
              value: '${service.rating}/5.0',
            ),
            _InfoRow(
              icon: Icons.payments,
              label: 'Monthly',
              value: 'Rs. ${service.price}',
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Request service',
              expanded: true,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking request sent to ${service.name}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DriverProfile> services = _getVisibleServices();

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text('Unable to load services', style: AppTypography.title),
            const SizedBox(height: 16),
            GradientButton(label: 'Try again', onPressed: _loadServices),
          ],
        ),
      );
    }

    // IMPORTANT: No Scaffold here. It uses the Scaffold from AppShell.
    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false, // We handle the icon ourselves
            leading: IconButton(
              icon: Icon(
                Navigator.canPop(context)
                    ? Icons.arrow_back_ios_new
                    : Icons.menu,
                color: AppColors.accent,
                size: Navigator.canPop(context) ? 20 : 24,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // This now correctly opens the AppShell's Drawer
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find a service',
                  style: AppTypography.headline.copyWith(fontSize: 20),
                ),
                Text(
                  '${services.length} available near you',
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteCard(
                    pickup: _pickup,
                    drop: _drop,
                    onPickupTap: () => _selectLocation(isPickup: true),
                    onDropTap: () => _selectLocation(isPickup: false),
                    onSwap: _swapLocations,
                  ),
                  const SizedBox(height: 16),
                  _FilterBar(
                    options: _filters,
                    selected: _selectedFilter,
                    onChanged: _updateFilter,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available services',
                        style: AppTypography.title.copyWith(fontSize: 18),
                      ),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.swap_vert, size: 18),
                        items: const [
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Rating'),
                          ),
                          DropdownMenuItem(
                            value: 'price',
                            child: Text('Price'),
                          ),
                          DropdownMenuItem(
                            value: 'distance',
                            child: Text('Distance'),
                          ),
                        ],
                        onChanged: _updateSortBy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...services.map(
                    (service) => _ServiceCard(
                      service: service,
                      onBook: () => _showBookingSheet(service),
                    ),
                  ),
                  const SizedBox(height: 100), // Extra space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.title,
    required this.initialValue,
    required this.recentLocations,
  });
  final String title;
  final String initialValue;
  final List<String> recentLocations;
  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTypography.headline.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search address',
            ),
          ),
          const SizedBox(height: 20),
          for (final loc in widget.recentLocations)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(loc),
              onTap: () => Navigator.pop(context, loc),
            ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Confirm location',
            expanded: true,
            onPressed: () => Navigator.pop(context, _controller.text),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.pickup,
    required this.drop,
    required this.onPickupTap,
    required this.onDropTap,
    required this.onSwap,
  });
  final String pickup;
  final String drop;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;
  final VoidCallback onSwap;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.stroke),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _LocationRow(
              icon: Icons.radio_button_checked,
              label: pickup,
              color: AppColors.accent,
              onTap: onPickupTap,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_vert, size: 18),
              label: const Text('Swap'),
            ),
            const SizedBox(height: 8),
            _LocationRow(
              icon: Icons.location_on,
              label: drop,
              color: AppColors.danger,
              onTap: onDropTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.title.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: opt,
                selected: selected == opt,
                onTap: () => onChanged(opt),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.buttonGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onBook});
  final DriverProfile service;
  final VoidCallback onBook;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(service.name[0])),
            title: Text(service.name),
            subtitle: Text(service.vehicleType),
            trailing: Text(
              'Rs. ${service.price}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                Text(' ${service.rating}'),
                const Spacer(),
                ElevatedButton(onPressed: onBook, child: const Text('Details')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
