import 'package:flutter/material.dart';
import '/services/vehicle_api_service.dart';
import '../utils/constants.dart';

class AddOwnerReviewPage extends StatefulWidget {
  final int saccoId;
  final String? saccoName;

  const AddOwnerReviewPage({super.key, required this.saccoId, this.saccoName});

  @override
  State<AddOwnerReviewPage> createState() => _AddOwnerReviewPageState();
}

class _AddOwnerReviewPageState extends State<AddOwnerReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  bool _isSubmitting = false;
  List<dynamic> _vehicles = [];
  bool _isLoadingVehicles = true;

  // Rating values aligned with Django model fields
  double _overallRating = 0.0; // 1-5 scale (matches Django model)
  double _rateFairnessRating = 0.0; // 1-10 scale (matches rate_fairness)
  double _supportRating = 0.0; // 1-10 scale (matches support)
  double _driverResponsibilityRating = 0.0; // 1-10 scale (matches driver_responsibility)
  double _transparencyRating = 0.0; // 1-10 scale (matches transparency)
  double _paymentPunctualityRating = 0.0; // 1-10 scale (matches payment_punctuality)

  @override
  void initState() {
    super.initState();
    _loadUserVehicles();
  }

  Future<void> _loadUserVehicles() async {
    try {
      final vehicles = await VehicleOwnerService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() => _isLoadingVehicles = false);
      _showErrorSnackBar('Failed to load vehicles: $e');
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_overallRating == 0) {
      _showErrorSnackBar('Please provide an overall rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate average like in passenger review
      // Note: Overall is 1-5, others are 1-10, so we normalize overall to 1-10 scale
      final normalizedOverall = _overallRating * 2; // Convert 1-5 to 2-10 scale
      final double calculatedAverage = (
        _paymentPunctualityRating +
        _driverResponsibilityRating +
        _rateFairnessRating +
        _supportRating +
        _transparencyRating +
        normalizedOverall
      ) / 6.0;

      // Map Flutter field names to Django model field names
      final reviewData = {
        'overall': _overallRating.toInt(), // Django expects integer, 1-5 scale
        'rate_fairness': _rateFairnessRating.toInt(), // 1-10 scale
        'support': _supportRating.toInt(), // 1-10 scale
        'driver_responsibility': _driverResponsibilityRating.toInt(), // 1-10 scale
        'transparency': _transparencyRating.toInt(), // 1-10 scale
        'payment_punctuality': _paymentPunctualityRating.toInt(), // 1-10 scale
        'average': calculatedAverage.toStringAsFixed(2), // Calculate average like passenger review
        'comment': _commentController.text.trim(),
      };

      print('Submitting review data: $reviewData'); // Debug log

      await VehicleOwnerService.createOwnerReview(widget.saccoId, reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit review: $e');
    } finally {
      setState(() => _isSubmitting = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${widget.saccoName ?? 'Sacco'}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card with sacco info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review,
                        size: 48,
                        color: AppColors.brown,
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      Text(
                        'Share Your Experience',
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        'Help others by sharing your experience with this sacco',
                        style: AppTextStyles.body2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Overall Rating (1-5 scale)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.warning),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Text(
                            'Overall Rating *',
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _buildRatingSection(
                        'How would you rate your overall experience?',
                        _overallRating,
                        (rating) => setState(() => _overallRating = rating),
                        maxRating: 5, // Overall rating is 1-5
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Detailed Ratings (1-10 scale)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assessment, color: AppColors.brown),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Text(
                            'Detailed Ratings',
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      _buildRatingSection(
                        'Payment Punctuality',
                        _paymentPunctualityRating,
                        (rating) => setState(() => _paymentPunctualityRating = rating),
                        subtitle: 'How timely are payments?',
                        maxRating: 10,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      _buildRatingSection(
                        'Driver Responsibility',
                        _driverResponsibilityRating,
                        (rating) => setState(() => _driverResponsibilityRating = rating),
                        subtitle: 'How careful are the drivers?',
                        maxRating: 10,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      _buildRatingSection(
                        'Rate Fairness',
                        _rateFairnessRating,
                        (rating) => setState(() => _rateFairnessRating = rating),
                        subtitle: 'How fair are the charges?',
                        maxRating: 10,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      _buildRatingSection(
                        'Support & Communication',
                        _supportRating,
                        (rating) => setState(() => _supportRating = rating),
                        subtitle: 'How responsive is the sacco management?',
                        maxRating: 10,
                      ),

                      const SizedBox(height: AppDimensions.paddingLarge),

                      _buildRatingSection(
                        'Transparency',
                        _transparencyRating,
                        (rating) => setState(() => _transparencyRating = rating),
                        subtitle: 'How transparent is sacco decision-making?',
                        maxRating: 10,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Comment Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.comment, color: AppColors.brown),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Text(
                            'Your Review',
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Share your detailed experience with this sacco...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please share your experience';
                          }
                          if (value.trim().length < 10) {
                            return 'Please provide a more detailed review (at least 10 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        'Help others by sharing specific details about your experience',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting Review...'),
                          ],
                        )
                      : const Text(
                          'Submit Review',
                          style: AppTextStyles.button,
                        ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.tan.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.tan),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.brown,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        'Your review will be publicly visible to help others make informed decisions. Please ensure your review is honest and constructive.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    double currentRating,
    Function(double) onRatingChanged, {
    String? subtitle,
    int maxRating = 10, // Default to 10, but allow override for overall rating (5)
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // For ratings with more than 5 stars, show them in two rows
        if (maxRating > 5) ...[
          // First row (1-5)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => onRatingChanged((index + 1).toDouble()),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: AppColors.warning,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row (6-10)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final starIndex = index + 5;
                    return GestureDetector(
                      onTap: () => onRatingChanged((starIndex + 1).toDouble()),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          starIndex < currentRating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: AppColors.warning,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  currentRating == 0 ? 'Not rated' : '${currentRating.toInt()}/$maxRating',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Single row for 5-star ratings
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(maxRating, (index) {
                    return GestureDetector(
                      onTap: () => onRatingChanged((index + 1).toDouble()),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: AppColors.warning,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  currentRating == 0 ? 'Not rated' : '${currentRating.toInt()}/$maxRating',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}