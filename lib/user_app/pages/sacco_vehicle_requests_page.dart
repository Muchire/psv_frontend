// lib/user_app/pages/sacco_vehicle_requests_page.dart
import 'package:flutter/material.dart';
import '../../services/vehicle_api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class SaccoVehicleRequestsPage extends StatefulWidget {
  final String saccoId;

  const SaccoVehicleRequestsPage({
    super.key,
    required this.saccoId,
  });

  @override
  State<SaccoVehicleRequestsPage> createState() => _SaccoVehicleRequestsPageState();
}

class _SaccoVehicleRequestsPageState extends State<SaccoVehicleRequestsPage> {
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    print('DEBUG: _loadPendingRequests called for saccoId: ${widget.saccoId}');
    print('DEBUG: saccoId type: ${widget.saccoId.runtimeType}');
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('DEBUG: About to call VehicleOwnerService.getPendingSaccoRequests');
      final requests = await VehicleOwnerService.getPendingSaccoRequests(widget.saccoId);
      print('DEBUG: Successfully received ${requests.length} requests');
      print('DEBUG: Requests data: $requests');
      
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error in _loadPendingRequests: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(dynamic requestId, String vehicleOwnerName) async {
    if (_isProcessing) return;

    print('DEBUG: _approveRequest called for requestId: $requestId, owner: $vehicleOwnerName');
    print('DEBUG: requestId type: ${requestId.runtimeType}');

    final confirmed = await _showConfirmationDialog(
      title: 'Approve Request',
      message: 'Are you sure you want to approve $vehicleOwnerName\'s request to join your sacco?',
      confirmText: 'Approve',
      confirmColor: AppColors.green,
    );

    if (!confirmed) {
      print('DEBUG: User cancelled approval');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('DEBUG: About to call VehicleOwnerService.approveSaccoRequest');
      await VehicleOwnerService.approveSaccoRequest(requestId);
      print('DEBUG: Successfully approved request');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully approved $vehicleOwnerName\'s request'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reload the requests list
        print('DEBUG: Reloading requests after approval');
        await _loadPendingRequests();
      }
    } catch (e) {
      print('DEBUG: Error in _approveRequest: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: ${e.toString()}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(dynamic requestId, String vehicleOwnerName) async {
    if (_isProcessing) return;

    print('DEBUG: _rejectRequest called for requestId: $requestId, owner: $vehicleOwnerName');
    print('DEBUG: requestId type: ${requestId.runtimeType}');

    final result = await _showRejectDialog(vehicleOwnerName);
    if (result == null) {
      print('DEBUG: User cancelled rejection');
      return;
    }

    print('DEBUG: Rejection reason: $result');

    setState(() {
      _isProcessing = true;
    });

    try {
      print('DEBUG: About to call VehicleOwnerService.rejectSaccoRequest');
      await VehicleOwnerService.rejectSaccoRequest(requestId, result);
      print('DEBUG: Successfully rejected request');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully rejected $vehicleOwnerName\'s request'),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reload the requests list
        print('DEBUG: Reloading requests after rejection');
        await _loadPendingRequests();
      }
    } catch (e) {
      print('DEBUG: Error in _rejectRequest: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request: ${e.toString()}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.brown,
            ),
          ),
          content: Text(
            message,
            style: AppTextStyles.body1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: AppColors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<String?> _showRejectDialog(String vehicleOwnerName) async {
    final TextEditingController reasonController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reject Request',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.brown,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reject $vehicleOwnerName\'s request?',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                'Reason for rejection:',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please provide a reason for rejection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    borderSide: BorderSide(color: AppColors.brown),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please provide a reason for rejection'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Requests'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? Center(
                  child: ErrorDisplayWidget(
                    error: _error!,
                    onRetry: _loadPendingRequests,
                  ),
                )
              : _buildRequestsList(),
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No Pending Requests',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Vehicle owners who want to join your sacco will appear here.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.brown,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    print('DEBUG: Building request card for request: $request');
    
    // Extract request data with fallbacks for different possible field names
    final requestId = request['id'] ?? request['request_id'];
    
    // Fix: Use the correct field name from your debug output
    final vehicleOwnerName = request['owner_name'] ?? 
                            request['vehicle_owner_name'] ?? 
                            request['user_name'] ?? 
                            request['name'] ?? 
                            'Unknown Owner';
    
    // Fix: Use 'vehicle_details' instead of 'vehicle_info' or 'vehicle'
    final vehicleInfo = request['vehicle_details'] ?? {};
    
    // Fix: Use the correct field names from your debug output
    final plateNumber = vehicleInfo['registration_number'] ?? 
                      vehicleInfo['plate_number'] ?? 
                      'N/A';
    
    final vehicleModel = '${vehicleInfo['make'] ?? 'Unknown'} ${vehicleInfo['model'] ?? 'Model'}';
    
    // Fix: Use the correct field name
    final requestDate = request['requested_at'] ?? request['created_at'] ?? request['request_date'] ?? '';
    
    // Fix: Use the correct field name
    final phoneNumber = request['owner_phone'] ?? request['phone_number'] ?? request['contact'] ?? '';
    
    // Additional vehicle info that's available
    final vehicleType = vehicleInfo['vehicle_type'] ?? '';
    final seatingCapacity = vehicleInfo['seating_capacity']?.toString() ?? '';
    final year = vehicleInfo['year']?.toString() ?? '';

    print('DEBUG: Extracted data - requestId: $requestId, owner: $vehicleOwnerName, plate: $plateNumber, model: $vehicleModel');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with owner info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.brown,
                  radius: 25,
                  child: Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleOwnerName,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (phoneNumber.isNotEmpty)
                        Text(
                          phoneNumber,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      if (requestDate.isNotEmpty)
                        Text(
                          'Requested: ${_formatDate(requestDate)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'PENDING',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Vehicle information
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColors.brown,
                    size: 24,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Information',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.brown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Model: $vehicleModel',
                          style: AppTextStyles.body2,
                        ),
                        Text(
                          'Registration: $plateNumber',
                          style: AppTextStyles.body2,
                        ),
                        if (vehicleType.isNotEmpty)
                          Text(
                            'Type: ${vehicleType.toUpperCase()}',
                            style: AppTextStyles.body2,
                          ),
                        if (seatingCapacity.isNotEmpty)
                          Text(
                            'Capacity: $seatingCapacity seats',
                            style: AppTextStyles.body2,
                          ),
                        if (year.isNotEmpty)
                          Text(
                            'Year: $year',
                            style: AppTextStyles.body2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing 
                        ? null 
                        : () => _rejectRequest(requestId, vehicleOwnerName),
                    icon: _isProcessing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing 
                        ? null 
                        : () => _approveRequest(requestId, vehicleOwnerName),
                    icon: _isProcessing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}