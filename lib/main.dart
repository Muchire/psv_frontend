import 'package:flutter/material.dart';
import 'user_app/pages/welcome_page.dart';
import 'user_app/utils/constants.dart';

void main() {
  runApp(const TransportHubApp());
}

class TransportHubApp extends StatelessWidget {
  const TransportHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.lightGrey,
        primaryColor: AppColors.brown,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brown,
          foregroundColor: AppColors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.brown),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.brown),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.carafe, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.error,
          contentTextStyle: TextStyle(color: AppColors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: AppTextStyles.body1,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}
