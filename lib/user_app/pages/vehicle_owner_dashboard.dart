import 'package:flutter/material.dart';
import '/services/vehicle_api_service.dart';
import '../utils/constants.dart';
import 'vehicle_sacco_detail_page.dart';
import 'vehicle_detail_page.dart';
import 'profile_page.dart';
import 'all_saccos_page.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class VehicleOwnerDashboard extends StatefulWidget {
  const VehicleOwnerDashboard({super.key});

  @override
  State<VehicleOwnerDashboard> createState() => _VehicleOwnerDashboardState();
}

class _VehicleOwnerDashboardState extends State<VehicleOwnerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _vehicles = [];
  List<dynamic> _joinRequests = [];
  List<dynamic> _availableSaccos = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load data individually to better handle errors
      print('DEBUG: Loading dashboard data...');

      // Load dashboard data
      try {
        _dashboardData = await VehicleOwnerService.getDashboardData();
        print('DEBUG: Dashboard data loaded: $_dashboardData');
      } catch (e) {
        print('DEBUG: Error loading dashboard data: $e');
        _dashboardData = {};
      }

      // Load vehicles
      try {
        _vehicles = await VehicleOwnerService.getVehicles();
        print('DEBUG: Vehicles loaded: ${_vehicles.length} vehicles');
      } catch (e) {
        print('DEBUG: Error loading vehicles: $e');
        _vehicles = [];
      }

      // Load join requests
      try {
        _joinRequests = await VehicleOwnerService.getJoinRequests();
        _pendingRequestsCount = _joinRequests.length;
        print('DEBUG: Join requests loaded: ${_joinRequests.length} requests');
      } catch (e) {
        print('DEBUG: Error loading join requests: $e');
        _joinRequests = [];
        _pendingRequestsCount = 0;
      }

      // Load available saccos
      try {
        final saccoResponse = await VehicleOwnerService.getAvailableSaccos();
        print('DEBUG: Raw sacco response: $saccoResponse');

        // Handle different response structures
        if (saccoResponse.containsKey('results')) {
          _availableSaccos = List<dynamic>.from(saccoResponse['results'] ?? []);
        } else if (saccoResponse.containsKey('data')) {
          _availableSaccos = List<dynamic>.from(saccoResponse['data'] ?? []);
        } else if (saccoResponse.containsKey('saccos')) {
          _availableSaccos = List<dynamic>.from(saccoResponse['saccos'] ?? []);
        } else if (saccoResponse is List) {
          _availableSaccos = List<dynamic>.from(saccoResponse as Iterable);
        } else {
          _availableSaccos = [saccoResponse];
        }

        print('DEBUG: Available saccos processed: ${_availableSaccos.length} saccos');
      } catch (e) {
        print('DEBUG: Error loading available saccos: $e');
        _availableSaccos = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('DEBUG: General error in _loadDashboardData: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadDashboardData();
    setState(() => _isRefreshing = false);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.green),
      );
    }
  }

  Future<void> _handleNavigationResult(dynamic result) async {
    if (result == true || result == 'refresh' || result == 'updated') {
      await _refreshData();
    }
  }

  void _navigateToVehicleDetail(dynamic vehicleId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicleId: vehicleId),
      ),
    );
    await _handleNavigationResult(result);
  }

  void _navigateToSaccoDetail(dynamic saccoId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSaccoDetailPage(saccoId: saccoId),
      ),
    );
    await _handleNavigationResult(result);
  }

  void _navigateToAllSaccos() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllSaccosPage(
          saccos: _availableSaccos,
          onSaccoTap: _navigateToSaccoDetail,
        ),
      ),
    );
    await _handleNavigationResult(result);
  }

  void _navigateToNotifications() {
    // TODO: Implement navigation to notifications/join requests page
    _showInfoSnackBar('Notifications page - Coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _dashboardData['owner_name'] != null
              ? '${_dashboardData['owner_name']} Dashboard'
              : 'Vehicle Owner Dashboard',
        ),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          // Notification icon with improved styling
          if (_pendingRequestsCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'You have notifications',
                  onPressed: _navigateToNotifications,
                ),
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_pendingRequestsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'No new notifications',
              onPressed: _navigateToNotifications,
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? Center(
                  child: ErrorDisplayWidget(
                    error: _error!,
                    onRetry: _loadDashboardData,
                  ),
                )
              : _buildDashboardContent(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brown,
        onPressed: () async {
          // TODO: Implement add vehicle navigation
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: AppDimensions.paddingMedium),
            if (_pendingRequestsCount > 0) ...[
              _buildPendingRequestsAlert(),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],
            _buildQuickStatsSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildMyVehiclesSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildAvailableSaccosSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsAlert() {
    return Card(
      elevation: 3,
      color: AppColors.orange.withOpacity(0.1),
      child: InkWell(
        onTap: _navigateToNotifications,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Icon(Icons.pending_actions, color: AppColors.orange, size: 32),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Join Requests',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_pendingRequestsCount request${_pendingRequestsCount == 1 ? '' : 's'} awaiting your review',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final ownerName = _dashboardData['owner_name'] ?? 'Vehicle Owner';
    final totalEarnings = _dashboardData['total_earnings'] ?? 0;
    final monthlyTrips = _dashboardData['monthly_trips'] ?? 0;
    final totalVehicles = _dashboardData['total_vehicles'] ?? _vehicles.length;

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brown, AppColors.carafe],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: AppColors.white, size: 32),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $ownerName!',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Vehicle Owner Dashboard',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Total Earnings This Month: KES ${totalEarnings.toStringAsFixed(2)}',
              style: AppTextStyles.heading3.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Vehicles', '$totalVehicles'),
                _buildQuickStat('Monthly Trips', '$monthlyTrips'),
                _buildQuickStat(
                  'Active Routes',
                  '${_dashboardData['active_routes'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Vehicles',
                '${_dashboardData['total_vehicles'] ?? _vehicles.length}',
                Icons.directions_car,
                AppColors.purple,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Monthly Earnings',
                'KES ${(_dashboardData['total_earnings'] ?? 0).toStringAsFixed(0)}',
                Icons.attach_money,
                AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Routes',
                '${_dashboardData['active_routes'] ?? 0}',
                Icons.route,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Pending Requests',
                '$_pendingRequestsCount',
                Icons.pending_actions,
                AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyVehiclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Vehicles',
              style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
            ),
            if (_vehicles.length > 3)
              TextButton(
                onPressed: () {
                  // Navigate to all vehicles page
                },
                child: Text(
                  'View All',
                  style: TextStyle(color: AppColors.brown),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        if (_vehicles.isEmpty)
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Row(
                children: [
                  Icon(Icons.directions_car, color: AppColors.grey, size: 32),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Text(
                      'No vehicles registered yet. Add your first vehicle to get started with earning opportunities.',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_vehicles
              .take(3)
              .map((vehicle) => _buildVehicleCard(vehicle))
              .toList()),
      ],
    );
  }

  Widget _buildVehicleCard(dynamic vehicle) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.brown.withOpacity(0.1),
          radius: 20,
          child: Icon(Icons.directions_bus, color: AppColors.brown, size: 20),
        ),
        title: Text(
          vehicle['registration_number'] ?? 'Unknown',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${vehicle['make']} ${vehicle['model']}',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 2),
            Text(
              'Status: ${vehicle['status'] ?? 'Active'}',
              style: AppTextStyles.caption.copyWith(
                color: vehicle['status'] == 'Active'
                    ? AppColors.green
                    : AppColors.grey,
              ),
            ),
            if (vehicle['sacco_name'] != null)
              Text(
                'Sacco: ${vehicle['sacco_name']}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'KES ${vehicle['monthly_earnings'] ?? 0}',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('This month', style: AppTextStyles.caption),
          ],
        ),
        onTap: () => _navigateToVehicleDetail(vehicle['id']),
      ),
    );
  }

  Widget _buildAvailableSaccosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Saccos',
              style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
            ),
            if (_availableSaccos.length > 2)
              TextButton(
                onPressed: _navigateToAllSaccos,
                child: Text(
                  'View All',
                  style: TextStyle(color: AppColors.brown),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        if (_availableSaccos.isEmpty)
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Row(
                children: [
                  Icon(Icons.business, color: AppColors.grey, size: 32),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Text(
                      'No saccos available at the moment. Check back later for new opportunities.',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_availableSaccos
              .take(2)
              .map((sacco) => _buildSaccoCard(sacco))
              .toList()),
      ],
    );
  }

  Widget _buildSaccoCard(dynamic sacco) {
    // Handle nested sacco data structure
    final saccoData = sacco['sacco'] ?? sacco;
    final routes = sacco['routes'] as List<dynamic>? ?? [];
    
    final saccoName = saccoData['name']?.toString() ?? 'Unknown Sacco';
    final saccoLocation = saccoData['location']?.toString() ?? 'Unknown Location';
    final totalVehicles = saccoData['total_vehicles'] ?? saccoData['vehicle_count'] ?? 0;
    final activeVehicles = saccoData['active_vehicles'] ?? 0;
    
    // Format routes for display
    String routesText = 'No routes available';
    if (routes.isNotEmpty) {
      final routeStrings = routes.map((route) {
        final start = route['start_location'] ?? '';
        final end = route['end_location'] ?? '';
        return '$start - $end';
      }).take(2).toList();
      
      routesText = routeStrings.join(', ');
      if (routes.length > 2) {
        routesText += ' (+${routes.length - 2} more)';
      }
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.blue.withOpacity(0.1),
          radius: 20,
          child: Text(
            saccoName.substring(0, 1).toUpperCase(),
            style: AppTextStyles.body1.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          saccoName,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              saccoLocation,
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 2),
            Text(
              'Routes: $routesText',
              style: AppTextStyles.caption.copyWith(color: AppColors.purple),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.directions_car, color: AppColors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$totalVehicles vehicles',
                  style: AppTextStyles.caption,
                ),
                if (activeVehicles > 0) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.check_circle, color: AppColors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$activeVehicles active',
                    style: AppTextStyles.caption.copyWith(color: AppColors.green),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.grey,
          size: 16,
        ),
        onTap: () => _navigateToSaccoDetail(saccoData['id']),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = _dashboardData['recent_activities'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        if (activities.isEmpty)
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.grey, size: 32),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Text(
                      'No recent activity. Your vehicle operations and sacco interactions will appear here.',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...activities
              .take(5)
              .map((activity) => _buildActivityCard(activity))
              .toList(),
      ],
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final activityType = activity['type']?.toString() ?? 'unknown';
    final activityMessage =
        activity['message']?.toString() ?? 'No details available';
    final activityDate = activity['date']?.toString() ?? 'Unknown date';

    IconData icon;
    Color iconColor;

    switch (activityType.toLowerCase()) {
      case 'sacco_join':
        icon = Icons.group_add;
        iconColor = AppColors.green;
        break;
      case 'vehicle_registered':
        icon = Icons.directions_car;
        iconColor = AppColors.blue;
        break;
      case 'earnings':
        icon = Icons.attach_money;
        iconColor = AppColors.green;
        break;
      case 'trip_completed':
        icon = Icons.check_circle;
        iconColor = AppColors.green;
        break;
      case 'maintenance':
        icon = Icons.build;
        iconColor = AppColors.orange;
        break;
      default:
        icon = Icons.info;
        iconColor = AppColors.grey;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          radius: 20,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          activityMessage,
          style: AppTextStyles.body1,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          activityDate,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.lightGrey,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0:
            // Dashboard - already here
            break;
          case 1:
            // Navigate to vehicles page
            _navigateToAllVehicles(context);
            break;
          case 2:
            // Navigate to saccos page
            _navigateToAllSaccos();
            break;
          case 3:
            // Navigate to earnings page
            _navigateToEarnings();
            break;
          case 4:
            // Navigate to profile page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.brown,
      unselectedItemColor: AppColors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.directions_car),
              if (_vehicles.length > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${_vehicles.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Vehicles',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.business),
              if (_availableSaccos.length > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${_availableSaccos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Saccos',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Earnings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // Helper methods for navigation
  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.blue,
        ),
      );
    }
  }

  void _navigateToAllVehicles(BuildContext context) {
    // TODO: Implement navigation to all vehicles page
    _showInfoSnackBar('All Vehicles page - Coming soon!');
  }

  void _navigateToEarnings() {
    // TODO: Implement navigation to earnings page
    _showInfoSnackBar('Earnings page - Coming soon!');
  }
}