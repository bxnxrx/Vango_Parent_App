import 'package:flutter/material.dart';
import 'package:vango_parent_app/supportbot/supportbot_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';

class SupportbotFab extends StatelessWidget {
  const SupportbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'parent-supportbot-fab',
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SupportbotScreen()),
        );
      },
      child: const Icon(Icons.support_agent_rounded),
    );
  }
}