import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() => _isChecking = true);

    try {
      // Get stored email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      print('DEBUG: AuthCheck - Stored email: ${email ?? "NULL"}');

      if (email == null) {
        // No stored email, go to login
        print('DEBUG: No email found, navigating to login');
        if (mounted) {
          setState(() => _isChecking = false);
          context.go('/login');
        }
        return;
      }

      // Check if Supabase session exists and is valid
      final session = Supabase.instance.client.auth.currentSession;
      print('DEBUG: Supabase session: ${session != null ? "EXISTS" : "NULL"}');

      if (session != null) {
        final now = DateTime.now();
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

        if (now.isAfter(expiresAt)) {
          print('DEBUG: Session expired, refreshing...');
          try {
            await Supabase.instance.client.auth.refreshSession();
            print('DEBUG: Session refreshed successfully');
          } catch (e) {
            print('DEBUG: Failed to refresh session: $e');
            // Session refresh failed, but we still have email in SharedPreferences
            // Continue with the email-based auth check
          }
        }
      }

      // Check verification status from database
      final user = await Supabase.instance.client
          .from('registrations')
          .select('verification_status')
          .eq('email', email)
          .maybeSingle();

      print('DEBUG: User verification status: ${user?['verification_status']}');

      if (mounted) {
        setState(() => _isChecking = false);
        if (user != null &&
            (user['verification_status'] == 'verified' ||
             user['verification_status'] == 'approve' ||
             user['verification_status'] == 'approved')) {
          print('DEBUG: User verified, navigating to dashboard');
          context.go('/dashboard');
        } else {
          print('DEBUG: User not verified, navigating to status');
          context.go('/status');
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
      // On error, still try to navigate based on stored email
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (mounted) {
        setState(() => _isChecking = false);
        if (email != null) {
          // Have email but error checking status - go to dashboard as fallback
          print('DEBUG: Error occurred but email exists, going to dashboard');
          context.go('/dashboard');
        } else {
          // No email and error - go to login
          print('DEBUG: Error occurred and no email, going to login');
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_isChecking) ...[
              const SizedBox(height: 16),
              const Text(
                'Verifying...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}