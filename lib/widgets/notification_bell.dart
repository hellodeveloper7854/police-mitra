import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;
  final bool includeCommunityNotifications;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.black,
    this.includeCommunityNotifications = false,
  });

  @override
  State<NotificationBell> createState() => NotificationBellState();
}

// Global key to access the NotificationBell state from outside
final GlobalKey<NotificationBellState> notificationBellKey = GlobalKey<NotificationBellState>();

class NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app returns to foreground
      _fetchUnreadCount();
    }
  }

  // Public method to refresh count
  void refreshCount() {
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) return;

      // Count unread regular notifications from notifications table
      final regularResponse = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_email', email)
          .eq('is_read', false);

      int regularCount = regularResponse.length;

      int pendingCount = 0;

      // Count pending community notifications that need replies
      if (widget.includeCommunityNotifications) {
        try {
          // Get all community notification IDs sent to this user
          final recipientsResponse = await Supabase.instance.client
              .from('notification_recipients')
              .select('notification_id')
              .eq('user_email', email)
              .eq('sent_status', 'sent');

          if (recipientsResponse.isNotEmpty) {
            final notificationIds = recipientsResponse
                .map((r) => r['notification_id'] as int)
                .toList();

            // Check which ones don't have replies yet
            for (var notificationId in notificationIds) {
              final hasReply = await Supabase.instance.client
                  .from('notification_replies')
                  .select('id')
                  .eq('notification_id', notificationId)
                  .eq('user_email', email)
                  .maybeSingle();

              if (hasReply == null) {
                pendingCount++;
              }
            }
          }
        } catch (e) {
          print('Error fetching pending community notifications: $e');
        }
      }

      // Total unread count
      final totalCount = regularCount + pendingCount;

      if (mounted) {
        setState(() {
          _unreadCount = totalCount;
        });
      }

      print('🔔 Notification count: $totalCount (regular: $regularCount, pending: $pendingCount)');
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
            // Navigate to notifications screen with flag
            context.push('/notifications?includeCommunity=${widget.includeCommunityNotifications}');
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
