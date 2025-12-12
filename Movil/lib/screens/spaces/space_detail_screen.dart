import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spaces_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_container.dart';

/// Pantalla de detalle de un espacio
class SpaceDetailScreen extends StatefulWidget {
  final String spaceId;
  
  const SpaceDetailScreen({
    super.key,
    required this.spaceId,
  });
  
  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpacesProvider>().loadSpaceById(widget.spaceId);
    });
  }
  
  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }
  
  void _openGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final spacesProvider = context.watch<SpacesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final space = spacesProvider.selectedSpace;
    
    if (spacesProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (spacesProvider.hasError || space == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
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
                'Error al cargar el espacio',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/main/home'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    }
    
    final images = space.images;
    final canBook = authProvider.canBook;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconActionButton(
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconActionButton(
                  icon: Icons.share_outlined,
                  onPressed: () {
                    // TODO: Implementar compartir
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(images),
            ),
          ),
          
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría
                  if (space.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        space.category!,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Nombre
                  Text(
                    space.name,
                    style: AppTypography.displaySmall,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ubicación
                  if (space.address != null || space.city != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [space.address, space.city]
                                .where((e) => e != null)
                                .join(', '),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.people_outline,
                          label: 'Capacidad',
                          value: '${space.capacity} personas',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.access_time,
                          label: 'Precio',
                          value: '\$${space.pricePerHour.toStringAsFixed(0)}/hr',
                          valueColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Descripción
                  if (space.description != null) ...[
                    Text(
                      'Descripción',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      space.description!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Amenidades
                  if (space.amenities.isNotEmpty) ...[
                    Text(
                      'Amenidades',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: space.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                amenity,
                                style: AppTypography.labelMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Propietario
                  if (space.owner != null) ...[
                    Text(
                      'Propietario',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              space.owner!.name.substring(0, 1).toUpperCase(),
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  space.owner!.name,
                                  style: AppTypography.titleSmall,
                                ),
                                if (space.owner!.businessName != null)
                                  Text(
                                    space.owner!.businessName!,
                                    style: AppTypography.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          if (space.owner!.isVerified)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Espacio para el botón fijo
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Botón de reserva fijo
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Precio
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${space.pricePerHour.toStringAsFixed(0)}',
                    style: AppTypography.priceMain,
                  ),
                  Text(
                    'por hora',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Botón de reservar
              Expanded(
                child: PrimaryButton(
                  text: canBook ? 'Reservar ahora' : 
                        authProvider.isOwner ? 'Los propietarios no pueden reservar' :
                        'Inicia sesión para reservar',
                  onPressed: canBook
                      ? () => context.go('/booking/${space.id}')
                      : authProvider.isAuthenticated
                          ? null
                          : () => context.go('/login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // Imágenes
        PageView.builder(
          controller: _imageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openGallery(images, index),
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(Icons.error_outline),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Indicadores
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        
        // Contador
        if (images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: GlassContainer(
              blur: 10,
              borderRadius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  IconData _getAmenityIcon(String amenity) {
    final lowerAmenity = amenity.toLowerCase();
    if (lowerAmenity.contains('wifi') || lowerAmenity.contains('internet')) {
      return Icons.wifi;
    }
    if (lowerAmenity.contains('estacionamiento') || lowerAmenity.contains('parking')) {
      return Icons.local_parking;
    }
    if (lowerAmenity.contains('aire') || lowerAmenity.contains('clima')) {
      return Icons.ac_unit;
    }
    if (lowerAmenity.contains('cocina')) {
      return Icons.kitchen;
    }
    if (lowerAmenity.contains('baño')) {
      return Icons.bathroom;
    }
    if (lowerAmenity.contains('proyector')) {
      return Icons.videocam;
    }
    if (lowerAmenity.contains('sonido') || lowerAmenity.contains('audio')) {
      return Icons.speaker;
    }
    if (lowerAmenity.contains('café') || lowerAmenity.contains('coffee')) {
      return Icons.coffee;
    }
    return Icons.check_circle_outline;
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Galería de imágenes en pantalla completa
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  
  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });
  
  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.images[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) {
          return Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          );
        },
      ),
    );
  }
}
