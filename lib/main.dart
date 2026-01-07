import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/super_admin_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/teachers_screen.dart';
import 'screens/problem_reports_screen.dart';
import 'screens/payment_proofs_screen.dart';
import 'screens/restriction_management_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service with FCM
  await NotificationService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // Global navigator key for notification navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set navigator key for notification service
    NotificationService.setNavigatorKey(navigatorKey);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Admin App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/teachers': (context) => const TeachersScreen(),
        '/problem-reports': (context) => const ProblemReportsScreen(),
        '/payment-proofs': (context) => const PaymentProofsScreen(),
        '/restriction-management': (context) => const RestrictionManagementScreen(),
      },
    );
  }
}
