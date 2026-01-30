import 'package:flutter/material.dart';

import 'package:vango_parent_app/data/mock_data.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class FinderScreen extends StatefulWidget {
  const FinderScreen({super.key});

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  String _pickup = 'Home - Bambalapitiya';
  String _drop = 'Royal Primary School';
  String _selectedFilter = 'All';
  String _sortBy = 'rating';

  // Options that drive the chips and quick picks.
  static const List<String> _filters = ['All', 'Van', 'Car', 'Mini Bus'];
  static const List<String> _recentLocations = [
    'Home - Bambalapitiya',
    'Royal Primary School',
    'Gateway College - Nugegoda',
    'Musaeus College - Colombo 7',
  ];

  // Allow parents to quickly reverse the two endpoints.
  void _swapLocations() {
    setState(() {
      final String previousPickup = _pickup;
      _pickup = _drop;
      _drop = previousPickup;
    });
  }

  void _updateFilter(String value) {
    if (value == _selectedFilter) {
      return;
    }
    setState(() {
      _selectedFilter = value;
    });
  }

  void _updateSortBy(String? value) {
    if (value == null) {
      return;
    }
    if (value == _sortBy) {
      return;
    }
    setState(() {
      _sortBy = value;
    });
  }

  // Build the visible list after applying the current filter and sort.
  List<DriverProfile> _getVisibleServices() {
    final List<DriverProfile> filtered = <DriverProfile>[];
    for (final DriverProfile driver in MockData.finderDrivers) {
      if (_selectedFilter == 'All') {
        filtered.add(driver);
      } else if (driver.vehicleType == _selectedFilter) {
        filtered.add(driver);
      }
    }

    if (filtered.length <= 1) {
      return filtered;
    }

    filtered.sort((DriverProfile a, DriverProfile b) {
      if (_sortBy == 'rating') {
        return b.rating.compareTo(a.rating);
      } else if (_sortBy == 'price') {
        return a.price.compareTo(b.price);
      } else {
        return a.distance.compareTo(b.distance);
      }
    });

    return filtered;
  }

  // Open the sheet that lets the user choose a pickup or drop.
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
      builder: (BuildContext context) {
        return _LocationPickerSheet(
          title: isPickup ? 'Pickup location' : 'Drop location',
          initialValue: initialValue,
          recentLocations: _recentLocations,
        );
      },
    );

    if (selected == null || selected.isEmpty) {
      return;
    }

    setState(() {
      if (isPickup) {
        _pickup = selected;
      } else {
        _drop = selected;
      }
    });
  }

  // Pop up details for the chosen driver profile.
  void _showBookingSheet(DriverProfile service) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
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
            children: <Widget>[
              Row(
                children: <Widget>[
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
                      children: <Widget>[
                        Text(
                          service.name,
                          style: AppTypography.headline.copyWith(fontSize: 20),
                        ),
                        Text(
                          '${service.vehicleType} - ${service.seats} seats',
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.route, label: 'Route', value: service.route),
              _InfoRow(icon: Icons.star, label: 'Rating', value: '${service.rating}/5.0'),
              _InfoRow(icon: Icons.payments, label: 'Monthly', value: 'Rs. ${service.price}'),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Request service',
                expanded: true,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking request sent to ${service.name}')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DriverProfile> services = _getVisibleServices();

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Find a service',
                  style: AppTypography.headline.copyWith(fontSize: 20),
                ),
                Text(
                  '${services.length} available near you',
                  style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                    children: <Widget>[
                      Text(
                        'Available services',
                        style: AppTypography.title.copyWith(fontSize: 18),
                      ),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.swap_vert, size: 18),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(value: 'rating', child: Text('Rating')),
                          DropdownMenuItem<String>(value: 'price', child: Text('Price')),
                          DropdownMenuItem<String>(value: 'distance', child: Text('Distance')),
                        ],
                        onChanged: _updateSortBy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final DriverProfile service in services)
                    _ServiceCard(
                      service: service,
                      onBook: () => _showBookingSheet(service),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet that collects a single location string.
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

  void _handleConfirm() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      Navigator.pop<String?>(context, null);
    } else {
      Navigator.pop<String>(context, value);
    }
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
        children: <Widget>[
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
              hintText: 'Search address or landmark',
              filled: true,
            ),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 20),
          for (final String location in widget.recentLocations)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(location),
              trailing: const Icon(Icons.north_west),
              onTap: () => Navigator.pop<String>(context, location),
            ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Confirm location',
            expanded: true,
            onPressed: _handleConfirm,
          ),
        ],
      ),
    );
  }
}

// Displays the pickup and drop summary at the top of the page.
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
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.subtle,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            _LocationRow(
              icon: Icons.radio_button_checked,
              label: pickup,
              color: AppColors.accent,
              onTap: onPickupTap,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: List<Widget>.generate(
                        3,
                        (_) => Container(
                          width: 2,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.stroke,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: const Text('Swap'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.title.copyWith(fontSize: 15),
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// Horizontally scrollable list of transport filters.
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
        children: <Widget>[
          for (final String option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: option,
                selected: selected == option,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

// Simple chip with gradient selection styling.
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.buttonGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.transparent : AppColors.stroke),
          boxShadow: selected ? AppShadows.subtle : null,
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Shows headline details for each available driver.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onBook,
  });

  final DriverProfile service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    AppColors.accent,
                                    AppColors.accent.withOpacity(0.7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  service.name[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    service.name,
                                    style: AppTypography.title.copyWith(fontSize: 16),
                                  ),
                                  Text(
                                    service.vehicleType,
                                    style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.star, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    service.rating.toStringAsFixed(1),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.route, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.route,
                                style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(service.vehicleImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceStrong.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: <Widget>[
                  _Stat(icon: Icons.event_seat, value: '${service.seats} seats'),
                  _Stat(icon: Icons.location_on, value: '${service.distance} km'),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Rs. ${service.price}',
                        style: AppTypography.title.copyWith(fontSize: 18, color: AppColors.accent),
                      ),
                      Text(
                        'per month',
                        style: AppTypography.label.copyWith(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: IconButton(
                      onPressed: onBook,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Renders a small icon-value pair inside the service card footer.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// Line item used inside the booking confirmation sheet.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.label.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: AppTypography.title.copyWith(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//