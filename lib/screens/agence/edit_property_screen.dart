import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/widgets/custom_button.dart';
import 'package:dramus/models/property.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  String _propertyType = 'Maison';
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _isLocating = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _imagesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final property = widget.property;

    _propertyType = property.type;
    _titleController.text = property.title;
    _descriptionController.text = property.description;
    _cityController.text = property.location.city;
    _districtController.text = property.location.district;
    _latitudeController.text = property.location.latitude?.toString() ?? '';
    _longitudeController.text = property.location.longitude?.toString() ?? '';
    _priceController.text = property.price.toString();
    _areaController.text = property.surface.toString();
    _imagesController.text = property.images.join(', ');

    _validateForm();
  }

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
          _priceController.text.isNotEmpty &&
          _areaController.text.isNotEmpty;
    });
  }

  Future<void> _updateProperty() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('EditPropertyScreen._updateProperty: Starting update process');
      debugPrint(
          'EditPropertyScreen._updateProperty: Original property ID: ${widget.property.id}');
      debugPrint(
          'EditPropertyScreen._updateProperty: Original property: ${widget.property.toJson()}');

      final listingService = context.read<ListingService>();

      // Créer une nouvelle propriété avec les données mises à jour
      final updatedProperty = Property(
        id: widget.property.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        surface: double.parse(_areaController.text),
        type: _propertyType,
        images: _imagesController.text
            .split(',')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(),
        location: PropertyLocation(
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitudeController.text.isNotEmpty
              ? double.parse(_latitudeController.text)
              : 0.0,
          longitude: _longitudeController.text.isNotEmpty
              ? double.parse(_longitudeController.text)
              : 0.0,
        ),
        owner: widget.property.owner, // Garder le même propriétaire
        status: widget.property.status,
        views: widget.property.views,
      );

      debugPrint(
          'EditPropertyScreen._updateProperty: Updated property ID: ${updatedProperty.id}');
      debugPrint(
          'EditPropertyScreen._updateProperty: Updated property: ${updatedProperty.toJson()}');

      final success = await listingService.updateListing(
          widget.property.id, updatedProperty);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à jour avec succès')),
        );
        Navigator.of(context).pop(); // Retour à l'écran précédent
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DramusColors.darkPetroleum,
        title: const Text('Modifier l\'annonce'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type de propriété
            _buildPropertyTypeSelector(),

            SizedBox(height: AppSpacing.lg),

            // Informations générales
            _buildGeneralInfoSection(),

            SizedBox(height: AppSpacing.lg),

            // Localisation
            _buildLocationSection(),

            SizedBox(height: AppSpacing.lg),

            // Prix et surface
            _buildPriceAreaSection(),

            SizedBox(height: AppSpacing.lg),

            // Images
            _buildImagesSection(),

            SizedBox(height: AppSpacing.xl),

            // Bouton de mise à jour
            CustomButton(
              label: _isLoading ? 'Mise à jour...' : 'Mettre à jour',
              onPressed:
                  _isFormValid && !_isLoading ? () => _updateProperty() : () {},
              variant: _isFormValid && !_isLoading
                  ? ButtonVariant.primary
                  : ButtonVariant.secondary,
            ),

            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de propriété',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            border: Border.all(color: DramusColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButton<String>(
            value: _propertyType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'Maison', child: Text('Maison')),
              DropdownMenuItem(
                  value: 'Appartement', child: Text('Appartement')),
              DropdownMenuItem(value: 'Terrain', child: Text('Terrain')),
              DropdownMenuItem(value: 'Bureau', child: Text('Bureau')),
              DropdownMenuItem(value: 'Commerce', child: Text('Commerce')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _propertyType = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations générales',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre de l\'annonce',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _validateForm(),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _validateForm(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quartier',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
      ],
    );
  }

  Widget _buildPriceAreaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix et surface',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix (GNF)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _validateForm(),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Surface (m²)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _validateForm(),
              ),
            ),
          ],
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _imagesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'URLs des images (séparées par des virgules)',
            border: OutlineInputBorder(),
            hintText:
                'https://example.com/image1.jpg, https://example.com/image2.jpg',
          ),
        ),
      ],
    );
  }
}
