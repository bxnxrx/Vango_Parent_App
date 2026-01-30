import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/mock_map.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class MapStatusCard extends StatelessWidget {
  final RideStatus status;
  final VoidCallback onViewRide;
  final VoidCallback onShare;
  final VoidCallback onMarkNotComing;

  const MapStatusCard({
    Key? key,
    required this.status,
    required this.onViewRide,
    required this.onShare,
    required this.onMarkNotComing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
        boxShadow: AppShadows.subtle,
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          MockMap(),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chamath is ${status.etaMinutes} mins away',
                      style: AppTypography.headline,
                    ),
                    Text(
                      'Van ${status.vehiclePlate} • ${status.speedKph} km/h',
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onShare, icon: Icon(Icons.ios_share)),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: status.timeline.length,
              itemBuilder: (context, index) {
                final step = status.timeline[index];

                Color color;
                if (step.completed) {
                  color = AppColors.accent;
                } else {
                  color = AppColors.stroke;
                }

                Color bgColor;
                if (step.completed) {
                  bgColor = AppColors.accent.withOpacity(0.12);
                } else {
                  bgColor = AppColors.surface;
                }

                return Chip(
                  backgroundColor: bgColor,
                  side: BorderSide(color: color.withOpacity(0.4)),
                  label: Text(
                    step.label,
                    style: AppTypography.label.copyWith(
                      color: step.completed
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(width: 12),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'View ride detail',
                  onPressed: onViewRide,
                  expanded: true,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: OutlinedButton(
                  onPressed: onMarkNotComing,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent),
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Mark not coming',
                    style: AppTypography.label.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}