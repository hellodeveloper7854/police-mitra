import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAvailable = false; // Initial status
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
        print('DEBUG: Navigating to /community using context.push()');
        context.push('/community');
        break;
      case 3:
        print('DEBUG: Navigating to /assigned-services using context.push()');
        context.push('/assigned-services');
        break;
    }
  }

  void _toggleAvailability() {
    setState(() {
      _isAvailable = !_isAvailable;
    });
    // Here you would also update the database
    // For now, we just print the action
    print('Availability updated to: ${_isAvailable ? "Available" : "Not Available"}');
  }

  @override
  Widget build(BuildContext context) {
    bool isAvailable = _isAvailable;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'पोलिस मित्र',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) GoRouter.of(context).go('/login');
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Circular Status Indicator
            GestureDetector(
              onTap: _toggleAvailability,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAvailable 
                            ? Colors.green.withOpacity(0.3) 
                            : Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAvailable 
                            ? Colors.green.withOpacity(0.5) 
                            : Colors.red.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isAvailable ? 'Available' : 'Not Available',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            // Grid of service cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCard('Assigned\nServices', Icons.location_on, Colors.red, () {
                    print('DEBUG: Card navigation - going to /assigned-services');
                    context.push('/assigned-services');
                  }),
                  _buildCard('Contact\nPolice Station', Icons.account_balance, Colors.blue, () {
                    print('DEBUG: Card navigation - going to /contact-police');
                    context.push('/contact-police');
                  }),
                  _buildCard('Other Helpline', Icons.headset_mic, Colors.grey[600]!, () {
                    print('DEBUG: Card navigation - going to /helpline');
                    context.push('/helpline');
                  }),
                  _buildCard('Community', Icons.groups, Colors.orange, () {
                    print('DEBUG: Card navigation - going to /community');
                    context.push('/community');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.groups),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'My Duties',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}