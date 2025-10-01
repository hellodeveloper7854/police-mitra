import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  // Determine which tab should be active based on the current route
  int _indexForLocation(String location) {
    if (location.startsWith('/contact-police')) return 1;
    if (location.startsWith('/helpline') ||
        location.startsWith('/cyber-security') ||
        location.startsWith('/other-helplines')) return 2;
    // Default to Home (dashboard or any other routes not explicitly mapped)
    return 0;
  }

  // Handle navigation when a tab is tapped
  Future<void> _onItemTapped(BuildContext context, int index) async {
    print('DEBUG: Bottom nav tapped - index: $index');
    switch (index) {
      case 0:
        print('DEBUG: Home tapped - checking verification status');
        try {
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString('user_email');

          if (email == null) {
            context.go('/login');
            break;
          }

          final user = await Supabase.instance.client
              .from('registrations')
              .select('verification_status')
              .eq('email', email)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          final normalized =
              (user?['verification_status'] ?? '').toString().trim().toLowerCase();

          if (normalized == 'verified' ||
              normalized == 'approve' ||
              normalized == 'approved') {
            context.go('/dashboard');
          } else {
            context.go('/status');
          }
        } catch (e) {
          print('ERROR: Home navigation failed - $e');
          context.go('/login');
        }
        break;
      case 1:
        print('DEBUG: Navigating to /contact-police using context.push()');
        context.push('/contact-police');
        break;
      case 2:
        print('DEBUG: Navigating to /helpline using context.push()');
        context.push('/helpline');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wifi_tethering),
          label: 'Police Station',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.phone),
          label: 'Helpline',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.groups),
        //   label: 'Community',
        // ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.assignment),
        //   label: 'My Duties',
        // ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}