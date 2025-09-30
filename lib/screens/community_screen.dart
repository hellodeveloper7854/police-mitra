import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/footer.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'पोलीस मित्र',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.push('/dashboard'),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B46C1),
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Something exciting is on the way',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              const Text(
                'We\'re working hard to bring you an amazing community experience. Stay tuned for updates!',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9E9E9E),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Decorative elements
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(Colors.purple[200]!),
                  const SizedBox(width: 8),
                  _buildDot(Colors.purple[400]!),
                  const SizedBox(width: 8),
                  _buildDot(Colors.purple[600]!),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FooterWidget(),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }






}