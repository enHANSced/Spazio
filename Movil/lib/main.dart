import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/spaces_provider.dart';
import 'providers/bookings_provider.dart';
import 'data/api/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/spaces_repository.dart';
import 'data/repositories/bookings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar localización para español
  await initializeDateFormatting('es', null);
  
  // Configurar orientación de pantalla (solo vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const SpazioApp());
}

class SpazioApp extends StatelessWidget {
  const SpazioApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Crear instancias de API client y repositorios
    final apiClient = ApiClient();
    final authRepository = AuthRepository(apiClient);
    final spacesRepository = SpacesRepository(apiClient);
    final bookingsRepository = BookingsRepository(apiClient);
    const secureStorage = FlutterSecureStorage();
    
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            apiClient: apiClient,
            storage: secureStorage,
          ),
        ),
        
        // Spaces Provider
        ChangeNotifierProvider(
          create: (_) => SpacesProvider(
            spacesRepository: spacesRepository,
          ),
        ),
        
        // Bookings Provider
        ChangeNotifierProvider(
          create: (_) => BookingsProvider(
            bookingsRepository: bookingsRepository,
          ),
        ),
      ],
      child: const _SpazioAppContent(),
    );
  }
}

class _SpazioAppContent extends StatelessWidget {
  const _SpazioAppContent();
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final router = AppRouter.router(authProvider);
    
    return MaterialApp.router(
      title: 'Spazio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Limitar el escalado de texto para accesibilidad
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
