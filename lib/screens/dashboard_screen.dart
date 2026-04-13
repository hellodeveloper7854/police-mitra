import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../widgets/notification_bell.dart';
import '../services/fcm_service.dart';

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
    _updateFCMToken(); // Add FCM token refresh
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

  // Update FCM token when dashboard is opened
  Future<void> _updateFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        print('⚠️ No user email found for FCM token update');
        return;
      }

      print('📱 Dashboard opened - Updating FCM token for: $email');

      // Get current FCM token
      final fcmToken = FCMService().currentToken ?? await FCMService().getSavedToken();

      if (fcmToken != null) {
        print('✅ FCM token found, updating database...');

        // Update FCM token in Supabase
        try {
          await Supabase.instance.client
              .from('registrations')
              .update({'fcm_token': fcmToken})
              .eq('email', email);

          print('✅ FCM token updated successfully in Supabase');
        } catch (e) {
          print('⚠️ Failed to update FCM token in Supabase: $e');
        }
      } else {
        print('⚠️ No FCM token available yet');
      }
    } catch (e) {
      print('❌ Error updating FCM token in dashboard: $e');
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

    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C563).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Color(0xFFF5C563),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Exit App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the Police Mitra app?',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C563),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        // If user confirmed exit, close the app
        if (shouldExit == true) {
          // Exit the app
          exit(0);
        }

        // Prevent default back behavior
        return false;
      },
      child: Scaffold(
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
          const NotificationBell(includeCommunityNotifications: true),
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
      ),
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