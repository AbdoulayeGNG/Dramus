import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';

class FilterPanel extends StatefulWidget {
  final Function(String type, int minPrice, int maxPrice) onFilterChanged;
  final TextEditingController? searchController;
  final VoidCallback? onSearchChanged;

  const FilterPanel({
    super.key,
    required this.onFilterChanged,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
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

          // ── Recherche & Type de bien ──────────────────────────
          if (widget.searchController == null)
            DropdownButtonFormField<String>(
              value: _selectedType,
              isExpanded: true,
              isDense: true,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  setState(() => _selectedType = value);
                  _notifyParent();
                }
              },
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: (_) => widget.onSearchChanged?.call(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Recherche...',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      filled: true,
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('Tous les types')),
                      DropdownMenuItem(value: 'Maison', child: Text('Maison')),
                      DropdownMenuItem(
                          value: 'Appartement', child: Text('Appartement')),
                      DropdownMenuItem(
                          value: 'Terrain', child: Text('Terrain')),
                      DropdownMenuItem(value: 'Bureau', child: Text('Bureau')),
                      DropdownMenuItem(
                          value: 'Chambre', child: Text('Chambre')),
                      DropdownMenuItem(
                          value: 'Magasin', child: Text('Magasin')),
                      DropdownMenuItem(value: 'Villa', child: Text('Villa')),
                      DropdownMenuItem(value: 'Studio', child: Text('Studio')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                        _notifyParent();
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _notifyParent() {
    // Aucun filtre de prix : plage maximale
    widget.onFilterChanged(
      _selectedType,
      0,
      999999999999,
    );
  }
}
