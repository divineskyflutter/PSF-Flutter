import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';

/// Login screen — mobile number + password only, same visual language as
/// RegisterScreen (header with back button + logo, labeled AppTextField.
/// form fields, full-width primary button).
///
/// The Login button does NOT call the login API yet — there is no real
/// login endpoint on the backend yet, so tapping it just validates the
/// form and navigates straight to Home (see _onLoginPressed's comment).
/// The full API-calling chain (LoginModel / LoginRemoteDataSource /
/// LoginRepository / LoginController) is already built and registered in
/// AuthBinding, ready for once the real endpoint exists.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

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

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    // No real login API exists yet — same reason
    // ProfileController.fetchProfile() is built but not auto-called (see
    // that class's onInit doc comment). Once the real endpoint is ready,
    // replace this with a call to Get.find<LoginController>().login(
    // mobile: ..., password: ...) and navigate to Home only on success.
    Get.offAllNamed(AppRoutes.home);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                              height: 35.px(context),
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
                  height: 32.px(context),
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

                        // Exactly 4 uppercase letters followed by exactly
                        // 4 digits — see AppValidators.loginPassword.
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
                        height: 30,
                      ),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onLoginPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            'login'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
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

                      const SizedBox(
                        height: 25,
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
