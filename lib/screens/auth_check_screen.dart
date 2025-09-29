import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.user != null) {
      // Check verification status
      final user = await Supabase.instance.client
          .from('registrations')
          .select('verification_status')
          .eq('email', session.user!.email!)
          .maybeSingle();

      if (mounted) {
        if (user != null && user['verification_status'] == 'verified') {
          context.go('/dashboard');
        } else {
          context.go('/status');
        }
      }
    } else {
      // No session, go to login
      if (mounted) {
        context.go('/login');
      }
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