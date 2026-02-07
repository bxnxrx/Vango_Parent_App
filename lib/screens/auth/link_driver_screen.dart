import 'package:flutter/material.dart';

import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class LinkDriverScreen extends StatefulWidget {
  const LinkDriverScreen({
    super.key,
    required this.onLinked,
    required this.onBack,
    this.preferredChildId,
    this.initialCode,
  });

  final VoidCallback onLinked;
  final VoidCallback onBack;
  final String? preferredChildId;
  final String? initialCode;

  @override
  State<LinkDriverScreen> createState() => _LinkDriverScreenState();
}

class _LinkDriverScreenState extends State<LinkDriverScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _loadingChildren = true;
  bool _linking = false;
  List<ChildProfile> _children = const [];
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!.toUpperCase();
    }
    _loadChildren();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _loadingChildren = true);
    try {
      final children = await ParentDataService.instance.fetchChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _selectedChildId = widget.preferredChildId ?? children.firstOrNull?.id;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to load children: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingChildren = false);
      }
    }
  }

  Future<void> _linkDriver() async {
    final code = _codeController.text.trim();
    final childId = _selectedChildId;
    if (code.length < 4 || childId == null) {
      _showMessage('Select a child and enter the code from your driver.');
      return;
    }

    setState(() => _linking = true);
    try {
      await AuthService.instance.linkDriver(code: code, childId: childId);
      if (!mounted) return;
      _showMessage('Driver linked successfully');
      widget.onLinked();
    } catch (error) {
      _showMessage('Failed to link driver: $error');
    } finally {
      if (mounted) {
        setState(() => _linking = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: 8),
              Text('Connect with your driver', style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'Enter the driver code shared by your driver to finish registration. '
                'This ensures only verified parents can message or track rides.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (_loadingChildren)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_children.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Add your child profile first to continue.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select child', style: AppTypography.label),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedChildId,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _children
                            .map(
                              (child) => DropdownMenuItem(
                                value: child.id,
                                child: Text('${child.name} • ${child.school}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedChildId = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Driver code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask your driver for the 8-character code shown in their app.',
                        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      GradientButton(
                        expanded: true,
                        label: _linking ? 'Linking...' : 'Link driver',
                        onPressed: _linking ? null : _linkDriver,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on List<ChildProfile> {
  ChildProfile? get firstOrNull => isEmpty ? null : first;
}
