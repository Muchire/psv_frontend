// lib/services/sacco_admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/services/api_service.dart';

class SaccoAdminService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String adminPath = '/sacco_admin';

  // Get auth headers with token - now async
  static Future<Map<String, String>> _getHeaders() async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Helper method to safely convert ID to int
  static int _parseId(dynamic id) {
    if (id is int) {
      return id;
    } else if (id is String) {
      return int.parse(id);
    } else {
      throw Exception('Invalid ID format: $id');
    }
  }

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/dashboard/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('No sacco found for this admin user');
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Get sacco details for editing
  static Future<Map<String, dynamic>> getSaccoDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/sacco/edit/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load sacco details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sacco details: $e');
    }
  }

  // Update sacco details
  static Future<Map<String, dynamic>> updateSaccoDetails(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$adminPath/sacco/edit/'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update sacco details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating sacco details: $e');
    }
  }

  // Get routes
  static Future<List<dynamic>> getRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/routes-with-stops/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Paginated response
          return List<dynamic>.from(data['results'] ?? []);
        } else if (data is List) {
          // Direct list response
          return List<dynamic>.from(data);
        } else {
          // Unexpected format
          throw Exception('Unexpected response format for routes');
        }
      } else {
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }

  static Future<Map<String, dynamic>> createRoute(
    Map<String, dynamic> routeData,
  ) async {
    try {
      if (routeData.containsKey('stops_data')) {
        routeData['stops'] = routeData.remove('stops_data');;
      }
      
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$adminPath/routes-with-stops/'),
        headers: headers,
        body: json.encode(routeData),
      );


      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorBody = response.body;
        
        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          if (errorData is Map && errorData.containsKey('errors')) {
            throw Exception('Validation errors: ${errorData['errors']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (e) {
          // If can't parse as JSON, use raw response
        }
        
        throw Exception('Failed to create route: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating route: $e');
    }
  }

  static Future<Map<String, dynamic>> updateRoute(
    dynamic routeId,
    Map<String, dynamic> routeData,
  ) async {
    try {
      
      // Fix the field name - backend expects 'stops', not 'stops_data'
      if (routeData.containsKey('stops_data')) {
        routeData['stops'] = routeData.remove('stops_data');
      }
      
      
      final id = _parseId(routeId);
      
      final headers = await _getHeaders();
      
      final response = await http.patch(
        Uri.parse('$baseUrl$adminPath/routes-with-stops/$id/'),
        headers: headers,
        body: json.encode(routeData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorBody = response.body;
        
        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          if (errorData is Map && errorData.containsKey('errors')) {
            throw Exception('Validation errors: ${errorData['errors']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (e) {
          // If can't parse as JSON, use raw response
        }
        
        throw Exception('Failed to update route: ${response.statusCode} - $errorBody');
      }
    } catch (e) {;
      throw Exception('Error updating route: $e');
    }
  }


  // Delete route - now accepts dynamic ID and converts it
  static Future<void> deleteRoute(dynamic routeId) async {
    try {
      final id = _parseId(routeId);
      final response = await http.delete(
        Uri.parse('$baseUrl$adminPath/routes-with-stops/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        final errorBody = response.body;
        throw Exception('Failed to delete route: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Error deleting route: $e');
    }
  }

  // Get all reviews with pagination
  static Future<Map<String, dynamic>> getAllReviews({
    int passengerPage = 1,
    int ownerPage = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/reviews/all/?passenger_page=$passengerPage&owner_page=$ownerPage&page_size=$pageSize'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  // Get passenger reviews
  static Future<List<dynamic>> getPassengerReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/reviews/passenger/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          return List<dynamic>.from(data['results'] ?? []);
        } else if (data is List) {
          return List<dynamic>.from(data);
        } else {
          throw Exception('Unexpected response format for passenger reviews');
        }
      } else {
        throw Exception('Failed to load passenger reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching passenger reviews: $e');
    }
  }

  // Get owner reviews
  static Future<List<dynamic>> getOwnerReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminPath/reviews/owner/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          return List<dynamic>.from(data['results'] ?? []);
        } else if (data is List) {
          return List<dynamic>.from(data);
        } else {
          throw Exception('Unexpected response format for owner reviews');
        }
      } else {
        throw Exception('Failed to load owner reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching owner reviews: $e');
    }
  }
}