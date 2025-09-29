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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      // No stored email, go to login
      if (mounted) context.go('/login');
      return;
    }

    // Check verification status
    try {
      final user = await Supabase.instance.client
          .from('registrations')
          .select('verification_status')
          .eq('email', email)
          .maybeSingle();

      if (mounted) {
        if (user != null && user['verification_status'] == 'verified') {
          context.go('/dashboard');
        } else {
          context.go('/status');
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
      // On error, go to login
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}