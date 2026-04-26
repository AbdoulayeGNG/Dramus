import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/auth_service.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/screens/auth/login_screen.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';
import 'package:dramus/screens/agence/main_app_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  // Agence fields
  final _agencyNameCtl = TextEditingController();
  final _agencyEmailCtl = TextEditingController();
  final _agencyPhoneCtl = TextEditingController();
  final _agencyAddressCtl = TextEditingController();
  final _adminFirstNameCtl = TextEditingController();
  final _adminLastNameCtl = TextEditingController();
  final _adminEmailCtl = TextEditingController();
  final _adminPasswordCtl = TextEditingController();
  final _adminPhoneCtl = TextEditingController();

  String _selectedRoleId = 'client';
  File? _avatarFile;
  bool _loading = false;
  bool _obscurePassword = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _phoneCtl.dispose();
    _agencyNameCtl.dispose();
    _agencyEmailCtl.dispose();
    _agencyPhoneCtl.dispose();
    _agencyAddressCtl.dispose();
    _adminFirstNameCtl.dispose();
    _adminLastNameCtl.dispose();
    _adminEmailCtl.dispose();
    _adminPasswordCtl.dispose();
    _adminPhoneCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final isAgency = _selectedRoleId == 'agence';
      Map<String, dynamic> data;

      if (isAgency) {
        data = {
          'name': _agencyNameCtl.text.trim(),
          'email': _agencyEmailCtl.text.trim(),
          'phone': _agencyPhoneCtl.text.trim(),
          'address': _agencyAddressCtl.text.trim(),
          'adminFirstName': _adminFirstNameCtl.text.trim(),
          'adminLastName': _adminLastNameCtl.text.trim(),
          'adminEmail': _adminEmailCtl.text.trim(),
          'adminPassword': _adminPasswordCtl.text.trim(),
          'adminPhone': _adminPhoneCtl.text.trim(),
        };
      } else {
        data = {
          'firstName': _firstNameCtl.text.trim(),
          'lastName': _lastNameCtl.text.trim(),
          'email': _emailCtl.text.trim(),
          'password': _passwordCtl.text.trim(),
          'phone':
              _phoneCtl.text.trim().isNotEmpty ? _phoneCtl.text.trim() : null,
          'roleName': _selectedRoleId,
        };
      }

      debugPrint('Données d\'inscription: $data');
      debugPrint('Avatar présent: ${_avatarFile != null}');

      final resp = await AuthService.instance.register(
        data: data,
        avatar: _avatarFile,
        isAgency: isAgency,
      );

      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        if (!mounted) return;

        // Pour une agence, les tokens sont gérés différemment — rediriger vers login
        if (isAgency) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Compte agence créé, connectez-vous')));
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()));
          return;
        }

        // Parser le user depuis la réponse pour mettre à jour le state global
        User? registeredUser;
        try {
          final body = resp.data as Map<String, dynamic>?;
          final dataMap = body != null && body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : null;
          final userJson =
              dataMap != null && dataMap['user'] is Map<String, dynamic>
                  ? dataMap['user'] as Map<String, dynamic>
                  : null;
          if (userJson != null) {
            registeredUser = User.fromJson(userJson);
          }
        } catch (e) {
          debugPrint('RegisterScreen: Erreur parsing user: $e');
        }

        if (registeredUser != null) {
          // Mettre à jour AuthController et UserService comme à la connexion
          final authController =
              Provider.of<AuthController>(context, listen: false);
          authController.setUser(registeredUser);

          final userService = Provider.of<UserService>(context, listen: false);
          userService.updateCurrentUser(registeredUser);

          // Naviguer selon le rôle
          final role = registeredUser.role.toLowerCase();
          if (role == 'client') {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainAppScreen()));
          } else {
            // particulier, agent
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainAppScreenAgence()));
          }
        } else {
          // Fallback : pas de user parsé, rediriger vers login
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Inscription réussie, connectez-vous')));
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        final message = resp.data != null && resp.data['message'] != null
            ? resp.data['message']
            : 'Erreur serveur';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Créer un compte'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: DramusColors.primaryTeal,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : null,
                            child: _avatarFile == null
                                ? Icon(Icons.camera_alt_outlined,
                                    color: Colors.white, size: 28)
                                : null,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Role selection dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedRoleId,
                          items: const [
                            DropdownMenuItem(
                                value: 'client', child: Text('Client')),
                            DropdownMenuItem(
                                value: 'particulier',
                                child: Text('Particulier')),
                            DropdownMenuItem(
                                value: 'agence', child: Text('Agence')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedRoleId = v);
                          },
                          decoration: const InputDecoration(
                              labelText: 'Type de compte'),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        if (_selectedRoleId != 'agence') ...[
                          // Client / Particulier fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtl,
                                  decoration: InputDecoration(
                                    labelText: 'Prénom',
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Prénom requis'
                                          : null,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtl,
                                  decoration: InputDecoration(
                                      labelText: 'Nom',
                                      prefixIcon: const Icon(Icons.person)),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nom requis'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'L\'adresse email est requise';
                              final re = RegExp(
                                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                              if (!re.hasMatch(v.trim()))
                                return 'Veuillez entrer une adresse email valide (ex: nom@domaine.com)';
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordCtl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                )),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Le mot de passe est requis';
                              if (v.length < 8)
                                return 'Le mot de passe doit contenir au moins 8 caractères';
                              if (!RegExp(r'[a-zA-Z]').hasMatch(v))
                                return 'Le mot de passe doit contenir au moins une lettre';
                              if (!RegExp(r'[0-9]').hasMatch(v))
                                return 'Le mot de passe doit contenir au moins un chiffre';
                              if (!RegExp(
                                      r'[!@#\$%^&*(),.?":{}|<>\-_=+\[\]\/\\;\x27`~]')
                                  .hasMatch(v))
                                return 'Le mot de passe doit contenir au moins un caractère spécial (!@#\$%^&*...)';
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: const Icon(Icons.phone)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Le numéro de téléphone est requis';
                              final digits = v
                                  .trim()
                                  .replaceAll(RegExp(r'[\s\-().+]'), '');
                              if (!digits.startsWith('6'))
                                return 'Le numéro doit commencer par 6 (ex: 620 123 456)';
                              if (digits.length < 9)
                                return 'Le numéro doit contenir au moins 9 chiffres';
                              if (!RegExp(r'^[0-9]+$').hasMatch(digits))
                                return 'Le numéro ne doit contenir que des chiffres';
                              return null;
                            },
                          ),
                        ] else ...[
                          // Agence fields
                          TextFormField(
                            controller: _agencyNameCtl,
                            decoration: const InputDecoration(
                              labelText: "Nom de l'agence",
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nom requis'
                                : null,
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _agencyEmailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email de l'agence",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Email requis'
                                : null,
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _agencyPhoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Téléphone de l'agence",
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Téléphone requis'
                                : null,
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _agencyAddressCtl,
                            decoration: const InputDecoration(
                              labelText: "Adresse",
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Adresse requise'
                                : null,
                          ),
                          const Divider(height: 32),
                          const Text('Informations Administrateur',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _adminFirstNameCtl,
                                  decoration: const InputDecoration(
                                      labelText: 'Prénom Admin'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requis'
                                          : null,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _adminLastNameCtl,
                                  decoration: const InputDecoration(
                                      labelText: 'Nom Admin'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requis'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _adminEmailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Admin',
                              prefixIcon: Icon(Icons.person_pin_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Email requis'
                                : null,
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _adminPasswordCtl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                                labelText: 'Mot de passe Admin',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                )),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Requis' : null,
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _adminPhoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone Admin',
                              prefixIcon: Icon(Icons.phone_android),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requis'
                                : null,
                          ),
                        ],

                        SizedBox(height: AppSpacing.lg),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DramusColors.primaryTeal,
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text('S\'inscrire',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ?'),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
