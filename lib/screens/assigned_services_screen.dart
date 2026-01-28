import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../utils/certificate_generator.dart';

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

  Future<void> _onBackPressed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        if (mounted) context.go('/login');
        return;
      }

      final user = await Supabase.instance.client
          .from('registrations')
          .select('verification_status')
          .eq('email', email)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final normalized =
          (user?['verification_status'] ?? '').toString().trim().toLowerCase();

      if (normalized == 'verified' ||
          normalized == 'approve' ||
          normalized == 'approved') {
        context.go('/dashboard');
      } else {
        context.go('/status');
      }
    } catch (e) {
      print('ERROR: Back navigation failed - $e');
      context.go('/login');
    }
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

  Future<void> _updateParticipationStatus(String serviceId, String status, {String? reason}) async {
    try {
      final Map<String, dynamic> updateData = {'participation_status': status};
      if (reason != null) {
        updateData['non_participation_reason'] = reason;
      } else if (status != 'declined') {
        updateData['non_participation_reason'] = null;
      }

      await Supabase.instance.client
          .from('assigned_services')
          .update(updateData)
          .eq('id', serviceId);

      _fetchAssignedServices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Participation status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update participation status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadCertificate(Map<String, dynamic> service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userResponse = await Supabase.instance.client
          .from('registrations')
          .select('full_name')
          .eq('email', email)
          .maybeSingle();

      final userName = userResponse?['full_name'] ?? 'Volunteer';

      final dateString = service['assigned_date'] as String?;
      if (dateString == null) return;

      final serviceDate = DateTime.parse(dateString);
      final formattedDate = DateFormat('dd MMMM, yyyy').format(serviceDate);

      String durationText = 'N/A';
      if (service['start_time'] != null && service['end_time'] != null) {
        final startTime = DateTime.parse(service['start_time']);
        final endTime = DateTime.parse(service['end_time']);
        final duration = endTime.difference(startTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        durationText = '${hours}h ${minutes}m';
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await CertificateGenerator.generateAndDownloadCertificate(
        userName: userName,
        serviceName: service['service_name'] ?? 'Police Service',
        participationArea: _mapEnumToParticipation(service['participation_area'] ?? ''),
        date: formattedDate,
        location: service['location'] ?? 'Thane City',
        duration: durationText,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate certificate: $e'),
            backgroundColor: Colors.red,
          ),
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
          .order('assigned_date', ascending: false);

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

  String _formatParticipationStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Response';
      case 'confirmed':
        return 'Can Participate';
      case 'declined':
        return 'Cannot Participate';
      default:
        return 'Pending Response';
    }
  }

  
  void _showReasonDialog(String serviceId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reason for Non-Participation'),
          content: SizedBox(
            width: double.infinity,
            child: TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Please provide a reason why you cannot participate... (Optional)',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Reason is now optional - submit regardless of whether reason is provided
                _updateParticipationStatus(
                  serviceId,
                  'declined',
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim()
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () => context.push('/settings'),
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
                    height: 100,
                    width: 100,
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
                                  ..._upcomingServices.map((service) => _buildServiceCard(service, isUpcomingService: true)),
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
    ),
    );
  }

  
  Widget _buildParticipationStatusWidget(Map<String, dynamic> service) {
    final participationStatus = service['participation_status'] as String? ?? '';
    final nonParticipationReason = service['non_participation_reason'] as String?;

    // If no status selected, show dropdown
    if (participationStatus.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: null,
            hint: Text('Select participation status', style: TextStyle(fontSize: 12)),
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            items: [
              DropdownMenuItem(
                value: 'confirmed',
                child: Text('I can participate', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: 'declined',
                child: Text('I can\'t participate', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                if (value == 'declined') {
                  _showReasonDialog(service['id'].toString());
                } else {
                  _updateParticipationStatus(service['id'].toString(), value);
                }
              }
            },
          ),
        ),
      );
    }

    // If status is selected, show non-editable status display
    List<Widget> children = [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: participationStatus == 'confirmed'
              ? Colors.green.shade50
              : Colors.red.shade50,
          border: Border.all(
            color: participationStatus == 'confirmed'
                ? Colors.green.shade300
                : Colors.red.shade300,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              participationStatus == 'confirmed'
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 16,
              color: participationStatus == 'confirmed'
                  ? Colors.green.shade600
                  : Colors.red.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                participationStatus == 'confirmed'
                    ? 'I can participate'
                    : 'I can\'t participate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: participationStatus == 'confirmed'
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    // Add reason display if declined and reason is provided
    if (participationStatus == 'declined' &&
        nonParticipationReason != null &&
        nonParticipationReason.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
              const SizedBox(width: 4),
              Text(
                'Reason:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  nonParticipationReason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, {bool isTodayService = false, bool isUpcomingService = false}) {
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

                    // Participation Status for Today's and Upcoming Services
                    
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
                      // Check if participation status is declined
                      if (service['participation_status'] == 'declined')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Not Participating',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _startService(service['id'].toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
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
                          backgroundColor: const Color(0xFFEF4444),
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

              // Certificate Download Button for Completed Services
              if (!isTodayService && !isUpcomingService && service['end_time'] != null) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadCertificate(service),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Certificate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (isTodayService || isUpcomingService) ...[
                      const SizedBox(height: 8),
                      _buildParticipationStatusWidget(service),
                    ],
        ],
      ),
    );
    
  }

}