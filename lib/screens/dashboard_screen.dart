import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';

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

      final userData = await ApiService.getUserRegistration(email);
      if (userData != null && userData['current_availability_status'] == 'available') {
        // Fetch the latest availability log without end_time
        final logData = await ApiService.getLatestAvailabilityLog(email);

        if (logData != null) {
          setState(() {
            _isAvailable = true;
            _startTime = DateTime.parse(logData['availability_start_time']);
          });
          _startTimer();
        } else {
          // User is marked as available but no active log found
          // This is a data inconsistency - show as available but without timer
          print('Warning: User marked as available but no active log found');
          setState(() {
            _isAvailable = true;
            _startTime = null; // No timer will be shown
          });
          _timer?.cancel();
        }
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

    print('\n========== TOGGLE AVAILABILITY START ==========');
    print('Current status: ${_isAvailable ? "Available" : "Not Available"}');
    print('New status: ${newStatus ? "Available" : "Not Available"}');
    print('User email: $email');
    print('Current _startTime: $_startTime');

    try {
      // Step 1: Update registrations table
      final statusString = newStatus ? 'available' : 'not-available';
      print('\n📝 Step 1: Updating registrations table...');
      final statusUpdated = await ApiService.updateAvailabilityStatus(email, statusString);
      print('Status update result: $statusUpdated');

      if (newStatus) {
        // BECOMING AVAILABLE
        print('\n✨ BRANCH: User is becoming AVAILABLE');

        // Step 2: Check for existing open logs
        print('\n🔍 Step 2: Checking for existing open logs...');
        final existingLog = await ApiService.getLatestAvailabilityLog(email);
        print('Existing log: $existingLog');

        if (existingLog != null) {
          print('Existing log found!');
          print('  - start_time: ${existingLog['availability_start_time']}');
          print('  - end_time: ${existingLog['end_time']}');

          if (existingLog['end_time'] == null) {
            // Found an open log - close it first
            print('\n⚠️ Step 3: Found UNCLOSED log, closing it first...');
            final oldStartTime = existingLog['availability_start_time'];
            print('Old start_time: $oldStartTime');

            final closeResult = await ApiService.updateAvailabilityLogEndTime(
              email,
              oldStartTime,
              DateTime.now().toIso8601String()
            );
            print('Close result: $closeResult');
          } else {
            print('\n✅ Step 3: Existing log is already closed, no need to close');
          }
        } else {
          print('\n✅ Step 3: No existing logs found');
        }

        // Step 4: Create new availability log
        print('\n📝 Step 4: Creating NEW availability log...');
        _startTime = DateTime.now();
        print('New _startTime: $_startTime');

        final userData = await ApiService.getUserRegistration(email);
        final policeStation = userData?['police_station'];
        print('Police station: $policeStation');

        if (policeStation != null) {
          final logData = {
            'user_email': email,
            'police_station': policeStation,
            'date': DateTime.now().toIso8601String().split('T')[0],
            'availability_start_time': _startTime!.toIso8601String(),
          };
          print('Log data: $logData');

          final createResult = await ApiService.createAvailabilityLog(logData);
          print('Create log result: $createResult');

          if (createResult) {
            print('✅ Successfully created new availability log');
          } else {
            print('❌ Failed to create new availability log');
          }
        } else {
          print('❌ Police station is null, cannot create log');
        }

        _startTimer();
        print('Started timer');

      } else {
        // BECOMING UNAVAILABLE
        print('\n🛑 BRANCH: User is becoming NOT AVAILABLE');

        // Step 2: Update end time
        print('\n📝 Step 2: Updating end_time...');
        print('_startTime is null: ${_startTime == null}');

        if (_startTime != null) {
          final startTimeStr = _startTime!.toIso8601String();
          final endTimeStr = DateTime.now().toIso8601String();
          print('  - start_time: $startTimeStr');
          print('  - end_time: $endTimeStr');

          final updateResult = await ApiService.updateAvailabilityLogEndTime(
            email,
            startTimeStr,
            endTimeStr
          );
          print('Update end_time result: $updateResult');

          if (updateResult) {
            print('✅ Successfully updated end_time');
          } else {
            print('❌ Failed to update end_time');
          }
        } else {
          print('❌ Cannot update end_time - _startTime is null!');
          print('This means we don\'t have a log to close');
        }

        _timer?.cancel();
        _elapsedTime = Duration.zero;
        _startTime = null;
        print('Timer cancelled and reset');
      }

      setState(() {
        _isAvailable = newStatus;
      });

      print('\n✅ Final State: ${_isAvailable ? "Available" : "Not Available"}');
      print('========== TOGGLE AVAILABILITY END ==========\n');

    } catch (e, stackTrace) {
      print('\n❌❌❌ ERROR in _toggleAvailability ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==============================================\n');
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
              await ApiService.logout();
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
                            if (isAvailable && _startTime != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (isAvailable && _startTime == null) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Active',
                                style: TextStyle(
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