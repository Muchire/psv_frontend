import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // Replace with your Django server URL
  
  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Store token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Get headers with token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }
  
  // Auth APIs
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/register/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await storeToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }
  
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await storeToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
  
  // Sacco APIs
  static Future<List<dynamic>> getSaccos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sacco/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load saccos');
    }
  }
  
  static Future<Map<String, dynamic>> getSaccoDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sacco/$id/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sacco details');
    }
  }
  
  // Route APIs
  static Future<List<dynamic>> getRoutes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/routes/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load routes');
    }
  }
  
  // ADD THIS MISSING METHOD - Route Detail API
  static Future<Map<String, dynamic>> getRouteDetail(int routeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/routes/$routeId/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load route details');
    }
  }
  
  static Future<List<dynamic>> searchRoutes({
    required String from,
    required String to,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/routes/search-routes/?from=$from&to=$to'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search routes');
    }
  }
  
  // Review APIs
  static Future<List<dynamic>> getPassengerReviews() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/passenger-reviews/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load passenger reviews');
    }
  }
  
  
// ADD THESE METHODS TO YOUR ApiService CLASS

  // Get reviews for a specific sacco
  static Future<List<dynamic>> getSaccoReviews(int saccoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/passenger-reviews/sacco/$saccoId/'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load sacco reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sacco reviews: $e');
    }
  }

  // Get routes for a specific sacco
  static Future<List<dynamic>> getRoutesBySacco(int saccoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/sacco/$saccoId/'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load routes for sacco: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load routes for sacco: $e');
    }
  }

  // Create passenger review
 // Updated createPassengerReview method with better error handling
  static Future<Map<String, dynamic>> createPassengerReview({
    required int saccoId,
    required int cleanliness,
    required int punctuality,
    required int comfort,
    required int overall,
    String? comment,
  }) async {
    try {
      final headers = await getHeaders();
      final double average = (cleanliness + punctuality + comfort + overall) / 4.0;
      final body = {
        'cleanliness': cleanliness,
        'punctuality': punctuality,
        'comfort': comfort,
        'overall': overall,
        'average': average.toStringAsFixed(2), // Calculate average rating
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/reviews/passenger-reviews/sacco/$saccoId/'),
        headers: headers,
        body: jsonEncode(body),
      );


      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error response
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'error': response.body};
        }
        
        // Create detailed error message
        String errorMessage = 'Failed to create review (${response.statusCode})';
        if (errorData.containsKey('error')) {
          errorMessage += ': ${errorData['error']}';
        } else if (errorData.containsKey('detail')) {
          errorMessage += ': ${errorData['detail']}';
        } else {
          errorMessage += ': ${response.body}';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Exception occurred: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Network error: $e');
      }
    }
  }
  // User mode switching
  static Future<Map<String, dynamic>> switchUserMode(String mode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/switch-user-mode/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'switch_to': mode,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to switch user mode');
    }
  }
  
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Get user reviews (replaces the old getPassengerReviews method)
  static Future<List<dynamic>> getUserReviews({int? limit}) async {
    String url = '$baseUrl/user/my-reviews/';
    if (limit != null) {
      url += '?limit=$limit';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user reviews');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
    String? phoneNumber,
  }) async {
    final Map<String, dynamic> body = {};
    
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;

    final response = await http.put(
      Uri.parse('$baseUrl/user/profile/update/'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/password/change/'),
      headers: await getHeaders(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to change password');
    }
  }

  // Deactivate user account (optional - for future use)
  static Future<Map<String, dynamic>> deactivateAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user/profile/deactivate/'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to deactivate account');
    }
  }

  // Add this method to your ApiService class
  static Future<Map<String, dynamic>> submitSaccoAdminRequest({
    int? saccoId, // null if creating a new sacco
    String? saccoName,
    String? location,
    String? dateEstablished,
    String? registrationNumber,
    String? contactNumber,
    String? email,
    String? website,
  }) async {
    final url = Uri.parse('$baseUrl/sacco/request-admin/');
    final headers = await getHeaders();

    final body = {
      if (saccoId != null) 'sacco_id': saccoId,
      if (saccoId == null) ...{
        'sacco_name': saccoName,
        'location': location,
        'date_established': dateEstablished,
        'registration_number': registrationNumber,
        'contact_number': contactNumber,
        'email': email,
        'website': website,
      }
    };


    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );


    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit admin request: ${response.body}');
    }
  }

  static Future<void> debugAuthStatus() async {
    final token = await getToken();
    print('DEBUG: Current token: ${token ?? 'NO TOKEN'}');
    
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/user/profile/'),
          headers: await getHeaders(),
        );
        print('DEBUG: Auth check status: ${response.statusCode}');
        print('DEBUG: Auth check response: ${response.body}');
      } catch (e) {
        print('DEBUG: Auth check error: $e');
      }
    }
  }

  // Call this before submitting the review to ensure user is authenticated
  static Future<bool> isUserAuthenticated() async {
    try {
      final response = await getUserProfile();
      return true;
    } catch (e) {
      print('DEBUG: User not authenticated: $e');
      return false;
    }
  }
}
