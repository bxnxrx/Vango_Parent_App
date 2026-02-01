import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key, this.status});

  final RideStatus? status;

  @override
  Widget build(BuildContext context) {
    final ride = status ?? const RideStatus.placeholder();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live status', style: AppTypography.headline),
            const SizedBox(height: 8),
            Text('Van ${ride.vehiclePlate} • ${ride.speedKph} km/h', style: AppTypography.body),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.stroke.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('${ride.etaMinutes} minutes away', style: AppTypography.title.copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...ride.timeline.map((step) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        step.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: step.completed ? AppColors.success : AppColors.textSecondary,
                      ),
                      title: Text(step.label),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Detailed tracking coming soon', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
