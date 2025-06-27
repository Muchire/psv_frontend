// lib/user_app/pages/sacco_reviews_page.dart
import 'package:flutter/material.dart';
import '../../services/sacco_admin_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class SaccoReviewsPage extends StatefulWidget {
  const SaccoReviewsPage({super.key});

  @override
  State<SaccoReviewsPage> createState() => _SaccoReviewsPageState();
}

class _SaccoReviewsPageState extends State<SaccoReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic>? _allReviewsData;
  List<dynamic> _passengerReviews = [];
  List<dynamic> _ownerReviews = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Pagination variables
  int _passengerPage = 1;
  int _ownerPage = 1;
  final int _pageSize = 10;
  bool _hasMorePassengerReviews = false;
  bool _hasMoreOwnerReviews = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await SaccoAdminService.getAllReviews(
        passengerPage: _passengerPage,
        ownerPage: _ownerPage,
        pageSize: _pageSize,
      );

      setState(() {
        _allReviewsData = data;
        _passengerReviews = data['passenger_reviews']['data'];
        _ownerReviews = data['owner_reviews']['data'];
        _hasMorePassengerReviews = data['passenger_reviews']['has_next'] ?? false;
        _hasMoreOwnerReviews = data['owner_reviews']['has_next'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePassengerReviews() async {
    if (!_hasMorePassengerReviews) return;

    try {
      _passengerPage++;
      final data = await SaccoAdminService.getAllReviews(
        passengerPage: _passengerPage,
        ownerPage: 1,
        pageSize: _pageSize,
      );

      setState(() {
        _passengerReviews.addAll(data['passenger_reviews']['data']);
        _hasMorePassengerReviews = data['passenger_reviews']['has_next'] ?? false;
      });
    } catch (e) {
      _passengerPage--; // Revert page increment on error
      _showErrorSnackbar('Failed to load more passenger reviews');
    }
  }

  Future<void> _loadMoreOwnerReviews() async {
    if (!_hasMoreOwnerReviews) return;

    try {
      _ownerPage++;
      final data = await SaccoAdminService.getAllReviews(
        passengerPage: 1,
        ownerPage: _ownerPage,
        pageSize: _pageSize,
      );

      setState(() {
        _ownerReviews.addAll(data['owner_reviews']['data']);
        _hasMoreOwnerReviews = data['owner_reviews']['has_next'] ?? false;
      });
    } catch (e) {
      _ownerPage--; // Revert page increment on error
      _showErrorSnackbar('Failed to load more owner reviews');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _passengerPage = 1;
              _ownerPage = 1;
              _loadAllReviews();
            },
          ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.white.withOpacity(0.7),
                indicatorColor: AppColors.white,
                tabs: [
                  Tab(
                    text: 'Overview',
                    icon: Icon(Icons.dashboard),
                  ),
                  Tab(
                    text: 'Passenger (${_allReviewsData?['summary']?['total_passenger_reviews'] ?? 0})',
                    icon: Icon(Icons.person),
                  ),
                  Tab(
                    text: 'Owner (${_allReviewsData?['summary']?['total_owner_reviews'] ?? 0})',
                    icon: Icon(Icons.business),
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? Center(
                  child: ErrorDisplayWidget(
                    error: _error!,
                    onRetry: _loadAllReviews,
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPassengerReviewsTab(),
                    _buildOwnerReviewsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    if (_allReviewsData == null) return const Center(child: Text('No data available'));

    final summary = _allReviewsData!['summary'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildRatingBreakdown(summary),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildRecentReviewsPreview(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
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
          children: [
            Text(
              'Overall Rating',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              '${summary['overall_avg_rating']}/10.0',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildStarRating(summary['overall_avg_rating']?.toDouble() ?? 0.0, 32),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Reviews',
                  '${(summary['total_passenger_reviews'] ?? 0) + (summary['total_owner_reviews'] ?? 0)}',
                ),
                _buildSummaryItem(
                  'Passenger Reviews',
                  '${summary['total_passenger_reviews'] ?? 0}',
                ),
                _buildSummaryItem(
                  'Owner Reviews',
                  '${summary['total_owner_reviews'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
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
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRatingBreakdown(Map<String, dynamic> summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Breakdown',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildRatingCard(
                'Passenger Rating',
                summary['passenger_avg_rating']?.toDouble() ?? 0.0,
                Icons.person,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildRatingCard(
                'Owner Rating',
                summary['owner_avg_rating']?.toDouble() ?? 0.0,
                Icons.business,
                AppColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingCard(String title, double rating, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
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
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              '${rating.toStringAsFixed(1)}/10.0',
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildStarRating(rating, 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReviewsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews Preview',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        if (_passengerReviews.isNotEmpty) ...[
          Text(
            'Latest Passenger Reviews',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ..._passengerReviews.take(2).map((review) => _buildReviewCard(review, 'passenger')),
        ],
        if (_ownerReviews.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Latest Owner Reviews',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ..._ownerReviews.take(2).map((review) => _buildReviewCard(review, 'owner')),
        ],
      ],
    );
  }

  Widget _buildPassengerReviewsTab() {
    return Column(
      children: [
        if (_passengerReviews.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No passenger reviews yet',
                style: AppTextStyles.body1,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              itemCount: _passengerReviews.length + (_hasMorePassengerReviews ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _passengerReviews.length) {
                  return _buildLoadMoreButton(_loadMorePassengerReviews);
                }
                return _buildReviewCard(_passengerReviews[index], 'passenger');
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOwnerReviewsTab() {
    return Column(
      children: [
        if (_ownerReviews.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No owner reviews yet',
                style: AppTextStyles.body1,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              itemCount: _ownerReviews.length + (_hasMoreOwnerReviews ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _ownerReviews.length) {
                  return _buildLoadMoreButton(_loadMoreOwnerReviews);
                }
                return _buildReviewCard(_ownerReviews[index], 'owner');
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brown,
          foregroundColor: AppColors.white,
        ),
        child: const Text('Load More Reviews'),
      ),
    );
  }

  // FIXED: Better handling of user data with proper type checking
  Widget _buildReviewCard(Map<String, dynamic> review, String type) {
    // Safe extraction of user name with proper type checking
    String userName = 'Anonymous';
    
    try {
      // Try different possible field names and structures
      if (review['user_name'] != null) {
        userName = review['user_name'].toString();
      } else if (review['username'] != null) {
        userName = review['username'].toString();
      } else if (review['user'] != null) {
        final user = review['user'];
        if (user is Map<String, dynamic>) {
          // User is an object with username field
          userName = user['username']?.toString() ?? user['name']?.toString() ?? 'Anonymous';
        } else if (user is String) {
          // User is already a string (username)
          userName = user;
        } else {
          // User is likely an ID (int), keep as Anonymous
          userName = 'User #${user.toString()}';
        }
      }
    } catch (e) {
      print('Error extracting username: $e');
      userName = 'Anonymous';
    }

    // Safe extraction of rating with proper type checking
    double rating = 0.0;
    try {
      if (review['average'] != null) {
        rating = double.tryParse(review['average'].toString()) ?? 0.0;
      } else if (review['rating'] != null) {
        rating = double.tryParse(review['rating'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error extracting rating: $e');
      rating = 0.0;
    }

    final comment = review['comment']?.toString() ?? 'No comment provided';
    final createdAt = review['created_at']?.toString() ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: type == 'passenger' ? AppColors.blue : AppColors.green,
                  child: Icon(
                    type == 'passenger' ? Icons.person : Icons.business,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        type == 'passenger' ? 'Passenger Review' : 'Owner Review',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rating.toStringAsFixed(1)}/5.0',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brown,
                      ),
                    ),
                    _buildStarRating(rating, 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              comment,
              style: AppTextStyles.body1,
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                'Posted on ${_formatDate(createdAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ],
            if (type == 'passenger') _buildPassengerReviewDetails(review),
          ],
        ),
      ),
    );
  }

  // FIXED: Better handling of review details with proper type checking
  Widget _buildPassengerReviewDetails(Map<String, dynamic> review) {
    // Safe extraction of detailed ratings with proper type checking
    int cleanliness = 0;
    int punctuality = 0;
    int comfort = 0;
    int overall = 0;

    try {
      cleanliness = int.tryParse(review['cleanliness']?.toString() ?? '0') ?? 0;
      punctuality = int.tryParse(review['punctuality']?.toString() ?? '0') ?? 0;
      comfort = int.tryParse(review['comfort']?.toString() ?? '0') ?? 0;
      overall = int.tryParse(review['overall']?.toString() ?? '0') ?? 0;
    } catch (e) {
      print('Error extracting detailed ratings: $e');
    }

    return Column(
      children: [
        const SizedBox(height: AppDimensions.paddingMedium),
        const Divider(),
        const SizedBox(height: AppDimensions.paddingSmall),
        Text(
          'Detailed Ratings',
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(child: _buildDetailRating('Cleanliness', cleanliness)),
            Expanded(child: _buildDetailRating('Punctuality', punctuality)),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(child: _buildDetailRating('Comfort', comfort)),
            Expanded(child: _buildDetailRating('Overall', overall)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRating(String label, int rating) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: AppColors.orange,
            size: 14,
          )),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: AppColors.orange,
        size: size,
      )),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}