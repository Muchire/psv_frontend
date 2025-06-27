import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sandDollar,
              AppColors.tan,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo/Icon
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.carafe.withAlpha(76),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      size: 50,
                      color: AppColors.brown,
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge * 1.5),
                  
                  // App Title
                  Text(
                    'PSV Finder',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  // Subtitle
                  Text(
                    'Find the best SACCO services\nfor your journey',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.brown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Buttons Container - Constrained width
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(
                      children: [
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.carafe,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Log In',
                              style: AppTextStyles.button,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppDimensions.paddingMedium),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.carafe, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Create Account',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.carafe,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  // Guest Mode
                  TextButton(
                    onPressed: () {
                      // Navigate to home as guest
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text(
                      'Continue as Guest',
                      style: AppTextStyles.body2.copyWith(
                        decoration: TextDecoration.underline,
                        color: AppColors.brown,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}