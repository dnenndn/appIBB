import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Login Screen for BrickMonitor Pro
/// Provides secure authentication for factory personnel with industrial-grade security
/// Implements mandatory password change flow for first-time users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberUsername = true;
  String? _errorMessage;

  // Mock credentials for demonstration
  final Map<String, Map<String, dynamic>> _mockUsers = {
    'manager@factory.com': {
      'password': 'Manager@123',
      'role': 'Factory Manager',
      'firstLogin': false,
    },
    'supervisor@factory.com': {
      'password': 'Super@123',
      'role': 'Supervisor',
      'firstLogin': true,
    },
    'engineer@factory.com': {
      'password': 'Engineer@123',
      'role': 'Plant Engineer',
      'firstLogin': false,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load saved username from secure storage (simulated)
  Future<void> _loadSavedUsername() async {
    // In production, load from secure storage
    await Future.delayed(const Duration(milliseconds: 100));
    if (_rememberUsername) {
      setState(() {
        _usernameController.text = 'manager@factory.com';
      });
    }
  }

  /// Validate username format
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password format
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handle login authentication
  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // Check credentials
      if (_mockUsers.containsKey(username)) {
        final user = _mockUsers[username]!;
        if (user['password'] == password) {
          // Success - trigger haptic feedback
          HapticFeedback.mediumImpact();

          // Check if first login
          if (user['firstLogin'] == true) {
            // Show mandatory password change modal
            await _showPasswordChangeModal(username, user['role'] as String);
          } else {
            // Navigate to dashboard
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/dashboard-screen');
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid password. Please try again.';
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        setState(() {
          _errorMessage = 'User not found. Please check your username.';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show mandatory password change modal for first-time users
  Future<void> _showPasswordChangeModal(String username, String role) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'lock_reset',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Password Change Required',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For security compliance, you must change your password on first login.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                SizedBox(height: 3.h),
                // New password field
                TextFormField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock_outline',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: isNewPasswordVisible
                            ? 'visibility_off'
                            : 'visibility',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Confirm password field
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter new password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock_outline',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: isConfirmPasswordVisible
                            ? 'visibility_off'
                            : 'visibility',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Password requirements
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements:',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildRequirement('At least 8 characters'),
                      _buildRequirement('One uppercase letter'),
                      _buildRequirement('One lowercase letter'),
                      _buildRequirement('One number'),
                      _buildRequirement('One special character'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!_validatePasswordStrength(newPassword)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password does not meet requirements'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Success
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard-screen');
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build password requirement item
  Widget _buildRequirement(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle_outline',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Validate password strength
  bool _validatePasswordStrength(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  /// Handle forgot password
  void _handleForgotPassword() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'help_outline',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('Forgot Password'),
          ],
        ),
        content: const Text(
          'Please contact your system administrator to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 6.h),
                      // Logo and header section
                      _buildHeader(),
                      SizedBox(height: 6.h),
                      // Login form
                      _buildLoginForm(),
                      const Spacer(),
                      // Network status indicator
                      _buildNetworkStatus(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with logo and security badge
  Widget _buildHeader() {
    return Column(
      children: [
        // Factory logo
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'factory',
              color: Colors.white,
              size: 15.w,
            ),
          ),
        ),
        SizedBox(height: 3.h),
        // App name
        Text(
          'BrickMonitor Pro',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 1.h),
        // Security badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'verified_user',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Industrial Grade Security',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build login form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.error
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.error,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
          // Username field
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            validator: _validateUsername,
            decoration: InputDecoration(
              labelText: 'Username / Email',
              hintText: 'Enter your username',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'person_outline',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'lock_outline',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName:
                      _isPasswordVisible ? 'visibility_off' : 'visibility',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 1.h),
          // Remember username and forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberUsername,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberUsername = value ?? false;
                              });
                            },
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Remember me',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ],
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Login button
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Login',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build network status indicator
  Widget _buildNetworkStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            'Connected to Factory Systems',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
