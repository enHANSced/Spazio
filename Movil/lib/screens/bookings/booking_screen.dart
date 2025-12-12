import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/booking_model.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/spaces_provider.dart';
import '../../widgets/buttons.dart';

/// Pantalla de creación de reserva
class BookingScreen extends StatefulWidget {
  final String spaceId;
  
  const BookingScreen({
    super.key,
    required this.spaceId,
  });
  
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  final _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Asegurarse de que el espacio esté cargado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spacesProvider = context.read<SpacesProvider>();
      if (spacesProvider.selectedSpace?.id != widget.spaceId) {
        spacesProvider.loadSpaceById(widget.spaceId);
      }
    });
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  DateTime get _startDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }
  
  DateTime get _endDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }
  
  double get _duration {
    final start = _startTime.hour + _startTime.minute / 60;
    final end = _endTime.hour + _endTime.minute / 60;
    return end - start;
  }
  
  double get _totalPrice {
    final space = context.read<SpacesProvider>().selectedSpace;
    if (space == null || _duration <= 0) return 0;
    return space.pricePerHour * _duration;
  }
  
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
        // Ajustar hora de fin si es necesario
        if (_toMinutes(_endTime) <= _toMinutes(_startTime)) {
          _endTime = TimeOfDay(
            hour: (time.hour + 2) % 24,
            minute: time.minute,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      if (_toMinutes(time) > _toMinutes(_startTime)) {
        setState(() {
          _endTime = time;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La hora de fin debe ser posterior a la de inicio'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
  
  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
  
  String? _validateBooking() {
    if (_duration < 0.5) {
      return 'La duración mínima es de 30 minutos';
    }
    if (_duration > 24) {
      return 'La duración máxima es de 24 horas';
    }
    if (_startDateTime.isBefore(DateTime.now())) {
      return 'La fecha y hora deben ser futuras';
    }
    return null;
  }
  
  Future<void> _confirmBooking() async {
    final error = _validateBooking();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final bookingsProvider = context.read<BookingsProvider>();
    final data = CreateBookingData(
      spaceId: widget.spaceId,
      startTime: _startDateTime,
      endTime: _endDateTime,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );
    
    final success = await bookingsProvider.createBooking(data);
    
    if (success && mounted) {
      final booking = bookingsProvider.lastCreatedBooking;
      if (booking != null) {
        context.go('/booking-confirmation/${booking.id}');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingsProvider.errorMessage ?? 'Error al crear reserva'),
          backgroundColor: AppColors.error,
        ),
      );
      bookingsProvider.clearError();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final spacesProvider = context.watch<SpacesProvider>();
    final bookingsProvider = context.watch<BookingsProvider>();
    final space = spacesProvider.selectedSpace;
    
    if (space == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final dateFormat = DateFormat('EEEE d \'de\' MMMM', 'es');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar espacio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del espacio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: space.mainImage != null
                        ? Image.network(
                            space.mainImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          style: AppTypography.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${space.pricePerHour.toStringAsFixed(0)}/hora',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selección de fecha
            Text(
              'Fecha',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateFormat.format(_selectedDate),
                        style: AppTypography.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selección de hora
            Text(
              'Horario',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Hora inicio
                Expanded(
                  child: GestureDetector(
                    onTap: _selectStartTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inicio',
                            style: AppTypography.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startTime.format(context),
                            style: AppTypography.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Separador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppColors.textTertiary,
                  ),
                ),
                
                // Hora fin
                Expanded(
                  child: GestureDetector(
                    onTap: _selectEndTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fin',
                            style: AppTypography.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _endTime.format(context),
                            style: AppTypography.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notas
            Text(
              'Notas (opcional)',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agrega detalles adicionales para tu reserva...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Resumen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Duración',
                    value: '${_duration.toStringAsFixed(1)} horas',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Precio por hora',
                    value: '\$${space.pricePerHour.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total',
                    value: '\$${_totalPrice.toStringAsFixed(0)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botón confirmar
            PrimaryButton(
              text: 'Confirmar reserva',
              isLoading: bookingsProvider.isCreating,
              onPressed: bookingsProvider.isCreating ? null : _confirmBooking,
            ),
            
            const SizedBox(height: 16),
            
            // Nota de cancelación
            Center(
              child: Text(
                'Puedes cancelar hasta 24 horas antes',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.background,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal 
              ? AppTypography.titleMedium
              : AppTypography.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.priceMain
              : AppTypography.titleSmall,
        ),
      ],
    );
  }
}
