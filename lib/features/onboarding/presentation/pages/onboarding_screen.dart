import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/core/storage/app_prefs.dart';

/// A single onboarding experience driven by [OnboardingPageData].
/// Add or update a slide by changing the list below; the layout stays shared.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  var _currentPage = 0;

  static final _pages = [
    OnboardingPageData(
      assetPath: AppAssets.onboardingCommunity,
      title: AppStrings.onboardingWelcomeTitle.tr,
      description: AppStrings.onboardingWelcomeDescription.tr,
    ),
    OnboardingPageData(
      assetPath: AppAssets.onboardingFamily,
      title: AppStrings.onboardingFamilyTitle.tr,
      description:
      AppStrings.onboardingFamilyDescription.tr,
    ),
    OnboardingPageData(
      assetPath: AppAssets.onboardingFinance,
      title:  AppStrings.onboardingGrowTitle.tr,
      description: AppStrings.onboardingGrowDescription.tr,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  // Language selection was registered but never reachable because onboarding
  // previously navigated directly to the login form.
  Future<void> _goToAuthSelection() async {
    await AppPrefs.setOnboardingCompleted(true);

    Get.offAllNamed(AppRoutes.authChoice);
  }
  void _next() {
    if (_isLastPage) {
      _goToAuthSelection();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) =>
                  OnboardingSlide(data: _pages[index]),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _OnboardingActions(
                currentPage: _currentPage,
                pageCount: _pages.length,
                isLastPage: _isLastPage,
                onNext: _next,
                onSkip: _goToAuthSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.assetPath,
    required this.title,
    required this.description,
  });

  final String assetPath;
  final String title;
  final String description;
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.data, super.key});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 236),
        child: Column(
          children: [
            const SizedBox(height: 18),
            Expanded(
              flex: 6,
              child: Center(
                  child: Lottie.asset(
                data.assetPath,
                width: constraints.maxWidth,
                fit: BoxFit.contain,
              )),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.onNext,
    required this.onSkip,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 42, 28, 28),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.primaryDark
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: currentPage == index ? 28 : 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(.42),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          if (isLastPage)
            _ActionButton(
                label: AppStrings.continueText.tr,
                icon: Icons.arrow_forward_rounded,
                onTap: onNext)
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(58),
                    ),
                    child: Text(AppStrings.skip.tr,
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                      label: AppStrings.next.tr,
                      icon: Icons.arrow_forward_rounded,
                      onTap: onNext),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 9),
              Icon(icon, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}
