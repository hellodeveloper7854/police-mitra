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
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _fetchAvailabilityStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAvailabilityStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) return;

      final res = await Supabase.instance.client
          .from('registrations')
          .select('current_availability_status')
          .eq('email', user.email!)
          .single();

      if (res['current_availability_status'] == 'available') {
        // Fetch the latest availability log without end_time
        final logRes = await Supabase.instance.client
            .from('availability_logs')
            .select('availability_start_time')
            .eq('user_email', user.email!)
            .filter('end_time', 'is', null)
            .order('availability_start_time', ascending: false)
            .limit(1)
            .single();

        setState(() {
          _isAvailable = true;
          _startTime = DateTime.parse(logRes['availability_start_time']);
        });
        _startTimer();
      } else {
        setState(() {
          _isAvailable = false;
          _elapsedTime = Duration.zero;
        });
        _timer?.cancel();
      }
    } catch (e) {
      print('Error fetching availability: $e');
      setState(() {
        _isAvailable = false;
        _elapsedTime = Duration.zero;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

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

  Future<void> _toggleAvailability() async {
    final newStatus = !_isAvailable;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      // Update registrations table
      await Supabase.instance.client
          .from('registrations')
          .update({'current_availability_status': newStatus ? 'available' : 'not-available'})
          .eq('email', user.email!);

      if (newStatus) {
        // Becoming available - insert start time
        _startTime = DateTime.now();
        await Supabase.instance.client.from('availability_logs').insert({
          'user_email': user.email!,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'availability_start_time': _startTime!.toIso8601String(),
        });
        _startTimer();
      } else {
        // Becoming unavailable - update end time
        if (_startTime != null) {
          await Supabase.instance.client
              .from('availability_logs')
              .update({'end_time': DateTime.now().toIso8601String()})
              .eq('user_email', user.email!)
              .eq('availability_start_time', _startTime!.toIso8601String());
        }
        _timer?.cancel();
        _elapsedTime = Duration.zero;
      }

      setState(() {
        _isAvailable = newStatus;
      });

      print('Availability updated to: ${newStatus ? "Available" : "Not Available"}');
    } catch (e) {
      print('Error updating availability: $e');
      // Optionally show snackbar
    }
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
                          if (isAvailable) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAvailable
                  ? 'Click to make your status unavailable'
                  : 'Click to make your status available',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
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