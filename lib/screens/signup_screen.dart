import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, String lang) async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('passwords_dont_match', lang))),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      _emailController.text,
      _passwordController.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else if (mounted && auth.errorKey != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(auth.errorKey!, lang))),
      );
    }
  }

  Future<void> _submitGoogle(BuildContext context, String lang) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else if (mounted && auth.errorKey != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(auth.errorKey!, lang))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('signup', lang))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.mosque, size: 72, color: AppColors.primary),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('email', lang),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? '' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('password', lang),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? '' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('confirm_password', lang),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? '' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () => _submit(context, lang),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            AppStrings.get('signup', lang),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: auth.loading
                        ? null
                        : () => _submitGoogle(context, lang),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(AppStrings.get('sign_in_with_google', lang)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(AppStrings.get('have_account_login', lang)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.get('continue_as_guest', lang)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
