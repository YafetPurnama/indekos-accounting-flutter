import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // NEW

// Core
import 'core/theme/app_theme.dart';
import 'core/constants/supabase_config.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/kamar_provider.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/dashboard/owner_dashboard_screen.dart';
import 'screens/dashboard/tenant_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //First time dahulu
  await dotenv.load(fileName: ".env");

  // Inisialisasi Firebase
  await Firebase.initializeApp();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const SiaIndekosApp());
}

/// Root widget apps Mobile.
class SiaIndekosApp extends StatelessWidget {
  const SiaIndekosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KamarProvider()),
      ],
      child: MaterialApp(
        title: 'SIA Indekos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // Global navigator key — untuk force logout dari AuthProvider
        navigatorKey: navigatorKey,

        // Hoem screen
        home: const SplashScreen(),

        // Named Routes
        routes: {
          '/login': (_) => const LoginScreen(),
          '/role-select': (_) => const RoleSelectionScreen(),
          '/owner-dashboard': (_) => const OwnerDashboardScreen(),
          '/tenant-dashboard': (_) => const TenantDashboardScreen(),
        },
      ),
    );
  }
}
