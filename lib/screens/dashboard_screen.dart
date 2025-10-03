import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAvailable = false; // Initial status
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
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) return;

      final res = await Supabase.instance.client
          .from('registrations')
          .select('current_availability_status')
          .eq('email', email)
          .single();

      if (res['current_availability_status'] == 'available') {
        // Fetch the latest availability log without end_time
        final logRes = await Supabase.instance.client
            .from('availability_logs')
            .select('availability_start_time')
            .eq('user_email', email)
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


  Future<void> _showAvailabilityConfirmation() async {
    final newStatus = !_isAvailable;
    final actionText = newStatus ? 'Available' : 'Not Available';

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Status Change'),
          content: Text('Are you sure you want to change your status to $actionText?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _toggleAvailability();
    }
  }

  Future<void> _toggleAvailability() async {
    final newStatus = !_isAvailable;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return;

    try {
      // Update registrations table
      await Supabase.instance.client
          .from('registrations')
          .update({'current_availability_status': newStatus ? 'available' : 'not-available'})
          .eq('email', email);

      if (newStatus) {
        // Becoming available - insert start time
        _startTime = DateTime.now();

        // Fetch police_station from registrations
        final regRes = await Supabase.instance.client
            .from('registrations')
            .select('police_station')
            .eq('email', email)
            .single();
        final policeStation = regRes['police_station'];

        await Supabase.instance.client.from('availability_logs').insert({
          'user_email': email,
          'police_station': policeStation,
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
              .eq('user_email', email)
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
            Image.asset('assets/images/logo.png', height: 80, width: 80),
            const SizedBox(width: 8),
            const Text(
              'पोलीस मित्र',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_email');
              if (mounted) GoRouter.of(context).go('/login');
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAvailabilityStatus,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Circular Status Indicator
              GestureDetector(
                onTap: _showAvailabilityConfirmation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.30),
                        spreadRadius: 2,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.15),
                        spreadRadius: 10,
                        blurRadius: 60,
                        offset: const Offset(0, 24),
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
              const SizedBox(height: 14),
              _buildStatusBanner(isAvailable),
              const SizedBox(height: 32),
              // Grid of service cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildCard('Assigned\nServices', 'assets/images/location 1.png', Colors.red, () {
                      print('DEBUG: Card navigation - going to /assigned-services');
                      context.push('/assigned-services');
                    }),
                    _buildCard('Contact\nPolice Station', 'assets/images/helpline 2.png', Colors.blue, () {
                      print('DEBUG: Card navigation - going to /contact-police');
                      context.push('/contact-police');
                    }),
                    _buildCard('Other Helpline', 'assets/images/helpline.png', Colors.grey[600]!, () {
                      print('DEBUG: Card navigation - going to /helpline');
                      context.push('/helpline');
                    }),
                    _buildCard('Community', 'assets/images/community.png', Colors.orange, () {
                      print('DEBUG: Card navigation - going to /community');
                      context.push('/community');
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FooterWidget(),
    );
  }

  Widget _buildStatusBanner(bool isAvailable) {
    final Color base = isAvailable ? Colors.green : Colors.red;
    final List<Color> gradient = isAvailable
        ? [Colors.green.shade500, Colors.green.shade700]
        : [Colors.red.shade400, Colors.red.shade600];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: base.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.error_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You are Available' : 'You are Not Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the status circle to ${isAvailable ? 'go Not Available' : 'become Available'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String imagePath, Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
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