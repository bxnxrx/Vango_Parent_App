import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class AuthUiHelper {
  // Parses exceptions and returns the localizable string key
  static String parseErrorKey(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials'))
        return 'err_invalid_creds';
      if (msg.contains('already registered') ||
          msg.contains('user already exists'))
        return 'err_user_exists';
      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('over_email_send_rate_limit'))
        return 'err_too_many_req';
      if (msg.contains('not confirmed') || msg.contains('unverified'))
        return 'err_unverified';
      if (msg.contains('password should be')) return 'err_pass_min';
      if (msg.contains('invalid') || msg.contains('expired'))
        return 'err_invalid';
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('network') ||
        errStr.contains('socket') ||
        errStr.contains('timeout') ||
        errStr.contains('clientexception')) {
      return 'err_network';
    }
    return 'err_generic';
  }

  // Centralized Snackbar
  static void showMessage(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    if (isError) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    final bgColor = isError
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade700;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
          elevation: 6,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
