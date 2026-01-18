import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:provider/provider.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  String _propertyType = 'Maison';
  bool _isFormValid = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _imagesController =
      TextEditingController(); // For now, comma-separated URLs

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _titleController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _districtController.text.isNotEmpty &&
          _latitudeController.text.isNotEmpty &&
          _longitudeController.text.isNotEmpty &&
          _priceController.text.isNotEmpty &&
          _areaController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DramusColors.darkPetroleum,
        title: const Text('Publier une annonce'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            HeaderSection(
              title: 'Publier une annonce',
              subtitle: 'Remplissez les informations de votre bien',
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyTypeSection(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildPropertyDetailsSection(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildDescriptionSection(),
                  SizedBox(height: AppSpacing.xxl),
                  _buildImagesSection(),
                  SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Annuler',
                          onPressed: () => Navigator.pop(context),
                          variant: ButtonVariant.outline,
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: CustomButton(
                          label: 'Publier',
                          onPressed: () async {
                            if (_isFormValid) {
                              final authController =
                                  context.read<AuthController>();
                              final user = authController.user;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Utilisateur non connecté'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final property = Property(
                                id: '', // Will be set by server
                                ownerId: user.id,
                                title: _titleController.text,
                                type: _propertyType,
                                price: num.tryParse(_priceController.text) ?? 0,
                                location: PropertyLocation(
                                  city: _cityController.text,
                                  district: _districtController.text,
                                  latitude: double.tryParse(
                                          _latitudeController.text) ??
                                      0.0,
                                  longitude: double.tryParse(
                                          _longitudeController.text) ??
                                      0.0,
                                ),
                                surface:
                                    num.tryParse(_areaController.text) ?? 0,
                                description: _descriptionController.text,
                                images: _imagesController.text.isEmpty
                                    ? []
                                    : _imagesController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .toList(),
                                status: 'published',
                                views: 0,
                              );

                              final listingService =
                                  context.read<ListingService>();

                              // Debug: Check if user is authenticated
                              debugPrint(
                                  'PublishScreen: AuthController user: ${authController.user}');
                              debugPrint(
                                  'PublishScreen: Is authenticated: ${authController.user != null}');

                              final success =
                                  await listingService.createListing(property);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Annonce publiée avec succès!'),
                                    backgroundColor: DramusColors.saleGreen,
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Erreur lors de la publication'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de propriété',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildPropertyTypeCard('Maison', 'Maison'),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildPropertyTypeCard('Appartement', 'Appartement'),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildPropertyTypeCard('Terrain', 'Terrain'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeCard(String label, String value) {
    final isSelected = _propertyType == value;
    return GestureDetector(
      onTap: () => setState(() => _propertyType = value),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isSelected
              ? DramusColors.primaryTeal
              : DramusColors.lightBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? Colors.transparent : DramusColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color:
                      isSelected ? DramusColors.white : DramusColors.darkText,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du bien',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildTextField(
          'Titre de l\'annonce',
          _titleController,
          'Ex: Appartement moderne au Plateau',
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Ville',
                _cityController,
                'Ex: Conakry',
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildTextField(
                'Quartier',
                _districtController,
                'Ex: Plateau',
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Latitude',
                _latitudeController,
                'Ex: 9.5092',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildTextField(
                'Longitude',
                _longitudeController,
                'Ex: -13.7122',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _buildTextField(
          'Prix (GNF)',
          _priceController,
          'Ex: 850000',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: AppSpacing.lg),
        _buildTextField(
          'Surface (m²)',
          _areaController,
          'Ex: 180',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _descriptionController,
          onChanged: (_) => _validateForm(),
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Décrivez votre propriété en détail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.lg),
        _buildTextField(
          'URLs des images (séparées par des virgules)',
          _imagesController,
          'Ex: https://example.com/image1.jpg, https://example.com/image2.jpg',
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          onChanged: (_) => _validateForm(),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
