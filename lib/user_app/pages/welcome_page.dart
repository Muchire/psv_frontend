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
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Logo/Icon
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.carafe.withAlpha(76),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 60,
                    color: AppColors.brown,
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingLarge * 2),
                
                // App Title
                Text(
                  'PSV Finder',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 32,
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
                
                const Spacer(),
                
                // Login Button
                ElevatedButton(
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
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Login',
                    style: AppTextStyles.button,
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Register Button
                OutlinedButton(
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
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    'Create Account',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.carafe,
                    ),
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
                    ),
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}