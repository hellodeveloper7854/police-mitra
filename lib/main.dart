import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_check_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assigned_services_screen.dart';
import 'screens/contact_police_screen.dart';
import 'screens/helpline_screen.dart';
import 'screens/cyber_security_screen.dart';
import 'screens/other_helplines_screen.dart';
import 'screens/community_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/verification_status_screen.dart';
import 'screens/profile_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //production account
  // await Supabase.initialize(
  //   url: 'https://ifzbizgupmttuwlajwtb.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlmemJpemd1cG10dHV3bGFqd3RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNjIwNzQsImV4cCI6MjA3MzkzODA3NH0.BYauXuoJvTaKHMXRC3Al5TtNIoPPVMWYmNgaBr6nRg4',
  // );

  //test account
  await Supabase.initialize(
    url: 'https://ejzovolwzecvbijkxutf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqem92b2x3emVjdmJpamt4dXRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwMzY0OTgsImV4cCI6MjA3NDYxMjQ5OH0.aLHseWsfPpbJNf5w6xPZHZBwp05tINBtGooHawYQo4M',
  );

  // DEBUG: Check for existing session
  final session = Supabase.instance.client.auth.currentSession;
  print('DEBUG: App startup - Current session: ${session != null ? 'EXISTS' : 'NULL'}');
  if (session != null) {
    print('DEBUG: Session user: ${session.user?.email}');
    print('DEBUG: Session expires: ${session.expiresAt}');
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Route not found: ${state.uri.path}'),
    ),
  ),
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthCheckScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignupScreen();
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: '/thank-you',
      builder: (BuildContext context, GoRouterState state) {
        return const ThankYouScreen();
      },
    ),
    GoRoute(
      path: '/status',
      builder: (BuildContext context, GoRouterState state) {
        return const VerificationStatusScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    GoRoute(
      path: '/assigned-services',
      builder: (BuildContext context, GoRouterState state) {
        return const AssignedServicesScreen();
      },
    ),
    GoRoute(
      path: '/contact-police',
      builder: (BuildContext context, GoRouterState state) {
        return const ContactPoliceScreen();
      },
    ),
    GoRoute(
      path: '/helpline',
      builder: (BuildContext context, GoRouterState state) {
        return const HelplineScreen();
      },
    ),
    GoRoute(
      path: '/cyber-security',
      builder: (BuildContext context, GoRouterState state) {
        return const CyberSecurityScreen();
      },
    ),
    GoRoute(
      path: '/other-helplines',
      builder: (BuildContext context, GoRouterState state) {
        return const OtherHelplinesScreen();
      },
    ),
    GoRoute(
      path: '/community',
      builder: (BuildContext context, GoRouterState state) {
        return const CommunityScreen();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Polismitr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
