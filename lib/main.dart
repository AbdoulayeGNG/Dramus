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
import 'package:dramus/services/socket_service.dart';
import 'package:dramus/services/admin_service.dart';
import 'package:dramus/core/app_navigator_key.dart';
import 'package:dramus/screens/auth/splash_screen.dart';
import 'package:dramus/core/services/onboarding_service.dart';
import 'package:dramus/core/state/theme_controller.dart';
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

/// Registers every service cache reset callback with [AuthController] so that
/// all in-memory data is cleared whenever a user signs out.
class _SignOutRegistry extends StatefulWidget {
  final Widget child;

  const _SignOutRegistry({required this.child});

  @override
  State<_SignOutRegistry> createState() => _SignOutRegistryState();
}

class _SignOutRegistryState extends State<_SignOutRegistry> {
  late final VoidCallback _listingReset;
  late final VoidCallback _favoritesClear;
  late final VoidCallback _messagesClear;
  late final VoidCallback _agentClear;
  late final VoidCallback _notificationsReset;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final listing = context.read<ListingService>();
    final favorites = context.read<FavoritesService>();
    final messages = context.read<MessageService>();
    final agent = context.read<AgentService>();
    final notifications = context.read<NotificationService>();

    _listingReset = listing.reset;
    _favoritesClear = favorites.clearFavorites;
    _messagesClear = messages.clear;
    _agentClear = agent.clear;
    _notificationsReset = notifications.reset;
    final socketReset = context.read<SocketService>().reset;

    auth.addSignOutListener(_listingReset);
    auth.addSignOutListener(_favoritesClear);
    auth.addSignOutListener(_messagesClear);
    auth.addSignOutListener(_agentClear);
    auth.addSignOutListener(_notificationsReset);
    auth.addSignOutListener(socketReset);
  }

  @override
  void dispose() {
    final auth = context.read<AuthController>();
    final socketReset = context.read<SocketService>().reset;
    auth.removeSignOutListener(_listingReset);
    auth.removeSignOutListener(_favoritesClear);
    auth.removeSignOutListener(_messagesClear);
    auth.removeSignOutListener(_agentClear);
    auth.removeSignOutListener(_notificationsReset);
    auth.removeSignOutListener(socketReset);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class DramusApp extends StatelessWidget {
  const DramusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(
            create: (_) => NotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ListingService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProxyProvider<SocketService, MessageService>(
          create: (_) => MessageService(),
          update: (_, socketService, messageService) => messageService!
            ..setSocketService(socketService)
            ..setupSocketListeners(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AgentService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        // MessageService disponible globalement pour toutes les routes
      ],
      child: _SignOutRegistry(
        child: Consumer<ThemeController>(
          builder: (context, themeController, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'DRAMUS - Immobilier Premium',
              navigatorKey: appNavigatorKey,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeController.themeMode,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
