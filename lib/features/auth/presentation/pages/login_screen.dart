import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/auth/presentation/controllers/login_controller.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/navigation/registration_navigator.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/sim_number_util.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';

/// Login screen — mobile number + password only, same visual language as
/// RegisterScreen (header with back button + logo, labeled AppTextField.
/// form fields, full-width primary button).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loginController = Get.find<LoginController>();

  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  late final FocusNode _mobileFocusNode;
  late final FocusNode _passwordFocusNode;

  bool _obscurePassword = true;

  /// SIM-associated numbers to offer as tap-to-fill suggestions (see
  /// SimNumberUtil) — empty on iOS, when nothing is reported, or once the
  /// member has typed something themselves.
  List<String> _suggestedNumbers = const [];
  bool _suggestionsRequested = false;

  /// Letters keyboard first; flips to a number keyboard once exactly 4
  /// letters have been typed (passwords look like "NIKH9601"). Only
  /// transitions are handled, never "current state", so a member who
  /// manually switches to numbers earlier (e.g. "NK" then 1234) is left
  /// alone: no digit-less 4-letter moment ever happens for that password.
  TextInputType _passwordKeyboardType = TextInputType.visiblePassword;

  @override
  void initState() {
    super.initState();
    _mobileFocusNode = FocusNode()..addListener(_onMobileFocusChange);
    _passwordFocusNode = FocusNode();
    _passwordController.addListener(_handlePasswordKeyboardSwitch);
  }

  /// Fires once, the first time the member taps into the (still empty)
  /// mobile number field — asks Android for any SIM-associated number(s)
  /// so they can be offered as tap-to-fill suggestions instead of typed.
  /// Never re-asks after that: a denied/empty result the first time isn't
  /// worth re-querying on every later focus, and a filled-in field has
  /// nothing to suggest into anyway.
  void _onMobileFocusChange() {
    if (!_mobileFocusNode.hasFocus) return;
    if (_suggestionsRequested) return;
    if (_mobileController.text.trim().isNotEmpty) return;

    _suggestionsRequested = true;
    SimNumberUtil.suggestedNumbers().then((numbers) {
      if (!mounted) return;
      setState(() => _suggestedNumbers = numbers);
    });
  }

  void _useSuggestedNumber(String number) {
    _mobileController.text = number;
    _mobileController.selection = TextSelection.collapsed(offset: number.length);
    setState(() => _suggestedNumbers = const []);
    FocusScope.of(context).requestFocus(_passwordFocusNode);
  }

  /// Same unfocus -> refocus-next-frame trick as the PAN field on the
  /// registration screen: just changing `keyboardType` on a focused field
  /// doesn't reliably make Android redraw an already-open keyboard.
  void _handlePasswordKeyboardSwitch() {
    final value = _passwordController.value;
    final text = value.text;

    // Once a digit exists the member is past the letters part (or has
    // switched keyboards themselves) — never touch the keyboard again.
    if (RegExp(r'[0-9]').hasMatch(text)) return;

    final letters = RegExp(r'[A-Za-z]').allMatches(text).length;

    TextInputType? target;
    if (letters == 4 && _passwordKeyboardType == TextInputType.visiblePassword) {
      // .phone (not .number) — reliably ASCII 0-9 even on Hindi/Gujarati
      // keyboards, same reasoning as the PAN field's digit zone.
      target = TextInputType.phone;
    } else if (letters < 4 && _passwordKeyboardType == TextInputType.phone) {
      target = TextInputType.visiblePassword;
    }

    if (target == null) return;

    final selectionToRestore = value.selection;
    final wasFocused = _passwordFocusNode.hasFocus;

    setState(() => _passwordKeyboardType = target!);

    if (!wasFocused) return;

    _passwordFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passwordFocusNode.requestFocus();
      _passwordController.selection = selectionToRestore;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordKeyboardSwitch);
    _mobileFocusNode.removeListener(_onMobileFocusChange);
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_loginController.isLoggingIn.value) return;

    FocusScope.of(context).unfocus();

    final success = await _loginController.login(
      mobile: _mobileController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success) {
      // LoginController already showed the success toast.
      final loggedInUser = _loginController.loggedInUser.value;

      if (loggedInUser?.isInEditMode == true) {
        // Prefill every Step 1 field from this member's already-saved
        // data — the exact same call RegisterScreen makes before
        // resuming (RegistrationController.getMemberStatus) — so both
        // the query-resolution flow below and the full open-edit flow
        // show existing values instead of blank fields. Without this,
        // RegistrationController.member stays null and Step 1's own
        // later re-check (_loadMember, gated on member already being
        // set) silently no-ops. LoginModel doesn't expose first/middle/
        // surname itself, so they come from the raw login payload.
        final raw = loggedInUser!.raw;
        await Get.find<RegistrationController>().getMemberStatus(
          isRegistered: true,
          firstName: raw['firstName']?.toString() ?? '',
          middleName: raw['lastName']?.toString() ?? '',
          surname: raw['surname']?.toString() ?? '',
          mobile: loggedInUser.mobile ?? '',
        );
      }

      if (loggedInUser?.hasUnresolvedQueries == true) {
        // Specific fields were flagged by an admin and need correcting —
        // a narrower flow than the full open-everything edit wizard below:
        // only those exact fields unlock, everything else stays locked.
        // Always starts at Step 1 — the wizard's own forward-skip logic
        // (see RegistrationController.queryState) jumps past any step with
        // nothing to resolve.
        final regController = Get.find<RegistrationController>();
        regController.isEditingAfterLogin = true;
        // Field names (which field is Gujarati/Hindi/plain) come from the
        // enum bundle — make sure they're here before the flow is set up,
        // otherwise a fast login would start it with every field looking
        // plain and nothing highlighted.
        await regController.ensureFieldEnumsLoaded();
        regController.startQueryResolutionMode(loggedInUser!.queries);
        Get.toNamed(AppRoutes.memberRegistrationStep1);
        return;
      }

      if (loggedInUser?.isInEditMode == true) {
        // Login succeeded, but this member's registration is still open
        // for correction — go straight to the wizard's form screens
        // instead of Home. Pushed (not offAll) so Back returns here to
        // Login for now — TODO: once there's a proper place for Back to
        // land instead, revisit this.
        Get.find<RegistrationController>().isEditingAfterLogin = true;

        final statusName =
            _loginController.loggedInUser.value?.raw['memberDetailStatusName']?.toString();
        final stepIndex = RegistrationNavigator.initialStepFor(statusName);

        if (stepIndex != null) {
          // memberDetailStatusName genuinely names one of the 4 wizard
          // steps (e.g. this member never finished step 3) — resume
          // exactly there.
          RegistrationNavigator.navigateToScreen(statusName);
        } else {
          // memberDetailStatusName names something else — most commonly
          // "/member-registration-pending" (a fully-filled application
          // sent back for correction). That name normally routes to the
          // "awaiting admin approval" screen, which is wrong here: edit
          // mode means there IS something to edit, so open the form
          // itself, from the top, instead.
          Get.toNamed(AppRoutes.memberRegistrationStep1);
        }
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
      return;
    }

    // Not a plain wrong-credentials/server error (that case already showed
    // its own toast and stays right here) — the API blocked this login
    // because the member's registration itself isn't finished or is still
    // being reviewed. Send them somewhere useful instead of leaving them
    // stuck on this screen. See LoginBlockedReason's doc comment.
    switch (_loginController.lastBlockedReason) {
      case LoginBlockedReason.pending:
        // Resumes wherever this member left off (any wizard step, editable)
        // — the same flow RegisterScreen already drives via
        // RegistrationController.getMemberStatus / RegistrationNavigator.
        // AuthChoice goes underneath it (not offAllNamed straight to
        // RegisterScreen) so Back on RegisterScreen returns to the normal
        // Sign In / Register choice screen, same as reaching it that way.
        Get.offAllNamed(AppRoutes.authChoice);
        Get.toNamed(AppRoutes.registerScreen);
      case LoginBlockedReason.review:
        Get.offAllNamed(AppRoutes.registrationPending, arguments: const {'fromLogin': true});
      case null:
        break;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // No scroll view here on purpose — this screen only ever has two
      // fields, so it should just fit on the screen like a normal fixed
      // layout instead of scrolling. Spacing below is deliberately
      // compact (and the gap before the footer text is a Spacer, not a
      // fixed height) so it also holds up once the keyboard opens.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.px(context),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 5.px(context),
                      ),

                      // Heading
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 12.px(context),
                            ),
                            Center(
                              child: Text(
                                'sign_in'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22.px(context),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Center(
                              child: Text(
                                'login_screen_subtitle'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.px(context),
                                  height: 1.5,
                                  color:
                                      AppColors.primaryDark.withOpacity(0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Logo
                      SvgPicture.asset(
                        AppAssets.logo,
                        height: 45.px(context),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 18.px(context),
                ),

                // ==================================================
                // FORM
                // ==================================================

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // MOBILE NUMBER
                      // ==================================================

                      _buildLabel(
                        'phone_number'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: _mobileController,
                        focusNode: _mobileFocusNode,

                        hintText: 'enter_mobile_number'.tr,

                        prefixIcon: Container(
                          width: 80,
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  AppAssets.indianFlagGif,
                                  width: 24,
                                  height: 18,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        keyboardType: TextInputType.phone,

                        textInputAction: TextInputAction.next,

                        maxLength: 10,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        // Exactly the same rule the Register screen's
                        // mobile field enforces — see AppValidators.mobile.
                        validator: AppValidators.mobile,
                      ),

                      if (_suggestedNumbers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _suggestedNumbersRow(),
                      ],

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PASSWORD
                      // ==================================================

                      _buildLabel(
                        'password'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,

                        hintText: 'enter_password'.tr,

                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.primaryDark.withOpacity(0.55),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),

                        obscureText: _obscurePassword,

                        keyboardType: _passwordKeyboardType,

                        textInputAction: TextInputAction.done,

                        maxLength: 8,

                        // Letters + exactly 4 digits, capped at 8 total —
                        // see AppValidators.loginPassword. Auto-uppercased
                        // as the member types, so the field's own display
                        // always matches the capital-letters format the
                        // login API expects.
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            ),
                          ),
                        ],

                        validator: AppValidators.loginPassword,

                        onSubmitted: (_) => _onLoginPressed(),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Obx(
                          () {
                            final isLoggingIn =
                                _loginController.isLoggingIn.value;

                            return ElevatedButton(
                              onPressed:
                                  isLoggingIn ? null : _onLoginPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                              child: isLoggingIn
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.background,
                                      ),
                                    )
                                  : Text(
                                      'login'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),

                      // Fixed gap, not Flexible — this Column is just a
                      // plain (non-flex) child of the outer Column (via the
                      // Padding above), so it gets an UNBOUNDED height from
                      // its parent, and a Flexible/Expanded child needs a
                      // bounded parent height to be legal (that's what
                      // crashed the screen: "RenderFlex children have
                      // non-zero flex but incoming height constraints are
                      // unbounded"). A small fixed gap is fine here since
                      // there's no scroll view to worry about overflowing.
                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // SIGN UP LINK
                      // ==================================================

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'dont_have_account'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryDark.withOpacity(0.65),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.offNamed(
                                AppRoutes.registerScreen,
                              ),
                              child: Text(
                                'sign_up'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // SECURITY
                      // ==================================================

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryDark.withOpacity(
                                    0.35,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: AppColors.primaryDark.withOpacity(
                                  0.55,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'secure_encrypted_login'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark.withOpacity(
                                  0.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  /// Tap-to-fill chips for whatever SIM-associated number(s) Android
  /// reported (see SimNumberUtil) — shown right under the mobile field
  /// while it's still empty. Each chip shows the number the way the member
  /// is used to seeing it (+91, grouped), and tapping one fills the field
  /// and moves on to Password, same as if they'd typed it themselves.
  Widget _suggestedNumbersRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedNumbers.map((number) {
        final display = number.length == 10
            ? '${number.substring(0, 5)} ${number.substring(5)}'
            : number;

        return InkWell(
          onTap: () => _useSuggestedNumber(number),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sim_card_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '+91 $display',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
    );
  }
}
