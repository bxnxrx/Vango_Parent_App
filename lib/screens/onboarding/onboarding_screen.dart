import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Slide content shown in order to new users.
  static const List<_Slide> _slides = [
    _Slide(
      title: 'Track every ride',
      body: 'Live GPS, ETA predictions, and safety checks keep you in control.',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=600&q=60',
      buttonLabel: "Let's go!",
    ),
    _Slide(
      title: 'Mark attendance instantly',
      body: 'Smart toggles sync with the driver and optimize the route.',
      imageUrl: 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=60',
      buttonLabel: 'Set attendance',
    ),
    _Slide(
      title: 'Payments & finder in one app',
      body: 'Pay van fees, discover new drivers, and chat securely.',
      imageUrl: 'https://images.unsplash.com/photo-1521791055366-0d553872125f?auto=format&fit=crop&w=600&q=60',
      buttonLabel: 'Get started',
    ),
  ];

  // Advance to the next slide or finish onboarding.
  void _goToNextPage() {
    final lastIndex = _slides.length - 1;
    if (_currentPage == lastIndex) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  // Shows which slide is currently active.
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.stroke,
            borderRadius: BorderRadius.circular(40),
          ),
        );
      }),
    );
  }

  Widget _buildCard(_Slide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.accent.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: _SlideImage(imageUrl: slide.imageUrl),
            ),
            Expanded(
              flex: 4,
              child: _SlideDetails(slide: slide, onNext: _goToNextPage),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(onPressed: widget.onFinished, child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildCard(_slides[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Simple data class for a single onboarding card.
class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.buttonLabel,
  });

  final String title;
  final String body;
  final String imageUrl;
  final String buttonLabel;
}

// Handles image loading states for each slide.
class _SlideImage extends StatelessWidget {
  const _SlideImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: AppColors.surfaceStrong,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.surfaceStrong,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary, size: 48),
      ),
    );
  }
}

// Displays the copy and primary action for a slide.
class _SlideDetails extends StatelessWidget {
  const _SlideDetails({required this.slide, required this.onNext});

  final _Slide slide;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: AppTypography.headline.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.body,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                slide.buttonLabel,
                style: AppTypography.title.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//