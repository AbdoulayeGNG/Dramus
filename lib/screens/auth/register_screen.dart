import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/auth_service.dart';
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
  final _agencyIdCtl = TextEditingController();

  String? _selectedRoleId; // stocke id de rôle (string)
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
    _agencyIdCtl.dispose();
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
      // 1. Préparer les données AVANT de les envoyer
      final data = <String, dynamic>{
        'firstName': _firstNameCtl.text.trim(),
        'lastName': _lastNameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'password': _passwordCtl.text.trim(), // AJOUTER .trim() ici
        'phone': _phoneCtl.text.trim().isNotEmpty
            ? _phoneCtl.text.trim()
            : null, // Envoyer null si vide
      };

      // 2. Gérer le rôle - vérifier la clé attendue par le backend
      if (_selectedRoleId != null) {
        // Essayer d'abord 'roleName', sinon 'role'
        data['roleName'] = _selectedRoleId!;
        // Si ça ne marche pas, essayez aussi avec 'role'
        // data['role'] = _selectedRoleId!;
      }

      // 3. Gérer agencyId - seulement si présent et non vide
      final agencyId = _agencyIdCtl.text.trim();
      if (_selectedRoleId == 'agent' && agencyId.isNotEmpty) {
        data['agencyId'] = agencyId;
      }

      // DEBUG: Afficher les données avant envoi
      debugPrint('Données d\'inscription: $data');
      debugPrint('Avatar présent: ${_avatarFile != null}');

      // 4. Appeler le service
      final resp = await AuthService.instance.register(
        data: data,
        avatar: _avatarFile,
      );

      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inscription réussie')));
          // Si client -> page d'accueil, sinon -> page de connexion
          if (_selectedRoleId == 'client') {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainAppScreen()));
          } else {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainAppScreenAgence()));
          }
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: DramusColors.darkPetroleum,
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

                        // Names row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameCtl,
                                decoration: InputDecoration(
                                  labelText: 'Prénom',
                                  prefixIcon: const Icon(Icons.person_outline),
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

                        // Email
                        TextFormField(
                          controller: _emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined)),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email requis';
                            final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!re.hasMatch(v.trim())) return 'Email invalide';
                            return null;
                          },
                        ),

                        SizedBox(height: AppSpacing.md),

                        // Password
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
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              )),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Mot de passe requis';
                            if (v.length < 6) return 'Au moins 6 caractères';
                            return null;
                          },
                        ),

                        SizedBox(height: AppSpacing.md),

                        // Phone
                        TextFormField(
                          controller: _phoneCtl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: const Icon(Icons.phone)),
                        ),

                        SizedBox(height: AppSpacing.md),

                        // Role selection (valeurs alignées avec le modèle `User`)
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
                            DropdownMenuItem(
                                value: 'agent', child: Text('Agent')),
                          ],
                          onChanged: (v) => setState(() => _selectedRoleId = v),
                          decoration: const InputDecoration(labelText: 'Rôle'),
                          validator: (v) =>
                              v == null ? 'Sélectionner un rôle' : null,
                        ),

                        SizedBox(height: AppSpacing.md),

                        // AgencyId (visible et requis si rôle = agent)
                        if (_selectedRoleId == 'agent')
                          TextFormField(
                            controller: _agencyIdCtl,
                            decoration: const InputDecoration(
                              labelText: "ID de l'agence",
                              hintText: 'ID de l’agence',
                            ),
                            validator: (v) {
                              if (_selectedRoleId == 'agent' &&
                                  (v == null || v.trim().isEmpty))
                                return 'ID agence requis pour les agents';
                              return null;
                            },
                          ),

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
                                  : const Text('S\'inscrire',
                                      style: TextStyle(
                                          color: DramusColors.lightGray))),
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
