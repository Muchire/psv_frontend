import 'package:flutter/material.dart';
import '/services/vehicle_api_service.dart';
import '../utils/constants.dart';

class VehicleDetailPage extends StatefulWidget {
  final dynamic vehicleId;

  const VehicleDetailPage({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver{
  Map<String, dynamic> _vehicleData = {};
  Map<String, dynamic> _vehicleStats = {};
  List<dynamic> _vehicleDocuments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVehicleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text(
          _vehicleData['registration_number'] ?? 'Vehicle Details',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brown),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditVehicleDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'refresh':
                  _refreshData();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.brown),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Vehicle'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brown,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.brown,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
    );
  }

  Future<void> _loadVehicleData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _getVehicleDetails(),
        VehicleOwnerService.getVehicleStats(widget.vehicleId),
        VehicleOwnerService.getVehicleDocuments(widget.vehicleId),
      ]);

      setState(() {
        _vehicleData = results[0] as Map<String, dynamic>;
        _vehicleStats = results[1] as Map<String, dynamic>;
        _vehicleDocuments = results[2] as List<dynamic>;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load vehicle data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getVehicleDetails() async {
    // Since there's no direct getVehicle method, we'll get it from the vehicles list
    final vehicles = await VehicleOwnerService.getVehicles();
    final vehicleId = widget.vehicleId.toString();
    
    final vehicle = vehicles.firstWhere(
      (v) => v['id'].toString() == vehicleId,
      orElse: () => throw Exception('Vehicle not found'),
    );
    
    return vehicle as Map<String, dynamic>;
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadVehicleData();
    setState(() => _isRefreshing = false);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleInfoCard(),
          const SizedBox(height: 16),
          _buildQuickStatsCard(),
          const SizedBox(height: 16),
          _buildEarningsCard(),
          const SizedBox(height: 16),
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: AppColors.brown,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicleData['registration_number'] ?? 'Unknown',
                      style: AppTextStyles.heading2,
                    ),
                    Text(
                      '${_vehicleData['make'] ?? ''} ${_vehicleData['model'] ?? ''}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Year', _vehicleData['year']?.toString() ?? 'N/A'),
          _buildInfoRow('Capacity', '${_vehicleData['capacity'] ?? 'N/A'} passengers'),
          _buildInfoRow('Route', _vehicleData['route'] ?? 'Not assigned'),
          _buildInfoRow('Sacco', _vehicleData['sacco_name'] ?? 'Not joined'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final stats = [
      {
        'title': 'Total Trips',
        'value': _vehicleStats['total_trips']?.toString() ?? '0',
        'icon': Icons.route,
        'color': AppColors.purple,
      },
      {
        'title': 'This Month',
        'value': _vehicleStats['monthly_trips']?.toString() ?? '0',
        'icon': Icons.calendar_today,
        'color': AppColors.success,
      },
      {
        'title': 'Average Rating',
        'value': (_vehicleStats['average_rating']?.toStringAsFixed(1) ?? '0.0'),
        'icon': Icons.star,
        'color': AppColors.warning,
      },
      {
        'title': 'Fuel Efficiency',
        'value': '${_vehicleStats['fuel_efficiency']?.toStringAsFixed(1) ?? '0.0'} km/l',
        'icon': Icons.local_gas_station,
        'color': AppColors.tan,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stat['value'] as String,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            stat['title'] as String,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppColors.white,
                size: 28,
              ),
              Text(
                'Earnings',
                style: AppTextStyles.heading3.copyWith(color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This Month',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          Text(
            'KES ${_vehicleData['monthly_earnings'] ?? 0}',
            style: AppTextStyles.heading1.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'KES ${_vehicleStats['total_earnings'] ?? 0}',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg per Trip',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'KES ${_vehicleStats['average_earning_per_trip'] ?? 0}',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _vehicleData['status'] ?? 'active';
    final isActive = status.toLowerCase() == 'active';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Status',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  _toggleVehicleStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppColors.error : AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: Text(isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last Updated: ${_vehicleData['updated_at'] ?? 'Unknown'}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _vehicleDocuments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents uploaded',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload important vehicle documents here',
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddDocumentDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brown,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Upload Document'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicleDocuments.length,
              itemBuilder: (context, index) {
                final document = _vehicleDocuments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: AppColors.brown,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document['name'] ?? 'Unknown Document',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              document['type'] ?? 'Unknown Type',
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              'Uploaded: ${document['uploaded_at'] ?? 'Unknown'}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // Implement document download
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showEditVehicleDialog() {
    // Implement edit vehicle dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: const Text('Edit vehicle functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement edit functionality
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVehicle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog() {
    // Implement add document dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Document upload functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement document upload functionality
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVehicleStatus() async {
    try {
      final currentStatus = _vehicleData['status'] ?? 'active';
      final newStatus = currentStatus.toLowerCase() == 'active' ? 'inactive' : 'active';
      
      await VehicleOwnerService.updateVehicle(
        widget.vehicleId,
        {'status': newStatus},
      );
      
      setState(() {
        _vehicleData['status'] = newStatus;
      });
      
      _showSuccessSnackBar('Vehicle status updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update vehicle status: $e');
    }
  }

  Future<void> _deleteVehicle() async {
    try {
      await VehicleOwnerService.deleteVehicle(widget.vehicleId);
      _showSuccessSnackBar('Vehicle deleted successfully');
      Navigator.pop(context, true); // Return true to indicate deletion
    } catch (e) {
      _showErrorSnackBar('Failed to delete vehicle: $e');
    }
  }
}