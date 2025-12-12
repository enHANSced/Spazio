import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';

/// Pantalla de "Mis Reservas" con tabs de estado
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBookings() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      await context.read<BookingsProvider>().loadMyBookings();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingsProvider = context.watch<BookingsProvider>();
    
    // Si no está autenticado
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Reservas'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Inicia sesión para ver tus reservas',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final upcomingBookings = bookingsProvider.upcomingBookings;
    final pastBookings = bookingsProvider.pastBookings;
    final cancelledBookings = bookingsProvider.cancelledBookings;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Próximas (${upcomingBookings.length})'),
            Tab(text: 'Pasadas (${pastBookings.length})'),
            Tab(text: 'Canceladas (${cancelledBookings.length})'),
          ],
        ),
      ),
      body: bookingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookingsList(
                    bookings: upcomingBookings,
                    emptyMessage: 'No tienes reservas próximas',
                    emptyIcon: Icons.event_available,
                    showCancelButton: true,
                  ),
                  _BookingsList(
                    bookings: pastBookings,
                    emptyMessage: 'No tienes reservas pasadas',
                    emptyIcon: Icons.history,
                  ),
                  _BookingsList(
                    bookings: cancelledBookings,
                    emptyMessage: 'No tienes reservas canceladas',
                    emptyIcon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showCancelButton;
  
  const _BookingsList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showCancelButton = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/main/search'),
              icon: const Icon(Icons.search),
              label: const Text('Explorar espacios'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          showCancelButton: showCancelButton,
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool showCancelButton;
  
  const _BookingCard({
    required this.booking,
    this.showCancelButton = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM', 'es');
    final timeFormat = DateFormat('HH:mm');
    
    return GestureDetector(
      onTap: () {
        // Ir al detalle del espacio
        if (booking.space != null) {
          context.push('/space/${booking.spaceId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen
            if (booking.space != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: booking.space!.mainImage != null
                        ? Image.network(
                            booking.space!.mainImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _StatusBadge(status: booking.status),
                  ),
                ],
              ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del espacio
                  Text(
                    booking.space?.name ?? 'Espacio',
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Fecha y hora
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(booking.startTime),
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Precio total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${booking.durationHours.toStringAsFixed(1)} horas',
                        style: AppTypography.caption,
                      ),
                      Text(
                        '\$${booking.totalPrice.toStringAsFixed(0)}',
                        style: AppTypography.priceSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Botón cancelar
                  if (showCancelButton && booking.canCancel) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancelar reserva'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.background,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: AppColors.textTertiary,
      ),
    );
  }
  
  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final bookingsProvider = context.read<BookingsProvider>();
      final success = await bookingsProvider.cancelBooking(booking.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Reserva cancelada exitosamente'
                  : bookingsProvider.errorMessage ?? 'Error al cancelar',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  
  const _StatusBadge({required this.status});
  
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    
    switch (status) {
      case BookingStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.9);
        textColor = Colors.white;
        text = 'Pendiente';
      case BookingStatus.confirmed:
        backgroundColor = AppColors.success.withValues(alpha: 0.9);
        textColor = Colors.white;
        text = 'Confirmada';
      case BookingStatus.cancelled:
        backgroundColor = AppColors.error.withValues(alpha: 0.9);
        textColor = Colors.white;
        text = 'Cancelada';
      case BookingStatus.completed:
        backgroundColor = AppColors.textSecondary.withValues(alpha: 0.9);
        textColor = Colors.white;
        text = 'Completada';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
