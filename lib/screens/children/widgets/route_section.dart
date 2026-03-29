import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class RouteSection extends StatelessWidget {
  final TextEditingController schoolController;
  final TextEditingController pickupLocationController;
  final TextEditingController dropLocationController;
  final TextEditingController etaSchoolController;
  final TextEditingController pickupTimeController;
  final Future<List<String>> Function(String) searchSchools;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;
  final VoidCallback onEtaTap;
  final String? routeDistance;
  final String? routeDuration;
  final bool isCalculatingRoute;

  const RouteSection({
    super.key,
    required this.schoolController,
    required this.pickupLocationController,
    required this.dropLocationController,
    required this.etaSchoolController,
    required this.pickupTimeController,
    required this.searchSchools,
    required this.onPickupTap,
    required this.onDropTap,
    required this.onEtaTap,
    this.routeDistance,
    this.routeDuration,
    required this.isCalculatingRoute,
  });

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
    bool isDark, {
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
      suffixIcon: suffix,
      labelStyle: TextStyle(
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolRouteDetailsSection,
          style: AppTypography.title.copyWith(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Autocomplete<String>(
          initialValue: TextEditingValue(text: schoolController.text),
          optionsBuilder: (TextEditingValue text) async => text.text.isEmpty
              ? const Iterable<String>.empty()
              : await searchSchools(text.text),
          onSelected: (String selection) {
            FocusManager.instance.primaryFocus?.unfocus();
            schoolController.text = selection;
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                controller.addListener(
                  () => schoolController.text = controller.text,
                );
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration(
                    l10n.schoolNameLabel,
                    l10n.schoolNameHint,
                    Icons.school_outlined,
                    isDark,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.schoolRequired;
                    }
                    return null;
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(
                        Icons.school,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        options.elementAt(index),
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      onTap: () => onSelected(options.elementAt(index)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: pickupLocationController,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onPickupTap,
          decoration: _buildInputDecoration(
            l10n.pickupLocationLabel,
            l10n.tapToSetOnMap,
            Icons.home_outlined,
            isDark,
            suffix: const Icon(Icons.map_outlined, color: AppColors.accent),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return l10n.pickupRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: dropLocationController,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onDropTap,
          decoration: _buildInputDecoration(
            l10n.dropLocationLabel,
            l10n.tapToSetOnMap,
            Icons.pin_drop_outlined,
            isDark,
            suffix: const Icon(Icons.map_outlined, color: AppColors.accent),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return l10n.dropRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: etaSchoolController,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onEtaTap,
          decoration: _buildInputDecoration(
            l10n.etaSchoolLabel,
            l10n.selectArrivalTime,
            Icons.access_time_filled,
            isDark,
            suffix: Icon(
              Icons.edit_calendar,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return l10n.etaRequired;
            }
            return null;
          },
        ),

        if (isCalculatingRoute)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (routeDistance != null && routeDuration != null)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.stroke,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.distanceLabel,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      routeDistance!,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
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
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom_outlined,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.trafficDelayLabel,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      routeDuration!,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (routeDistance != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: pickupTimeController,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _buildInputDecoration(
              l10n.confirmPickupTimeLabel,
              l10n.pickupTimeExample, // ✅ HARDCODED TEXT REMOVED
              Icons.alarm_on,
              isDark,
            ).copyWith(prefixIconColor: Colors.green),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return l10n.pickupTimeRequired;
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
