import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:is_project_1/models/profile_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://de6f-41-90-176-14.ngrok-free.app';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get user profile
  static Future<ProfileResponse> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get emergency contacts (only for role_id == 5)
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // You'll need to create this endpoint in your FastAPI backend
      final response = await http.get(
        Uri.parse('$baseUrl/emergency-contacts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EmergencyContact.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No emergency contacts found
        return [];
      } else {
        throw Exception(
          'Failed to load emergency contacts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Even if logout request fails, clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}
