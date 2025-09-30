import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    print('DEBUG: Bottom nav tapped - index: $index');
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home - already on dashboard
        print('DEBUG: Staying on dashboard (home)');
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