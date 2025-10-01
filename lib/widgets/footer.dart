import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  int _selectedIndex = 0;

  Future<void> _onItemTapped(int index) async {
    print('DEBUG: Bottom nav tapped - index: $index');
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        print('DEBUG: Home tapped - checking verification status');
        try {
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString('user_email');

          if (email == null) {
            if (mounted) context.go('/login');
            break;
          }

          final user = await Supabase.instance.client
              .from('registrations')
              .select('verification_status')
              .eq('email', email)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (!mounted) break;

          final normalized = (user?['verification_status'] ?? '').toString().trim().toLowerCase();

          if (normalized == 'verified' || normalized == 'approve' || normalized == 'approved') {
            context.go('/dashboard');
          } else {
            context.go('/status');
          }
        } catch (e) {
          print('ERROR: Home navigation failed - $e');
          if (mounted) context.go('/login');
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
      case 3:
        print('DEBUG: Navigating to /community using context.push()');
        context.push('/community');
        break;
      case 4:
        print('DEBUG: Navigating to /assigned-services using context.push()');
        context.push('/assigned-services');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }
}