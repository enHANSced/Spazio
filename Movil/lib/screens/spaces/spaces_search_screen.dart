import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/spaces_repository.dart';
import '../../providers/spaces_provider.dart';
import '../../widgets/space_card.dart';
import '../../widgets/text_fields.dart';

/// Pantalla de búsqueda de espacios
class SpacesSearchScreen extends StatefulWidget {
  const SpacesSearchScreen({super.key});
  
  @override
  State<SpacesSearchScreen> createState() => _SpacesSearchScreenState();
}

class _SpacesSearchScreenState extends State<SpacesSearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {}); // Para actualizar el botón de limpiar
  }
  
  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      context.read<SpacesProvider>().loadSpaces();
    } else {
      context.read<SpacesProvider>().searchSpaces(query);
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _searchController.clear();
    });
    context.read<SpacesProvider>().clearFilters();
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCity: _selectedCity,
        selectedCategory: _selectedCategory,
        onApply: (city, category) {
          setState(() {
            _selectedCity = city;
            _selectedCategory = category;
          });
          final filters = SpaceFilters(
            search: _searchController.text.trim().isEmpty 
                ? null 
                : _searchController.text.trim(),
            city: city,
            category: category,
          );
          context.read<SpacesProvider>().applyFilters(filters);
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final spacesProvider = context.watch<SpacesProvider>();
    final hasActiveFilters = _selectedCity != null || _selectedCategory != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar espacios'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchTextField(
                        controller: _searchController,
                        hint: 'Nombre, ciudad, categoría...',
                        onSubmitted: (_) => _performSearch(),
                        onClear: _performSearch,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón de filtros
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: hasActiveFilters 
                              ? AppColors.primary 
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.tune,
                                color: hasActiveFilters 
                                    ? Colors.white 
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (hasActiveFilters)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Chips de filtros activos
                if (hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_selectedCity != null)
                                  _FilterChip(
                                    label: _selectedCity!,
                                    onRemove: () {
                                      setState(() => _selectedCity = null);
                                      context.read<SpacesProvider>().filterByCity(null);
                                    },
                                  ),
                                if (_selectedCategory != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: _selectedCity != null ? 8 : 0,
                                    ),
                                    child: _FilterChip(
                                      label: _selectedCategory!,
                                      onRemove: () {
                                        setState(() => _selectedCategory = null);
                                        context.read<SpacesProvider>().filterByCategory(null);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Resultados
          Expanded(
            child: _buildResults(spacesProvider),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResults(SpacesProvider spacesProvider) {
    if (spacesProvider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const SpaceCardShimmer(),
      );
    }
    
    if (spacesProvider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al buscar',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              spacesProvider.errorMessage ?? '',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => spacesProvider.refreshSpaces(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (spacesProvider.spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron espacios',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: spacesProvider.spaces.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final space = spacesProvider.spaces[index];
        return SpaceCard(
          space: space,
          onTap: () => context.push('/space/${space.id}'),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  
  const _FilterChip({
    required this.label,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCity;
  final String? selectedCategory;
  final void Function(String? city, String? category) onApply;
  
  const _FilterBottomSheet({
    this.selectedCity,
    this.selectedCategory,
    required this.onApply,
  });
  
  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _city;
  String? _category;
  
  final List<String> _cities = [
    'Ciudad de México',
    'Guadalajara',
    'Monterrey',
    'Puebla',
    'Querétaro',
  ];
  
  final List<String> _categories = [
    'Eventos',
    'Reuniones',
    'Coworking',
    'Estudio',
    'Bodega',
    'Jardín',
  ];
  
  @override
  void initState() {
    super.initState();
    _city = widget.selectedCity;
    _category = widget.selectedCategory;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Filtros',
                style: AppTypography.headlineMedium,
              ),
              
              const SizedBox(height: 24),
              
              // Ciudad
              Text(
                'Ciudad',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cities.map((city) {
                  final isSelected = _city == city;
                  return ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _city = selected ? city : null;
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Categoría
              Text(
                'Categoría',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _category == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? category : null;
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _city = null;
                          _category = null;
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_city, _category);
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
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
