import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/community_notification_service.dart';

class NotificationReplyPopup extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onReplySubmitted;

  const NotificationReplyPopup({
    super.key,
    required this.notification,
    this.onReplySubmitted,
  });

  @override
  State<NotificationReplyPopup> createState() => _NotificationReplyPopupState();
}

class _NotificationReplyPopupState extends State<NotificationReplyPopup> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final replyText = _replyController.text.trim();

    if (replyText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your reply';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');

      if (userEmail == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isSubmitting = false;
        });
        return;
      }

      // Convert notification ID to int (it might be stored as string)
      final notificationId = widget.notification['id'] is String
          ? int.tryParse(widget.notification['id'])
          : widget.notification['id'] as int?;

      if (notificationId == null) {
        setState(() {
          _errorMessage = 'Invalid notification ID';
          _isSubmitting = false;
        });
        return;
      }

      if (mounted) {
        print('📝 Submitting reply for notification ID: $notificationId');
        print('📝 Reply text: $replyText');
      }

      final success = await CommunityNotificationService().submitReply(
        notificationId: notificationId,
        replyText: replyText,
      );

      if (success) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reply submitted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Close dialog and notify parent
          Navigator.of(context).pop();
          widget.onReplySubmitted?.call();
        }
      } else {
        if (mounted) {
          print('❌ Submit reply returned false');
          setState(() {
            _errorMessage = 'Failed to submit reply. You may have already replied to this notification.';
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('❌ Exception during submit reply: $e');
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent dialog from closing until reply is submitted
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Colors.purple[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.notification['title'] ?? 'Community Message',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification body
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.notification['message'] ?? widget.notification['body'] ?? 'No message content',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Reply instruction
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please provide your reply to continue',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reply text field
              TextField(
                controller: _replyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your reply here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.purple[700]!),
                  ),
                  errorText: _errorMessage,
                ),
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
        actions: [
          // Submit button (only button - no cancel)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Reply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
