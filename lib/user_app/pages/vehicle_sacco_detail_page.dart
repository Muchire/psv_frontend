import 'package:flutter/material.dart';
import '/services/vehicle_api_service.dart';
import '../utils/constants.dart';
import 'add_owner_review_page.dart';
import 'join_sacco_page.dart';

class VehicleSaccoDetailPage extends StatefulWidget {
  final int saccoId;

  const VehicleSaccoDetailPage({super.key, required this.saccoId});

  @override
  State<VehicleSaccoDetailPage> createState() => _VehicleSaccoDetailPageState();
}

class _VehicleSaccoDetailPageState extends State<VehicleSaccoDetailPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _saccoData;
  Map<String, dynamic>? _fullSaccoResponse; // Store the full API response
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _reviews = [];
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  bool _isLoadingVehicles = false;
  bool _isLoadingDashboard = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSaccoDetails();
    // _loadSaccoDashboard();
    _loadOwnerReviews();
    _loadSaccoVehicles();
  }

  Future<void> _loadSaccoDetails() async {
    try {
      final data = await VehicleOwnerService.getSaccoDetails(widget.saccoId);
      setState(() {
        _fullSaccoResponse = data;
        _saccoData =
            data['sacco']; // Extract the sacco data from the nested structure
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load sacco details: $e');
    }
  }

// In your VehicleSaccoDetailPage or wherever you navigate to join page
  Future<void> _showJoinSaccoForm() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinSaccoPage(
          saccoId: widget.saccoId,
          saccoName: _saccoData?['name'] ?? 'Sacco',
        ),
      ),
    );
  }

  Future<void> _loadOwnerReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await VehicleOwnerService.getOwnerReviews();
      // Filter reviews for this specific sacco
      final saccoReviews =
          reviews['results']
              ?.where(
                (review) =>
                    review['sacco_id'] == widget.saccoId ||
                    review['sacco']['id'] == widget.saccoId,
              )
              .toList() ??
          [];
      setState(() {
        _reviews = saccoReviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      _showErrorSnackBar('Failed to load reviews: $e');
    }
  }

  Future<void> _loadSaccoVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      // This would typically be an endpoint to get vehicles by sacco
      // For now, we'll use the general vehicles endpoint and filter
      final vehicles = await VehicleOwnerService.getVehicles();
      // In a real implementation, you'd have an endpoint like getSaccoVehicles(saccoId)
      setState(() {
        _vehicles = vehicles;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() => _isLoadingVehicles = false);
      _showErrorSnackBar('Failed to load vehicles: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  double _calculateAverageRating(String type) {
    // Use the ratings from the API response if available
    if (_fullSaccoResponse != null && _fullSaccoResponse!['ratings'] != null) {
      final ratings = _fullSaccoResponse!['ratings'];
      final rating = ratings[type] ?? ratings['overall'] ?? 0.0;
      return double.tryParse(rating.toString()) ?? 0.0;
    }

    // Fallback to calculating from reviews
    if (_reviews.isEmpty) return 0.0;

    double sum = 0;
    int count = 0;
    for (var review in _reviews) {
      final rating = review[type];
      if (rating != null) {
        sum +=
            rating.toString().isEmpty
                ? 0
                : double.tryParse(rating.toString()) ?? 0;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_saccoData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text(
            'Failed to load sacco details',
            style: AppTextStyles.body1,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_saccoData!['name'] ?? 'Sacco Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOwnerReviewPage(
                    saccoId: widget.saccoId,
                  ),
                ),
              );
              if (result == true) {
                _loadOwnerReviews(); // Refresh reviews
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sacco Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.tan,
                  child: Text(
                    _saccoData!['name']?.substring(0, 1).toUpperCase() ?? 'S',
                    style: AppTextStyles.heading1.copyWith(color: AppColors.carafe),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                Text(
                  _saccoData!['name'] ?? 'Unknown Sacco',
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                if (_saccoData!['description'] != null) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    _saccoData!['description'],
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildRatingsOverview(),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Financials'),
              Tab(text: 'Vehicles'),
              Tab(text: 'Reviews'),
            ],
            labelColor: AppColors.brown,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.brown,
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildFinancialsTab(),
                _buildVehiclesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),

        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.group_add),
          label: const Text('Join Sacco'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JoinSaccoPage(
                  saccoId: _saccoData!['id'],
                  saccoName: _saccoData!['name'],
                  // vehicleId: currentVehicleId, // Make sure this is defined in your state
                ),
              ),
            );
          },
        ),
    );


  }

  Widget _buildRatingsOverview() {
    // Use ratings from API response if available
    if (_fullSaccoResponse != null && _fullSaccoResponse!['ratings'] != null) {
      final ratings = _fullSaccoResponse!['ratings'];
      final overallRating =
          double.tryParse(ratings['overall']?.toString() ?? '0') ?? 0.0;
      final totalReviews = ratings['total_reviews'] ?? 0;

      if (totalReviews == 0) {
        return const Text('No reviews yet', style: AppTextStyles.caption);
      }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatingItem('Overall', overallRating),
              _buildRatingItem(
                'Payment',
                double.tryParse(
                      ratings['payment_punctuality']?.toString() ?? '0',
                    ) ??
                    0.0,
              ),
              _buildRatingItem(
                'Support',
                double.tryParse(ratings['support']?.toString() ?? '0') ?? 0.0,
              ),
              _buildRatingItem(
                'Fairness',
                double.tryParse(ratings['rate_fairness']?.toString() ?? '0') ??
                    0.0,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text('Based on $totalReviews reviews', style: AppTextStyles.caption),
        ],
      );
    }

    // Fallback for when no ratings data is available
    if (_reviews.isEmpty) {
      return const Text('No reviews yet', style: AppTextStyles.caption);
    }

    final overallRating = _calculateAverageRating('overall_rating');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRatingItem('Overall', overallRating),
        _buildRatingItem(
          'Management',
          _calculateAverageRating('management_rating'),
        ),
        _buildRatingItem('Support', _calculateAverageRating('support_rating')),
        _buildRatingItem(
          'Profitability',
          _calculateAverageRating('profitability_rating'),
        ),
      ],
    );
  }

  Widget _buildRatingItem(String label, double rating) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: rating > 0 ? AppColors.warning : AppColors.grey,
            ),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Information', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    _saccoData!['contact_number'] ?? 'Not available',
                  ),
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    _saccoData!['email'] ?? 'Not available',
                  ),
                  _buildInfoRow(
                    Icons.location_on,
                    "Location",
                    _saccoData!['location'] ?? 'Not available',
                  ),
                  if (_saccoData!['website'] != null)
                    _buildInfoRow(Icons.web, 'Website', _saccoData!['website']),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Details', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Established',
                    _saccoData!['date_established'] ?? 'Not available',
                  ),
                  _buildInfoRow(
                    Icons.person,
                    'Manager',
                    _saccoData!['manager_name'] ??
                        _saccoData!['sacco_admin'] ??
                        'Not available',
                  ),
                  _buildInfoRow(
                    Icons.directions_bus,
                    'Total Vehicles',
                    '${_saccoData!['total_vehicles'] ?? 0}',
                  ),
                  _buildInfoRow(
                    Icons.directions_bus,
                    'Active Vehicles',
                    '${_saccoData!['active_vehicles'] ?? 0}',
                  ),
                  if (_saccoData!['description'] != null)
                    _buildInfoRow(
                      Icons.description,
                      'Description',
                      _saccoData!['description'],
                    ),
                ],
              ),
            ),
          ),

          // Routes Section
          if (_fullSaccoResponse != null &&
              _fullSaccoResponse!['routes'] != null) ...[
            const SizedBox(height: AppDimensions.paddingMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Routes', style: AppTextStyles.heading3),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    ..._buildRoutesList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRoutesList() {
    final routes = _fullSaccoResponse!['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      return [const Text('No routes available', style: AppTextStyles.body2)];
    }

    return routes.map<Widget>((route) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.tan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.tan.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppColors.brown, size: 20),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    '${route['start_location']} → ${route['end_location']}',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance: ${route['distance']} km',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Duration: ${route['duration']}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Fare: KES ${route['fare']}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFinancialsTab() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: AppColors.grey),
            SizedBox(height: AppDimensions.paddingMedium),
            Text('No financial data available', style: AppTextStyles.body1),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          // Revenue Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Overview', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialCard(
                          'Monthly Revenue',
                          'KES ${_dashboardData!['monthly_revenue'] ?? '0'}',
                          Icons.trending_up,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Expanded(
                        child: _buildFinancialCard(
                          'Daily Average',
                          'KES ${_dashboardData!['daily_average'] ?? '0'}',
                          Icons.today,
                          AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Expenses Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expenses Overview', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialCard(
                          'Operating Costs',
                          'KES ${_dashboardData!['operating_costs'] ?? '0'}',
                          Icons.build,
                          AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Expanded(
                        child: _buildFinancialCard(
                          'Maintenance',
                          'KES ${_dashboardData!['maintenance_costs'] ?? '0'}',
                          Icons.car_repair,
                          AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Profit Analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profit Analysis', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildProfitCard(
                    'Net Profit',
                    'KES ${_dashboardData!['net_profit'] ?? '0'}',
                    double.tryParse(
                          _dashboardData!['profit_margin']?.toString() ?? '0',
                        ) ??
                        0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(amount, style: AppTextStyles.heading3.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildProfitCard(String title, String amount, double margin) {
    final isPositive = margin >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 32,
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3),
                Text(
                  amount,
                  style: AppTextStyles.heading2.copyWith(color: color),
                ),
                Text(
                  '${margin.toStringAsFixed(1)}% margin',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesTab() {
    if (_isLoadingVehicles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: AppColors.grey),
            SizedBox(height: AppDimensions.paddingMedium),
            Text('No vehicles in this sacco', style: AppTextStyles.body1),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tan,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: AppColors.carafe,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle['license_plate'] ?? 'Unknown Vehicle',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'
                                .trim(),
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                    if (vehicle['status'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            vehicle['status'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vehicle['status'].toString().toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(vehicle['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Vehicle Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildVehicleStatItem(
                        'Monthly Earnings',
                        'KES ${vehicle['monthly_earnings'] ?? '0'}',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildVehicleStatItem(
                        'Trips',
                        '${vehicle['total_trips'] ?? '0'}',
                        Icons.route,
                      ),
                    ),
                    Expanded(
                      child: _buildVehicleStatItem(
                        'Rating',
                        '${vehicle['rating'] ?? '0.0'}★',
                        Icons.star,
                      ),
                    ),
                  ],
                ),

                if (vehicle['route'] != null) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Row(
                    children: [
                      Icon(Icons.route, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Route: ${vehicle['route']}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.brown),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.error;
      case 'maintenance':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use recent_reviews from API response if available
    List<dynamic> reviewsToShow = _reviews;
    if (_fullSaccoResponse != null &&
        _fullSaccoResponse!['recent_reviews'] != null) {
      reviewsToShow = _fullSaccoResponse!['recent_reviews'];
    }

    if (reviewsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review, size: 64, color: AppColors.grey),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text('No owner reviews yet', style: AppTextStyles.body1),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AddOwnerReviewPage(saccoId: widget.saccoId),
                  ),
                );
                if (result == true) {
                  _loadOwnerReviews();
                }
              },
              child: const Text('Be the first to review'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: reviewsToShow.length,
      itemBuilder: (context, index) {
        final review = reviewsToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.tan,
                      child: Text(
                        (review['owner_name'] ?? review['user'] ?? 'O')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.carafe,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['owner_name'] ??
                                review['user'] ??
                                'Anonymous',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(review['created_at'] ?? review['date']),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    _buildOverallRating(
                      review['overall_rating'] ?? review['rating'] ?? 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Review ratings breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallRatingItem(
                      'Payment',
                      review['payment_punctuality'] ?? 0,
                    ),
                    _buildSmallRatingItem('Support', review['support'] ?? 0),
                    _buildSmallRatingItem(
                      'Fairness',
                      review['rate_fairness'] ?? 0,
                    ),
                    _buildSmallRatingItem(
                      'Management',
                      review['management_rating'] ?? 0,
                    ),
                  ],
                ),

                if (review['review'] != null || review['comment'] != null) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    review['review'] ?? review['comment'] ?? '',
                    style: AppTextStyles.body2,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallRatingItem(String label, dynamic rating) {
    final ratingValue = double.tryParse(rating.toString()) ?? 0.0;
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 12,
              color: ratingValue > 0 ? AppColors.warning : AppColors.grey,
            ),
            const SizedBox(width: 2),
            Text(
              ratingValue.toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallRating(dynamic rating) {
    final ratingValue = double.tryParse(rating.toString()) ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            ratingValue.toStringAsFixed(1),
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brown),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else {
        return '${(difference.inDays / 365).floor()} years ago';
      }
    } catch (e) {
      return dateString.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
