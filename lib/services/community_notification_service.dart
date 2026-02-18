import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityNotificationService {
  static final CommunityNotificationService _instance =
      CommunityNotificationService._internal();
  factory CommunityNotificationService() => _instance;
  CommunityNotificationService._internal();

  // Get pending notifications that require user reply from Supabase
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        if (kDebugMode) {
          print('⚠️ No user email found');
        }
        return [];
      }

      if (kDebugMode) {
        print('🔍 Fetching pending notifications from Supabase for: $email');
      }

      // Use the optimized method
      return await getPendingNotificationsOptimized();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching pending notifications from Supabase: $e');
      }
      return [];
    }
  }

  // Check if notification exists for user in notification_recipients
  Future<bool> hasNotificationReceived(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) return false;

      final response = await Supabase.instance.client
          .from('notification_recipients')
          .select()
          .eq('notification_id', notificationId)
          .eq('user_email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking notification: $e');
      }
      return false;
    }
  }

  // Check if user has replied to a specific notification
  Future<bool> hasReplied(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) return false;

      final response = await Supabase.instance.client
          .from('notification_replies')
          .select()
          .eq('notification_id', notificationId)
          .eq('user_email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking reply status: $e');
      }
      return false;
    }
  }

  // Submit reply to a notification using Supabase
  Future<bool> submitReply({
    required int notificationId,
    required String replyText,
    String? userName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');

      if (userEmail == null) {
        if (kDebugMode) {
          print('⚠️ No user email found');
        }
        return false;
      }

      if (kDebugMode) {
        print('📝 Submitting reply for notification: $notificationId');
        print('📝 Reply text: $replyText');
        print('📝 User email: $userEmail');
      }

      // Check if reply already exists
      final existingReply = await Supabase.instance.client
          .from('notification_replies')
          .select()
          .eq('notification_id', notificationId)
          .eq('user_email', userEmail)
          .maybeSingle();

      if (existingReply != null) {
        if (kDebugMode) {
          print('⚠️ Reply already exists for this notification');
        }
        return false;
      }

      // Get user details from registrations table
      final userDetails = await Supabase.instance.client
          .from('registrations')
          .select('full_name')
          .eq('email', userEmail)
          .maybeSingle();

      final finalUserName = userName ?? (userDetails?['full_name'] ?? 'Unknown');

      // Insert the reply with correct column names
      final response = await Supabase.instance.client
          .from('notification_replies')
          .insert({
            'notification_id': notificationId,
            'user_id': userEmail, // Using email as user_id
            'user_name': finalUserName,
            'user_email': userEmail,
            'reply_message': replyText, // Changed from reply_text to reply_message
          })
          .select();

      if (kDebugMode) {
        print('✅ Reply submitted successfully to Supabase');
      }

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting reply to Supabase: $e');
      }
      return false;
    }
  }

  // Get all notifications that need reply (using single query with LEFT JOIN logic)
  Future<List<Map<String, dynamic>>> getPendingNotificationsOptimized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        if (kDebugMode) {
          print('⚠️ No user email found');
        }
        return [];
      }

      if (kDebugMode) {
        print('🔍 Fetching pending notifications (optimized) for: $email');
      }

      // First, get all notification_ids sent to this user
      final recipientsResponse = await Supabase.instance.client
          .from('notification_recipients')
          .select('notification_id')
          .eq('user_email', email)
          .eq('sent_status', 'sent');

      if (recipientsResponse.isEmpty) {
        if (kDebugMode) {
          print('✅ No notifications sent to this user');
        }
        return [];
      }

      // Extract notification_ids
      final notificationIds = recipientsResponse
          .map((r) => r['notification_id'] as int)
          .toList();

      if (kDebugMode) {
        print('📋 Found ${notificationIds.length} notification IDs');
      }

      // Get all notifications
      final notificationsResponse = await Supabase.instance.client
          .from('community_notifications')
          .select('id, title, body, sent_at, data')
          .inFilter('id', notificationIds)
          .order('sent_at', ascending: false);

      if (kDebugMode) {
        print('✅ Retrieved ${notificationsResponse.length} notifications');
      }

      // Check which ones don't have replies yet
      final List<Map<String, dynamic>> pendingNotifications = [];

      for (var notification in notificationsResponse) {
        final notificationId = notification['id'] as int;

        // Check if reply exists
        final hasReply = await Supabase.instance.client
            .from('notification_replies')
            .select('id')
            .eq('notification_id', notificationId)
            .eq('user_email', email)
            .maybeSingle();

        if (hasReply == null) {
          // No reply exists, this is pending
          final recipientRecord = recipientsResponse.firstWhere(
            (r) => r['notification_id'] == notificationId,
          );

          pendingNotifications.add({
            'id': notification['id'],
            'title': notification['title'],
            'body': notification['body'],
            'sent_at': notification['sent_at'],
            'data': notification['data'],
            'recipient_id': recipientRecord['notification_id'],
          });
        }
      }

      if (kDebugMode) {
        print('✅ Found ${pendingNotifications.length} pending notifications after filtering');
      }

      return pendingNotifications;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching pending notifications: $e');
      }
      return [];
    }
  }
}
