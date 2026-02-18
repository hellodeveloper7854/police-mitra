import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentToken;

  // Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('🔥 Initializing FCM Service...');
      }

      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('✅ Notification settings: ${settings.authorizationStatus}');
      }

      // Get the initial FCM token
      _currentToken = await _firebaseMessaging.getToken();

      if (_currentToken != null) {
        if (kDebugMode) {
          print('✅ FCM Token generated successfully!');
          print('📱 Token: $_currentToken');
          print('📏 Token length: ${_currentToken!.length}');
        }
        // Save token locally
        await _saveTokenLocally(_currentToken!);
        if (kDebugMode) {
          print('💾 Token saved locally to SharedPreferences');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ WARNING: FCM Token is NULL!');
          print('   This usually means:');
          print('   1. Running on emulator (use physical device)');
          print('   2. Google Play Services not available');
          print('   3. App is not properly signed/configured');
        }
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        _currentToken = newToken;
        await _saveTokenLocally(newToken);

        // Automatically send new token to backend and Supabase if user is logged in
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email');
        if (userEmail != null) {
          // Send to backend API
          await sendTokenToBackend(userEmail, newToken);

          // Also update in Supabase
          try {
            await Supabase.instance.client
                .from('registrations')
                .update({'fcm_token': newToken})
                .eq('email', userEmail);
            if (kDebugMode) {
              print('✅ FCM token updated in Supabase after refresh');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error updating FCM token in Supabase: $e');
            }
          }
        }
      });

      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received message in foreground: ${message.messageId}');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
        }
      });

      // Configure background message handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Message opened from background: ${message.messageId}');
        }
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  // Get current FCM token
  String? get currentToken => _currentToken;

  // Save token locally
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving token locally: $e');
      }
    }
  }

  // Get token from local storage
  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved token: $e');
      }
      return null;
    }
  }

  // Send FCM token to backend
  Future<bool> sendTokenToBackend(String email, String token) async {
    try {
      // Replace with your actual backend URL
      final String baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000', // Default for development
      );

      final response = await http.put(
        Uri.parse('$baseUrl/api/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('FCM token sent to backend successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to send FCM token: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM token to backend: $e');
      }
      return false;
    }
  }

  // Send FCM token during login
  Future<String?> sendTokenOnLogin(String email) async {
    if (kDebugMode) {
      print('🔐 sendTokenOnLogin called for: $email');
      print('📱 Current token: ${_currentToken != null ? "EXISTS" : "NULL"}');
    }

    final token = _currentToken ?? await getSavedToken();

    if (token != null) {
      if (kDebugMode) {
        print('✅ Token found, sending to backend...');
        print('📤 Token length: ${token.length}');
      }

      await sendTokenToBackend(email, token);

      if (kDebugMode) {
        print('✅ Token processing complete');
      }

      return token;
    } else {
      if (kDebugMode) {
        print('❌ ERROR: No FCM token available!');
        print('   Cannot save to database without a token');
      }
      return null;
    }
  }
}
