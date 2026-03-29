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

  InputDecoration _buildDarkInputDecoration(
    String label,
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white54),
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white30),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolRouteDetailsSection,
          style: AppTypography.title.copyWith(
            fontSize: 16,
            color: Colors.white,
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
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildDarkInputDecoration(
                    l10n.schoolNameLabel,
                    l10n.schoolNameHint,
                    Icons.school_outlined,
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
                color: const Color(0xFF1E1E1E),
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
                        style: const TextStyle(color: Colors.white),
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
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onPickupTap,
          decoration: _buildDarkInputDecoration(
            l10n.pickupLocationLabel,
            l10n.tapToSetOnMap,
            Icons.home_outlined,
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
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onDropTap,
          decoration: _buildDarkInputDecoration(
            l10n.dropLocationLabel,
            l10n.tapToSetOnMap,
            Icons.pin_drop_outlined,
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
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onEtaTap,
          decoration: _buildDarkInputDecoration(
            l10n.etaSchoolLabel,
            'Tap to select time',
            Icons.access_time_filled,
            suffix: const Icon(Icons.edit_calendar, color: Colors.white54),
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
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.distanceLabel,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const Spacer(),
                    Text(
                      routeDistance!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.white10),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.hourglass_bottom_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.trafficDelayLabel,
                      style: const TextStyle(color: Colors.white54),
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
            style: const TextStyle(color: Colors.white),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _buildDarkInputDecoration(
              l10n.confirmPickupTimeLabel,
              'e.g. 06:45 AM',
              Icons.alarm_on,
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
