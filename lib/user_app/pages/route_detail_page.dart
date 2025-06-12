import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'sacco_detail_page.dart';

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailPage({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  Map<String, dynamic>? _saccoDetails;
  bool _isLoadingSacco = false;
  bool _isLoadingReviews = false;
  List<dynamic> _reviews = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSaccoDetails();
    _loadReviews();
  }

  Future<void> _loadSaccoDetails() async {
    if (widget.route['sacco_id'] == null) return;

    setState(() {
      _isLoadingSacco = true;
      _errorMessage = '';
    });

    try {
      final saccoDetails = await ApiService.getSaccoDetail(widget.route['sacco_id']?? 0);
      setState(() {
        _saccoDetails = saccoDetails;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sacco details: $e';
      });
    } finally {
      setState(() {
        _isLoadingSacco = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    if (widget.route['sacco_id'] == null) return;

    setState(() => _isLoadingReviews = true);

    try {
      // Load reviews for this sacco - you might need to modify this based on your API
      final reviews = await ApiService.getUserReviews(limit: 5);
      // Filter reviews for this specific sacco
      final filteredReviews = reviews.where((review) => 
        review['sacco'] == widget.route['sacco_id']).toList();
      
      setState(() {
        _reviews = filteredReviews;
      });
    } catch (e) {
      // Reviews loading is optional, so we don't show error for this
      print('Failed to load reviews: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  void _navigateToSaccoDetail() {
    if (widget.route['sacco_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SaccoDetailPage(saccoId: widget.route['sacco_id']?? 0),
        ),
      );
    }
  }

  void _showReviewDialog() {
    if (widget.route['sacco_id'] == null) return;

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(saccoId: widget.route['sacco_id']),
    ).then((result) {
      if (result == true) {
        // Reload reviews if a new review was submitted
        _loadReviews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        actions: [
          if (widget.route['sacco_id'] != null)
            IconButton(
              icon: const Icon(Icons.rate_review),
              onPressed: _showReviewDialog,
              tooltip: 'Write Review',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Information Card
            _buildRouteInfoCard(),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Sacco Information Card
            _buildSaccoInfoCard(),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Route Details Card
            _buildRouteDetailsCard(),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Reviews Section
            _buildReviewsSection(),
            
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: AppTextStyles.body2.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: AppColors.brown),
                const SizedBox(width: 8),
                Text('Route Information', style: AppTextStyles.heading2),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Route path with icons
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.route['start_location'] ?? 'Unknown',
                                style: AppTextStyles.heading3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.arrow_downward, color: AppColors.brown),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.route['end_location'] ?? 'Unknown',
                                style: AppTextStyles.heading3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'KES ${widget.route['fare'] ?? '0'}',
                        style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.brown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.route['duration'] ?? '0'} mins',
                        style: AppTextStyles.body2.copyWith(color: AppColors.brown),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaccoInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: AppColors.brown),
                const SizedBox(width: 8),
                Text('Sacco Information', style: AppTextStyles.heading2),
                const Spacer(),
                if (widget.route['sacco_id'] != null)
                  TextButton(
                    onPressed: _navigateToSaccoDetail,
                    child: const Text('View Details'),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            if (_isLoadingSacco)
              const Center(child: CircularProgressIndicator())
            else if (_saccoDetails != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.tan,
                  child: Text(
                    _saccoDetails!['name']?.substring(0, 1).toUpperCase() ?? 'S',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.carafe),
                  ),
                ),
                title: Text(
                  _saccoDetails!['name'] ?? 'Unknown Sacco',
                  style: AppTextStyles.heading3,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_saccoDetails!['description'] != null)
                      Text(
                        _saccoDetails!['description'],
                        style: AppTextStyles.body2,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _saccoDetails!['contact_phone'] ?? 'No phone',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.brown),
                onTap: _navigateToSaccoDetail,
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.tan,
                  child: Text(
                    (widget.route['sacco_name'] ?? 'S').substring(0, 1).toUpperCase(),
                    style: AppTextStyles.heading3.copyWith(color: AppColors.carafe),
                  ),
                ),
                title: Text(
                  widget.route['sacco_name'] ?? 'Unknown Sacco',
                  style: AppTextStyles.heading3,
                ),
                subtitle: const Text('Tap to view details'),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.brown),
                onTap: _navigateToSaccoDetail,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: AppColors.brown),
                const SizedBox(width: 8),
                Text('Additional Details', style: AppTextStyles.heading2),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            if (widget.route['description'] != null && widget.route['description'].isNotEmpty) ...[
              _buildDetailRow('Description', widget.route['description']),
              const SizedBox(height: 8),
            ],
            
            _buildDetailRow('Route ID', widget.route['id']?.toString() ?? 'N/A'),
            const SizedBox(height: 8),
            
            if (widget.route['distance'] != null)
              _buildDetailRow('Distance', '${widget.route['distance']} km'),
            
            if (widget.route['schedule'] != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Schedule', widget.route['schedule']),
            ],
            
            if (widget.route['frequency'] != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Frequency', widget.route['frequency']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.brown),
                const SizedBox(width: 8),
                Text('Recent Reviews', style: AppTextStyles.heading2),
                const Spacer(),
                TextButton(
                  onPressed: _showReviewDialog,
                  child: const Text('Write Review'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            if (_isLoadingReviews)
              const Center(child: CircularProgressIndicator())
            else if (_reviews.isEmpty)
              const Center(
                child: Text(
                  'No reviews yet. Be the first to review!',
                  style: AppTextStyles.body2,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Text(
                          'Overall: ${review['overall'] ?? 0}/5',
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(5, (i) => Icon(
                          i < (review['overall'] ?? 0) ? Icons.star : Icons.star_border,
                          color: AppColors.success,
                          size: 16,
                        )),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (review['comment'] != null && review['comment'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(review['comment'], style: AppTextStyles.body2),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Cleanliness: ${review['cleanliness'] ?? 0}/5, Punctuality: ${review['punctuality'] ?? 0}/5, Comfort: ${review['comfort'] ?? 0}/5',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Review Dialog Widget
class ReviewDialog extends StatefulWidget {
  final int saccoId;

  const ReviewDialog({super.key, required this.saccoId});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _commentController = TextEditingController();
  int _cleanliness = 5;
  int _punctuality = 5;
  int _comfort = 5;
  int _overall = 5;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      await ApiService.createPassengerReview(
        saccoId: widget.saccoId,
        cleanliness: _cleanliness,
        punctuality: _punctuality,
        comfort: _comfort,
        overall: _overall,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildRatingRow(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.body2),
        ),
        const SizedBox(width: 16),
        ...List.generate(5, (index) {
          return GestureDetector(
            onTap: () => onChanged(index + 1),
            child: Icon(
              index < value ? Icons.star : Icons.star_border,
              color: AppColors.success,
              size: 24,
            ),
          );
        }),
        const SizedBox(width: 8),
        Text('$value/5', style: AppTextStyles.caption),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRatingRow('Cleanliness', _cleanliness, (value) => setState(() => _cleanliness = value)),
            const SizedBox(height: 16),
            _buildRatingRow('Punctuality', _punctuality, (value) => setState(() => _punctuality = value)),
            const SizedBox(height: 16),
            _buildRatingRow('Comfort', _comfort, (value) => setState(() => _comfort = value)),
            const SizedBox(height: 16),
            _buildRatingRow('Overall', _overall, (value) => setState(() => _overall = value)),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (Optional)',
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Review'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}