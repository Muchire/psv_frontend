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

  static Future<Map<String, dynamic>> googleAuthWithTokens({
    required Map<String, String> tokens,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/google-auth/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tokens), // Send both id_token and access_token if available
    );
        
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await storeToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Google authentication failed: ${response.body}');
    }
  }

  // Keep your existing method for backward compatibility
  static Future<Map<String, dynamic>> googleAuth({
    required String idToken,
  }) async {
    return googleAuthWithTokens(tokens: {'id_token': idToken});
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
  
    static Future<Map<String, dynamic>> requestPasswordReset({
      required String email,
    }) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/user/auth/request-password-reset/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to request password reset');
        }
      } catch (e) {
        throw Exception('Network error: ${e.toString()}');
      }
    }

    /// Validate password reset token
    static Future<Map<String, dynamic>> validateResetToken({
      required String token,
      required String uid,
    }) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/user/auth/validate-reset-token/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'uid': uid,
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Invalid token');
        }
      } catch (e) {
        throw Exception('Network error: ${e.toString()}');
      }
    }

    /// Confirm password reset with new password
    static Future<Map<String, dynamic>> confirmPasswordReset({
      required String token,
      required String uid,
      required String newPassword,
    }) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/user/auth/reset-password/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'uid': uid,
            'new_password': newPassword,
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to reset password');
        }
      } catch (e) {
        throw Exception('Network error: ${e.toString()}');
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
    static Future<Map<String, dynamic>> getSaccoDetailPOV(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sacco/$id/POV/'),
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
        'average': average.toStringAsFixed(2),
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
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'error': response.body};
        }
        
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

  // Get user reviews
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

  // Deactivate user account
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

  // Submit sacco admin request
  static Future<Map<String, dynamic>> submitSaccoAdminRequest({
    int? saccoId,
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

  // ADDED: Logout method to clear token
  static Future<void> logout() async {
    await removeToken();
  }

  // Debug methods
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

  static Future<bool> isUserAuthenticated() async {
    try {
      final response = await getUserProfile();
      return true;
    } catch (e) {
      print('DEBUG: User not authenticated: $e');
      return false;
    }
  }
    // Send OTP to email for password reset
  static Future<Map<String, dynamic>> sendPasswordResetOTP({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/auth/password-reset/send-otp/'),
        headers: await getHeaders(),
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  // Verify the OTP
  static Future<Map<String, dynamic>> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/auth/password-reset/verify-otp/'),
        headers: await getHeaders(),
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  // Reset password with verified OTP
  static Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/auth/password-reset/confirm/'),
        headers: await getHeaders(),
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

}