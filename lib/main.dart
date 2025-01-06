// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_exchange_app/providers/auth_provider.dart';
import 'package:currency_exchange_app/screens/login_screen.dart';
import 'package:currency_exchange_app/screens/home_screen.dart';
import 'package:currency_exchange_app/theme/app_theme.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadTokenFromPrefs()),
        // Можно добавить DataProvider для валют/операций
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Currency Exchange',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashWrapper(),
      ),
    );
  }
}

/// SplashWrapper проверяет, загрузился ли токен, и решает, куда идти.
class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    if (authProv.isLoadingPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!authProv.isLoggedIn) {
      return const LoginScreen();
    } else {
      return const OperationMainScreen();
    }
  }
}
