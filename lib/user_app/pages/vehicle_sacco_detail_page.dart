import 'package:flutter/material.dart';
import '/services/sacco_admin_service.dart';
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
  Map<String, dynamic>? _fullSaccoResponse;
  List<dynamic> _routes = [];
  Map<String, dynamic>? _ratings;
  List<dynamic> _reviews = [];
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 4 to 3 tabs
    _loadSaccoDetails();
    _loadOwnerReviews();
    
    // Add scroll listener for sticky header
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showStickyHeader) {
        setState(() => _showStickyHeader = true);
      } else if (_scrollController.offset <= 200 && _showStickyHeader) {
        setState(() => _showStickyHeader = false);
      }
    });
  }

  Future<void> _loadSaccoDetails() async {
    try {
      final data = await VehicleOwnerService.getSaccoDetails(widget.saccoId);
      setState(() {
        _fullSaccoResponse = data;
        _saccoData = data['sacco'];
        _routes = data['routes'] ?? [];
        _ratings = data['ratings'] ?? {};
        _reviews = data['recent_reviews'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load sacco details: $e');
    }
  }

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
      final saccoReviews = reviews['results']
              ?.where(
                (review) =>
                    review['sacco_id'] == widget.saccoId ||
                    review['sacco']['id'] == widget.saccoId,
              )
              .toList() ??
          [];
      setState(() {
        _reviews.addAll(saccoReviews);
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      _showErrorSnackBar('Failed to load additional reviews: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
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
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
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
                          _loadOwnerReviews();
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
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
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
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
                            const SizedBox(height: AppDimensions.paddingMedium),
                            _buildRatingsOverview(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Info'),
                        Tab(text: 'Routes'),
                        Tab(text: 'Reviews'),
                      ],
                      labelColor: AppColors.brown,
                      unselectedLabelColor: AppColors.grey,
                      indicatorColor: AppColors.brown,
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildRoutesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
          
          // Sticky header when scrolling
          if (_showStickyHeader)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.tan,
                      child: Text(
                        _saccoData!['name']?.substring(0, 1).toUpperCase() ?? 'S',
                        style: AppTextStyles.body1.copyWith(color: AppColors.carafe),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        _saccoData!['name'] ?? 'Unknown Sacco',
                        style: AppTextStyles.heading3,
                      ),
                    ),
                  ],
                ),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingsOverview() {
    if (_ratings == null || _ratings!['total_reviews'] == 0) {
      return const Text('No reviews yet', style: AppTextStyles.caption);
    }

    final overallRating = double.tryParse(_ratings!['overall']?.toString() ?? '0') ?? 0.0;
    final totalReviews = _ratings!['total_reviews'] ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRatingItem('Overall', overallRating),
            _buildRatingItem(
              'Payment',
              double.tryParse(_ratings!['payment_punctuality']?.toString() ?? '0') ?? 0.0,
            ),
            _buildRatingItem(
              'Support',
              double.tryParse(_ratings!['support']?.toString() ?? '0') ?? 0.0,
            ),
            _buildRatingItem(
              'Fairness',
              double.tryParse(_ratings!['rate_fairness']?.toString() ?? '0') ?? 0.0,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Text('Based on $totalReviews reviews', style: AppTextStyles.caption),
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
                    _formatEstablishedDate(_saccoData!['date_established']),
                  ),
                  _buildInfoRow(
                    Icons.directions_bus,
                    'Fleet Size',
                    '${_saccoData!['total_vehicles'] ?? 0} vehicles',
                  ),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Active Vehicles',
                    '${_saccoData!['active_vehicles'] ?? 0} operational',
                  ),
                  _buildInfoRow(
                    Icons.route,
                    'Available Routes',
                    '${_routes.length} routes',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesTab() {
    if (_routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: AppColors.grey),
            SizedBox(height: AppDimensions.paddingMedium),
            Text('No routes available', style: AppTextStyles.body1),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];
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
                        Icons.route,
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
                            '${route['start_location']} → ${route['end_location']}',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            'Distance: ${route['distance']} km • Duration: ${_formatDuration(route['duration'])}',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Route Stats
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.tan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildRouteStatItem('Fare', 'KES ${route['fare']}', Icons.attach_money),
                          _buildRouteStatItem('Daily Trips', '${route['avg_daily_trips'] ?? 0}', Icons.repeat),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildRouteStatItem(
                            'Monthly Revenue',
                            'KES ${_formatCurrency(route['avg_monthly_revenue'] ?? '0')}',
                            Icons.trending_up,
                          ),
                          _buildRouteStatItem(
                            'Daily Revenue',
                            'KES ${_formatCurrency(route['estimated_daily_revenue']?.toString() ?? '0')}',
                            Icons.today,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Improved stops display
                if (route['stops'] != null && route['stops'].isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  const Text('Major Stops:', style: AppTextStyles.body1),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildStopsList(route['stops']),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStopsList(List stops) {
    // Filter out technical stop data and format properly
    List<String> cleanStops = [];
    
    for (var stop in stops) {
      if (stop is String) {
        // If it's already a string, check if it looks like technical data
        if (!stop.contains('id:') && !stop.contains('stage_name:') && !stop.contains('order:')) {
          cleanStops.add(stop);
        } else {
          // Try to extract stage_name from technical format
          final stageNameMatch = RegExp(r'stage_name:\s*([^,]+)').firstMatch(stop);
          if (stageNameMatch != null) {
            cleanStops.add(stageNameMatch.group(1)?.trim() ?? '');
          }
        }
      } else if (stop is Map) {
        // If it's a map, try to get the name field
        final name = stop['name'] ?? stop['stage_name'] ?? stop['location'];
        if (name != null) {
          cleanStops.add(name.toString());
        }
      }
    }

    // Remove duplicates and empty strings
    cleanStops = cleanStops.where((stop) => stop.isNotEmpty).toSet().toList();

    if (cleanStops.isEmpty) {
      return [
        Text(
          'Stop information not available',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    return cleanStops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isLast = index == cleanStops.length - 1;
      
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.success : 
                       isLast ? AppColors.error : AppColors.brown,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stop,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: (index == 0 || isLast) ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRouteStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brown),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
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
                    builder: (context) => AddOwnerReviewPage(saccoId: widget.saccoId),
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
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
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
                        style: AppTextStyles.body1.copyWith(color: AppColors.carafe),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['owner_name'] ?? review['user'] ?? 'Anonymous',
                            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(review['created_at'] ?? review['date']),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    _buildOverallRating(review['overall_rating'] ?? review['rating'] ?? 0),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                if (review['review'] != null || review['comment'] != null) ...[
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

  String _formatEstablishedDate(String? dateString) {
    if (dateString == null) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(String? duration) {
    if (duration == null) return 'Unknown';
    // Convert "00:01:00" format to readable format
    final parts = duration.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
    return duration;
  }

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
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
    _scrollController.dispose();
    super.dispose();
  }
}

// Custom SliverPersistentHeaderDelegate for the TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.tan,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}