import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        // ajoute d'autres providers globaux ici (AuthService, ListingService, ...)
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DRAMUS - Immobilier Premium',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
