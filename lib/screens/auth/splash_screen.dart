import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/core/api/api_client.dart';
import 'package:dramus/core/app_navigator_key.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/core/services/onboarding_service.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';
import 'package:dramus/screens/agence/main_app_screen.dart';
import 'package:dramus/screens/admin_screen.dart';
import 'package:dramus/features/onboarding/onboarding_screen.dart';
import 'package:dramus/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final authController = context.read<AuthController>();
    final userService = context.read<UserService>();

    await authController.initialize();

    _setupAuthFailureHandler();

    if (!mounted) return;

    final hasSeenOnboarding = OnboardingService().hasSeenOnboarding();

    if (!hasSeenOnboarding) {
      _replace(const OnboardingScreen());
      return;
    }

    final user = authController.user;
    if (user != null) {
      userService.updateCurrentUser(user);
      final role = user.role.toLowerCase();
      if (role == 'client') {
        _replace(const MainAppScreen());
      } else if (role == 'admin') {
        _replace(const AdminScreen());
      } else {
        _replace(const MainAppScreenAgence());
      }
    } else {
      _replace(const LoginScreen());
    }
  }

  void _setupAuthFailureHandler() {
    ApiClient.I.onAuthFailed = () {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;

      final ctx = appNavigatorKey.currentContext;
      if (ctx != null) {
        try {
          ctx.read<AuthController>().clearUser();
        } catch (e) {
          debugPrint('SplashScreen: failed to clear auth state: $e');
        }
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };
  }

  void _replace(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/dramus_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
