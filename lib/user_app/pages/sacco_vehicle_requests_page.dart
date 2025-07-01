// lib/user_app/pages/sacco_vehicle_requests_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Updated _buildRequestCard method to correctly access nested vehicle data
  Widget _buildRequestCard(Map<String, dynamic> request) {
    print('DEBUG: Building request card for request: $request');
    
    // Extract request data - the vehicle data is not nested under 'vehicle_details'
    final requestId = request['id'] ?? request['request_id'];
    final vehicleOwnerName = request['owner_name'] ?? 'Unknown Owner';
    final vehicleDocuments = request['vehicle_documents'] ?? [];
    
    // Vehicle information is directly in the request object based on your serializer
    final vehicleRegistration = request['vehicle_registration'] ?? 'N/A';
    final vehicleMake = request['vehicle_make'] ?? 'Unknown';
    final vehicleModel = request['vehicle_model'] ?? 'Model';
    final vehicleYear = request['vehicle_year']?.toString() ?? '';
    
    final requestDate = request['requested_at'] ?? '';
    final phoneNumber = request['owner_phone'] ?? '';
    final experienceYears = request['experience_years']?.toString() ?? '';
    final reasonForJoining = request['reason_for_joining'] ?? '';
    final preferredRoutes = request['preferred_routes'] ?? [];

    print('DEBUG: Found ${vehicleDocuments.length} documents for this vehicle');

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
                          'Registration: $vehicleRegistration',
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Model: $vehicleMake $vehicleModel',
                          style: AppTextStyles.body2,
                        ),
                        if (vehicleYear.isNotEmpty)
                          Text(
                            'Year: $vehicleYear',
                            style: AppTextStyles.body2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Additional request information
            if (experienceYears.isNotEmpty || reasonForJoining.isNotEmpty || preferredRoutes.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildRequestInfoSection(experienceYears, reasonForJoining, preferredRoutes),
            ],
            
            // Vehicle Documents Section
            if (vehicleDocuments.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildDocumentsSection(vehicleDocuments),
            ],
            
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

  // Add this method to display additional request information
  Widget _buildRequestInfoSection(String experienceYears, String reasonForJoining, List<dynamic> preferredRoutes) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.brown,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Request Details',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          if (experienceYears.isNotEmpty)
            Text(
              'Experience: $experienceYears years',
              style: AppTextStyles.body2,
            ),
          if (preferredRoutes.isNotEmpty)
            Text(
              'Preferred Routes: ${preferredRoutes.join(', ')}',
              style: AppTextStyles.body2,
            ),
          if (reasonForJoining.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason for joining:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              reasonForJoining,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Updated documents section to handle the correct data structure
  Widget _buildDocumentsSection(List<dynamic> documents) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.brown.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.brown,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Vehicle Documents (${documents.length})',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
        ],
      ),
    );
  }

  // Updated document item to handle the correct field names from your serializer
  Widget _buildDocumentItem(Map<String, dynamic> document) {
    final documentType = document['document_type_display'] ?? 
                        document['document_type'] ?? 
                        'Unknown Document';
    final documentName = document['document_name'] ?? '';
    final isVerified = document['is_verified'] ?? false;
    final expiryDate = document['expiry_date'];
    final isExpired = document['is_expired'] ?? false;
    final daysUntilExpiry = document['days_until_expiry'];
    final documentUrl = document['document_url'];

    Color statusColor = AppColors.grey;
    String statusText = 'Unverified';
    IconData statusIcon = Icons.help_outline;

    if (isVerified) {
      statusColor = AppColors.green;
      statusText = 'Verified';
      statusIcon = Icons.verified;
    } else if (isExpired) {
      statusColor = AppColors.red;
      statusText = 'Expired';
      statusIcon = Icons.error_outline;
    } else if (daysUntilExpiry != null && daysUntilExpiry <= 30) {
      statusColor = AppColors.orange;
      statusText = 'Expiring Soon';
      statusIcon = Icons.warning_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(document['document_type']),
            color: AppColors.brown,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentType,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (documentName.isNotEmpty)
                  Text(
                    documentName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                if (expiryDate != null)
                  Text(
                    'Expires: ${_formatDate(expiryDate)}',
                    style: AppTextStyles.caption.copyWith(
                      color: isExpired ? AppColors.red : AppColors.grey,
                    ),
                  ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // View document button
          if (documentUrl != null && documentUrl.toString().isNotEmpty) ...[
            const SizedBox(width: AppDimensions.paddingSmall),
            IconButton(
              onPressed: () => _viewDocument(documentUrl, documentType),
              icon: Icon(
                Icons.visibility,
                color: AppColors.brown,
                size: 20,
              ),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  // Updated to handle the correct document types from your model
  IconData _getDocumentIcon(String? documentType) {
    switch (documentType?.toLowerCase()) {
      case 'logbook':
        return Icons.book;
      case 'insurance':
        return Icons.security;
      case 'inspection':
        return Icons.search;
      case 'license':
        return Icons.card_membership;
      case 'permit':
        return Icons.approval;
      case 'ntsa':
        return Icons.verified_user;
      case 'other':
        return Icons.description;
      default:
        return Icons.description;
    }
  }

  void _viewDocument(String documentUrl, String documentType) async {
    try {
      final Uri url = Uri.parse(documentUrl);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _getDocumentIcon(documentType.toLowerCase()),
                color: AppColors.brown,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  documentType,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.brown,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will open the document in your default browser or document viewer.',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: AppColors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        documentUrl,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Could not open document'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: AppColors.white,
              ),
              label: const Text('Open Document'),
            ),
          ],
          ),
      );
    } catch (e) {
      print('DEBUG: Error opening document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      print('DEBUG: Error formatting date: $dateString, error: $e');
      return dateString; // Return original string if parsing fails
    }
  }
}