import 'package:flutter/material.dart';

import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/mock_map.dart';

class RideDetailScreen extends StatelessWidget {
  final RideStatus status;

  const RideDetailScreen({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride detail')),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          MockMap(),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver ${status.driverName}', style: AppTypography.title),
                Text('Van ${status.vehiclePlate}', style: AppTypography.body),
                SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(label: 'ETA', value: '${status.etaMinutes} min'),
                    _StatCard(label: 'Speed', value: '${status.speedKph} km/h'),
                    _StatCard(
                      label: 'Status',
                      value: status.delayReason ?? 'On schedule',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...status.timeline.map((step) {
                  IconData icon;
                  if (step.completed) {
                    icon = Icons.check_circle;
                  } else {
                    icon = Icons.radio_button_unchecked;
                  }

                  Color color;
                  if (step.completed) {
                    color = AppColors.accent;
                  } else {
                    color = AppColors.stroke;
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: color),
                    title: Text(
                      step.label,
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    subtitle: Text(step.time),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            icon: Icon(Icons.emergency_share),
            label: Text('Emergency center'),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.title.copyWith(fontSize: 18)),
            SizedBox(height: 4),
            Text(label, style: AppTypography.body.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
