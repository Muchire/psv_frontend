import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '/user_app/pages/sacco_detail_page.dart';
import '../utils/constants.dart';

class RouteDetailPage extends StatefulWidget {
  final int routeId;
  final String? routeName;

  const RouteDetailPage({Key? key, required this.routeId, this.routeName})
    : super(key: key);

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
      print('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routeName ?? 'Route Details',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.carafe),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.carafe,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.carafe),
      ),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brown,
                  strokeWidth: 3,
                ),
              )
              : error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[800],
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.error_outline, size: 48, color: AppColors.tan),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load route details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.carafe,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.carafe,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRouteData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildRouteHeader(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.carafe,
            unselectedLabelColor: AppColors.tan,
            indicatorColor: AppColors.brown,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.tan.withOpacity(0.1)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: AppColors.brown,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${routeData!['start_location']} → ${routeData!['end_location']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.carafe,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.straighten,
                    label: '${routeData!['distance']} km',
                    backgroundColor: AppColors.brown,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${routeData!['duration']} hours',
                    backgroundColor: AppColors.brown,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.attach_money,
                    label: 'KSh ${routeData!['fare']}',
                    backgroundColor: AppColors.brown,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Route Details'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Start Location', routeData!['start_location']),
            _buildDetailRow('End Location', routeData!['end_location']),
            _buildDetailRow('Distance', '${routeData!['distance']} km'),
            _buildDetailRow('Duration', '${routeData!['duration']} minutes'),
            _buildDetailRow('Fare', 'KSh ${routeData!['fare']}'),
          ]),
          const SizedBox(height: 24),
          if (routeData!['stops'] != null &&
              routeData!['stops'].isNotEmpty) ...[
            _buildSectionTitle('Route Stops'),
            const SizedBox(height: 16),
            _buildStopsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSaccoInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sacco Information'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Sacco Name', routeData!['sacco_name']),
            _buildDetailRow('Sacco ID', routeData!['sacco'].toString()),
          ]),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SaccoDetailPage(saccoId: routeData!['sacco']),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('View Full Sacco Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brown, strokeWidth: 3),
      );
    }

    if (saccoReviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.tan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  size: 48,
                  color: AppColors.brown,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.carafe,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Be the first to review this sacco!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.carafe),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddReviewDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: AppColors.tan.withOpacity(0.05),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${saccoReviews.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.carafe,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Review'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brown,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.brown),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
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
        color: AppColors.carafe,
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.tan.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.carafe,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.carafe,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsCard() {
    final stops = routeData!['stops'] as List;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.tan.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children:
              stops.asMap().entries.map((entry) {
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
                            color: AppColors.brown,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 32,
                            color: AppColors.tan,
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
                            fontSize: 14,
                            color: AppColors.carafe,
                            fontWeight: FontWeight.w500,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.tan.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.tan,
                  radius: 20,
                  child: Text(
                    review['user']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.carafe,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review['date_created'] ?? '',
                        style: const TextStyle(
                          color: AppColors.carafe,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(
                      review['overall']?.toDouble() ?? 0.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${review['overall']?.toStringAsFixed(1) ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRatingChip('Cleanliness', review['cleanliness']),
                _buildRatingChip('Punctuality', review['punctuality']),
                _buildRatingChip('Comfort', review['comfort']),
              ],
            ),
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tan.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review['comment'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.carafe,
                    height: 1.4,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${ratingValue.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'Anonymous';
    }

    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty ? nameParts[0] : 'Anonymous';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return AppColors.brown;
    if (rating >= 3.0) return AppColors.tan;
    return AppColors.tan.withOpacity(0.7);
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddReviewDialog(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Review ${widget.saccoName}',
        style: const TextStyle(color: AppColors.carafe, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience...',
                labelStyle: const TextStyle(color: AppColors.carafe),
                hintStyle: TextStyle(color: AppColors.carafe.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.tan.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.tan.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brown, width: 2),
                ),
                filled: true,
                fillColor: AppColors.tan.withOpacity(0.05),
              ),
              maxLines: 3,
              style: const TextStyle(color: AppColors.carafe),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.carafe,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isSubmitting
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

  Widget _buildRatingSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.carafe,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.brown,
                    inactiveTrackColor: AppColors.tan.withOpacity(0.3),
                    thumbColor: AppColors.brown,
                    overlayColor: AppColors.brown.withOpacity(0.2),
                    valueIndicatorColor: AppColors.brown,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: value.toStringAsFixed(1),
                    onChanged: onChanged,
                    ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brown,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createPassengerReview(
        saccoId: widget.saccoId,
        cleanliness: _cleanliness.toInt(),
        punctuality: _punctuality.toInt(),
        comfort: _comfort.toInt(),
        overall: _overall.toInt(),
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Review submitted successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.brown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit review: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.tan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}