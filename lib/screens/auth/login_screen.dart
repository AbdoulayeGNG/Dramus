import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/register_screen.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';
import 'package:dramus/screens/agence/main_app_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final phone = _phoneCtl.text.trim();
      final password = _passwordCtl.text;
      final user = await AuthService.instance.login(phone, password);

      if (user != null) {
        if (!mounted) return;

        // Update AuthController with the authenticated user
        final authController =
            Provider.of<AuthController>(context, listen: false);
        authController.setUser(user);

        // Update UserService with the authenticated user
        final userService = Provider.of<UserService>(context, listen: false);
        userService.updateCurrentUser(user);

        // Navigate based on role: agence -> agence main, otherwise client main
        if (user.role == 'client') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainAppScreen()));
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainAppScreenAgence()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la connexion')));
      }
    } catch (e) {
      String errorMessage = 'Erreur de connexion';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Téléphone ou mot de passe incorrect';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Données invalides';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Erreur serveur, réessayez plus tard';
        } else {
          errorMessage = 'Erreur réseau: ${e.message}';
        }
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond clair de l'application
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header / Brand
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E2330), // bleu pétrole sombre
                      Color(0xFF0D4C60), // teal profond
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C2A8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'D',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRAMUS',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Trouvez votre bien idéal',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DramusColors.lightGray,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Card contenant le formulaire
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connexion',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DramusColors.primaryTeal,
                                ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Connectez-vous pour accéder à vos annonces, messages et plus.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DramusColors.secondaryText,
                            ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Phone
                            TextFormField(
                              controller: _phoneCtl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_outlined),
                                labelText: 'Téléphone',
                                hintText: 'ex: +221 77 123 45 67',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Téléphone requis';
                                if (v.trim().length < 9)
                                  return 'Numéro invalide';
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.md),

                            // Password
                            TextFormField(
                              controller: _passwordCtl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                labelText: 'Mot de passe',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Mot de passe requis';
                                if (v.length < 6)
                                  return 'Au moins 6 caractères';
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.sm),

                            // Actions row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(value: true, onChanged: (_) {}),
                                    Text('Se souvenir',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Forgot password
                                  },
                                  child: Text('Mot de passe oublié ?',
                                      style: TextStyle(
                                          color: DramusColors.primaryTeal)),
                                ),
                              ],
                            ),

                            SizedBox(height: AppSpacing.md),

                            // Bouton connexion
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.login),
                                    label: Text(
                                        _loading
                                            ? 'Connexion...'
                                            : 'Se connecter',
                                        style: TextStyle(
                                            color: DramusColors.lightGray)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DramusColors.primaryTeal,
                                      padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.md),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md)),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _submit)),

                            SizedBox(height: AppSpacing.md),

                            // Inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Pas encore de compte ?',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    );
                                  },
                                  child: Text('S\'inscrire',
                                      style: TextStyle(
                                          color: DramusColors.deepTeal)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Footer / alternative info
              Center(
                child: Text(
                  'DRAMUS — Immobilier premium en Guinée',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: DramusColors.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
