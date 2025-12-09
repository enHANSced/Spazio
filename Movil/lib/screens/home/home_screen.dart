import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spaces_provider.dart';
import '../../widgets/space_card.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/text_fields.dart';

/// Pantalla principal / Home
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Cargar espacios al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpacesProvider>().loadSpaces();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final spacesProvider = context.watch<SpacesProvider>();
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => spacesProvider.refreshSpaces(),
        child: CustomScrollView(
          slivers: [
            // Header con gradiente
            SliverToBoxAdapter(
              child: _buildHeader(authProvider),
            ),
            
            // Barra de búsqueda
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: () => context.go('/main/search'),
                  child: AbsorbPointer(
                    child: SearchTextField(
                      controller: _searchController,
                      hint: 'Buscar espacios...',
                    ),
                  ),
                ),
              ),
            ),
            
            // Categorías
            SliverToBoxAdapter(
              child: _buildCategories(),
            ),
            
            // Espacios destacados
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Espacios destacados',
                      style: AppTypography.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.go('/main/search'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de espacios
            _buildSpacesList(spacesProvider),
            
            // Espacio al final
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.isAuthenticated
                            ? authProvider.user?.name ?? 'Usuario'
                            : 'Invitado',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Avatar o logo
                  GlassContainer(
                    blur: 10,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      authProvider.isAuthenticated 
                          ? Icons.person 
                          : Icons.space_dashboard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Título
              Text(
                'Encuentra el espacio\nperfecto para ti',
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategories() {
    final categories = [
      _CategoryItem(
        icon: Icons.celebration,
        label: 'Eventos',
        color: AppColors.primary,
      ),
      _CategoryItem(
        icon: Icons.meeting_room,
        label: 'Reuniones',
        color: AppColors.gradientEnd,
      ),
      _CategoryItem(
        icon: Icons.workspace_premium,
        label: 'Coworking',
        color: AppColors.success,
      ),
      _CategoryItem(
        icon: Icons.photo_camera,
        label: 'Estudio',
        color: AppColors.warning,
      ),
    ];
    
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              context.read<SpacesProvider>().filterByCategory(category.label);
              context.go('/main/search');
            },
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.label,
                    style: AppTypography.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSpacesList(SpacesProvider spacesProvider) {
    if (spacesProvider.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SpaceCardShimmer(),
            ),
            childCount: 3,
          ),
        ),
      );
    }
    
    if (spacesProvider.hasError) {
      return SliverToBoxAdapter(
        child: _buildErrorState(spacesProvider),
      );
    }
    
    if (spacesProvider.spaces.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final space = spacesProvider.featuredSpaces[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SpaceCard(
                space: space,
                onTap: () => context.push('/space/${space.id}'),
              ),
            );
          },
          childCount: spacesProvider.featuredSpaces.length,
        ),
      ),
    );
  }
  
  Widget _buildErrorState(SpacesProvider spacesProvider) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
            'Error al cargar espacios',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            spacesProvider.errorMessage ?? 'Intenta de nuevo más tarde',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
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
  
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.space_dashboard_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay espacios disponibles',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve a intentarlo más tarde',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días 👋';
    } else if (hour < 18) {
      return 'Buenas tardes 👋';
    } else {
      return 'Buenas noches 👋';
    }
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  
  _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
