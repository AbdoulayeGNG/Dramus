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
  int _maxPrice = 5000000;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DramusColors.white,
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
          Text(
            'Type de propriété',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              _buildFilterChip('Tous', 'all'),
              _buildFilterChip('Maison', 'Maison'),
              _buildFilterChip('Appartement', 'Appartement'),
              _buildFilterChip('Terrain', 'Terrain'),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Budget: ${_minPrice.toStringAsFixed(0)} - ${_maxPrice.toStringAsFixed(0)} GNF',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          RangeSlider(
            values: RangeValues(_minPrice.toDouble(), _maxPrice.toDouble()),
            min: 0,
            max: 10000000,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start.toInt();
                _maxPrice = values.end.toInt();
              });
              widget.onFilterChanged(_selectedType, _minPrice, _maxPrice);
            },
            activeColor: DramusColors.primaryTeal,
            inactiveColor: DramusColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedType == value,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
        });
        widget.onFilterChanged(_selectedType, _minPrice, _maxPrice);
      },
      backgroundColor: DramusColors.white,
      selectedColor: DramusColors.primaryTeal,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _selectedType == value
                ? DramusColors.white
                : DramusColors.darkText,
          ),
      side: BorderSide(
        color: _selectedType == value
            ? DramusColors.primaryTeal
            : DramusColors.border,
      ),
    );
  }
}
