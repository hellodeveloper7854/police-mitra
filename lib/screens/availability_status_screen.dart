import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AvailabilityStatusScreen extends StatefulWidget {
  const AvailabilityStatusScreen({super.key});

  @override
  State<AvailabilityStatusScreen> createState() => _AvailabilityStatusScreenState();
}

class _AvailabilityStatusScreenState extends State<AvailabilityStatusScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _availabilityLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailabilityLogs();
  }

  Future<void> _fetchAvailabilityLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('availability_logs')
          .select('*')
          .eq('user_email', user.email!)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      _availabilityLogs = List<Map<String, dynamic>>.from(response);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load availability logs: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.push('/profile'),
        ),
        title: const Text(
          'Availability Status',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  width: 60,
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 40),

            // Title
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'My ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Availability',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B46C1), // Purple color
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchAvailabilityLogs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _availabilityLogs.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Text(
                                  'No availability logs found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _availabilityLogs.length,
                              itemBuilder: (context, index) {
                                final log = _availabilityLogs[index];
                                return _buildAvailabilityCard(log);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard(Map<String, dynamic> log) {
    final dateString = log['date'] as String?;
    final startTimeString = log['availability_start_time'] as String?;
    final endTimeString = log['end_time'] as String?;
    final createdAtString = log['created_at'] as String?;

    String formattedDate = 'N/A';
    if (dateString != null) {
      try {
        final date = DateTime.parse(dateString);
        formattedDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        formattedDate = dateString;
      }
    }

    String formattedStartTime = 'N/A';
    if (startTimeString != null) {
      try {
        final startTime = DateTime.parse(startTimeString);
        formattedStartTime = DateFormat('HH:mm').format(startTime);
      } catch (e) {
        formattedStartTime = startTimeString;
      }
    }

    String formattedEndTime = 'N/A';
    if (endTimeString != null) {
      try {
        final endTime = DateTime.parse(endTimeString);
        formattedEndTime = DateFormat('HH:mm').format(endTime);
      } catch (e) {
        formattedEndTime = endTimeString;
      }
    }

    String formattedCreatedAt = 'N/A';
    if (createdAtString != null) {
      try {
        final createdAt = DateTime.parse(createdAtString);
        formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
      } catch (e) {
        formattedCreatedAt = createdAtString;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF6B46C1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Date: $formattedDate',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Start Time: $formattedStartTime',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'End Time: $formattedEndTime',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Text(
          //   'Logged at: $formattedCreatedAt',
          //   style: const TextStyle(
          //     fontSize: 12,
          //     color: Colors.grey,
          //   ),
          // ),
        ],
      ),
    );
  }
}