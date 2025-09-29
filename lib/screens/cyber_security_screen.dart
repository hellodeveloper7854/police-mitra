import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class CyberSecurityScreen extends StatelessWidget {
  const CyberSecurityScreen({super.key});

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    print('Trying to launch URL: $url');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('URL launched successfully');
    } catch (e) {
      print('Failed to launch URL: $e');
    }
  }

  void _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
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
          onPressed: () => context.push('/helpline'),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings, color: Colors.black),
        //     onPressed: () {},
        //   ),
        // ],
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
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Cyber ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Security',
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // For Cheating Dial Card
                    _buildInfoCard(
                      title: 'For Cheating Dial',
                      onShare: () {
                        print('Sharing For Cheating Dial');
                        Share.share('For Cheating Dial: 1930\nVisit: https://cybercrime.gov.in', subject: 'Cyber Security Helpline');
                      },
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Dial : ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _makeCall('1930'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.call, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        '1930',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Visit : ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _launchURL('https://cybercrime.gov.in'),
                                child: const Text(
                                  'Cybercrime.gov.in',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Facebook Account Hacked Card
                    _buildInfoCard(
                      title: 'How to report Hacked Facebook Account ?',
                      onShare: () {
                        print('Sharing Facebook Hack Report');
                        Share.share('How to report Hacked Facebook Account:\n1. Report on https://www.facebook.com/help/contact/278770247037228 and get ticket number.\n2. If no response after 2 days, report on https://goc.gov.in [IAC - MHA, MeitY etc part of it]', subject: 'Facebook Account Hack Report');
                      },
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Report on ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL('https://www.facebook.com/help/contact/278770247037228'),
                            child: const Text(
                              'https://www.facebook.com/help/contact/278770247037228',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            ' and get ticket number.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '2. If no response, after 2 days, report on ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL('https://goc.gov.in'),
                            child: const Text(
                              'https://goc.gov.in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            '. [IAC - MHA, MeitY etc part of it]',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // WhatsApp Account Hacked Card
                    _buildInfoCard(
                      title: 'How to report Hacked / Impersonating WhatsApp Account ?',
                      onShare: () {
                        print('Sharing WhatsApp Hack Report');
                        Share.share('How to report Hacked / Impersonating WhatsApp Account:\n1. Report on https://www.whatsapp.com/contact/forms/1534459096974129?lang=en_US\n2. If no response after 2 days, report on https://goc.gov.in [IAC - MHA, MeitY etc part of it]', subject: 'WhatsApp Account Hack Report');
                      },
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Report on ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL('https://www.whatsapp.com/contact/forms/15344590969741299'),
                            child: const Text(
                              'https://www.whatsapp.com/contact/forms/15344590969741299',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            '?lang=en_US',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '2. If no response, after 2 days, report on ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL('https://goc.gov.in'),
                            child: const Text(
                              'https://goc.gov.in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            '. [IAC - MHA, MeitY etc part of it]',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content, VoidCallback? onShare}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF), // Light purple background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: onShare,
                icon: const Icon(
                  Icons.share,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}