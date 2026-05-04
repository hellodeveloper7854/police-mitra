import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assigned_services_screen.dart';
import 'widgets/notification_bell.dart';
import 'screens/contact_police_screen.dart';
import 'screens/helpline_screen.dart';
import 'screens/cyber_security_screen.dart';
import 'screens/other_helplines_screen.dart';
import 'screens/community_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/verification_status_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/availability_status_screen.dart';
import 'screens/auth_check_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/feedback_history_screen.dart';
import 'screens/settings_reset_password_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/notification_history_screen.dart';
import 'screens/certificates_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM Service
  await FCMService().initialize();

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

    // User is already logged in - update FCM token immediately
    final userEmail = session.user?.email;
    if (userEmail != null) {
      print('🔐 User already logged in at startup: $userEmail');

      // Save email to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', userEmail);
      print('💾 User email saved to preferences at startup');

      // Wait a moment for FCM to initialize, then update token
      await Future.delayed(const Duration(seconds: 2));

      final fcmToken = await FCMService().currentToken ?? await FCMService().getSavedToken();

      if (fcmToken != null) {
        print('📱 FCM token available at startup, updating database...');

        try {
          await Supabase.instance.client
              .from('registrations')
              .update({'fcm_token': fcmToken})
              .eq('email', userEmail);

          print('✅ FCM token updated in Supabase at startup for: $userEmail');

          // Also send to backend API
          await FCMService().sendTokenToBackend(userEmail, fcmToken);
          print('✅ FCM token sent to backend API at startup');
        } catch (e) {
          print('⚠️ Error updating FCM token at startup: $e');
        }
      } else {
        print('⚠️ No FCM token available at startup, will update when generated');
      }
    }
  }

  // Listen to auth state changes
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    print('DEBUG: Auth state changed: $event');
    print('DEBUG: Session is now: ${session != null ? 'EXISTS' : 'NULL'}');

    // When user is signed in or token is refreshed, update FCM token
    if (event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.userUpdated) {
      print('DEBUG: Auth event: $event - keeping user logged in');

      // Get the user email from session
      if (session?.user?.email != null) {
        final userEmail = session!.user!.email!;
        print('🔐 User authenticated: $userEmail');

        // Save user email to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', userEmail);
        print('💾 User email saved to preferences');

        // Update FCM token for this user
        final fcmToken = await FCMService().currentToken ?? await FCMService().getSavedToken();

        if (fcmToken != null) {
          print('📱 FCM token found, updating database...');

          try {
            // Update Supabase with FCM token
            await Supabase.instance.client
                .from('registrations')
                .update({'fcm_token': fcmToken})
                .eq('email', userEmail);

            print('✅ FCM token updated in Supabase for: $userEmail');

            // Also send to backend API
            await FCMService().sendTokenToBackend(userEmail, fcmToken);
            print('✅ FCM token sent to backend API');
          } catch (e) {
            print('⚠️ Error updating FCM token on auth change: $e');
          }
        } else {
          print('⚠️ No FCM token available yet, will update when generated');
        }
      }
    } else if (event == AuthChangeEvent.signedOut) {
      print('DEBUG: User signed out - clearing stored email');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      print('✅ User email cleared from preferences');
    }
  });

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
      path: '/forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordScreen();
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ResetPasswordScreen();
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
      path: '/availability-status',
      builder: (BuildContext context, GoRouterState state) {
        return const AvailabilityStatusScreen();
      },
    ),
    GoRoute(
      path: '/assigned-services',
      builder: (BuildContext context, GoRouterState state) {
        return const AssignedServicesScreen();
      },
    ),
    GoRoute(
      path: '/certificates',
      builder: (BuildContext context, GoRouterState state) {
        return const CertificatesScreen();
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
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
    GoRoute(
      path: '/feedback',
      builder: (BuildContext context, GoRouterState state) {
        return const FeedbackScreen();
      },
    ),
    GoRoute(
      path: '/feedback-history',
      builder: (BuildContext context, GoRouterState state) {
        return const FeedbackHistoryScreen();
      },
    ),
    GoRoute(
      path: '/settings-reset-password',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsResetPasswordScreen();
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationsScreen();
      },
      onExit: (BuildContext context, GoRouterState state) async {
        // Refresh notification count when leaving notifications screen
        notificationBellKey.currentState?.refreshCount();
        return true;
      },
    ),
    GoRoute(
      path: '/notification-history',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationHistoryScreen();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Polismitr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
