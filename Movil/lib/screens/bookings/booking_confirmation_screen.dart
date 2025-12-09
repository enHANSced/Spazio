import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/glass_container.dart';

/// Pantalla de confirmación de reserva exitosa
class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  
  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
  });
  
  @override
  Widget build(BuildContext context) {
    final bookingsProvider = context.watch<BookingsProvider>();
    final booking = bookingsProvider.lastCreatedBooking;
    
    if (booking == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Cargando confirmación...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    final dateFormat = DateFormat('EEEE d \'de\' MMMM, yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFF1E88E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Icono de éxito
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 48,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título
                Text(
                  '¡Reserva confirmada!',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Tu espacio ha sido reservado exitosamente',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Detalles de la reserva
                GlassContainer(
                  child: Column(
                    children: [
                      // Espacio
                      if (booking.space != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.space!.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  if (booking.space!.address != null)
                                    Text(
                                      booking.space!.address!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                      ],
                      
                      // Fecha
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Fecha',
                        value: dateFormat.format(booking.startTime),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Horario
                      _DetailRow(
                        icon: Icons.access_time,
                        label: 'Horario',
                        value: '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Duración
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Duración',
                        value: '${booking.durationHours.toStringAsFixed(1)} horas',
                      ),
                      
                      const Divider(height: 24),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total pagado',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            '\$${booking.totalPrice.toStringAsFixed(0)}',
                            style: AppTypography.priceMain.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Botones
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/main/bookings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver mis reservas',
                      style: AppTypography.buttonMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/main/home');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Volver al inicio',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
