import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/footer.dart';
import '../widgets/notification_reply_popup.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notificationsWithReplies = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotificationHistory();
  }

  Future<void> _fetchNotificationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      // Fetch all notifications for the user
      final notificationsResponse = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('user_email', email)
          .order('created_at', ascending: false);

      // Fetch all community notifications that were sent to this user
      // This includes both replied and not-replied notifications
      final communityNotificationsResponse = await Supabase.instance.client
          .from('community_notifications')
          .select('''
            id,
            title,
            body,
            sent_at,
            notification_recipients!inner (user_email, id)
          ''')
          .eq('notification_recipients.user_email', email)
          .order('sent_at', ascending: false);

      // Fetch all replies for this user from notification_replies table
      final repliesResponse = await Supabase.instance.client
          .from('notification_replies')
          .select('*')
          .eq('user_email', email)
          .order('replied_at', ascending: false);

      print('📊 Fetched ${notificationsResponse.length} regular notifications');
      print('📊 Fetched ${communityNotificationsResponse.length} community notifications');
      print('📊 Fetched ${repliesResponse.length} replies');

      // Combine and format all data
      List<Map<String, dynamic>> combinedHistory = [];

      // Add regular notifications (these don't have replies)
      for (var notification in notificationsResponse) {
        try {
          combinedHistory.add({
            'id': notification['id'],
            'type': 'regular',
            'title': notification['title'] ?? 'System Notification',
            'message': notification['message'] ?? '',
            'created_at': notification['created_at'],
            'is_read': notification['is_read'] ?? false,
            'reply': null,
            'hasReply': false,
          });
        } catch (e) {
          print('⚠️ Error processing regular notification: $e');
          continue;
        }
      }

      // Add ALL community notifications (both replied and not replied)
      for (var commNotif in communityNotificationsResponse) {
        try {
          final notificationId = commNotif['id'] as int;
          final recipients = commNotif['notification_recipients'] as List?;

          // Safely extract recipient ID
          int? recipientId;
          if (recipients != null && recipients.isNotEmpty) {
            final recipient = recipients[0];
            if (recipient is Map<String, dynamic>) {
              recipientId = recipient['id'] as int?;
            }
          }

          // Find if this user has replied to this notification
          Map<String, dynamic>? userReply;
          try {
            userReply = repliesResponse.firstWhere(
              (reply) => reply['notification_id'] == notificationId,
              orElse: () => null as dynamic,
            ) as Map<String, dynamic>?;
          } catch (e) {
            userReply = null;
          }

          combinedHistory.add({
            'id': notificationId,
            'type': 'community',
            'title': commNotif['title'] ?? 'Community Notification',
            'message': commNotif['body'] ?? '',
            'created_at': commNotif['sent_at'],
            'is_read': true, // Community notifications are always considered read
            'reply': userReply, // Will be null if not replied, or the reply object if replied
            'hasReply': userReply != null, // Boolean flag for easier checking
            'recipient_id': recipientId,
          });
        } catch (e) {
          print('⚠️ Error processing community notification: $e');
          print('⚠️ Notification data: $commNotif');
          // Skip this notification and continue with others
          continue;
        }
      }

      // Sort by created_at descending (newest first)
      combinedHistory.sort((a, b) {
        final aDate = DateTime.parse(a['created_at']);
        final bDate = DateTime.parse(b['created_at']);
        return bDate.compareTo(aDate);
      });

      print('✅ Total combined history: ${combinedHistory.length} items');

      setState(() {
        _notificationsWithReplies = combinedHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching notification history: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toUtc();
      final istTime = dateTime.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatReplyTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toUtc();
      final istTime = dateTime.add(const Duration(hours: 5, minutes: 30));
      final now = DateTime.now();
      final difference = now.difference(istTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('dd MMM yyyy').format(istTime);
      }
    } catch (e) {
      return timestamp;
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
      case 'community':
        return Icons.campaign;
      case 'regular':
      default:
        return Icons.notifications;
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
      case 'community':
        return const Color(0xFF3B82F6);
      case 'regular':
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40, width: 40),
            const SizedBox(width: 8),
            const Text(
              'Notification History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _fetchNotificationHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading history',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchNotificationHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _notificationsWithReplies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notification history',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your notification history will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotificationHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        itemCount: _notificationsWithReplies.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _notificationsWithReplies[index];
                          final type = item['type'] as String;
                          final hasReply = item['hasReply'] == true;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Notification header
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getNotificationColor(type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getNotificationIcon(type),
                                          color: _getNotificationColor(type),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'] as String,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['message'] as String,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Timestamp
                                  Text(
                                    _formatTimestamp(item['created_at'] as String),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),

                                  // Reply section (if exists)
                                  if (hasReply && item['reply'] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade700,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'REPLIED',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (item['reply']?['replied_at'] != null)
                                                Text(
                                                  'Replied ${_formatReplyTimestamp(item['reply']['replied_at'] as String)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              item['reply']?['reply_message']?.toString() ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade800,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (type == 'community') ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () async {
                                        // Open reply popup for pending notifications
                                        final replyPopupResult = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => NotificationReplyPopup(
                                            notification: item,
                                            onReplySubmitted: () {
                                              // Refresh the list after reply
                                              _fetchNotificationHistory();
                                            },
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade700,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.pending_actions,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'PENDING REPLY',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.orange.shade700,
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Tap here to reply to this notification',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.orange.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.orange.shade700,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: const FooterWidget(),
    );
  }
}
