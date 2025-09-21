import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Thank You', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.purple),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              GoRouter.of(context).go('/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.purple),
            tooltip: 'My Profile',
            onPressed: () => context.go('/profile'),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.check_circle_outline, color: Colors.purple, size: 96),
              const SizedBox(height: 24),
              const Text(
                'Thanks for enrolling!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your application is under verification. Please wait for some time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Spacer(),
              // const SizedBox(height: 24),
              // _buildCard('Other Helpline', Icons.headset_mic, Colors.grey[600]!, () {
              //   context.go('/helpline');
              // }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go to Sign In'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
