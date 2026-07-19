import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/register_screen.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';
import 'package:dramus/screens/agence/main_app_screen.dart';
import 'package:dramus/screens/admin_screen.dart';
import 'package:dramus/screens/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifierCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final identifier = _identifierCtl.text.trim();
      final password = _passwordCtl.text;
      final user = await AuthService.instance.login(identifier, password);

      if (user != null) {
        if (!mounted) return;

        // Update AuthController with the authenticated user
        final authController =
            Provider.of<AuthController>(context, listen: false);
        authController.setUser(user);

        // Update UserService with the authenticated user
        final userService = Provider.of<UserService>(context, listen: false);
        userService.updateCurrentUser(user);

        // Recharger les annonces pour l'utilisateur connecté
        final listingService =
            Provider.of<ListingService>(context, listen: false);
        try {
          await listingService.refreshListings(user: user);
        } catch (e) {
          debugPrint('LoginScreen: Erreur rechargement annonces: $e');
        }

        // Navigate based on role
        final role = user.role.toLowerCase();
        final messageService =
            Provider.of<MessageService>(context, listen: false);
        final pending = messageService.pendingConversationId;

        if (role == 'client') {
          // Clients utilisent l'interface client
          if (pending != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainAppScreen(
                  initialTabIndex: 3,
                  selectedConversationId: pending,
                  propertyId: messageService.pendingPropertyId,
                  ownerName: messageService.pendingOwnerName,
                  prefilledMessage: messageService.pendingPrefilledMessage,
                ),
              ),
            );
            messageService.clearPendingConversation();
          } else {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainAppScreen()));
          }
        } else if (role == 'admin') {
          // Administrateurs
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          // Particuliers, agents et agences utilisent l'interface agence
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainAppScreenAgence()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la connexion')));
      }
    } catch (e) {
      String errorMessage = 'Une erreur est survenue lors de la connexion';

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage =
                'Le délai d\'attente est dépassé. Vérifiez votre connexion internet.';
            break;
          case DioExceptionType.badResponse:
            final statusCode = e.response?.statusCode;
            if (statusCode == 401) {
              errorMessage = 'Téléphone ou mot de passe incorrect';
            } else if (statusCode == 400) {
              errorMessage =
                  'Les informations saisies sont invalides. Veuillez vérifier vos données.';
            } else if (statusCode == 403) {
              errorMessage = 'Accès refusé. Votre compte est peut-être bloqué.';
            } else if (statusCode == 500) {
              errorMessage = 'Erreur interne du serveur. Réessayez plus tard.';
            } else {
              errorMessage = 'Erreur serveur ($statusCode). Réessayez.';
            }
            break;
          case DioExceptionType.connectionError:
            errorMessage =
                'Impossible de contacter le serveur. Vérifiez que vous avez accès à internet.';
            break;
          case DioExceptionType.cancel:
            errorMessage = 'La requête a été annulée.';
            break;
          default:
            errorMessage = 'Problème de réseau détecté. Veuillez réessayer.';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    errorMessage,
                    softWrap: true,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: DramusColors.notificationRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond clair de l'application
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
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
                color: Theme.of(context).cardColor,
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
                            // Email ou Téléphone
                            TextFormField(
                              controller: _identifierCtl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: 'Email ou Téléphone',
                                hintText: 'ex: dupont@mail.com ou 612345678',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Email ou téléphone requis';
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
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                          value: true, onChanged: (_) {}),
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    Text('Se souvenir de moi  ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text('Mot de passe oublié ?',
                                      style: TextStyle(
                                          color: DramusColors.primaryTeal,
                                          fontSize: 12)),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary)),
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
                            SizedBox(height: AppSpacing.md),
                            // Continuer en tant qu'invité
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const MainAppScreen()),
                                );
                              },
                              child: Text(
                                'Continuer en tant qu\'invité',
                                style: TextStyle(
                                  color: DramusColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
