import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    // For web, use production URL
    if (kIsWeb) {
      return 'https://policemitrabackend.thanepolice.in/api';
    }
    // For Android emulator, use production URL
    // For iOS simulator and physical devices, use production URL
    try {
      if (Platform.isAndroid) {
        return 'https://policemitrabackend.thanepolice.in/api';
      } else {
        return 'https://policemitrabackend.thanepolice.in/api';
      }
    } catch (e) {
      // Fallback for platforms where Platform is not supported
      return 'https://policemitrabackend.thanepolice.in/api';
    }
  }

  // Authentication methods
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = '$baseUrl/login';
      print('Login URL: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Store user email and verification status in shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', email);
          await prefs.setString('verification_status', data['data']['verification_status'] ?? 'pending');
          print('Login successful, verification_status: ${data['data']['verification_status']}');
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('verification_status');
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Reset password method
  static Future<Map<String, dynamic>?> resetPassword(String email, String newPassword) async {
    try {
      final url = '$baseUrl/user-credentials/reset-password';
      print('Reset password URL: $url');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );
      print('Reset password response status: ${response.statusCode}');
      print('Reset password response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Reset password error: $e');
      return null;
    }
  }

  // Registration methods
  static Future<bool> createRegistration(Map<String, dynamic> registrationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registrations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registrationData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getRegistrations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/registrations'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get registrations error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRegistrationById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/registrations/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get registration error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getRegistrationsByStation(String stationName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/registrations/station/$stationName'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get registrations by station error: $e');
      return [];
    }
  }

  // Services methods
  static Future<List<dynamic>> getAssignedServices(String userEmail) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assigned-services/$userEmail'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get assigned services error: $e');
      return [];
    }
  }

  // Feedback methods
  static Future<List<dynamic>> getFeedbacksByStation(String policeStation) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feedbacks/$policeStation'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get feedbacks error: $e');
      return [];
    }
  }

  // Statistics
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get stats error: $e');
      return null;
    }
  }

  // Database connection test
  static Future<Map<String, dynamic>?> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/test-connection'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Connection test error: $e');
      return null;
    }
  }

  // Availability status methods
  static Future<Map<String, dynamic>?> getUserRegistration(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mobileregistrations?email=$email'));
      print('DEBUG getUserRegistration: Calling URL: $baseUrl/mobileregistrations?email=$email');
      print('DEBUG getUserRegistration: Status Code: ${response.statusCode}');
      print('DEBUG getUserRegistration: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Try to parse response body
        final dynamic decoded = json.decode(response.body);
        print('DEBUG getUserRegistration: Decoded type = ${decoded.runtimeType}');

        List<dynamic> dataList;

        // Handle different response formats
        if (decoded is Map<String, dynamic>) {
          // Response is an object with data field
          print('DEBUG getUserRegistration: Response is an object');
          if (decoded['success'] == true && decoded['data'] != null) {
            dataList = decoded['data'] as List<dynamic>;
            print('DEBUG getUserRegistration: Extracted data array from object');
          } else {
            print('DEBUG getUserRegistration: Response object has no valid data');
            return null;
          }
        } else if (decoded is List<dynamic>) {
          // Response is directly an array
          print('DEBUG getUserRegistration: Response is directly an array');
          dataList = decoded;
        } else {
          print('DEBUG getUserRegistration: Unknown response format');
          return null;
        }

        print('DEBUG getUserRegistration: Response contains ${dataList.length} items');
        print('DEBUG getUserRegistration: Data: $dataList');

        // Since backend now filters by email, we should get 0 or 1 result
        if (dataList.isNotEmpty) {
          final userData = dataList[0] as Map<String, dynamic>;
          print('DEBUG getUserRegistration: Found user data: $userData');

          // Verify email matches (case-insensitive)
          final itemEmail = userData['email']?.toString().toLowerCase().trim();
          final searchEmail = email.toLowerCase().trim();
          print('DEBUG getUserRegistration: Comparing "$itemEmail" with "$searchEmail"');

          if (itemEmail == searchEmail) {
            print('DEBUG getUserRegistration: Email match confirmed!');
            return userData;
          } else {
            print('DEBUG getUserRegistration: Email mismatch!');
          }
        } else {
          print('DEBUG getUserRegistration: No user found for email: $email');
        }
      }
      print('DEBUG getUserRegistration: Returning null');
      return null;
    } catch (e, stackTrace) {
      print('Get user registration error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> updateRegistration(String email, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/registrations?email=$email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Update registration error: $e');
      return false;
    }
  }

  static Future<bool> updateAvailabilityStatus(String email, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/registrations/availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Update availability status error: $e');
      return false;
    }
  }

  // Availability logs methods
  static Future<bool> createAvailabilityLog(Map<String, dynamic> logData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/availability-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Create availability log error: $e');
      return false;
    }
  }

  static Future<bool> updateAvailabilityLogEndTime(String email, String startTime, String endTime) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/availability-logs/end-time'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email': email,
          'start_time': startTime,
          'end_time': endTime
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Update availability log error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLatestAvailabilityLog(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/availability-logs/latest?email=$email'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get latest availability log error: $e');
      return null;
    }
  }

  // Feedback methods
  static Future<bool> createFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Create feedback error: $e');
      return false;
    }
  }

  static Future<bool> updateServiceStatus(String serviceId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assigned-services/$serviceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Update service status error: $e');
      return false;
    }
  }

  // Availability logs methods
  static Future<List<dynamic>> getAvailabilityLogs(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/availability-logs-mobile?email=$email'));
      print('DEBUG getAvailabilityLogs response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response body as a Map first
        final data = jsonDecode(response.body);
        print('DEBUG getAvailabilityLogs: Response body: ${response.body}');

        // Check if response has success and data fields
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> dataList = data['data'] ?? [];
          print('DEBUG getAvailabilityLogs: Response is a map with ${dataList.length} items');

          // Filter by email if needed
          if (email.isNotEmpty) {
            final filteredList = dataList.where((item) {
              if (item is Map<String, dynamic>) {
                final userEmail = item['user_email']?.toString().toLowerCase();
                return userEmail == email.toLowerCase();
              }
              return false;
            }).toList();
            return filteredList;
          }

          return dataList;
        } else if (data is List) {
          // Fallback: if response is directly a list
          print('DEBUG getAvailabilityLogs: Response is a direct list with ${data.length} items');
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Get availability logs error: $e');
      return [];
    }
  }

  // Station contacts methods
  static Future<List<dynamic>> getStationContacts() async {
    try {
      final url = '$baseUrl/station-mobile-contacts';
      print('🔍 DEBUG getStationContacts: Calling URL: $url');

      final response = await http.get(Uri.parse(url));
      print('🔍 DEBUG getStationContacts: Status Code = ${response.statusCode}');
      print('🔍 DEBUG getStationContacts: Response Body = ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 DEBUG getStationContacts: Parsed JSON successfully');
        print('🔍 DEBUG getStationContacts: Success flag = ${data['success']}');
        print('🔍 DEBUG getStationContacts: Message = ${data['message']}');

        // Return all station contacts from the data array
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> contactsList = data['data'];
          print('✅ DEBUG getStationContacts: Found ${contactsList.length} station contacts');
          print('✅ DEBUG getStationContacts: First contact = ${contactsList.isNotEmpty ? contactsList[0] : "No contacts"}');
          return contactsList;
        } else {
          print('❌ DEBUG getStationContacts: Success flag is false or data is null');
          print('❌ DEBUG getStationContacts: data["success"] = ${data['success']}');
          print('❌ DEBUG getStationContacts: data["data"] = ${data['data']}');
        }
      } else {
        print('❌ DEBUG getStationContacts: Status code is not 200, it\'s ${response.statusCode}');
      }
      print('⚠️ DEBUG getStationContacts: Returning empty list');
      return [];
    } catch (e, stackTrace) {
      print('❌ Get station contacts error: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }
}