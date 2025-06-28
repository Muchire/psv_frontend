import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '/services/api_service.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? token;
  final String? uid;
  
  const ResetPasswordPage({super.key, this.token, this.uid});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _uidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isValidatingToken = false;
  bool _tokenValid = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _tokenError;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
    if (widget.uid != null) {
      _uidController.text = widget.uid!;
    }
    // Auto-validate if both token and uid are provided
    if (widget.token != null && widget.uid != null) {
      _validateToken();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _uidController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    if (_tokenController.text.trim().isEmpty || _uidController.text.trim().isEmpty) return;
    
    setState(() {
      _isValidatingToken = true;
      _tokenError = null;
    });

    try {
      await ApiService.validateResetToken(
        token: _tokenController.text.trim(),
        uid: _uidController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _tokenValid = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tokenValid = false;
          _tokenError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingToken = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_tokenValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid reset token and UID'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.confirmPasswordReset(
        token: _tokenController.text.trim(),
        uid: _uidController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.carafe,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sandDollar,
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.carafe.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: AppColors.carafe,
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  // Title
                  Text(
                    'Reset Your Password',
                    style: AppTextStyles.heading1,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  // Description
                  Text(
                    'Enter the reset token and UID from your email to create a new password.',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.brown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge * 2),
                  
                  // Form Container
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // UID field
                          TextFormField(
                            controller: _uidController,
                            decoration: InputDecoration(
                              labelText: 'User ID (UID)',
                              prefixIcon: const Icon(Icons.person, color: AppColors.brown),
                              border: const OutlineInputBorder(),
                              helperText: 'Found in your reset email',
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && _tokenController.text.length >= 6) {
                                _validateToken();
                              } else {
                                setState(() {
                                  _tokenValid = false;
                                  _tokenError = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the UID';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.paddingMedium),
                          
                          // Token field
                          TextFormField(
                            controller: _tokenController,
                            decoration: InputDecoration(
                              labelText: 'Reset Token',
                              prefixIcon: const Icon(Icons.vpn_key, color: AppColors.brown),
                              suffixIcon: _isValidatingToken
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(
                                          color: AppColors.brown,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _tokenValid
                                      ? const Icon(Icons.check_circle, color: AppColors.success)
                                      : _tokenError != null
                                          ? const Icon(Icons.error, color: AppColors.error)
                                          : null,
                              border: const OutlineInputBorder(),
                              errorText: _tokenError,
                              helperText: 'Found in your reset email',
                            ),
                            onChanged: (value) {
                              if (value.length >= 6 && _uidController.text.isNotEmpty) {
                                _validateToken();
                              } else {
                                setState(() {
                                  _tokenValid = false;
                                  _tokenError = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the reset token';
                              }
                              if (value.trim().length < 6) {
                                return 'Token must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.paddingMedium),
                          
                          // New Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.lock, color: AppColors.brown),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.brown,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.paddingMedium),
                          
                          // Confirm Password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon: const Icon(Icons.lock, color: AppColors.brown),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.brown,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.paddingLarge),
                          
                          // Reset Password button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_tokenValid) ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.carafe,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Reset Password', style: AppTextStyles.button),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  // Help text
                  Text(
                    'Check your email for both the reset token and UID. Both are required to reset your password.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  // Back to login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.brown,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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