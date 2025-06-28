// lib/user_app/pages/sacco_admin_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/sacco_admin_service.dart';
import '../../services/vehicle_api_service.dart'; // Make sure this import is correct
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'sacco_routes_page.dart';
import 'sacco_reviews_page.dart';
import 'sacco_edit_page.dart';
import 'sacco_vehicle_requests_page.dart';

class SaccoAdminDashboard extends StatefulWidget {
  const SaccoAdminDashboard({super.key});

  @override
  State<SaccoAdminDashboard> createState() => _SaccoAdminDashboardState();
}

class _SaccoAdminDashboardState extends State<SaccoAdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
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

      final data = await SaccoAdminService.getDashboardData();
      
      // Load pending requests count - FIXED: Use VehicleApiService consistently
      final saccoId = data['sacco_info']?['id'];
      if (saccoId != null) {
        try {
          final pendingRequests = await VehicleOwnerService.getPendingSaccoRequests(saccoId.toString());
          _pendingRequestsCount = pendingRequests.length;
        } catch (e) {
          // If we can't load pending requests, don't fail the whole dashboard
          print('Error loading pending requests: $e');
          _pendingRequestsCount = 0;
        }
      }
      
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dashboardData?['sacco_info']?['name'] ?? 'Sacco Admin Dashboard'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          // Pending requests notification
          if (_pendingRequestsCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    final saccoId = _dashboardData?['sacco_info']?['id'];
                    if (saccoId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaccoVehicleRequestsPage(saccoId: saccoId.toString()),
                        ),
                      ).then((_) => _loadDashboardData());
                    }
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_pendingRequestsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
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
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
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
          _buildRecentReviewsSection(),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsAlert() {
    return Card(
      elevation: 3,
      color: AppColors.orange.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          final saccoId = _dashboardData?['sacco_info']?['id'];
          if (saccoId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaccoVehicleRequestsPage(saccoId: saccoId.toString()),
              ),
            ).then((_) => _loadDashboardData());
          }
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: AppColors.orange,
                size: 32,
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Vehicle Requests',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_pendingRequestsCount vehicle owner${_pendingRequestsCount == 1 ? '' : 's'} waiting for approval',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final saccoInfo = _dashboardData!['sacco_info'];
    final stats = _dashboardData!['statistics'];

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
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.white,
                  size: 32,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${saccoInfo['name']} Admin!',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        saccoInfo['location'],
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
              'Overall Rating: ${stats['overall_avg_rating']}/5.0',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Routes', '${stats['total_routes']}'),
                _buildQuickStat('Passenger Reviews', '${stats['total_passenger_reviews']}'),
                _buildQuickStat('Owner Reviews', '${stats['total_owner_reviews']}'),
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

  // Method to handle reviews page navigation with type casting error prevention
  void _navigateToReviewsPage() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading reviews..."),
              ],
            ),
          );
        },
      );

      // Small delay to ensure data is properly processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to reviews page
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SaccoReviewsPage(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load reviews: Type casting error. Please contact support.'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _navigateToReviewsPage(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildQuickStatsSection() {
    final stats = _dashboardData!['statistics'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Statistics',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Routes',
                '${stats['total_routes']}',
                Icons.route,
                AppColors.green,
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
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Passenger Rating',
                '${stats['passenger_avg_rating']}/5',
                Icons.star,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Owner Rating',
                '${stats['owner_avg_rating']}/5',
                Icons.business,
                AppColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              style: AppTextStyles.body2.copyWith(
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    final recentReviews = _dashboardData!['recent_reviews'];
    final passengerReviews = recentReviews['passenger_reviews'] as List;
    final ownerReviews = recentReviews['owner_reviews'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reviews',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.brown,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to reviews page with better error handling for type casting issues
                _navigateToReviewsPage();
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.brown),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        if (passengerReviews.isNotEmpty) ...[
          Text(
            'Passenger Reviews',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ...passengerReviews.take(2).map((review) => _buildReviewCard(
                // Fix: Try different possible field names for user
                review['user_name'] ?? review['user'] ?? review['name'] ?? 'Anonymous',
                review['average']?.toDouble() ?? review['rating']?.toDouble() ?? 0.0,
                review['comment'] ?? review['review'] ?? 'No comment',
                'passenger',
              )),
        ],
        if (ownerReviews.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Owner Reviews',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ...ownerReviews.take(2).map((review) => _buildReviewCard(
                // Fix: Try different possible field names for user
                review['user_name'] ?? review['user'] ?? review['name'] ?? 'Anonymous',
                review['average']?.toDouble() ?? review['rating']?.toDouble() ?? 0.0,
                review['comment'] ?? review['review'] ?? 'No comment',
                'owner',
              )),
        ],
        if (passengerReviews.isEmpty && ownerReviews.isEmpty)
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Text(
                      'No recent reviews available. Reviews will appear here once users start rating your sacco.',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(String userName, double rating, String comment, String type) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: CircleAvatar(
          backgroundColor: type == 'passenger' ? AppColors.blue : AppColors.green,
          radius: 20,
          child: Icon(
            type == 'passenger' ? Icons.person : Icons.business,
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Text(
          userName,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: AppColors.orange,
                  size: 14,
                )),
                const SizedBox(width: 6),
                Text(
                  '${rating.toStringAsFixed(1)}/5',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              comment,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            final saccoId = _dashboardData?['sacco_info']?['id'];
            if (saccoId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SaccoVehicleRequestsPage(saccoId: saccoId.toString()),
                ),
              ).then((_) => _loadDashboardData());
            }
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaccoRoutesPage(),
              ),
            );
            break;
          case 3:
            // Handle reviews page with error catching
            _navigateToReviewsPage();
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaccoEditPage(),
              ),
            ).then((_) => _loadDashboardData());
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
              const Icon(Icons.approval),
              if (_pendingRequestsCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$_pendingRequestsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Requests',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.route),
          label: 'Routes',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Reviews',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}