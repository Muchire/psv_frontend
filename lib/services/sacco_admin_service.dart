// lib/services/sacco_admin_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '/services/api_service.dart';

class SaccoAdminService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String adminPath = '/sacco_admin';
  static const String routesPath = '/routes';

  // Debug logging helper
  static void _debugLog(
    String method,
    String message, {
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log(
      '[$timestamp] SaccoAdminService.$method: $message',
      name: 'SaccoAdminService',
    );
    if (data != null) {
      developer.log(
        '[$timestamp] Data: ${json.encode(data)}',
        name: 'SaccoAdminService',
      );
    }

    // Also print to console for easier debugging
    print('🔍 [$method] $message');
    if (data != null) {
      print('📊 Data: ${json.encode(data)}');
    }
  }

  // Debug HTTP response helper
  static void _debugHttpResponse(
    String method,
    String endpoint,
    http.Response response,
  ) {
    _debugLog(method, 'HTTP ${response.request?.method} $endpoint');
    _debugLog(method, 'Status Code: ${response.statusCode}');
    _debugLog(method, 'Headers: ${response.headers}');
    _debugLog(method, 'Body: ${response.body}');
  }

  // Get auth headers with token - now async
  static Future<Map<String, String>> _getHeaders() async {
    try {
      _debugLog('_getHeaders', 'Fetching auth token...');
      final token = await ApiService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

      _debugLog(
        '_getHeaders',
        'Headers prepared',
        data: {
          'has_token': token != null,
          'token_length': token?.length ?? 0,
          'headers': headers,
        },
      );

      return headers;
    } catch (e) {
      _debugLog('_getHeaders', 'ERROR: Failed to get headers: $e');
      rethrow;
    }
  }

  // Helper method to safely convert ID to int
  static int _parseId(dynamic id) {
    try {
      _debugLog('_parseId', 'Parsing ID: $id (type: ${id.runtimeType})');

      if (id is int) {
        _debugLog('_parseId', 'ID is already int: $id');
        return id;
      } else if (id is String) {
        final parsed = int.parse(id);
        _debugLog('_parseId', 'Parsed string to int: $id -> $parsed');
        return parsed;
      } else {
        _debugLog(
          '_parseId',
          'ERROR: Invalid ID format: $id (type: ${id.runtimeType})',
        );
        throw Exception('Invalid ID format: $id');
      }
    } catch (e) {
      _debugLog('_parseId', 'ERROR: Exception parsing ID: $e');
      rethrow;
    }
  }

  // ==================== DASHBOARD AND BASIC SACCO METHODS ====================

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    const method = 'getDashboardData';
    try {
      _debugLog(method, 'Starting dashboard data fetch...');

      final endpoint = '$baseUrl$adminPath/dashboard/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      _debugLog(method, 'Making HTTP GET request...');

      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Dashboard data received');
        final data = json.decode(response.body);
        _debugLog(method, 'Parsed response data', data: data);
        return data;
      } else if (response.statusCode == 404) {
        _debugLog(method, 'ERROR: No sacco found for admin user (404)');
        throw Exception('No sacco found for this admin user');
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Get sacco details for editing
  static Future<Map<String, dynamic>> getSaccoDetails() async {
    const method = 'getSaccoDetails';
    try {
      _debugLog(method, 'Starting sacco details fetch...');

      final endpoint = '$baseUrl$adminPath/sacco/edit/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Sacco details received');
        final data = json.decode(response.body);
        return data;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        throw Exception('Failed to load sacco details: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error fetching sacco details: $e');
    }
  }

  // Update sacco details
  static Future<Map<String, dynamic>> updateSaccoDetails(
    Map<String, dynamic> data,
  ) async {
    const method = 'updateSaccoDetails';
    try {
      _debugLog(method, 'Starting sacco details update...', data: data);

      final endpoint = '$baseUrl$adminPath/sacco/edit/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final body = json.encode(data);
      _debugLog(method, 'Request body: $body');

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Sacco details updated');
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        throw Exception(
          'Failed to update sacco details: ${response.statusCode}',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error updating sacco details: $e');
    }
  }

  // ==================== ROUTES MANAGEMENT ====================

  // Get routes
  static Future<List<dynamic>> getRoutes() async {
    const method = 'getRoutes';
    try {
      _debugLog(method, 'Starting routes fetch...');

      final endpoint = '$baseUrl$adminPath/routes-with-stops/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Routes data received');
        final data = json.decode(response.body);
        _debugLog(method, 'Response data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Paginated response
          _debugLog(method, 'Processing paginated response');
          final results = List<dynamic>.from(data['results'] ?? []);
          _debugLog(method, 'Paginated results count: ${results.length}');
          return results;
        } else if (data is List) {
          // Direct list response
          _debugLog(method, 'Processing direct list response');
          final results = List<dynamic>.from(data);
          _debugLog(method, 'Direct list count: ${results.length}');
          return results;
        } else {
          // Unexpected format
          _debugLog(
            method,
            'ERROR: Unexpected response format',
            data: {'response_type': data.runtimeType.toString()},
          );
          throw Exception('Unexpected response format for routes');
        }
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error fetching routes: $e');
    }
  }

  static Future<Map<String, dynamic>> createRoute(
    Map<String, dynamic> routeData,
  ) async {
    const method = 'createRoute';
    try {
      _debugLog(method, 'Starting route creation...', data: routeData);

      // Transform stops_data to stops if needed
      if (routeData.containsKey('stops_data')) {
        routeData['stops'] = routeData.remove('stops_data');
        _debugLog(method, 'Transformed stops_data to stops');
      }

      final endpoint = '$baseUrl$adminPath/routes-with-stops/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final body = json.encode(routeData);
      _debugLog(method, 'Request body: $body');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 201) {
        _debugLog(method, 'SUCCESS: Route created');
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;

        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          _debugLog(method, 'Parsed error data', data: errorData);

          if (errorData is Map && errorData.containsKey('errors')) {
            throw Exception('Validation errors: ${errorData['errors']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (parseError) {
          _debugLog(
            method,
            'Could not parse error response as JSON: $parseError',
          );
        }

        throw Exception(
          'Failed to create route: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error creating route: $e');
    }
  }

  static Future<Map<String, dynamic>> updateRoute(
    dynamic routeId,
    Map<String, dynamic> routeData,
  ) async {
    const method = 'updateRoute';
    try {
      _debugLog(
        method,
        'Starting route update...',
        data: {'routeId': routeId, 'routeData': routeData},
      );

      // Fix the field name - backend expects 'stops', not 'stops_data'
      if (routeData.containsKey('stops_data')) {
        routeData['stops'] = routeData.remove('stops_data');
        _debugLog(method, 'Transformed stops_data to stops');
      }

      final id = _parseId(routeId);
      final endpoint = '$baseUrl$adminPath/routes-with-stops/$id/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final body = json.encode(routeData);
      _debugLog(method, 'Request body: $body');

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Route updated');
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;

        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          _debugLog(method, 'Parsed error data', data: errorData);

          if (errorData is Map && errorData.containsKey('errors')) {
            throw Exception('Validation errors: ${errorData['errors']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (parseError) {
          _debugLog(
            method,
            'Could not parse error response as JSON: $parseError',
          );
        }

        throw Exception(
          'Failed to update route: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error updating route: $e');
    }
  }

  // Delete route - now accepts dynamic ID and converts it
  static Future<void> deleteRoute(dynamic routeId) async {
    const method = 'deleteRoute';
    try {
      _debugLog(
        method,
        'Starting route deletion...',
        data: {'routeId': routeId},
      );

      final id = _parseId(routeId);
      final endpoint = '$baseUrl$adminPath/routes-with-stops/$id/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 204) {
        _debugLog(method, 'SUCCESS: Route deleted');
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;
        throw Exception(
          'Failed to delete route: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error deleting route: $e');
    }
  }

  // ==================== ROUTE FINANCIAL MANAGEMENT METHODS ====================

  /// Get route earnings calculation
  static Future<Map<String, dynamic>> getRouteEarnings(dynamic routeId) async {
    const method = 'getRouteEarnings';
    try {
      _debugLog(
        method,
        'Starting route earnings fetch...',
        data: {'routeId': routeId},
      );

      final id = _parseId(routeId);
      final endpoint = '$baseUrl/api/routes/$id/earnings/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Route earnings received');
        final data = json.decode(response.body);
        return data;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;
        throw Exception(
          'Failed to get route earnings: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error fetching route earnings: $e');
    }
  }

  /// Update financial data for a specific route
  static Future<Map<String, dynamic>> updateRouteFinancialData(
    dynamic routeId,
    Map<String, dynamic> financialData,
  ) async {
    const method = 'updateRouteFinancialData';
    try {
      _debugLog(
        method,
        'Starting route financial data update...',
        data: {'routeId': routeId, 'financialData': financialData},
      );

      final id = _parseId(routeId);

      // Map frontend field names to backend field names
      final backendData = <String, dynamic>{};

      // Map the field names correctly based on your backend expectations
      if (financialData.containsKey('fare')) {
        backendData['fare'] = financialData['fare'];
      }
      if (financialData.containsKey('daily_trips')) {
        backendData['avg_daily_trips'] =
            financialData['daily_trips']; // Backend expects avg_daily_trips
      }
      if (financialData.containsKey('avg_passengers')) {
        backendData['avg_passengers_per_trip'] =
            financialData['avg_passengers'];
      }

      // Add other financial fields if they exist
      if (financialData.containsKey('peak_hours_multiplier')) {
        backendData['peak_hours_multiplier'] =
            financialData['peak_hours_multiplier'];
      }
      if (financialData.containsKey('seasonal_variance')) {
        backendData['seasonal_variance'] = financialData['seasonal_variance'];
      }
      if (financialData.containsKey('fuel_cost_per_km')) {
        backendData['fuel_cost_per_km'] = financialData['fuel_cost_per_km'];
      }
      if (financialData.containsKey('maintenance_cost_per_month')) {
        backendData['maintenance_cost_per_month'] =
            financialData['maintenance_cost_per_month'];
      }

      _debugLog(method, 'Mapped to backend data', data: backendData);

      final endpoint = '$baseUrl/routes/$id/financial/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final body = json.encode(backendData);
      _debugLog(method, 'Request body: $body');

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Route financial data updated');
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;

        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          _debugLog(method, 'Parsed error data', data: errorData);

          if (errorData is Map && errorData.containsKey('error')) {
            throw Exception('${errorData['error']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (parseError) {
          _debugLog(
            method,
            'Could not parse error response as JSON: $parseError',
          );
        }

        throw Exception(
          'Failed to update route financial data: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error updating route financial data: $e');
    }
  }

  /// Bulk update financial data for all routes of a sacco
  static Future<Map<String, dynamic>> bulkUpdateSaccoRoutesFinancialData(
    dynamic saccoId,
    Map<String, dynamic> financialData,
  ) async {
    const method = 'bulkUpdateSaccoRoutesFinancialData';
    try {
      _debugLog(
        method,
        'Starting bulk update...',
        data: {'saccoId': saccoId, 'financialData': financialData},
      );

      final id = _parseId(saccoId);
      final requestBody = {'financial_data': financialData};

      final endpoint = '$baseUrl/api/routes/sacco/$id/bulk-financial-update/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final body = json.encode(requestBody);
      _debugLog(method, 'Request body: $body');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Bulk update completed');
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;

        try {
          final errorData = json.decode(errorBody);
          _debugLog(method, 'Parsed error data', data: errorData);

          if (errorData is Map && errorData.containsKey('error')) {
            throw Exception('${errorData['error']}');
          }
        } catch (parseError) {
          _debugLog(
            method,
            'Could not parse error response as JSON: $parseError',
          );
        }

        throw Exception(
          'Failed to bulk update routes: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error bulk updating routes: $e');
    }
  }

  // Helper method to update specific financial fields for a route
  static Future<Map<String, dynamic>> updateRouteFinancialField(
    dynamic routeId,
    String fieldName,
    dynamic value,
  ) async {
    const method = 'updateRouteFinancialField';
    _debugLog(
      method,
      'Starting single field update...',
      data: {'routeId': routeId, 'fieldName': fieldName, 'value': value},
    );

    final financialData = {fieldName: value};
    return await updateRouteFinancialData(routeId, financialData);
  }

  // Bulk update financial data for sacco routes with specific fields
  static Future<Map<String, dynamic>> bulkUpdateSaccoFinancialFields(
    dynamic saccoId, {
    double? avgDailyTrips,
    double? peakHoursMultiplier,
    double? seasonalVariance,
    double? fuelCostPerKm,
    double? maintenanceCostPerMonth,
  }) async {
    const method = 'bulkUpdateSaccoFinancialFields';
    _debugLog(
      method,
      'Starting bulk field update...',
      data: {
        'saccoId': saccoId,
        'avgDailyTrips': avgDailyTrips,
        'peakHoursMultiplier': peakHoursMultiplier,
        'seasonalVariance': seasonalVariance,
        'fuelCostPerKm': fuelCostPerKm,
        'maintenanceCostPerMonth': maintenanceCostPerMonth,
      },
    );

    final financialData = <String, dynamic>{};

    if (avgDailyTrips != null) financialData['avg_daily_trips'] = avgDailyTrips;
    if (peakHoursMultiplier != null)
      financialData['peak_hours_multiplier'] = peakHoursMultiplier;
    if (seasonalVariance != null)
      financialData['seasonal_variance'] = seasonalVariance;
    if (fuelCostPerKm != null)
      financialData['fuel_cost_per_km'] = fuelCostPerKm;
    if (maintenanceCostPerMonth != null)
      financialData['maintenance_cost_per_month'] = maintenanceCostPerMonth;

    if (financialData.isEmpty) {
      _debugLog(method, 'ERROR: No financial data provided');
      throw Exception('No financial data provided for bulk update');
    }

    return await bulkUpdateSaccoRoutesFinancialData(saccoId, financialData);
  }

  // ==================== SACCO FINANCIAL METRICS METHODS ====================

  /// Check if user can edit financial metrics for a sacco
  static Future<bool> canEditFinancialMetrics(dynamic saccoId) async {
    const method = 'canEditFinancialMetrics';
    try {
      _debugLog(method, 'Checking permissions...', data: {'saccoId': saccoId});

      final id = _parseId(saccoId);
      final endpoint = '$baseUrl/api/sacco/$id/financial-metrics/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: User has permissions');
        return true;
      } else if (response.statusCode == 403) {
        _debugLog(method, 'INFO: User lacks permissions (403)');
        return false;
      } else {
        _debugLog(
          method,
          'INFO: Assuming no access due to status ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: Assuming no access - $e');
      return false;
    }
  }

  /// Get sacco financial metrics and route earnings
  static Future<Map<String, dynamic>> getSaccoFinancialMetrics(
    dynamic saccoId,
  ) async {
    const method = 'getSaccoFinancialMetrics';
    try {
      _debugLog(
        method,
        'Starting financial metrics fetch...',
        data: {'saccoId': saccoId},
      );

      final id = _parseId(saccoId);
      final endpoint = '$baseUrl/api/sacco/$id/financial-metrics/';
      _debugLog(method, 'Endpoint: $endpoint');

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      _debugHttpResponse(method, endpoint, response);

      if (response.statusCode == 200) {
        _debugLog(method, 'SUCCESS: Financial metrics received');
        final data = json.decode(response.body);
        return data;
      } else {
        _debugLog(method, 'ERROR: Failed with status ${response.statusCode}');
        final errorBody = response.body;

        // Try to parse error details
        try {
          final errorData = json.decode(errorBody);
          _debugLog(method, 'Parsed error data', data: errorData);

          if (errorData is Map && errorData.containsKey('error')) {
            throw Exception('${errorData['error']}');
          } else if (errorData is Map) {
            throw Exception('Server error: ${errorData.toString()}');
          }
        } catch (parseError) {
          _debugLog(
            method,
            'Could not parse error response as JSON: $parseError',
          );
        }

        throw Exception(
          'Failed to load financial metrics: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      _debugLog(method, 'EXCEPTION: $e');
      throw Exception('Error fetching financial metrics: $e');
    }
  }

  /// Update sacco financial metrics using POST
  static Future<Map<String, dynamic>> updateSaccoFinancialMetrics(
    dynamic saccoId, {
    double? avgRevenuePerVehicle,
    double? operationalCosts,
    double? netProfitMargin,
    double? ownerAverageProfit,
  }) async {
    print('🚀 [updateSaccoFinancialMetrics] Starting with saccoId: $saccoId');

    try {
      print('📝 [updateSaccoFinancialMetrics] Parsing ID...');
      final id = _parseId(saccoId);
      print('✅ [updateSaccoFinancialMetrics] Parsed ID: $id');

      print('🔑 [updateSaccoFinancialMetrics] Getting headers...');
      final headers = await _getHeaders();
      print(
        '✅ [updateSaccoFinancialMetrics] Headers obtained: ${headers.keys}',
      );

      final requestBody = <String, dynamic>{};

      // Map to the correct backend field names
      if (avgRevenuePerVehicle != null) {
        requestBody['avg_revenue_per_vehicle'] = avgRevenuePerVehicle;
        print(
          '📊 [updateSaccoFinancialMetrics] Added avg_revenue_per_vehicle: $avgRevenuePerVehicle',
        );
      }
      if (operationalCosts != null) {
        requestBody['operational_costs'] = operationalCosts;
        print(
          '📊 [updateSaccoFinancialMetrics] Added operational_costs: $operationalCosts',
        );
      }
      if (netProfitMargin != null) {
        requestBody['net_profit_margin'] = netProfitMargin;
        print(
          '📊 [updateSaccoFinancialMetrics] Added net_profit_margin: $netProfitMargin',
        );
      }
      if (ownerAverageProfit != null) {
        requestBody['owner_average_profit'] = ownerAverageProfit;
        print(
          '📊 [updateSaccoFinancialMetrics] Added owner_average_profit: $ownerAverageProfit',
        );
      }

      final url = '$baseUrl/api/sacco/$id/financial-metrics/';
      print('🌐 [updateSaccoFinancialMetrics] Request URL: $url');
      print(
        '📦 [updateSaccoFinancialMetrics] Request body: ${json.encode(requestBody)}',
      );

      print('🚀 [updateSaccoFinancialMetrics] Sending POST request...');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      print(
        '📨 [updateSaccoFinancialMetrics] Response received - Status: ${response.statusCode}',
      );
      print(
        '📨 [updateSaccoFinancialMetrics] Response headers: ${response.headers}',
      );
      print('📨 [updateSaccoFinancialMetrics] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [updateSaccoFinancialMetrics] Success! Parsing response...');
        final result = json.decode(response.body);
        print('✅ [updateSaccoFinancialMetrics] Parsed result: $result');
        return result;
      } else {
        final errorBody = response.body;
        print(
          '❌ [updateSaccoFinancialMetrics] Error response - Status: ${response.statusCode}',
        );
        print('❌ [updateSaccoFinancialMetrics] Error body: $errorBody');

        // Try to parse error details
        try {
          print(
            '🔍 [updateSaccoFinancialMetrics] Attempting to parse error JSON...',
          );
          final errorData = json.decode(errorBody);
          print(
            '🔍 [updateSaccoFinancialMetrics] Parsed error data: $errorData',
          );

          if (errorData is Map && errorData.containsKey('error')) {
            final errorMsg = '${errorData['error']}';
            print(
              '❌ [updateSaccoFinancialMetrics] Throwing parsed error: $errorMsg',
            );
            throw Exception(errorMsg);
          } else if (errorData is Map) {
            final errorMsg = 'Server error: ${errorData.toString()}';
            print(
              '❌ [updateSaccoFinancialMetrics] Throwing map error: $errorMsg',
            );
            throw Exception(errorMsg);
          }
        } catch (parseError) {
          print(
            '⚠️ [updateSaccoFinancialMetrics] JSON parse error: $parseError',
          );
          // If can't parse as JSON, use raw response
        }

        final errorMsg =
            'Failed to update financial metrics: ${response.statusCode} - $errorBody';
        print(
          '❌ [updateSaccoFinancialMetrics] Throwing final error: $errorMsg',
        );
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [updateSaccoFinancialMetrics] Caught exception: $e');
      print(
        '💥 [updateSaccoFinancialMetrics] Exception type: ${e.runtimeType}',
      );
      print(
        '💥 [updateSaccoFinancialMetrics] Stack trace: ${StackTrace.current}',
      );
      throw Exception('Error updating financial metrics: $e');
    }
  }

  /// Alternative method using PUT for updates (if your backend supports it)
  static Future<Map<String, dynamic>> putSaccoFinancialMetrics(
    dynamic saccoId,
    Map<String, dynamic> metricsData,
  ) async {
    print('🚀 [putSaccoFinancialMetrics] Starting with saccoId: $saccoId');
    print('📊 [putSaccoFinancialMetrics] Metrics data: $metricsData');

    try {
      print('📝 [putSaccoFinancialMetrics] Parsing ID...');
      final id = _parseId(saccoId);
      print('✅ [putSaccoFinancialMetrics] Parsed ID: $id');

      print('🔑 [putSaccoFinancialMetrics] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [putSaccoFinancialMetrics] Headers obtained: ${headers.keys}');

      final url = '$baseUrl/api/sacco/$id/financial-metrics/';
      print('🌐 [putSaccoFinancialMetrics] Request URL: $url');
      print(
        '📦 [putSaccoFinancialMetrics] Request body: ${json.encode(metricsData)}',
      );

      print('🚀 [putSaccoFinancialMetrics] Sending PUT request...');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(metricsData),
      );

      print(
        '📨 [putSaccoFinancialMetrics] Response received - Status: ${response.statusCode}',
      );
      print(
        '📨 [putSaccoFinancialMetrics] Response headers: ${response.headers}',
      );
      print('📨 [putSaccoFinancialMetrics] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [putSaccoFinancialMetrics] Success! Parsing response...');
        final result = json.decode(response.body);
        print('✅ [putSaccoFinancialMetrics] Parsed result: $result');
        return result;
      } else {
        final errorBody = response.body;
        print(
          '❌ [putSaccoFinancialMetrics] Error response - Status: ${response.statusCode}',
        );
        print('❌ [putSaccoFinancialMetrics] Error body: $errorBody');

        try {
          print(
            '🔍 [putSaccoFinancialMetrics] Attempting to parse error JSON...',
          );
          final errorData = json.decode(errorBody);
          print('🔍 [putSaccoFinancialMetrics] Parsed error data: $errorData');

          if (errorData is Map && errorData.containsKey('error')) {
            final errorMsg = '${errorData['error']}';
            print(
              '❌ [putSaccoFinancialMetrics] Throwing parsed error: $errorMsg',
            );
            throw Exception(errorMsg);
          }
        } catch (parseError) {
          print('⚠️ [putSaccoFinancialMetrics] JSON parse error: $parseError');
          // If can't parse as JSON, use raw response
        }

        final errorMsg =
            'Failed to update financial metrics: ${response.statusCode} - $errorBody';
        print('❌ [putSaccoFinancialMetrics] Throwing final error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [putSaccoFinancialMetrics] Caught exception: $e');
      print('💥 [putSaccoFinancialMetrics] Exception type: ${e.runtimeType}');
      print('💥 [putSaccoFinancialMetrics] Stack trace: ${StackTrace.current}');
      throw Exception('Error updating financial metrics: $e');
    }
  }

  // ==================== BATCH UPDATE METHODS ====================

  /// Batch update multiple sacco financial metrics (superuser only)
  static Future<Map<String, dynamic>> batchUpdateFinancialMetrics(
    List<Map<String, dynamic>> updates,
  ) async {
    print(
      '🚀 [batchUpdateFinancialMetrics] Starting with ${updates.length} updates',
    );
    print('📊 [batchUpdateFinancialMetrics] Updates data: $updates');

    try {
      print('🔑 [batchUpdateFinancialMetrics] Getting headers...');
      final headers = await _getHeaders();
      print(
        '✅ [batchUpdateFinancialMetrics] Headers obtained: ${headers.keys}',
      );

      final requestBody = {'updates': updates};

      final url = '$baseUrl/sacco/admin/financial-metrics/batch-update/';
      print('🌐 [batchUpdateFinancialMetrics] Request URL: $url');
      print(
        '📦 [batchUpdateFinancialMetrics] Request body: ${json.encode(requestBody)}',
      );

      print('🚀 [batchUpdateFinancialMetrics] Sending POST request...');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      print(
        '📨 [batchUpdateFinancialMetrics] Response received - Status: ${response.statusCode}',
      );
      print(
        '📨 [batchUpdateFinancialMetrics] Response headers: ${response.headers}',
      );
      print('📨 [batchUpdateFinancialMetrics] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [batchUpdateFinancialMetrics] Success! Parsing response...');
        final result = json.decode(response.body);
        print('✅ [batchUpdateFinancialMetrics] Parsed result: $result');
        return result;
      } else {
        final errorBody = response.body;
        print(
          '❌ [batchUpdateFinancialMetrics] Error response - Status: ${response.statusCode}',
        );
        print('❌ [batchUpdateFinancialMetrics] Error body: $errorBody');

        try {
          print(
            '🔍 [batchUpdateFinancialMetrics] Attempting to parse error JSON...',
          );
          final errorData = json.decode(errorBody);
          print(
            '🔍 [batchUpdateFinancialMetrics] Parsed error data: $errorData',
          );

          if (errorData is Map && errorData.containsKey('error')) {
            final errorMsg = '${errorData['error']}';
            print(
              '❌ [batchUpdateFinancialMetrics] Throwing parsed error: $errorMsg',
            );
            throw Exception(errorMsg);
          }
        } catch (parseError) {
          print(
            '⚠️ [batchUpdateFinancialMetrics] JSON parse error: $parseError',
          );
          // If can't parse as JSON, use raw response
        }

        final errorMsg =
            'Failed to batch update metrics: ${response.statusCode} - $errorBody';
        print(
          '❌ [batchUpdateFinancialMetrics] Throwing final error: $errorMsg',
        );
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [batchUpdateFinancialMetrics] Caught exception: $e');
      print(
        '💥 [batchUpdateFinancialMetrics] Exception type: ${e.runtimeType}',
      );
      print(
        '💥 [batchUpdateFinancialMetrics] Stack trace: ${StackTrace.current}',
      );
      throw Exception('Error batch updating metrics: $e');
    }
  }

  // ==================== REVIEWS MANAGEMENT ====================

  // Get all reviews with pagination
  static Future<Map<String, dynamic>> getAllReviews({
    int passengerPage = 1,
    int ownerPage = 1,
    int pageSize = 10,
  }) async {
    print(
      '🚀 [getAllReviews] Starting with passengerPage: $passengerPage, ownerPage: $ownerPage, pageSize: $pageSize',
    );

    try {
      final url =
          '$baseUrl$adminPath/reviews/all/?passenger_page=$passengerPage&owner_page=$ownerPage&page_size=$pageSize';
      print('🌐 [getAllReviews] Request URL: $url');

      print('🔑 [getAllReviews] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [getAllReviews] Headers obtained: ${headers.keys}');

      print('🚀 [getAllReviews] Sending GET request...');
      final response = await http.get(Uri.parse(url), headers: headers);

      print(
        '📨 [getAllReviews] Response received - Status: ${response.statusCode}',
      );
      print('📨 [getAllReviews] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [getAllReviews] Success! Parsing response...');
        final result = json.decode(response.body);
        print('✅ [getAllReviews] Parsed result keys: ${result.keys}');
        return result;
      } else {
        final errorMsg = 'Failed to load reviews: ${response.statusCode}';
        print('❌ [getAllReviews] Error: $errorMsg');
        print('❌ [getAllReviews] Error body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [getAllReviews] Caught exception: $e');
      print('💥 [getAllReviews] Exception type: ${e.runtimeType}');
      throw Exception('Error fetching reviews: $e');
    }
  }

  // Get passenger reviews
  static Future<List<dynamic>> getPassengerReviews() async {
    print('🚀 [getPassengerReviews] Starting...');

    try {
      final url = '$baseUrl$adminPath/reviews/passenger/';
      print('🌐 [getPassengerReviews] Request URL: $url');

      print('🔑 [getPassengerReviews] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [getPassengerReviews] Headers obtained: ${headers.keys}');

      print('🚀 [getPassengerReviews] Sending GET request...');
      final response = await http.get(Uri.parse(url), headers: headers);

      print(
        '📨 [getPassengerReviews] Response received - Status: ${response.statusCode}',
      );
      print('📨 [getPassengerReviews] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [getPassengerReviews] Success! Parsing response...');
        final data = json.decode(response.body);
        print('✅ [getPassengerReviews] Parsed data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          print(
            '✅ [getPassengerReviews] Found paginated response with ${data['results']?.length ?? 0} results',
          );
          return List<dynamic>.from(data['results'] ?? []);
        } else if (data is List) {
          print(
            '✅ [getPassengerReviews] Found list response with ${data.length} items',
          );
          return List<dynamic>.from(data);
        } else {
          final errorMsg = 'Unexpected response format for passenger reviews';
          print('❌ [getPassengerReviews] Error: $errorMsg');
          print('❌ [getPassengerReviews] Data structure: $data');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg =
            'Failed to load passenger reviews: ${response.statusCode}';
        print('❌ [getPassengerReviews] Error: $errorMsg');
        print('❌ [getPassengerReviews] Error body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [getPassengerReviews] Caught exception: $e');
      print('💥 [getPassengerReviews] Exception type: ${e.runtimeType}');
      throw Exception('Error fetching passenger reviews: $e');
    }
  }

  // Get owner reviews
  static Future<List<dynamic>> getOwnerReviews() async {
    print('🚀 [getOwnerReviews] Starting...');

    try {
      final url = '$baseUrl$adminPath/reviews/owner/';
      print('🌐 [getOwnerReviews] Request URL: $url');

      print('🔑 [getOwnerReviews] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [getOwnerReviews] Headers obtained: ${headers.keys}');

      print('🚀 [getOwnerReviews] Sending GET request...');
      final response = await http.get(Uri.parse(url), headers: headers);

      print(
        '📨 [getOwnerReviews] Response received - Status: ${response.statusCode}',
      );
      print('📨 [getOwnerReviews] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [getOwnerReviews] Success! Parsing response...');
        final data = json.decode(response.body);
        print('✅ [getOwnerReviews] Parsed data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          print(
            '✅ [getOwnerReviews] Found paginated response with ${data['results']?.length ?? 0} results',
          );
          return List<dynamic>.from(data['results'] ?? []);
        } else if (data is List) {
          print(
            '✅ [getOwnerReviews] Found list response with ${data.length} items',
          );
          return List<dynamic>.from(data);
        } else {
          final errorMsg = 'Unexpected response format for owner reviews';
          print('❌ [getOwnerReviews] Error: $errorMsg');
          print('❌ [getOwnerReviews] Data structure: $data');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Failed to load owner reviews: ${response.statusCode}';
        print('❌ [getOwnerReviews] Error: $errorMsg');
        print('❌ [getOwnerReviews] Error body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [getOwnerReviews] Caught exception: $e');
      print('💥 [getOwnerReviews] Exception type: ${e.runtimeType}');
      throw Exception('Error fetching owner reviews: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Debug method to check user permissions and authentication status
  static Future<Map<String, dynamic>> checkUserPermissions() async {
    print('🚀 [checkUserPermissions] Starting...');

    try {
      print('🔑 [checkUserPermissions] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [checkUserPermissions] Headers obtained: ${headers.keys}');

      final url = '$baseUrl$adminPath/dashboard/';
      print('🌐 [checkUserPermissions] Request URL: $url');

      // Try to access the dashboard to check permissions
      print('🚀 [checkUserPermissions] Sending GET request...');
      final response = await http.get(Uri.parse(url), headers: headers);

      print(
        '📨 [checkUserPermissions] Response received - Status: ${response.statusCode}',
      );
      print('📨 [checkUserPermissions] Response body: ${response.body}');

      final result = {
        'status_code': response.statusCode,
        'is_authenticated': response.statusCode != 401,
        'is_admin': response.statusCode == 200,
        'response_body':
            response.statusCode == 200
                ? json.decode(response.body)
                : response.body,
      };

      print('✅ [checkUserPermissions] Result: $result');
      return result;
    } catch (e) {
      print('💥 [checkUserPermissions] Caught exception: $e');
      print('💥 [checkUserPermissions] Exception type: ${e.runtimeType}');

      final result = {
        'status_code': 0,
        'is_authenticated': false,
        'is_admin': false,
        'error': e.toString(),
      };

      print('❌ [checkUserPermissions] Error result: $result');
      return result;
    }
  }

  /// Get user profile information
  static Future<Map<String, dynamic>> getUserProfile() async {
    print('🚀 [getUserProfile] Starting...');

    try {
      print('🔑 [getUserProfile] Getting headers...');
      final headers = await _getHeaders();
      print('✅ [getUserProfile] Headers obtained: ${headers.keys}');

      final url = '$baseUrl/api/user/profile/';
      print('🌐 [getUserProfile] Request URL: $url');

      print('🚀 [getUserProfile] Sending GET request...');
      final response = await http.get(Uri.parse(url), headers: headers);

      print(
        '📨 [getUserProfile] Response received - Status: ${response.statusCode}',
      );
      print('📨 [getUserProfile] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [getUserProfile] Success! Parsing response...');
        final result = json.decode(response.body);
        print('✅ [getUserProfile] Parsed result keys: ${result.keys}');
        return result;
      } else {
        final errorMsg = 'Failed to load user profile: ${response.statusCode}';
        print('❌ [getUserProfile] Error: $errorMsg');
        print('❌ [getUserProfile] Error body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('💥 [getUserProfile] Caught exception: $e');
      print('💥 [getUserProfile] Exception type: ${e.runtimeType}');
      throw Exception('Error fetching user profile: $e');
    }
  }
}
