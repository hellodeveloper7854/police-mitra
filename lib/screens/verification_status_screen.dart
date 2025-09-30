import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  String? _message;
  String? _status;
  String? _rejectionReason;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        setState(() {
          _message = 'Please sign in to view your verification status.';
          _loading = false;
        });
        return;
      }

      // Fetch registration by email and read the latest status
      final res = await Supabase.instance.client
          .from('registrations')
          .select('verification_status, rejection_reason')
          .eq('email', email)
          .order('created_at', ascending: false)
          .limit(1);
      String? status;
      if (res is List && res.isNotEmpty && res.first is Map) {
        status = (res.first as Map)['verification_status']?.toString();
        _rejectionReason = (res.first as Map)['rejection_reason']?.toString();
      }

      // Normalize and decide
      final normalized = (status ?? 'pending').toString().trim().toLowerCase();
      _status = normalized;
      if (normalized == 'verified' || normalized == 'approve' || normalized == 'approved') {
        _message = 'Your account has been verified. App is in development.';
      } else if (normalized == 'rejected') {
        _message = 'Your application has been rejected.' +
            (_rejectionReason != null && _rejectionReason!.isNotEmpty ? ' Reason: $_rejectionReason' : '');
      } else {
        _message = status == null
            ? 'We could not find your registration record. If you just signed up, please wait a moment and try again.'
            : 'Application is under verification. Please wait for some time for the admin approval.';
      }
    } catch (e) {
      _message = 'Failed to load verification status: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getStatusIcon() {
    if (_status == 'rejected') {
      return Icons.cancel;
    } else {
      return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png', height: 80, width: 80),
        ),
        title: const Text('Status', style: TextStyle(color: Colors.black)),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.purple),
            tooltip: 'My Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.purple),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_email');
              if (mounted) GoRouter.of(context).go('/login');
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.purple)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getStatusIcon(), color: _status == 'rejected' ? Colors.red : Colors.purple, size: 96),
                        const SizedBox(height: 24),
                        Text(
                          _message ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        if (_status == 'verified' || _status == 'approve' || _status == 'approved') ...[
                          _buildCard('Other Helpline', Icons.headset_mic, Colors.grey[600]!, () {
                            context.push('/helpline');
                          }),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const FooterWidget(),
    );
  }

  Widget _buildCard(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/helpline.png', width: 90, height: 90),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
