import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';

class AddReviewPage extends StatefulWidget {
  final int saccoId;

  const AddReviewPage({super.key, required this.saccoId});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _cleanlinessRating = 3;
  int _punctualityRating = 3;
  int _comfortRating = 3;
  int _overallRating = 3;

  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.createPassengerReview(
        saccoId: widget.saccoId,
        cleanliness: _cleanlinessRating,
        punctuality: _punctualityRating,
        comfort: _comfortRating,
        overall: _overallRating,
        comment:
            _commentController.text.isEmpty ? null : _commentController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Review'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: Text(
              'Submit',
              style: TextStyle(
                color: _isSubmitting ? AppColors.grey : AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review, size: 48, color: AppColors.brown),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        'Rate Your Experience',
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        'Help other passengers by sharing your experience with this sacco',
                        style: AppTextStyles.body2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Rating Categories
              Text(
                'Rate the following aspects:',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              _buildRatingCard(
                'Cleanliness',
                'How clean were the vehicles?',
                Icons.cleaning_services,
                _cleanlinessRating,
                (rating) => setState(() => _cleanlinessRating = rating),
              ),

              _buildRatingCard(
                'Punctuality',
                'How punctual were the departures?',
                Icons.access_time,
                _punctualityRating,
                (rating) => setState(() => _punctualityRating = rating),
              ),

              _buildRatingCard(
                'Comfort',
                'How comfortable was your journey?',
                Icons.airline_seat_recline_normal,
                _comfortRating,
                (rating) => setState(() => _comfortRating = rating),
              ),

              _buildRatingCard(
                'Overall Experience',
                'Rate your overall experience',
                Icons.star,
                _overallRating,
                (rating) => setState(() => _overallRating = rating),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Comment Section
              Text(
                'Additional Comments (Optional)',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Share more details about your experience...',
                      border: InputBorder.none,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMedium,
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Submit Review',
                            style: AppTextStyles.button,
                          ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(
    String title,
    String subtitle,
    IconData icon,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.brown),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => onRatingChanged(starIndex),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      starIndex <= currentRating
                          ? Icons.star
                          : Icons.star_border,
                      size: 32,
                      color:
                          starIndex <= currentRating
                              ? AppColors.warning
                              : AppColors.grey,
                    ),
                  ),
                );
              }),
            ),
            Center(
              child: Text(
                _getRatingText(currentRating),
                style: AppTextStyles.body2.copyWith(
                  color: _getRatingColor(currentRating),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Good';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return AppColors.error;
      case 3:
        return AppColors.warning;
      case 4:
      case 5:
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
