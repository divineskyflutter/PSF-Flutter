import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/auth/presentation/controllers/login_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
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

  @override
  void initState() {
    super.initState();
    _mobileFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
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

    // LoginController already shows a success/error toast either way —
    // only navigate on success.
    if (success) {
      Get.offAllNamed(AppRoutes.home);
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

                        keyboardType: TextInputType.visiblePassword,

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
