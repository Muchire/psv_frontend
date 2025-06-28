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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final requests = await VehicleOwnerService.getPendingSaccoRequests(widget.saccoId);
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(dynamic requestId) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      await VehicleOwnerService.approveSaccoRequest(requestId);
      
      _showSuccessSnackBar('Request approved successfully!');
      await _loadPendingRequests(); // Refresh the list
    } catch (e) {
      _showErrorSnackBar('Failed to approve request: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectRequest(dynamic requestId) async {
    final reason = await _showRejectReasonDialog();
    if (reason == null || reason.trim().isEmpty) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      await VehicleOwnerService.rejectSaccoRequest(requestId, reason);
      
      _showSuccessSnackBar('Request rejected successfully!');
      await _loadPendingRequests(); // Refresh the list
    } catch (e) {
      _showErrorSnackBar('Failed to reject request: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String?> _showRejectReasonDialog() async {
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
                'Please provide a reason for rejecting this request:',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brown),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(reasonController.text.trim());
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
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
              Icons.inbox,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No pending requests',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'All vehicle owner requests have been processed',
              style: AppTextStyles.body2.copyWith(
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
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.brown.withOpacity(0.1),
                  child: Icon(
                    Icons.directions_car,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['owner_name'] ?? 'Unknown Owner',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.brown,
                        ),
                      ),
                      Text(
                        'Vehicle: ${request['vehicle_plate'] ?? 'Unknown'}',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
            
            // Request Details
            _buildDetailRow('Vehicle Model', request['vehicle_model'] ?? 'Not specified'),
            _buildDetailRow('Seating Capacity', '${request['seating_capacity'] ?? 'Not specified'}'),
            _buildDetailRow('Route', request['preferred_route'] ?? 'Not specified'),
            _buildDetailRow('Request Date', _formatDate(request['created_at'])),
            
            if (request['message'] != null && request['message'].toString().isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                'Message:',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brown,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  request['message'],
                  style: AppTextStyles.body2.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing 
                        ? null 
                        : () => _rejectRequest(request['id']),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                    ),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing 
                        ? null 
                        : () => _approveRequest(request['id']),
                    icon: Icon(
                      Icons.check,
                      size: 18,
                    ),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateTime.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTime.toString();
    }
  }
}