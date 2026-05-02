import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;

  int _currentStep = 0; // 0 = basic, 1 = optional details

  final List<String> _genders = ['male', 'female', 'other', 'prefer_not_to_say'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Convert ft/inch to cm for API
  double? _getHeightInCm() {
    final ft = int.tryParse(_heightFtController.text);
    final inch = int.tryParse(_heightInController.text) ?? 0;
    if (ft == null) return null;
    return ((ft * 12) + inch) * 2.54;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      age: _ageController.text.isEmpty
          ? null
          : int.tryParse(_ageController.text),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      height: _getHeightInCm(),
      weight: _weightController.text.isEmpty
          ? null
          : double.tryParse(_weightController.text),
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A2C5B), Color(0xFF3D1835)],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    _buildStepDot(0, 'Basic Info'),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep >= 1
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    _buildStepDot(1, 'Health Info'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: _currentStep == 0
                          ? _buildStep1()
                          : _buildStep2(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your name';
            return null;
          },
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Minimum 8 characters',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone (Optional)',
          hint: '+91XXXXXXXXXX',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 24),

        // Error message
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        PrimaryButton(
          text: 'Next',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() => _currentStep = 1);
            }
          },
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // Age
        CustomTextField(
          controller: _ageController,
          label: 'Age',
          hint: 'e.g., 25',
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 18),

        // Gender (full width - fixes overflow)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gender',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                hintText: 'Select gender',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              isExpanded: true,
              items: _genders
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          g.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' '),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Group',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bloodGroups.map((bg) {
                final isSelected = _selectedBloodGroup == bg;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBloodGroup = bg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      bg,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Height in ft + inch
        Text(
          'Height',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _heightFtController,
                label: '',
                hint: 'ft',
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
                // suffixIcon: Padding(
                //   padding: const EdgeInsets.only(right: 12),
                //   child: Text('ft', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                // ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _heightInController,
                label: '',
                hint: 'in',
                prefixIcon: Icons.straighten,
                keyboardType: TextInputType.number,
                //suffixIcon: Padding(
                  //padding: const EdgeInsets.only(right: 12),
                  //child: Text('in', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                //),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Weight
        CustomTextField(
          controller: _weightController,
          label: 'Weight (kg)',
          hint: 'e.g., 65',
          prefixIcon: Icons.monitor_weight_outlined,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),

        // Error message
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return PrimaryButton(
              text: 'Create Account',
              isLoading: auth.isLoading,
              onPressed: _register,
            );
          },
        ),

        const SizedBox(height: 12),

        PrimaryButton(
          text: 'Back',
          isOutlined: true,
          onPressed: () => setState(() => _currentStep = 0),
        ),
      ],
    );
  }
}
