// lib/user_app/pages/sacco_admin_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/sacco_admin_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'sacco_routes_page.dart';
import 'sacco_reviews_page.dart';
import 'sacco_edit_page.dart';

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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaccoEditPage(),
                ),
              ).then((_) => _loadDashboardData());
            },
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
          _buildQuickStatsSection(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildQuickActionsSection(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildRecentReviewsSection(),
        ],
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
                'Passenger Rating',
                '${stats['passenger_avg_rating']}/5',
                Icons.star,
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
                'Owner Rating',
                '${stats['owner_avg_rating']}/5',
                Icons.business,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Overall Rating',
                '${stats['overall_avg_rating']}/5',
                Icons.trending_up,
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

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppDimensions.paddingSmall,
          mainAxisSpacing: AppDimensions.paddingSmall,
          children: [
            _buildActionCard(
              'Manage Routes',
              Icons.route,
              AppColors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaccoRoutesPage(),
                ),
              ),
            ),
            _buildActionCard(
              'View Reviews',
              Icons.star,
              AppColors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaccoReviewsPage(),
                ),
              ),
            ),
            _buildActionCard(
              'Edit Sacco Info',
              Icons.edit,
              AppColors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaccoEditPage(),
                ),
              ).then((_) => _loadDashboardData()),
            ),
            _buildActionCard(
              'Analytics',
              Icons.analytics,
              Colors.purple,
              () => _showComingSoon('Analytics'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        Text(
          'Recent Reviews',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
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
          ...passengerReviews.take(3).map((review) => _buildReviewCard(
                review['user_name'] ?? 'Anonymous',
                review['average']?.toDouble() ?? 0.0,
                review['comment'] ?? 'No comment',
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
          ...ownerReviews.take(3).map((review) => _buildReviewCard(
                review['user_name'] ?? 'Anonymous',
                review['average']?.toDouble() ?? 0.0,
                review['comment'] ?? 'No comment',
                'owner',
              )),
        ],
      ],
    );
  }

  Widget _buildReviewCard(String userName, double rating, String comment, String type) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == 'passenger' ? AppColors.blue : AppColors.green,
          child: Icon(
            type == 'passenger' ? Icons.person : Icons.business,
            color: AppColors.white,
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
            Row(
              children: [
                ...List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: AppColors.orange,
                  size: 16,
                )),
                const SizedBox(width: 8),
                Text('${rating.toStringAsFixed(1)}/5'),
              ],
            ),
            const SizedBox(height: 4),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaccoRoutesPage(),
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaccoReviewsPage(),
              ),
            );
            break;
          case 3:
            _showComingSoon('Reports');
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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.route),
          label: 'Routes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Reviews',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.construction,
                color: AppColors.brown,
              ),
              const SizedBox(width: 8),
              Text(
                'Coming Soon',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.brown,
                ),
              ),
            ],
          ),
          content: Text(
            '$feature feature is currently under development and will be available soon!',
            style: AppTextStyles.body1,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brown,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}