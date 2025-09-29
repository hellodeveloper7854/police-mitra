import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class ContactPoliceScreen extends StatefulWidget {
  const ContactPoliceScreen({super.key});

  @override
  State<ContactPoliceScreen> createState() => _ContactPoliceScreenState();
}

class _ContactPoliceScreenState extends State<ContactPoliceScreen> {
  String? policeStation;
  List<Map<String, dynamic>> contacts = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        setState(() => error = 'User not logged in');
        return;
      }

      final reg = await Supabase.instance.client
          .from('registrations')
          .select('police_station')
          .eq('email', email)
          .maybeSingle();

      if (reg == null) {
        setState(() => error = 'User registration not found');
        return;
      }

      final station = reg['police_station'] as String?;
      if (station == null) {
        setState(() => error = 'Police station not found');
        return;
      }

      setState(() => policeStation = station);

      final contactsData = await Supabase.instance.client
          .from('station_contacts')
          .select('*')
          .eq('police_station', policeStation!);

      setState(() => contacts = List<Map<String, dynamic>>.from(contactsData));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error
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
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
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
                  // const Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       'भारतीय पुलिस',
                  //       style: TextStyle(
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w500,
                  //         color: Colors.black87,
                  //       ),
                  //     ),
                  //     Text(
                  //       'INDIAN POLICE',
                  //       style: TextStyle(
                  //         fontSize: 10,
                  //         color: Colors.black54,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Police Station',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B46C1), // Purple color
                ),
              ),
              const SizedBox(height: 30),

              // Station Name
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                Text(
                  policeStation ?? 'Unknown Station',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 20),

              // Police Officers List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(
                            child: Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : contacts.isEmpty
                            ? const Center(
                                child: Text(
                                  'Data is not existing',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: contacts.length,
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return Column(
                                    children: [
                                      _buildOfficerCard(contact),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FooterWidget(),
    );
  }

  Widget _buildOfficerCard(Map<String, dynamic> contact) {
    final name = contact['name'] ?? 'Unknown';
    final phone = contact['phone_number'] ?? '';
    final role = contact['role'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          // Police Officer Avatar
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
                'assets/images/police_officer.png', // You can use a police officer image
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Officer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$role $name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Call Button
          GestureDetector(
            onTap: () => _makeCall(phone),
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E), // Green color
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}