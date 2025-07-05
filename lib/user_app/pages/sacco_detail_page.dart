import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'add_review_page.dart';
import 'package:intl/intl.dart';

class SaccoDetailPage extends StatefulWidget {
  final int saccoId;
  
  const SaccoDetailPage({super.key, required this.saccoId});

  @override
  State<SaccoDetailPage> createState() => _SaccoDetailPageState();
}

class _SaccoDetailPageState extends State<SaccoDetailPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _saccoData;
  List<dynamic> _reviews = [];
  List<dynamic> _routes = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  bool _isLoadingRoutes = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSaccoDetails();
    _loadReviews();
    _loadRoutes();
  }

  Future<void> _loadSaccoDetails() async {
    try {
      final data = await ApiService.getSaccoDetailPOV(widget.saccoId);
      setState(() {
        _saccoData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load sacco details: $e');
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ApiService.getSaccoReviews(widget.saccoId);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      _showErrorSnackBar('Failed to load reviews: $e');
    }
  }
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    
    try {

      DateTime dateTime = DateTime.parse(dateString);

      return DateFormat('MMM d, yyyy').format(dateTime); 
    } catch (e) {
      return dateString; 
    }
}

  Future<void> _loadRoutes() async {
    setState(() => _isLoadingRoutes = true);
    try {
      final routes = await ApiService.getRoutesBySacco(widget.saccoId);
      setState(() {
        _routes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      setState(() => _isLoadingRoutes = false);
      _showErrorSnackBar('Failed to load routes: $e');
    }
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

  double _calculateAverageRating(String type) {
    if (_reviews.isEmpty) return 0.0;
    
    double sum = 0;
    int count = 0;
    for (var review in _reviews) {
      final rating = review[type];
      if (rating != null) {
        sum += rating.toString().isEmpty ? 0 : double.tryParse(rating.toString()) ?? 0;
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
          child: Text('Failed to load sacco details', style: AppTextStyles.body1),
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
                  builder: (context) => AddReviewPage(
                    saccoId: _saccoData!['id'],
                  ),
                ),
              );
              if (result == true) {
                _loadReviews(); // Refresh reviews
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
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Routes'),
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
                _buildRoutesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsOverview() {
    if (_reviews.isEmpty) {
      return const Text('No reviews yet', style: AppTextStyles.caption);
    }

    final overallRating = _calculateAverageRating('overall');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRatingItem('Overall', overallRating),
        _buildRatingItem('Cleanliness', _calculateAverageRating('cleanliness')),
        _buildRatingItem('Punctuality', _calculateAverageRating('punctuality')),
        _buildRatingItem('Comfort', _calculateAverageRating('comfort')),
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
          const SizedBox(height: AppDimensions.paddingMedium),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Information', style: AppTextStyles.heading3),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  // Try multiple possible field names
                  _buildInfoRow(Icons.phone, 'Phone', 
                    _saccoData!['contact_number'] ?? 
                    'Not available'),
                  _buildInfoRow(Icons.email, 'Email', 
                    _saccoData!['email'] ?? 
                    'Not available'),
                  _buildInfoRow(Icons.location_on, "Location", 
                    _saccoData!['location'] ?? 
                    'Not available'),
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
                  _buildInfoRow(Icons.calendar_today, 'Established', 
                    _saccoData!['date_established'] ?? 
                    'Not available'),
                  _buildInfoRow(Icons.person, 'Manager',
                    _saccoData!['sacco_admin'] ?? 
                    'Not available'),
                  if (_saccoData!['description'] != null)
                    _buildInfoRow(Icons.description, 'Description', 
                      _saccoData!['description']),
                ],
              ),
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
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value, style: AppTextStyles.body1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesTab() {
    if (_isLoadingRoutes) {
      return const Center(child: CircularProgressIndicator());
    }
    
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
                    Expanded(
                      child: Text(
                        '${route['start_location'] ?? 'Unknown'} → ${route['end_location'] ?? 'Unknown'}',
                        style: AppTextStyles.heading3,
                      ),
                    ),
                    if (route['fare'] != null)
                      Text(
                        'KES ${route['fare']}',
                        style: AppTextStyles.heading3.copyWith(color: AppColors.success),
                      ),
                  ],
                ),
                if (route['duration'] != null) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text('${route['duration']} hours', style: AppTextStyles.caption),
                    ],
                  ),
                ],
                if (route['description'] != null && route['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(route['description'], style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
        );
      },
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
            const Text('No reviews yet', style: AppTextStyles.body1),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewPage(saccoId: widget.saccoId),
                  ),
                );
                if (result == true) {
                  _loadReviews();
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
                        (review['user_name'] ?? review['user'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                        style: AppTextStyles.body1.copyWith(color: AppColors.carafe),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['user_name'] ?? review['user'] ?? 'Anonymous',
                            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(review['created_at'] ?? review['date_created'] ?? ''),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    _buildStarRating(double.tryParse(review['overall']?.toString() ?? '0') ?? 0),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Rating breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallRating('Cleanliness', double.tryParse(review['cleanliness']?.toString() ?? '0') ?? 0),
                    _buildSmallRating('Punctuality', double.tryParse(review['punctuality']?.toString() ?? '0') ?? 0),
                    _buildSmallRating('Comfort', double.tryParse(review['comfort']?.toString() ?? '0') ?? 0),
                  ],
                ),
                
                if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(review['comment'], style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: AppColors.warning,
        );
      }),
    );
  }

  Widget _buildSmallRating(String label, double rating) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 12, color: AppColors.warning),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}