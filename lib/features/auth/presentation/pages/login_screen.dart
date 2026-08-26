import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/theme/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.isSignUp = false, super.key});

  final bool isSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  late final bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Welcome Back'),
        actions: [
          IconButton(
            icon: Icon(themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Icon(
                Icons.security_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                _isSignUp ? 'Get Started Today' : 'Sign In to Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ),
              if (!_isSignUp) const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Get.offAllNamed('/home');
                },
                child: Text(
                  _isSignUp ? 'Create Account' : 'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account?'
                        : 'Don\'t have an account?',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  TextButton(
                    onPressed: () => Get.offNamed(
                      _isSignUp ? AppRoutes.login : AppRoutes.registerScreen,
                    ),
                    child: Text(
                      _isSignUp ? 'Login' : 'Sign up',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
