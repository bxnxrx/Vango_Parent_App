import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class DriverSection extends StatelessWidget {
  final bool hasDriver;
  final ValueChanged<bool> onHasDriverChanged;
  final TextEditingController inviteCodeController;
  final String? inviteCodeError;
  final bool isValidatingCode;
  final Map<String, dynamic>? verifiedDriverDetails;
  final VoidCallback onVerifyCode;
  final VoidCallback onScanQRCode;
  final VoidCallback onCodeChanged;

  const DriverSection({
    super.key,
    required this.hasDriver,
    required this.onHasDriverChanged,
    required this.inviteCodeController,
    this.inviteCodeError,
    required this.isValidatingCode,
    this.verifiedDriverDetails,
    required this.onVerifyCode,
    required this.onScanQRCode,
    required this.onCodeChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              hasDriver
                  ? 'Enter their invite code below'
                  : 'I will find a driver later',
            ),
            value: hasDriver,
            activeThumbColor: AppColors.accent,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onHasDriverChanged(val);
            },
            secondary: Icon(
              hasDriver ? Icons.local_taxi : Icons.person_search,
              color: AppColors.accent,
            ),
          ),
        ),
        if (hasDriver) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: inviteCodeController,
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
                      onPressed: onScanQRCode,
                      tooltip: 'Scan QR Code',
                    ),
                    errorText: inviteCodeError,
                  ),
                  onChanged: (_) => onCodeChanged(),
                  validator: (v) {
                    if (!hasDriver) return null;
                    if (v == null || v.isEmpty) return 'Code is required';
                    if (v.trim().length != 8)
                      return 'Code must be exactly 8 characters';
                    if (verifiedDriverDetails == null)
                      return 'Please verify the code first';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isValidatingCode ? null : onVerifyCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isValidatingCode
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
          if (verifiedDriverDetails != null)
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
                    verifiedDriverDetails!['driverName'],
                  ),
                  _buildDriverDetailRow(
                    Icons.directions_car_outlined,
                    'Vehicle',
                    '${verifiedDriverDetails!['vehicleMake']} ${verifiedDriverDetails!['vehicleModel']}',
                  ),
                  _buildDriverDetailRow(
                    Icons.location_on_outlined,
                    'Operating Area',
                    '${verifiedDriverDetails!['city'] ?? ''}, ${verifiedDriverDetails!['district'] ?? ''}',
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
