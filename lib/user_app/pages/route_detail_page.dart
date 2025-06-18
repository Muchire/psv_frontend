import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '/user_app/pages/sacco_detail_page.dart';

class RouteDetailPage extends StatefulWidget {
  final int routeId;
  final String? routeName;

  const RouteDetailPage({
    Key? key,
    required this.routeId,
    this.routeName,
  }) : super(key: key);

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? routeData;
  List<dynamic> saccoReviews = [];
  bool isLoading = true;
  bool isLoadingReviews = true;
  String? error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRouteData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final route = await ApiService.getRouteDetail(widget.routeId);
      setState(() {
        routeData = route;
        isLoading = false;
      });

      // Load sacco reviews
      if (route['sacco'] != null) {
        _loadSaccoReviews(route['sacco']);
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadSaccoReviews(int saccoId) async {
    try {
      setState(() {
        isLoadingReviews = true;
      });

      final reviews = await ApiService.getSaccoReviews(saccoId);
      setState(() {
        saccoReviews = reviews;
        isLoadingReviews = false;
      });
    } catch (e) {
      setState(() {
        isLoadingReviews = false;
      });
      // Don't show error for reviews, just log it
      print('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Route Details'),
        backgroundColor: const Color(0xFF523A28), // AppColors.carafe
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE4D4C8), // AppColors.sandDollar
      body: isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF523A28), // AppColors.carafe
            ))
          : error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFA47551), // AppColors.brown
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load route details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF523A28), // AppColors.carafe
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFA47551), // AppColors.brown
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRouteData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA47551), // AppColors.brown
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildRouteHeader(),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF523A28), // AppColors.carafe
            unselectedLabelColor: const Color(0xFFA47551), // AppColors.brown
            indicatorColor: const Color(0xFF523A28), // AppColors.carafe
            tabs: const [
              Tab(text: 'Route Info'),
              Tab(text: 'Sacco Info'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRouteInfoTab(),
              _buildSaccoInfoTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF523A28), // AppColors.carafe
            const Color(0xFF523A28),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF523A28), // AppColors.carafe
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${routeData!['start_location']} → ${routeData!['end_location']}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF523A28), // AppColors.carafe
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.straighten,
                label: '${routeData!['distance']} km',
                color: const Color(0xFFA47551), // AppColors.brown
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${routeData!['duration']} min',
                color: const Color(0xFFD0B49F), // AppColors.tan
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.attach_money,
                label: 'KSh ${routeData!['fare']}',
                color: const Color(0xFF523A28), // AppColors.carafe
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Route Details'),
          const SizedBox(height: 12),
          _buildDetailCard([
            _buildDetailRow('Start Location', routeData!['start_location']),
            _buildDetailRow('End Location', routeData!['end_location']),
            _buildDetailRow('Distance', '${routeData!['distance']} km'),
            _buildDetailRow('Duration', '${routeData!['duration']} minutes'),
            _buildDetailRow('Fare', 'KSh ${routeData!['fare']}'),
          ]),
          const SizedBox(height: 24),
          if (routeData!['stops'] != null && routeData!['stops'].isNotEmpty) ...[
            _buildSectionTitle('Route Stops'),
            const SizedBox(height: 12),
            _buildStopsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSaccoInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sacco Information'),
          const SizedBox(height: 12),
          _buildDetailCard([
            _buildDetailRow('Sacco Name', routeData!['sacco_name']),
            _buildDetailRow('Sacco ID', routeData!['sacco'].toString()),
          ]),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to sacco detail page;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => SaccoDetailPage(saccoId: routeData!['sacco'])
              ));
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('View Full Sacco Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA47551), // AppColors.brown
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(
        color: Color(0xFF523A28), // AppColors.carafe
      ));
    }

    if (saccoReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: const Color(0xFFD0B49F), // AppColors.tan
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF523A28), // AppColors.carafe
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this sacco!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFA47551), // AppColors.brown
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showAddReviewDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA47551), // AppColors.brown
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Review'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${saccoReviews.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF523A28), // AppColors.carafe
                ),
              ),
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Review'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA47551), // AppColors.brown
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: saccoReviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(saccoReviews[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF523A28), // AppColors.carafe
          ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF523A28), // AppColors.carafe
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFA47551), // AppColors.brown
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsCard() {
    final stops = routeData!['stops'] as List;
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isLast = index == stops.length - 1;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF523A28), // AppColors.carafe
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: const Color(0xFF523A28), // AppColors.carafe
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      stop['stage_name'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF523A28), // AppColors.carafe
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF523A28), // AppColors.carafe
                  child: Text(
                    review['user']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFirstName(review['user']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF523A28), // AppColors.carafe
                        ),
                      ),
                      Text(
                        review['date_created'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFFA47551), // AppColors.brown
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFD0B49F), size: 16), // AppColors.tan
                    Text(
                      ' ${review['overall']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF523A28), // AppColors.carafe
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRatingChip('Cleanliness', review['cleanliness']),
                const SizedBox(width: 8),
                _buildRatingChip('Punctuality', review['punctuality']),
                const SizedBox(width: 8),
                _buildRatingChip('Comfort', review['comfort']),
              ],
            ),
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review['comment'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF523A28), // AppColors.carafe
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingChip(String label, dynamic rating) {
    final ratingValue = rating?.toDouble() ?? 0.0;
    final chipColor = _getRatingColor(ratingValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        '$label: ${ratingValue.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'Anonymous';
    }
    
    // Split the name by spaces and return the first part
    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty ? nameParts[0] : 'Anonymous';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF523A28); // AppColors.carafe for high ratings
    if (rating >= 3.0) return const Color(0xFFA47551); // AppColors.brown for medium ratings
    return const Color(0xFFD0B49F); // AppColors.tan for low ratings
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        saccoId: routeData!['sacco'],
        saccoName: routeData!['sacco_name'],
        onReviewAdded: () {
          _loadSaccoReviews(routeData!['sacco']);
        },
      ),
    );
  }
}

