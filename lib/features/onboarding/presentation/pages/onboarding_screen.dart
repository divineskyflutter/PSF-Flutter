import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/ornamental_divider.dart';

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

  // ============================================================
  // LAYOUT
  //
  // The action bar/indicator used to float on TOP of the PageView (via an
  // Align inside a Stack), with the slide reserving a guessed pixel gap at
  // its own bottom so its text wouldn't be covered. That guess didn't
  // always match the action bar's real height (it changes with the
  // language's text length and font metrics), so long Hindi/Gujarati
  // titles/descriptions could end up rendering underneath the floating
  // bar. Using a plain Column instead — PageView on top (Expanded),
  // indicator + action bar below as normal siblings — means their real
  // heights are always accounted for by the layout itself: nothing can
  // ever sit underneath anything else, with no pixel guessing and no
  // scrolling required.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) =>
                    OnboardingSlide(data: _pages[index]),
              ),
            ),

            // Indicator now lives outside the action card, on the plain
            // background, so it gets its own (non-white) color scheme.
            _PageIndicator(
              currentPage: _currentPage,
              pageCount: _pages.length,
            ),

            SizedBox(height: 12.px(context)),

            _OnboardingActions(
              isLastPage: _isLastPage,
              onNext: _next,
              onSkip: _goToAuthSelection,
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
  const OnboardingSlide({
    required this.data,
    super.key,
  });

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Fixed responsive heights. Kept smaller than before (was 390/50)
        // now that the action bar sits below the slide instead of
        // floating on top of it — the slide only gets whatever height is
        // left after the indicator + action bar, so it needs to spend
        // less of that on the hero image and more on the text.
        final imageHeight = 450.px(context);
        final overlap = 36.px(context);

        final contentTop = imageHeight - overlap;

        return Stack(
          children: [
            // ============================================================
            // IMAGE
            // ============================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageHeight,
              child: Image.asset(
                data.assetPath,
                width: screenWidth,
                height: imageHeight,
                fit: BoxFit.cover,
              ),
            ),

            // ============================================================
            // CONTENT CONTAINER
            // ============================================================
            Positioned(
              top: contentTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40.px(context)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // ----------------------------------------------------
                    // TOP DECORATION
                    // ----------------------------------------------------
                    SizedBox(
                      height: 16.px(context),
                    ),

                    OrnamentalDivider(
                      iconSize: 18.px(context),
                    ),

                    SizedBox(
                      height: 10.px(context),
                    ),

                    // ----------------------------------------------------
                    // TEXT AREA — top-aligned (not centered) and never
                    // truncated, so a longer Hindi/Gujarati translation
                    // always renders in full instead of being cut short
                    // with an ellipsis or centered into the space the
                    // action bar used to cover.
                    // ----------------------------------------------------
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 26.px(context),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // TITLE
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24.px(context),
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            height: 10.px(context),
                          ),

                          // DESCRIPTION
                          Text(
                            data.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.5.px(context),
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// PAGE INDICATOR — previously drawn inside the gradient action card;
// moved out to sit on the plain background above it, so it needed its
// own (non-white) color scheme instead of the one designed to sit on a
// colored gradient.
// ============================================================

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(
            horizontal: 3.px(context),
          ),
          height: 6.px(context),
          width: currentPage == index
              ? 22.px(context)
              : 6.px(context),
          decoration: BoxDecoration(
            color: currentPage == index
                ? AppColors.primary
                : AppColors.primary.withOpacity(.20),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.isLastPage,
    required this.onNext,
    required this.onSkip,
  });

  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.px(context),
        right: 20.px(context),
        bottom: 14.px(context),
      ),
      child: Container(
        // Height reduced — was vertical: 12 with the indicator row also
        // taking space inside; the indicator lives outside now, so this
        // card only ever needs to fit the action button(s).
        padding: EdgeInsets.symmetric(
          horizontal: 16.px(context),
          vertical: 8.px(context),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(
            22.px(context),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(.16),
            ),
          ],
        ),
        child: isLastPage
            ? _ActionButton(
          label: AppStrings.continueText.tr,
          icon: Icons.arrow_forward_rounded,
          onTap: onNext,
        )
            : Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42.px(context),
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppStrings.skip.tr,
                    style: TextStyle(
                      fontSize: 15.px(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 10.px(context)),

            Expanded(
              flex: 1,
              child: _ActionButton(
                label: AppStrings.next.tr,
                icon: Icons.arrow_forward_rounded,
                onTap: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.px(context),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.px(context)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.px(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 15.px(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 7.px(context)),
              Icon(
                icon,
                color: AppColors.primaryDark,
                size: 20.px(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
