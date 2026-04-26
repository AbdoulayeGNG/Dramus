import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user!;
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simuler un appel réseau
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authController = context.read<AuthController>();
    final currentUser = authController.user!;

    // Créer un nouvel objet User avec les modifications
    // Note: User.copyWith doit être utilisé
    final updatedUser = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // Sauvegarder dans le state local
    // Idéalement, on appellerait un service API ici (UserService.updateProfile)
    // Mais pour l'instant, on met juste à jour le state local
    authController.setUser(updatedUser);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: DramusColors.primaryTeal,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatarSection(context),
              SizedBox(height: AppSpacing.xxl),
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: AppSpacing.xxl),
              CustomButton(
                label: 'Enregistrer les modifications',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: DramusColors.primaryTeal,
            backgroundImage:
                user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar.isEmpty
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: DramusColors.white,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changement de photo à venir')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: DramusColors.primaryTeal,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: DramusColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
