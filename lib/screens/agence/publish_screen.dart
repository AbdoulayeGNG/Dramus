import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/widgets/header_section.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  String _propertyType = 'Maison';
  final List<String> _types = [
    'Maison',
    'Appartement',
    'Terrain',
    'Bureau',
    'Chambre',
    'Magasin',
    'Villa',
    'Studio',
  ];
  bool _isFormValid = false;
  bool _isLocating = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  List<XFile> _selectedImageFiles = [];
  final ImagePicker _picker = ImagePicker();

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
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Permission de localisation refusée')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Les permissions de localisation sont définitivement refusées')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
      _validateForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de localisation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Localisation désactivée'),
          content: const Text(
              'La localisation est nécessaire pour récupérer vos coordonnées automatiquement. Souhaitez-vous l\'activer dans les paramètres ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANNULER',
                  style: TextStyle(color: DramusColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DramusColors.primaryTeal,
              ),
              child: const Text('ACTIVER',
                  style: TextStyle(color: DramusColors.white)),
            ),
          ],
        );
      },
    );
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
          _areaController.text.isNotEmpty &&
          _selectedImageFiles.isNotEmpty;
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
                                owner: PropertyOwner(
                                  id: user.id,
                                  firstName: user.firstName,
                                  lastName: user.lastName,
                                  email: user.email,
                                  phone: user.phone,
                                  avatar: user.avatar,
                                ),
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
                                images: [], // Images will be sent as multipart files
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
                                  await listingService.createListing(property,
                                      imageFiles: _selectedImageFiles);

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
        DropdownButtonFormField<String>(
          value: _propertyType,
          items: _types.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _propertyType = value);
              _validateForm();
            }
          },
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: DramusColors.border),
            ),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  // _buildPropertyTypeCard est supprimé car remplacé par un dropdown

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
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _getCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(_isLocating
                ? 'Récupération...'
                : 'Utiliser ma position actuelle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DramusColors.primaryTeal,
              side: const BorderSide(color: DramusColors.primaryTeal),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
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

  Future<void> _pickImages() async {
    if (_selectedImageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de 5 images atteinte')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      List<XFile> validImages = [];
      for (var image in images) {
        final length = await image.length();
        if (length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('L\'image ${image.name} dépasse 5Mo')),
            );
          }
          continue;
        }
        if (_selectedImageFiles.length + validImages.length < 5) {
          validImages.add(image);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Limite de 5 images respectée')),
            );
          }
          break;
        }
      }

      setState(() {
        _selectedImageFiles.addAll(validImages);
      });
      _validateForm();
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de 5 images atteinte')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final length = await image.length();
      if (length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('L\'image dépasse 5Mo')),
          );
        }
        return;
      }

      setState(() {
        _selectedImageFiles.add(image);
      });
      _validateForm();
    }
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images (${_selectedImageFiles.length}/5)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt,
                      color: DramusColors.primaryTeal),
                  tooltip: 'Prendre une photo',
                ),
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library,
                      color: DramusColors.primaryTeal),
                  tooltip: 'Sélectionner depuis la galerie',
                ),
              ],
            ),
          ],
        ),
        const Text(
          'Maximum 5 images, 5Mo chacune.',
          style: TextStyle(fontSize: 12, color: DramusColors.secondaryText),
        ),
        SizedBox(height: AppSpacing.lg),
        if (_selectedImageFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImageFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: AppSpacing.md),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        image: DecorationImage(
                          image:
                              FileImage(File(_selectedImageFiles[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageFiles.removeAt(index);
                          });
                          _validateForm();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: DramusColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: DramusColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: DramusColors.secondaryText),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ajouter des photos',
                    style: TextStyle(color: DramusColors.secondaryText),
                  ),
                ],
              ),
            ),
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
