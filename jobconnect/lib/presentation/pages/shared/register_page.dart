import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import '../../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterPage extends StatefulWidget {
  final String role;

  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authBloc.close();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    final role =
        widget.role == 'company' ? UserRole.company : UserRole.student;

    _authBloc.add(
      AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: role,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColorsLight.textTertiary),
      prefixIcon: Icon(icon, color: AppColorsLight.primary.withOpacity(0.7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColorsLight.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColorsLight.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.role == UserRole.company) {
              context.go('/company/dashboard');
            } else {
              context.go('/student/home');
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Stack(
            children: [
              // Background Gradient Header with Image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.45,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColorsLight.primary, Color(0xFF5A189A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Hero(
                    tag: 'auth_image',
                    child: Image.asset(
                      'assets/images/signup.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Espace pour laisser voir l'image en fond avant la carte
                      SizedBox(height: size.height * 0.28),
                      
                      // Form Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text('Créer un compte', style: AppTypography.displayMedium.copyWith(color: AppColorsLight.primary)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.role == 'student' ? 'En tant que candidat 🚀' : 'En tant qu\'entreprise 🏢',
                                style: AppTypography.bodyMedium.copyWith(color: AppColorsLight.textTertiary),
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Full name
                              TextFormField(
                                controller: _fullNameController,
                                style: AppTypography.bodyLarge,
                                decoration: _buildInputDecoration(
                                  label: widget.role == 'student' ? 'Nom complet' : 'Nom de l\'entreprise',
                                  icon: Icons.person_rounded,
                                ),
                                validator: Validators.fullName,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTypography.bodyLarge,
                                decoration: _buildInputDecoration(
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                ),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: AppTypography.bodyLarge,
                                decoration: _buildInputDecoration(
                                  label: 'Mot de passe',
                                  icon: Icons.lock_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: AppColorsLight.textTertiary,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: Validators.password,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Confirm password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: AppTypography.bodyLarge,
                                decoration: _buildInputDecoration(
                                  label: 'Confirmer le mot de passe',
                                  icon: Icons.lock_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: AppColorsLight.textTertiary,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Error message
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is AuthError) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: AppColorsLight.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                        border: Border.all(color: AppColorsLight.error.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: AppColorsLight.error, size: 20),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              state.message,
                                              style: AppTypography.bodySmall.copyWith(color: AppColorsLight.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Register button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return ElevatedButton(
                                    onPressed: isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColorsLight.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      minimumSize: const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : Text('Créer mon compte', style: AppTypography.labelLarge.copyWith(fontSize: 16)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Déjà un compte ? ',
                            style: AppTypography.bodyMedium.copyWith(color: AppColorsLight.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Se connecter',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColorsLight.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // Back Button (Au premier plan pour être cliquable)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/status-selection');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}