import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/community_notification_service.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.black,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) return;

      // Count unread regular notifications
      final regularResponse = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_email', email)
          .eq('is_read', false);

      int regularCount = regularResponse.length;

      // Count pending notifications that require replies
      final pendingNotifications = await CommunityNotificationService().getPendingNotifications();
      int pendingCount = pendingNotifications.length;

      // Total unread count
      final totalCount = regularCount + pendingCount;

      if (mounted) {
        setState(() {
          _unreadCount = totalCount;
        });
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: widget.iconColor,
          onPressed: () async {
            // Navigate to notifications screen
            context.push('/notifications');
            // Refresh count after viewing
            await Future.delayed(const Duration(milliseconds: 500));
            _fetchUnreadCount();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
