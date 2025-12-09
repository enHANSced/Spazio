import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/spaces/space_detail_screen.dart';
import '../../screens/spaces/spaces_search_screen.dart';
import '../../screens/bookings/booking_screen.dart';
import '../../screens/bookings/booking_confirmation_screen.dart';
import '../../screens/bookings/my_bookings_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/main_navigation_screen.dart';

/// Configuración de rutas de la aplicación
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation.startsWith('/login') || 
                           state.matchedLocation.startsWith('/register');
        final isSplash = state.matchedLocation == '/';
        final isOnboarding = state.matchedLocation == '/onboarding';
        
        // Permitir splash y onboarding
        if (isSplash || isOnboarding) {
          return null;
        }
        
        // Si está en una ruta de auth y ya está autenticado, ir a home
        if (isAuthRoute && isAuthenticated) {
          return '/main/home';
        }
        
        return null;
      },
      routes: [
        // Splash screen
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Onboarding
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        
        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Main navigation shell
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainNavigationScreen(child: child),
          routes: [
            // Home
            GoRoute(
              path: '/main/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            
            // Search
            GoRoute(
              path: '/main/search',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SpacesSearchScreen(),
              ),
            ),
            
            // My Bookings
            GoRoute(
              path: '/main/bookings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MyBookingsScreen(),
              ),
            ),
            
            // Profile
            GoRoute(
              path: '/main/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
        
        // Space detail (outside shell for full screen)
        GoRoute(
          path: '/space/:id',
          builder: (context, state) => SpaceDetailScreen(
            spaceId: state.pathParameters['id']!,
          ),
        ),
        
        // Booking flow
        GoRoute(
          path: '/booking/:spaceId',
          builder: (context, state) => BookingScreen(
            spaceId: state.pathParameters['spaceId']!,
          ),
        ),
        GoRoute(
          path: '/booking-confirmation/:bookingId',
          builder: (context, state) => BookingConfirmationScreen(
            bookingId: state.pathParameters['bookingId']!,
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.matchedLocation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/main/home'),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
