import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/models/agent_model.dart';

class AddEditAgentScreen extends StatefulWidget {
  final AgentModel? agent;
  const AddEditAgentScreen({super.key, this.agent});

  @override
  State<AddEditAgentScreen> createState() => _AddEditAgentScreenState();
}

class _AddEditAgentScreenState extends State<AddEditAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  final List<String> _permissions = [];

  final Map<String, String> _availablePermissions = {
    'create_property': 'Créer des annonces',
    'edit_property': 'Modifier des annonces',
    'view_clients': 'Voir les clients',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.agent?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.agent?.lastName ?? '');
    _emailController = TextEditingController(text: widget.agent?.email ?? '');
    _phoneController = TextEditingController(text: widget.agent?.phone ?? '');
    _passwordController = TextEditingController();

    if (widget.agent != null) {
      _permissions.addAll(widget.agent!.permissions);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final agentData = AgentModel(
      id: widget.agent?.id ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password:
          _passwordController.text.isNotEmpty ? _passwordController.text : null,
      phone: _phoneController.text.trim(),
      permissions: _permissions,
    );

    final agentService = Provider.of<AgentService>(context, listen: false);
    bool success;

    if (widget.agent == null) {
      success = await agentService.createAgent(agentData);
    } else {
      success = await agentService.updateAgent(widget.agent!.id, agentData);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.agent == null
              ? 'Agent créé avec succès'
              : 'Agent mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue'),
          backgroundColor: DramusColors.notificationRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.agent != null;

    return Scaffold(
      backgroundColor: DramusColors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'agent' : 'Ajouter un agent'),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations d\'identité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DramusColors.darkPetroleum,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'Prénom',
                            hint: 'Prénom de l\'agent',
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Nom',
                            hint: 'Nom de l\'agent',
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email professionnel',
                      hint: 'email@agence.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: '+221...',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: isEditing
                          ? 'Nouveau mot de passe (optionnel)'
                          : 'Mot de passe',
                      hint: 'Au moins 6 caractères',
                      obscureText: true,
                      validator: (v) {
                        if (!isEditing && v!.isEmpty) return 'Requis';
                        if (v!.isNotEmpty && v.length < 6) return 'Trop court';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DramusColors.darkPetroleum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._availablePermissions.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value),
                        value: _permissions.contains(entry.key),
                        activeColor: DramusColors.primaryTeal,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _permissions.add(entry.key);
                            } else {
                              _permissions.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveAgent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DramusColors.primaryTeal,
                          foregroundColor: DramusColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing
                              ? 'Enregistrer les modifications'
                              : 'Créer l\'agent',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DramusColors.lightGray),
            filled: true,
            fillColor: DramusColors.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DramusColors.primaryTeal),
            ),
          ),
        ),
      ],
    );
  }
}
