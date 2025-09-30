import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class AssignedServicesScreen extends StatefulWidget {
  const AssignedServicesScreen({super.key});

  @override
  State<AssignedServicesScreen> createState() => _AssignedServicesScreenState();
}

class _AssignedServicesScreenState extends State<AssignedServicesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _todayServices = [];
  List<Map<String, dynamic>> _upcomingServices = [];
  List<Map<String, dynamic>> _completedServices = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignedServices();
  }

  Future<void> _startService(String serviceId) async {
    try {
      // Get current time in IST (UTC + 5:30)
      final nowIST = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final istTimeString = nowIST.toIso8601String();

      await Supabase.instance.client
          .from('assigned_services')
          .update({'start_time': istTimeString})
          .eq('id', serviceId);

      _fetchAssignedServices(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start service: $e')),
        );
      }
    }
  }

  Future<void> _endService(String serviceId) async {
    try {
      // Get current time in IST (UTC + 5:30)
      final nowIST = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final istTimeString = nowIST.toIso8601String();

      await Supabase.instance.client
          .from('assigned_services')
          .update({
            'end_time': istTimeString,
            'status': 'completed'
          })
          .eq('id', serviceId);

      _fetchAssignedServices(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end service: $e')),
        );
      }
    }
  }

  Future<void> _fetchAssignedServices() async {
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
          .from('assigned_services')
          .select('*')
          .eq('user_email', email)
          .order('assigned_date', ascending: true);

      final services = List<Map<String, dynamic>>.from(response);

      // Categorize services based on date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      _todayServices.clear();
      _upcomingServices.clear();
      _completedServices.clear();

      for (final service in services) {
        // If service is completed (has end_time), put it in completed regardless of date
        if (service['end_time'] != null) {
          _completedServices.add(service);
          continue;
        }

        final dateString = service['assigned_date'] as String?;
        if (dateString == null) continue;

        final serviceDate = DateTime.parse(dateString);
        final serviceDateOnly = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);

        if (serviceDateOnly.isAtSameMomentAs(today)) {
          _todayServices.add(service);
        } else if (serviceDateOnly.isAfter(today)) {
          _upcomingServices.add(service);
        } else {
          _completedServices.add(service);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load services: $e';
        _isLoading = false;
      });
    }
  }

  String _mapEnumToParticipation(String enumValue) {
    switch (enumValue) {
      case 'traffic_management':
        return 'Traffic Management';
      case 'school_awareness':
        return 'School/College Awareness Programs';
      case 'senior_citizens':
        return 'Senior Citizen Visits';
      case 'social_media_volunteer':
        return 'Social Media Promotion';
      case 'crowd_management':
        return 'Festival Crowd Management';
      default:
        return enumValue;
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
          onPressed: () => context.push('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedServices,
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
                      text: 'Services',
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
                                  onPressed: _fetchAssignedServices,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Today's Services Section
                                if (_todayServices.isNotEmpty) ...[
                                  const Text(
                                    'Today\'s Services',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._todayServices.map((service) => _buildServiceCard(service, isTodayService: true)),
                                  const SizedBox(height: 30),
                                ],

                                // Upcoming Services Section
                                if (_upcomingServices.isNotEmpty) ...[
                                  const Text(
                                    'Upcoming Services',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._upcomingServices.map((service) => _buildServiceCard(service)),
                                  const SizedBox(height: 30),
                                ],

                                // Completed Services Section
                                if (_completedServices.isNotEmpty) ...[
                                  const Text(
                                    'Completed Services',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._completedServices.map((service) => _buildServiceCard(service)),
                                ],

                                // No services message
                                if (_todayServices.isEmpty && _upcomingServices.isEmpty && _completedServices.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40.0),
                                      child: Text(
                                        'No assigned services found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FooterWidget(),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, {bool isTodayService = false}) {
    final dateString = service['assigned_date'] as String?;
    if (dateString == null) return const SizedBox.shrink();

    final serviceDate = DateTime.parse(dateString);
    final formattedDate = DateFormat('dd/MM/yyyy').format(serviceDate);

    // Calculate duration if both start and end times exist
    String? durationText;
    if (service['start_time'] != null && service['end_time'] != null) {
      final startTime = DateTime.parse(service['start_time']);
      final endTime = DateTime.parse(service['end_time']);
      final duration = endTime.difference(startTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      durationText = '${hours}h ${minutes}m ${seconds}s';
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
          // Duration at top right if available
          if (durationText != null) ...[
            Align(
              alignment: Alignment.topRight,
              child: Text(
                durationText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B46C1), // Purple color to match theme
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              // Service Image/Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/event_image.png', // You can use a service image
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF60A5FA),
                              Color(0xFF3B82F6),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event
                    Text(
                      'Event: ${(service['service_name'] as String?) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Participation Area
                    Text(
                      'Participation Area: ${_mapEnumToParticipation((service['participation_area'] as String?) ?? 'N/A')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Date
                    Text(
                      'Date: $formattedDate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Location
                    Text(
                      'Location: ${(service['location'] as String?) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons for Today's Services
              if (isTodayService) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (service['start_time'] == null) ...[
                      ElevatedButton(
                        onPressed: () => _startService(service['id'].toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Start Service'),
                      ),
                    ] else if (service['end_time'] == null) ...[
                      ElevatedButton(
                        onPressed: () => _endService(service['id'].toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), // Red color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('End Service'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

}