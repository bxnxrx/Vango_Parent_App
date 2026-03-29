import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class DriverSection extends StatelessWidget {
  final bool hasDriver;
  final ValueChanged<bool> onHasDriverChanged;
  final TextEditingController inviteCodeController;
  final String? inviteCodeError;
  final bool isValidatingCode;
  final DriverProfile? verifiedDriverDetails;
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

  Widget _buildDriverDetailRow(
    IconData icon,
    String label,
    String? value,
    bool isDark,
  ) {
    if (value == null || value.trim().isEmpty || value == 'null null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.stroke,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              l10n.alreadyHaveDriver,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              hasDriver ? l10n.enterInviteCodeBelow : l10n.findDriverLater,
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            value: hasDriver,
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade300,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              FirebaseAnalytics.instance.logEvent(
                name: 'toggle_has_driver',
                parameters: {'status': val.toString()},
              );
              onHasDriverChanged(val);
            },
            secondary: Icon(
              hasDriver ? Icons.local_taxi : Icons.person_search,
              color: hasDriver
                  ? AppColors.accent
                  : (isDark ? Colors.white54 : AppColors.textSecondary),
            ),
          ),
        ),
        if (hasDriver) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: inviteCodeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF141414)
                        : Colors.grey.shade100,
                    labelText: l10n.driverInviteCode,
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      letterSpacing: 0,
                    ),
                    prefixIcon: Icon(
                      Icons.vpn_key_outlined,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.accent,
                      ),
                      onPressed: onScanQRCode,
                      tooltip: l10n.scanQRCodeTooltip,
                    ),
                    errorText: inviteCodeError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  onChanged: (_) => onCodeChanged(),
                  validator: (v) {
                    if (!hasDriver) {
                      return null;
                    }
                    if (v == null || v.isEmpty) {
                      return l10n.codeRequired;
                    }
                    if (v.trim().length != 8) {
                      return l10n.codeLengthError;
                    }
                    if (verifiedDriverDetails == null) {
                      return l10n.verifyCodeFirst;
                    }
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
                      : Text(
                          l10n.verifyBtn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (verifiedDriverDetails != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.driverFoundValidated,
                        style: AppTypography.title.copyWith(
                          color: Colors.green,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : AppColors.stroke,
                    ),
                  ),
                  _buildDriverDetailRow(
                    Icons.person_outline,
                    l10n.driverNameLabel,
                    verifiedDriverDetails!.name,
                    isDark,
                  ),
                  _buildDriverDetailRow(
                    Icons.directions_car_outlined,
                    l10n.driverVehicleLabel,
                    verifiedDriverDetails!.vehicleType,
                    isDark,
                  ),
                  _buildDriverDetailRow(
                    Icons.location_on_outlined,
                    l10n.driverAreaLabel,
                    verifiedDriverDetails!.route,
                    isDark,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
