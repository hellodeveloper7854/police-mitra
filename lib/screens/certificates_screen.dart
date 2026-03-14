import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../utils/certificate_generator.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompletedServices();
  }

  Future<void> _fetchCompletedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> allCertificates = [];

      // Fetch from work_certificates table (new certificates)
      try {
        final workCertsResponse = await Supabase.instance.client
            .from('work_certificates')
            .select('*')
            .eq('user_email', email)
            .order('issued_at', ascending: false);

        final workCerts = List<Map<String, dynamic>>.from(workCertsResponse);
        print('✅ Found ${workCerts.length} certificates in work_certificates table');
        allCertificates.addAll(workCerts);
      } catch (e) {
        print('⚠️ Error fetching from work_certificates: $e');
      }

      // Also fetch from assigned_services table (old certificates for backward compatibility)
      try {
        final assignedServicesResponse = await Supabase.instance.client
            .from('assigned_services')
            .select('*')
            .eq('user_email', email)
            .not('end_time', 'is', null)
            .order('assigned_date', ascending: false);

        final assignedServices = List<Map<String, dynamic>>.from(assignedServicesResponse);
        print('✅ Found ${assignedServices.length} completed services in assigned_services table');

        // Convert assigned services to certificate format
        for (var service in assignedServices) {
          allCertificates.add({
            'certificate_id': service['id'].toString(),
            'user_name': null, // Will fetch from service
            'user_email': email,
            'police_station': service['location'] ?? 'Thane City',
            'total_hours': 0, // Will calculate
            'issued_at': service['end_time'],
            'service_name': service['service_name'],
            'participation_area': service['participation_area'],
            'assigned_date': service['assigned_date'],
            'start_time': service['start_time'],
            'end_time': service['end_time'],
            'is_from_assigned_services': true, // Mark as old certificate
          });
        }
      } catch (e) {
        print('⚠️ Error fetching from assigned_services: $e');
      }

      print('📊 Total certificates to display: ${allCertificates.length}');

      setState(() {
        _certificates = allCertificates;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching certificates: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificate(Map<String, dynamic> certificate) async {
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

      // Check if this is from assigned_services (old certificate)
      final isFromAssignedServices = certificate['is_from_assigned_services'] == true;

      String userName;
      String serviceName;
      String participationArea;
      String formattedDate;
      String location;
      String durationText;

      if (isFromAssignedServices) {
        // Handle old certificate from assigned_services
        final userResponse = await Supabase.instance.client
            .from('registrations')
            .select('full_name')
            .eq('email', email)
            .maybeSingle();

        userName = userResponse?['full_name'] ?? 'Volunteer';
        serviceName = certificate['service_name'] ?? 'Police Service';
        participationArea = _mapEnumToParticipation(certificate['participation_area'] ?? '');

        final dateString = certificate['assigned_date'] as String?;
        if (dateString == null) return;

        final serviceDate = DateTime.parse(dateString);
        formattedDate = DateFormat('dd MMMM, yyyy').format(serviceDate);

        location = certificate['location'] ?? 'Thane City';

        // Calculate duration
        if (certificate['start_time'] != null && certificate['end_time'] != null) {
          final startTime = DateTime.parse(certificate['start_time']);
          final endTime = DateTime.parse(certificate['end_time']);
          final duration = endTime.difference(startTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);
          durationText = '${hours}h ${minutes}m';
        } else {
          durationText = 'N/A';
        }
      } else {
        // Handle new certificate from work_certificates
        userName = certificate['user_name'] ?? 'Volunteer';
        serviceName = 'Police Service Certificate';
        participationArea = 'Community Service';

        final issuedAtString = certificate['issued_at'] as String?;
        if (issuedAtString == null) return;

        final issuedAt = DateTime.parse(issuedAtString);
        formattedDate = DateFormat('dd MMMM, yyyy').format(issuedAt);

        location = certificate['police_station'] ?? 'Thane City';
        final totalHours = certificate['total_hours'] ?? 0;
        durationText = '${totalHours}h';
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
        serviceName: serviceName,
        participationArea: participationArea,
        date: formattedDate,
        location: location,
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

  Future<void> _onBackPressed() async {
    context.push('/settings');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return false;
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
          onRefresh: _fetchCompletedServices,
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
                      height: 80,
                      width: 80,
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
                        text: 'Certificates',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Download your service certificates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // Certificates List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading certificates',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchCompletedServices,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _certificates.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.card_membership,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No certificates yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Complete services to earn certificates',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _certificates.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildCertificateCard(_certificates[index]),
                                    );
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

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    // Check if this is from assigned_services (old certificate)
    final isFromAssignedServices = certificate['is_from_assigned_services'] == true;

    String certificateId;
    String displayTitle;
    String displaySubtitle;
    String hoursDisplay;
    String locationDisplay;
    String dateDisplay;
    String bannerText;

    if (isFromAssignedServices) {
      // Old certificate from assigned_services
      certificateId = certificate['certificate_id'] ?? 'N/A';
      displayTitle = certificate['service_name'] ?? 'Police Service';
      displaySubtitle = _mapEnumToParticipation(certificate['participation_area'] ?? '');

      final dateString = certificate['assigned_date'] as String?;
      if (dateString == null) return const SizedBox.shrink();
      final serviceDate = DateTime.parse(dateString);
      dateDisplay = DateFormat('dd MMM, yyyy').format(serviceDate);

      // Calculate duration
      if (certificate['start_time'] != null && certificate['end_time'] != null) {
        final startTime = DateTime.parse(certificate['start_time']);
        final endTime = DateTime.parse(certificate['end_time']);
        final duration = endTime.difference(startTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        hoursDisplay = '${hours}h ${minutes}m';
      } else {
        hoursDisplay = 'N/A';
      }

      locationDisplay = certificate['location'] ?? 'Thane City';
      bannerText = 'Service Certificate';
    } else {
      // New certificate from work_certificates
      certificateId = certificate['certificate_id'] ?? 'N/A';
      displayTitle = 'Police Service Certificate';
      displaySubtitle = 'Community Service';

      final issuedAtString = certificate['issued_at'] as String?;
      if (issuedAtString == null) return const SizedBox.shrink();

      final issuedAt = DateTime.parse(issuedAtString);
      dateDisplay = DateFormat('dd MMM, yyyy').format(issuedAt);

      final totalHours = certificate['total_hours'] ?? 0;
      hoursDisplay = '${totalHours}h';

      locationDisplay = certificate['police_station'] ?? 'Unknown Station';
      bannerText = 'Work Certificate';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for certificate type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bannerText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Certificate header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFromAssignedServices) ...[
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displaySubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      isFromAssignedServices ? 'Completed: $dateDisplay' : 'Issued: $dateDisplay',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _downloadCertificate(certificate),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simple details without background
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Hours: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                hoursDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: Text(
                  locationDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
