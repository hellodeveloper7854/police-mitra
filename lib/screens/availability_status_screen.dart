import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class AvailabilityStatusScreen extends StatefulWidget {
  const AvailabilityStatusScreen({super.key});

  @override
  State<AvailabilityStatusScreen> createState() => _AvailabilityStatusScreenState();
}

class _AvailabilityStatusScreenState extends State<AvailabilityStatusScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _availabilityLogs = [];
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _filteredLogs = [];
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchAvailabilityLogs();
  }

  Future<void> _onBackPressed() async {
    // Navigate back to settings (Account page) instead of dashboard
    context.push('/settings');
  }

  Future<void> _fetchAvailabilityLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('availability_logs')
          .select('*')
          .eq('user_email', email)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      _availabilityLogs = List<Map<String, dynamic>>.from(response);

      // Calculate total duration from all logs that have both start and end time
      _calculateTotalDuration();

      _updateFilteredLogs();

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

  void _calculateTotalDuration() {
    int totalSeconds = 0;

    for (final log in _availabilityLogs) {
      final startTime = log['availability_start_time'];
      final endTime = log['end_time'];

      if (startTime != null && endTime != null) {
        try {
          final start = DateTime.parse(startTime);
          final end = DateTime.parse(endTime);
          final difference = end.difference(start);
          totalSeconds += difference.inSeconds;
        } catch (e) {
          print('Error parsing duration for log ${log['id']}: $e');
        }
      }
    }

    setState(() {
      _totalDuration = Duration(seconds: totalSeconds);
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  void _updateFilteredLogs() {
    if (_selectedDate == null) {
      _filteredLogs = _availabilityLogs.take(5).toList();
    } else {
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      _filteredLogs = _availabilityLogs.where((log) => log['date'] == selectedDateStr).toList();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateFilteredLogs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return false; // Prevent default back
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _onBackPressed,
        ),
        title: const Text(
          'Availability Status',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAvailabilityLogs,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 30),

              // Total Hours Served Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B46C1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Hours Served',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'as Police Mitra',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

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

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectDate,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text(
                        _selectedDate == null ? 'Select Date' : 'Selected: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _updateFilteredLogs();
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

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
                        : _filteredLogs.isEmpty
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
                                itemCount: _filteredLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _filteredLogs[index];
                                  return _buildAvailabilityCard(log);
                                },
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

    DateTime? startTimeParsed;
    String formattedStartTime = 'N/A';
    if (startTimeString != null) {
      try {
        startTimeParsed = DateTime.parse(startTimeString);
        formattedStartTime = DateFormat('HH:mm').format(startTimeParsed!);
      } catch (e) {
        formattedStartTime = startTimeString;
      }
    }

    DateTime? endTimeParsed;
    String formattedEndTime = 'N/A';
    if (endTimeString != null) {
      try {
        endTimeParsed = DateTime.parse(endTimeString);
        formattedEndTime = DateFormat('HH:mm').format(endTimeParsed!);
      } catch (e) {
        formattedEndTime = endTimeString;
      }
    }

    String durationText = 'N/A';
    if (startTimeParsed != null && endTimeParsed != null) {
      final duration = endTimeParsed.difference(startTimeParsed);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      durationText = '${hours}h ${minutes}m ${seconds}s';
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
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Duration: $durationText',
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