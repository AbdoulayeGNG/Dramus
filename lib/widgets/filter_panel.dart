import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class FilterPanel extends StatefulWidget {
  final Function(String type, int minPrice, int maxPrice) onFilterChanged;

  const FilterPanel({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _selectedType = 'all';
  int _minPrice = 0;
  int _maxPrice = 10000000000;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              filled: true,
            ),
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les types')),
              DropdownMenuItem(value: 'Maison', child: Text('Maison')),
              DropdownMenuItem(
                  value: 'Appartement', child: Text('Appartement')),
              DropdownMenuItem(value: 'Terrain', child: Text('Terrain')),
              DropdownMenuItem(value: 'Bureau', child: Text('Bureau')),
              DropdownMenuItem(value: 'Chambre', child: Text('Chambre')),
              DropdownMenuItem(value: 'Magasin', child: Text('Magasin')),
              DropdownMenuItem(value: 'Villa', child: Text('Villa')),
              DropdownMenuItem(value: 'Studio', child: Text('Studio')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
                widget.onFilterChanged(_selectedType, _minPrice, _maxPrice);
              }
            },
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Budget: ${_formatPrice(_minPrice)} - ${_formatPrice(_maxPrice)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          RangeSlider(
            values: RangeValues(_minPrice.toDouble(), _maxPrice.toDouble()),
            min: 0,
            max: 10000000000,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start.toInt();
                _maxPrice = values.end.toInt();
              });
              widget.onFilterChanged(_selectedType, _minPrice, _maxPrice);
            },
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)} Milliards GNF';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} Millions GNF';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K GNF';
    }
    return '$price GNF';
  }
}
