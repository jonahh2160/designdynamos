import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/data/services/supabase_service.dart';
import 'package:designdynamos/features/dashboard/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _redirecting = false;
  final supabase = SupabaseService.client;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  String get _ctaLabel => _isSignUp ? 'Send Sign Up Link' : 'Send Sign In Link';
  String get _title => _isSignUp ? 'Create Account' : 'Sign In';
  String get _description => _isSignUp
      ? 'Enter your email to create an account. We will send you a confirmation link.'
      : 'Enter your email to sign in with a magic link.';

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) _showSnack('Please enter an email.', isError: true);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final redirect = kIsWeb
          //Use the current web origin so the code verifier stays in the same storage bucket.
          ? Uri.base.toString()
          : 'io.supabase.flutterquickstart://login-callback/';

      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirect,
        shouldCreateUser: _isSignUp,
      );

      if (mounted) {
        final message = _isSignUp
            ? 'Check your email to confirm and finish signing up.'
            : 'Check your email for a sign-in link.';
        _showSnack(message);

        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        _showSnack('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        if (!mounted) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      },
      onError: (error) {
        if (error is AuthException) {
          _showSnack(error.message, isError: true);
        } else {
          _showSnack('Unexpected error occurred', isError: true);
        }
      },
    );
    super.initState();
  }

  void _showSnack(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.snackBarTheme.backgroundColor,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = 440.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSwitcher(theme),
                const SizedBox(height: 18),
                _AuthCard(
                  title: _title,
                  description: _description,
                  emailController: _emailController,
                  isLoading: _isLoading,
                  ctaLabel: _ctaLabel,
                  onSubmit: _isLoading ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.taskCardHighlight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcher(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sidebarActive.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SwitcherChip(
            label: 'Sign In',
            selected: !_isSignUp,
            onTap: _isLoading
                ? null
                : () => setState(() {
                      _isSignUp = false;
                    }),
          ),
          const SizedBox(width: 10),
          _SwitcherChip(
            label: 'Create Account',
            selected: _isSignUp,
            onTap: _isLoading
                ? null
                : () => setState(() {
                      _isSignUp = true;
                    }),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.description,
    required this.emailController,
    required this.isLoading,
    required this.ctaLabel,
    required this.onSubmit,
  });

  final String title;
  final String description;
  final TextEditingController emailController;
  final bool isLoading;
  final String ctaLabel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sidebarActive.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.detailCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.sidebarActive),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.taskCardHighlight),
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.taskCardHighlight,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isLoading ? 'Sending…' : ctaLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherChip extends StatelessWidget {
  const _SwitcherChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.taskCardHighlight : AppColors.detailCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.taskCardHighlight.withValues(alpha: 0.8)
                : AppColors.sidebarActive,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
