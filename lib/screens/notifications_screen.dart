import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/footer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
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

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('user_email', email)
          .order('created_at', ascending: false);

      final notifications = List<Map<String, dynamic>>.from(response);

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // Mark all as read when fetched
      await _markAllAsRead(email);
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead(String email) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_email', email)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      _fetchNotifications();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email != null) {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('user_email', email);

        _fetchNotifications();
      }
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'service_assigned':
        return Icons.assignment;
      case 'community_post':
        return Icons.people;
      case 'new_resource':
        return Icons.library_books;
      case 'system_message':
        return Icons.notifications;
      default:
        return Icons.notification_important;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'service_assigned':
        return const Color(0xFF6B46C1);
      case 'community_post':
        return const Color(0xFFF5C563);
      case 'new_resource':
        return const Color(0xFF10B981);
      case 'system_message':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
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
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_notifications.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All'),
                      content: const Text('Are you sure you want to clear all notifications?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _clearAllNotifications();
                  }
                },
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final type = notification['type'] as String? ?? 'system_message';
                        final isRead = notification['is_read'] as bool? ?? false;

                        return Dismissible(
                          key: Key(notification['id'].toString()),
                          onDismissed: (direction) {
                            _deleteNotification(notification['id'].toString());
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead ? Colors.grey.shade300 : Colors.blue.shade200,
                                width: isRead ? 1 : 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['title'] as String? ?? 'Notification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isRead ? Colors.grey.shade700 : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'] as String? ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTimestamp(notification['created_at'] as String? ?? ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        bottomNavigationBar: const FooterWidget(),
      ),
    );
  }
}
