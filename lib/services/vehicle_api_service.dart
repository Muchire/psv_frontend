// lib/services/vehicle_owner_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/services/api_service.dart';
import 'package:file_picker/file_picker.dart';


class VehicleOwnerService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String vehicleOwnerPath = '/vehicles';

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
        Uri.parse('$baseUrl$vehicleOwnerPath/dashboard/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('No vehicles found for this owner');
      } else {
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Get all vehicles
  static Future<List<dynamic>> getVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/'),
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
          throw Exception('Unexpected response format for vehicles');
        }
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  // Create vehicle
  static Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> vehicleData,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl$vehicleOwnerPath/'),
        headers: headers,
        body: json.encode(vehicleData),
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

        throw Exception(
          'Failed to create vehicle: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Error creating vehicle: $e');
    }
  }

  // Update vehicle
  static Future<Map<String, dynamic>> updateVehicle(
    dynamic vehicleId,
    Map<String, dynamic> vehicleData,
  ) async {
    try {
      final id = _parseId(vehicleId);
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/'),
        headers: headers,
        body: json.encode(vehicleData),
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

        throw Exception(
          'Failed to update vehicle: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  // Delete vehicle
  static Future<void> deleteVehicle(dynamic vehicleId) async {
    try {
      final id = _parseId(vehicleId);
      final response = await http.delete(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        final errorBody = response.body;
        throw Exception(
          'Failed to delete vehicle: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  // Get vehicle stats
  static Future<Map<String, dynamic>> getVehicleStats(dynamic vehicleId) async {
    try {
      final id = _parseId(vehicleId);
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/stats/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load vehicle stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle stats: $e');
    }
  }

  // Get vehicle earnings estimation
  static Future<Map<String, dynamic>> getVehicleEarnings(
    dynamic vehicleId, {
    String? saccoId,
  }) async {
    try {
      final id = _parseId(vehicleId);
      String url = '$baseUrl$vehicleOwnerPath/$id/earnings/';
      if (saccoId != null) {
        url += '?sacco_id=$saccoId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load vehicle earnings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching vehicle earnings: $e');
    }
  }

  // Get available saccos
  static Future<Map<String, dynamic>> getAvailableSaccos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/saccos/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load saccos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching saccos: $e');
    }
  }

  // Search saccos with filters
  static Future<Map<String, dynamic>> searchSaccos({
    String? search,
    String? route,
    String? location,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (route != null && route.isNotEmpty) queryParams['route'] = route;
      if (location != null && location.isNotEmpty)
        queryParams['location'] = location;
      if (minRating != null) queryParams['min_rating'] = minRating.toString();

      final uri = Uri.parse(
        '$baseUrl$vehicleOwnerPath/saccos/search/',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search saccos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching saccos: $e');
    }
  }

  // Get sacco details
  // Debug version with logging
  static Future<Map<String, dynamic>> getSaccoDetails(dynamic saccoId) async {
    try {
      final id = _parseId(saccoId);
      final url = '$baseUrl/vehicles/saccos/$id/';

      print('Calling URL: $url'); // Debug line
      print('Sacco ID: $id'); // Debug line

      final headers = await _getHeaders();
      print('Headers: $headers'); // Debug line

      final response = await http.get(Uri.parse(url), headers: headers);

      print('Response status: ${response.statusCode}'); // Debug line
      print('Response body: ${response.body}'); // Debug line

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load sacco details: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Exception in getSaccoDetails: $e'); // Debug line
      throw Exception('Error fetching sacco details: $e');
    }
  }

  // Get sacco dashboard
  static Future<Map<String, dynamic>> getSaccoDashboard(dynamic saccoId) async {
    try {
      final id = _parseId(saccoId);
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/saccos/$id/dashboard/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load sacco dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching sacco dashboard: $e');
    }
  }

  // Compare saccos
  static Future<Map<String, dynamic>> compareSaccos(List<int> saccoIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$vehicleOwnerPath/saccos/compare/'),
        headers: await _getHeaders(),
        body: json.encode({'sacco_ids': saccoIds}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to compare saccos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error comparing saccos: $e');
    }
  }

  // Get join requests
  static Future<List<dynamic>> getJoinRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/join-requests/'),
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
          throw Exception('Unexpected response format for join requests');
        }
      } else {
        throw Exception('Failed to load join requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching join requests: $e');
    }
  }

  // // Create join request
  // static Future<Map<String, dynamic>> createJoinRequest(
  //   Map<String, dynamic> requestData,
  // ) async {
  //   try {
  //     final headers = await _getHeaders();

  //     final response = await http.post(
  //       Uri.parse('$baseUrl$vehicleOwnerPath/join-requests/'),
  //       headers: headers,
  //       body: json.encode(requestData),
  //     );

  //     if (response.statusCode == 201) {
  //       final responseData = json.decode(response.body);
  //       return responseData;
  //     } else {
  //       final errorBody = response.body;

  //       // Try to parse error details
  //       try {
  //         final errorData = json.decode(errorBody);
  //         if (errorData is Map && errorData.containsKey('error')) {
  //           throw Exception(errorData['error']);
  //         } else if (errorData is Map) {
  //           throw Exception('Server error: ${errorData.toString()}');
  //         }
  //       } catch (e) {
  //         // If can't parse as JSON, use raw response
  //       }

  //       throw Exception('Failed to create join request: ${response.statusCode} - $errorBody');
  //     }
  //   } catch (e) {
  //     throw Exception('Error creating join request: $e');
  //   }
  // }

  // Get vehicle trips
  static Future<List<dynamic>> getVehicleTrips(dynamic vehicleId) async {
    try {
      final id = _parseId(vehicleId);
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/trips/'),
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
          throw Exception('Unexpected response format for trips');
        }
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trips: $e');
    }
  }

  // Create trip
  static Future<Map<String, dynamic>> createTrip(
    dynamic vehicleId,
    Map<String, dynamic> tripData,
  ) async {
    try {
      final id = _parseId(vehicleId);
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/trips/'),
        headers: headers,
        body: json.encode(tripData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorBody = response.body;
        throw Exception(
          'Failed to create trip: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  // Get vehicle performance
  static Future<List<dynamic>> getVehiclePerformance(dynamic vehicleId) async {
    try {
      final id = _parseId(vehicleId);
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/performance/'),
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
          throw Exception('Unexpected response format for performance');
        }
      } else {
        throw Exception('Failed to load performance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching performance: $e');
    }
  }

  // Get routes
  static Future<Map<String, dynamic>> getRoutes({String? saccoId}) async {
    try {
      String url = '$baseUrl$vehicleOwnerPath/routes/';
      if (saccoId != null) {
        url += '?sacco_id=$saccoId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }

  // Get owner reviews
  static Future<Map<String, dynamic>> getOwnerReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/reviews/'),
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

  // Create owner review - Updated with sacco_id in URL
  static Future<Map<String, dynamic>> createOwnerReview(
    int saccoId,
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$vehicleOwnerPath/saccos/$saccoId/reviews/create/';

      print(
        'Creating review for Sacco ID: $saccoId at URL: $url',
      ); // Debug line
      print('Review data: $reviewData'); // Debug line
      print('Headers: $headers'); // Debug line

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(reviewData),
      );

      print('Response status: ${response.statusCode}'); // Debug line
      print('Response body: ${response.body}'); // Debug line

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorBody = response.body;

        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          if (errorData is Map && errorData.containsKey('detail')) {
            throw Exception(errorData['detail']);
          } else if (errorData is Map && errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (e) {
          // If can't parse as JSON, use raw response
        }

        throw Exception(
          'Failed to create review: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      print('Exception in createOwnerReview: $e'); // Debug line
      throw Exception('Error creating review: $e');
    }
  }

  // Get vehicle documents
  static Future<List<dynamic>> getVehicleDocuments(dynamic vehicleId) async {
    try {
      final id = _parseId(vehicleId);
      final response = await http.get(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/documents/'),
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
          throw Exception('Unexpected response format for documents');
        }
      } else {
        throw Exception('Failed to load documents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching documents: $e');
    }
  }

  // Create vehicle document
  static Future<Map<String, dynamic>> createVehicleDocument(
    dynamic vehicleId,
    Map<String, dynamic> documentData,
  ) async {
    try {
      final id = _parseId(vehicleId);
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl$vehicleOwnerPath/$id/documents/'),
        headers: headers,
        body: json.encode(documentData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorBody = response.body;
        throw Exception(
          'Failed to create document: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Error creating document: $e');
    }
  }

  // Alternative method that handles both with and without file uploads
  static Future<Map<String, dynamic>> createJoinRequestWithDocuments(
    int saccoId,
    Map<String, dynamic> requestData,
    Map<String, PlatformFile> documents,
  ) async {
    try {
      print('Creating join request for Sacco ID: $saccoId'); // Debug line
      print('Request data: $requestData'); // Debug line
      print('Documents to upload: ${documents.keys.toList()}'); // Debug line

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$vehicleOwnerPath/join-requests/'),
      );

      // Add authorization header
      final token = await ApiService.getToken(); // Use the existing static method from ApiService
      request.headers['Authorization'] = 'Token $token';

      // Add sacco_id to the request data
      requestData['sacco'] = saccoId;

      // Add form fields
      requestData.forEach((key, value) {
        if (value != null) {
          if (value is Map || value is List) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add required document files
      final requiredDocuments = [
        'logbook',
        'insurance',
        'inspection',
        'license',
        'permit',
      ];

      for (String docType in requiredDocuments) {
        if (documents.containsKey(docType) && documents[docType] != null) {
          final file = documents[docType]!;

          print('Adding $docType document: ${file.name}'); // Debug line

          request.files.add(
            http.MultipartFile.fromBytes(
              docType,
              file.bytes!,
              filename: file.name,
            ),
          );
        } else {
          print('Missing required document: $docType'); // Debug line
        }
      }

      print(
        'Sending request with ${request.files.length} files...',
      ); // Debug line

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}'); // Debug line
      print('Response body: ${response.body}'); // Debug line

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        // Handle error response
        final errorBody = response.body;
        Map<String, dynamic>? errorData;

        try {
          errorData = json.decode(errorBody);
        } catch (e) {
          print('Could not parse error response: $e');
        }

        if (errorData != null) {
          if (errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          } else if (errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          } else if (errorData.containsKey('missing_documents')) {
            final missing = errorData['missing_documents'] as List;
            throw Exception(
              'Missing required documents: ${missing.join(', ')}',
            );
          } else {
            // Handle field validation errors
            String errorMessage = 'Validation errors: ';
            errorData.forEach((key, value) {
              if (value is List) {
                errorMessage += '$key: ${value.join(', ')}. ';
              } else {
                errorMessage += '$key: $value. ';
              }
            });
            throw Exception(errorMessage);
          }
        }

        throw Exception(
          'Failed to create join request: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      print('Exception in createJoinRequestWithDocuments: $e');
      rethrow;
    }
  }

  // Helper method to validate documents before upload
  static Map<String, String> validateRequiredDocuments(
    Map<String, PlatformFile?> documents,
  ) {
    final requiredDocs = [
      'logbook',
      'insurance',
      'inspection',
      'license',
      'permit',
    ];
    final missing = <String, String>{};

    for (String docType in requiredDocs) {
      if (!documents.containsKey(docType) || documents[docType] == null) {
        missing[docType] = 'This document is required';
      }
    }

    return missing;
  }

  // Helper method to get readable document names
  static String getDocumentDisplayName(String documentType) {
    const displayNames = {
      'logbook': 'Vehicle Logbook',
      'insurance': 'Insurance Certificate',
      'inspection': 'Inspection Certificate',
      'license': 'Driving License',
      'permit': 'PSV Permit',
    };

    return displayNames[documentType] ?? documentType;
  }
  // Add this method to your VehicleOwnerService class
  static Future<Map<String, dynamic>> uploadVehicleDocument(
    int vehicleId,
    String documentType,
    PlatformFile file,
  ) async {
    try {
      print('Uploading $documentType for vehicle $vehicleId');
      
      final uri = Uri.parse('$baseUrl/vehicles/$vehicleId/documents/');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication headers
      final token = await ApiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      
      // Add the file
      final multipartFile = http.MultipartFile.fromBytes(
        'document_file',
        file.bytes!,
        filename: file.name,
      );
      request.files.add(multipartFile);
      
      // Add required fields
      request.fields['document_type'] = documentType;
      request.fields['document_name'] = file.name; // This was missing!
      
      // Optional: Add expiry date if you have it
      // request.fields['expiry_date'] = '2025-12-31'; // Format: YYYY-MM-DD
      
      print('Sending upload request for $documentType...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Document upload response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to upload $documentType: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading document: $e');
      rethrow;
    }
  }

  // Alternative method with custom document name
  static Future<Map<String, dynamic>> uploadVehicleDocumentWithName(
    int vehicleId,
    String documentType,
    PlatformFile file,
    String customDocumentName,
  ) async {
    try {
      print('Uploading $documentType for vehicle $vehicleId');
      
      final uri = Uri.parse('$baseUrl/vehicles/$vehicleId/documents/');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication headers
      final token = await ApiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      
      // Add the file
      final multipartFile = http.MultipartFile.fromBytes(
        'document_file',
        file.bytes!,
        filename: file.name,
      );
      request.files.add(multipartFile);
      
      // Add required fields
      request.fields['document_type'] = documentType;
      request.fields['document_name'] = customDocumentName; // Use custom name
      
      print('Sending upload request for $documentType...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Document upload response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to upload $documentType: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading document: $e');
      rethrow;
    }
  }
  // Updated join request method - no file uploads, just form data
  static Future<Map<String, dynamic>> createJoinRequestForSacco(
    int saccoId,
    Map<String, dynamic> requestData, {
    Map<String, PlatformFile>? documents, // Keep for compatibility but won't use for upload
  }) async {
    try {
      print('Creating join request for Sacco ID: $saccoId');
      print('Request data: $requestData');

      final headers = await _getHeaders();

      // Simple JSON request - no file uploads
      final response = await http.post(
        Uri.parse('$baseUrl$vehicleOwnerPath/join-requests/'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('Join request response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body;
        
        // Parse error details
        try {
          final errorData = json.decode(errorBody);
          if (errorData is Map && errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          } else if (errorData is Map && errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          }
        } catch (e) {
          // If can't parse as JSON, use raw response
        }

        throw Exception('Failed to create join request: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('Exception in createJoinRequestForSacco: $e');
      rethrow;
    }
  }

  // New method to handle the complete flow: upload documents then create join request
  static Future<Map<String, dynamic>> submitJoinRequestWithDocuments(
    int saccoId,
    int vehicleId,
    Map<String, dynamic> requestData,
    Map<String, PlatformFile> documents,
  ) async {
    try {
      print('Starting complete join request submission...');
      
      // Step 1: Upload all documents first
      final uploadedDocuments = <String, Map<String, dynamic>>{};
      
      for (var entry in documents.entries) {
        final documentType = entry.key;
        final file = entry.value;
        
        print('Uploading $documentType...');
        
        try {
          final uploadResult = await uploadVehicleDocument(vehicleId, documentType, file);
          uploadedDocuments[documentType] = uploadResult;
          print('Successfully uploaded $documentType');
        } catch (e) {
          print('Failed to upload $documentType: $e');
          throw Exception('Failed to upload $documentType: $e');
        }
      }
      
      // Step 2: Create join request (documents should now exist in database)
      print('All documents uploaded, creating join request...');
      
      final joinRequestResponse = await createJoinRequestForSacco(
        saccoId,
        requestData,
      );
      
      print('Join request created successfully');
      
      return {
        'join_request': joinRequestResponse,
        'uploaded_documents': uploadedDocuments,
      };
      
    } catch (e) {
      print('Error in submitJoinRequestWithDocuments: $e');
      rethrow;
    }
  }
  static Future<Map<String, dynamic>> updateVehicleDocument(
    int vehicleId,
    int documentId,
    String documentType,
    PlatformFile file,
  ) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('No access token found');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/vehicles/$vehicleId/documents/$documentId/'),
      );

      request.headers.addAll({
        'Authorization': 'Token $token',
      });

      request.fields['document_type'] = documentType;

      // Add file
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        throw Exception('File data not available');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Failed to update document: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }
  // Add these methods to your VehicleApiService class

  // // Approve sacco request (called by sacco admin)
  // static Future<void> approveSaccoRequest(dynamic requestId) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/sacco/requests/$requestId/approve'),
  //       headers: await ApiService.getHeaders(),
  //     );

  //     if (response.statusCode == 200) {
  //       // Success - request approved
  //       print('Sacco request approved successfully');
        
  //       // Optionally invalidate any cached data
  //       // You might want to trigger a notification or refresh
  //     } else if (response.statusCode == 403) {
  //       throw Exception('Unauthorized: Only sacco admins can approve requests');
  //     } else if (response.statusCode == 404) {
  //       throw Exception('Sacco request not found');
  //     } else {
  //       final errorData = json.decode(response.body);
  //       throw Exception(errorData['message'] ?? 'Failed to approve sacco request');
  //     }
  //   } catch (e) {
  //     throw Exception('Error approving sacco request: $e');
  //   }
  // }

  // // Reject sacco request (called by sacco admin)
  // static Future<void> rejectSaccoRequest(dynamic requestId, String reason) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/sacco/requests/$requestId/reject'),
  //       headers: await ApiService.getHeaders(),
  //       body: json.encode({'reason': reason}),
  //     );

  //     if (response.statusCode == 200) {
  //       print('Sacco request rejected successfully');
  //     } else if (response.statusCode == 403) {
  //       throw Exception('Unauthorized: Only sacco admins can reject requests');
  //     } else if (response.statusCode == 404) {
  //       throw Exception('Sacco request not found');
  //     } else {
  //       final errorData = json.decode(response.body);
  //       throw Exception(errorData['message'] ?? 'Failed to reject sacco request');
  //     }
  //   } catch (e) {
  //     throw Exception('Error rejecting sacco request: $e');
  //   }
  // }

  // Get vehicle with updated sacco information
  static Future<Map<String, dynamic>> getVehicleWithSacco(dynamic vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId/sacco-details'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['vehicle'] ?? {};
      } else if (response.statusCode == 404) {
        throw Exception('Vehicle not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load vehicle details');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle with sacco info: $e');
    }
  }

  static Future<List<dynamic>> getPendingSaccoRequests(String saccoId) async {
    final url = '$baseUrl/sacco/$saccoId/join-requests/pending/';
    print('DEBUG: Calling GET $url');
    
    try {
      final headers = await ApiService.getHeaders();
      print('DEBUG: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? [];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to load requests');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getPendingSaccoRequests: $e');
      rethrow;
    }
  }

  static Future<void> approveSaccoRequest(dynamic requestId) async {
    final url = '$baseUrl/vehicles/join-requests/$requestId/approve/';
    print('DEBUG: Calling POST $url');
    
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({}), // Empty body for approval
      );
      
      print('DEBUG: Approve response status: ${response.statusCode}');
      print('DEBUG: Approve response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['error'] ?? 'Failed to approve request');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception('Request not found');
      } else {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['error'] ?? 'Failed to approve request');
      }
    } catch (e) {
      print('DEBUG: Error in approveSaccoRequest: $e');
      rethrow;
    }
  }

  static Future<void> rejectSaccoRequest(dynamic requestId, String reason) async {
    final url = '$baseUrl/vehicles/join-requests/$requestId/reject/';
    print('DEBUG: Calling POST $url');
    
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'reason': reason,
        }),
      );
      
      print('DEBUG: Reject response status: ${response.statusCode}');
      print('DEBUG: Reject response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['error'] ?? 'Failed to reject request');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception('Request not found');
      } else {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['error'] ?? 'Failed to reject request');
      }
    } catch (e) {
      print('DEBUG: Error in rejectSaccoRequest: $e');
      rethrow;
    }
  }
}
