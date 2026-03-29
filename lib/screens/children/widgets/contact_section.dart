import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class ContactSection extends StatelessWidget {
  final TextEditingController emergencyContactController;
  final String parentPhone;
  final List<String> previouslyUsedNumbers;
  final String selectedEmergencyOption;
  final bool isCustomContactVerified;
  final bool isSendingOtp;
  final Function(String) onOptionChanged;
  final VoidCallback onVerifyRequested;
  final VoidCallback onResetVerification;

  const ContactSection({
    super.key,
    required this.emergencyContactController,
    required this.parentPhone,
    required this.previouslyUsedNumbers,
    required this.selectedEmergencyOption,
    required this.isCustomContactVerified,
    required this.isSendingOtp,
    required this.onOptionChanged,
    required this.onVerifyRequested,
    required this.onResetVerification,
  });

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
              color: isSelected ? AppColors.accent : Colors.white54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.emergencyContactSection,
          style: AppTypography.title.copyWith(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildCustomRadio(
                title: '${l10n.useParentProfileNumber}\n($parentPhone)',
                isSelected: selectedEmergencyOption == 'parent',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOptionChanged('parent');
                },
              ),
              ...previouslyUsedNumbers.map(
                (phone) => _buildCustomRadio(
                  title: '${l10n.previouslyUsedNumber}\n($phone)',
                  isSelected: selectedEmergencyOption == phone,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOptionChanged(phone);
                  },
                ),
              ),
              _buildCustomRadio(
                title: l10n.addNewNumber,
                isSelected: selectedEmergencyOption == 'new',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOptionChanged('new');
                },
              ),
            ],
          ),
        ),
        if (selectedEmergencyOption == 'new') ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: emergencyContactController,
                  style: const TextStyle(color: Colors.white),
                  readOnly: isCustomContactVerified,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    labelText: l10n.newEmergencyContactLabel,
                    prefixText: '+94 ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Colors.white54,
                    ),
                    labelStyle: const TextStyle(color: Colors.white54),
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
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Required';
                    }
                    if (!RegExp(r'^7\d{8}$').hasMatch(v.trim())) {
                      return l10n.invalidSlNumber;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isCustomContactVerified
                      ? onResetVerification
                      : (isSendingOtp ? null : onVerifyRequested),
                  style: FilledButton.styleFrom(
                    backgroundColor: isCustomContactVerified
                        ? const Color(0xFF1E1E1E)
                        : AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isCustomContactVerified
                              ? Icons.edit
                              : Icons.verified_user,
                        ),
                ),
              ),
            ],
          ),
          if (!isCustomContactVerified)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                l10n.tapVerifyConfirm,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