class AddReviewDialog extends StatefulWidget {
  final int saccoId;
  final String saccoName;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({
    Key? key,
    required this.saccoId,
    required this.saccoName,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _commentController = TextEditingController();
  double _cleanliness = 3.0;
  double _punctuality = 3.0;
  double _comfort = 3.0;
  double _overall = 3.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Review ${widget.saccoName}',
        style: const TextStyle(
          color: Color(0xFF523A28), // AppColors.carafe
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRatingSlider('Cleanliness', _cleanliness, (value) {
              setState(() => _cleanliness = value);
            }),
            _buildRatingSlider('Punctuality', _punctuality, (value) {
              setState(() => _punctuality = value);
            }),
            _buildRatingSlider('Comfort', _comfort, (value) {
              setState(() => _comfort = value);
            }),
            _buildRatingSlider('Overall', _overall, (value) {
              setState(() => _overall = value);
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience...',
                labelStyle: const TextStyle(
                  color: Color(0xFFA47551), // AppColors.brown
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFFD0B49F), // AppColors.tan
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF523A28), // AppColors.carafe
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFA47551), // AppColors.brown
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF523A28), // AppColors.carafe
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF523A28), // AppColors.carafe
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
                activeColor: const Color(0xFF523A28), // AppColors.carafe
                inactiveColor: const Color(0xFFD0B49F), // AppColors.tan
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF523A28), // AppColors.carafe
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      await ApiService.createPassengerReview(
        saccoId: widget.saccoId,
        cleanliness: _cleanliness.round(),
        punctuality: _punctuality.round(),
        comfort: _comfort.round(),
        overall: _overall.round(),
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Color(0xFF523A28), // AppColors.carafe
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Color(0xFFA47551), // AppColors.brown
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}