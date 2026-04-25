import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/notification_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/features/onboarding/onboarding_screen.dart';
import 'package:dramus/core/services/onboarding_service.dart';
import 'package:dramus/theme.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Initialiser les services essentiels
  await OnboardingService().init();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const DramusApp());
}

class DramusApp extends StatelessWidget {
  const DramusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ListingService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
        ChangeNotifierProvider(create: (_) => MessageService()),
        ChangeNotifierProvider(
            create: (_) => NotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => AgentService()),
        // MessageService disponible globalement pour toutes les routes
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DRAMUS - Immobilier Premium',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: OnboardingService().hasSeenOnboarding()
            ? const LoginScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
