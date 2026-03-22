import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/payments/card_added_success_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/payment_service.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _isProcessing = false;

  void _initiatePayHerePreapproval() async {
    setState(() => _isProcessing = true);

    await PaymentService.instance.initCardPreapproval(
      onSuccess: (paymentId) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CardAddedSuccessScreen()),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Error: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
      onDismissed: () {
        if (!mounted) return;
        setState(() => _isProcessing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Setup Automated Billing',
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const _CardPreview(),
            const SizedBox(height: 40),

            Icon(Icons.autorenew, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Automated Monthly Fees',
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                fontSize: 20,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Securely link your card to automatically pay your monthly school van fees on your billing date. You can cancel or update this at any time.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),

            const Spacer(),

            FilledButton(
              onPressed: _isProcessing ? null : _initiatePayHerePreapproval,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkSurfaceStrong
                    : AppColors.surfaceStrong,
                foregroundColor: textColor,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Link Card Securely',
                      style: AppTypography.title.copyWith(
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PayHere Secure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•••• •••• •••• ••••',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card Details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tokenized for Safety',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
