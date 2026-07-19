import 'package:flutter/material.dart';

class PropertyCharacteristic {
  final String key;
  final String label;
  final String type; // 'number' | 'boolean'
  final String icon;
  final bool isRequired;

  const PropertyCharacteristic({
    required this.key,
    required this.label,
    required this.type,
    required this.icon,
    required this.isRequired,
  });
}

class PropertyConstants {
  static const Map<String, List<PropertyCharacteristic>> characteristicsByType =
      {
    'Appartement': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'chambres',
          label: 'Chambres',
          type: 'number',
          icon: 'bed',
          isRequired: false),
      PropertyCharacteristic(
          key: 'sallesDeBain',
          label: 'Salles de bain',
          type: 'number',
          icon: 'bath',
          isRequired: false),
      PropertyCharacteristic(
          key: 'etage',
          label: 'Étage',
          type: 'number',
          icon: 'building',
          isRequired: false),
      PropertyCharacteristic(
          key: 'ascenseur',
          label: 'Ascenseur',
          type: 'boolean',
          icon: 'elevator',
          isRequired: false),
      PropertyCharacteristic(
          key: 'balcon',
          label: 'Balcon',
          type: 'boolean',
          icon: 'balcony',
          isRequired: false),
    ],
    'Maison': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'chambres',
          label: 'Chambres',
          type: 'number',
          icon: 'bed',
          isRequired: false),
      PropertyCharacteristic(
          key: 'sallesDeBain',
          label: 'Salles de bain',
          type: 'number',
          icon: 'bath',
          isRequired: false),
      PropertyCharacteristic(
          key: 'garage',
          label: 'Garage',
          type: 'boolean',
          icon: 'car',
          isRequired: false),
      PropertyCharacteristic(
          key: 'jardin',
          label: 'Jardin',
          type: 'boolean',
          icon: 'tree',
          isRequired: false),
      PropertyCharacteristic(
          key: 'piscine',
          label: 'Piscine',
          type: 'boolean',
          icon: 'water',
          isRequired: false),
    ],
    'Terrain': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'viabilise',
          label: 'Viabilisé',
          type: 'boolean',
          icon: 'check',
          isRequired: false),
      PropertyCharacteristic(
          key: 'cloture',
          label: 'Clôturé',
          type: 'boolean',
          icon: 'fence',
          isRequired: false),
    ],
    'Bureau': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'pieces',
          label: 'Pièces',
          type: 'number',
          icon: 'door',
          isRequired: false),
      PropertyCharacteristic(
          key: 'parking',
          label: 'Parking',
          type: 'boolean',
          icon: 'car',
          isRequired: false),
    ],
    'Commerce': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'vitrine',
          label: 'Vitrine',
          type: 'boolean',
          icon: 'store',
          isRequired: false),
      PropertyCharacteristic(
          key: 'reserve',
          label: 'Réserve',
          type: 'boolean',
          icon: 'box',
          isRequired: false),
    ],
    'Entrepot': [
      PropertyCharacteristic(
          key: 'surface',
          label: 'Surface (m²)',
          type: 'number',
          icon: 'ruler',
          isRequired: true),
      PropertyCharacteristic(
          key: 'hauteur',
          label: 'Hauteur',
          type: 'number',
          icon: 'arrows-alt-v',
          isRequired: false),
      PropertyCharacteristic(
          key: 'acces',
          label: 'Accès camion',
          type: 'boolean',
          icon: 'truck',
          isRequired: false),
    ],
  };

  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'ruler':
        return Icons.square_foot_outlined;
      case 'bed':
        return Icons.king_bed_outlined;
      case 'bath':
        return Icons.bathtub_outlined;
      case 'building':
        return Icons.domain;
      case 'elevator':
        return Icons.elevator_outlined;
      case 'balcony':
        return Icons.balcony_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'tree':
        return Icons.park_outlined;
      case 'water':
        return Icons.pool_outlined;
      case 'check':
        return Icons.check_circle_outline;
      case 'fence':
        return Icons.fence_outlined;
      case 'door':
        return Icons.door_front_door_outlined;
      case 'store':
        return Icons.storefront_outlined;
      case 'box':
        return Icons.inventory_2_outlined;
      case 'arrows-alt-v':
        return Icons.height;
      case 'truck':
        return Icons.local_shipping_outlined;
      default:
        return Icons.info_outline;
    }
  }

  static List<String> get availableTypes => characteristicsByType.keys.toList();
}
