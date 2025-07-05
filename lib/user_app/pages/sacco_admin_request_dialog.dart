import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';

class SaccoAdminRequestDialog extends StatefulWidget {
  final List<dynamic> availableSaccos;
  final Function(Map<String, dynamic>) onRequestSuccess;

  const SaccoAdminRequestDialog({
    super.key,
    required this.availableSaccos,
    required this.onRequestSuccess,
  });

  @override
  State<SaccoAdminRequestDialog> createState() => _SaccoAdminRequestDialogState();
}

class _SaccoAdminRequestDialogState extends State<SaccoAdminRequestDialog> {
  int? _selectedSaccoId;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedSaccoId == null) {
      _showErrorSnackBar('Please select a SACCO');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide a reason for your request');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.submitSaccoAdminRequest(
        saccoId: _selectedSaccoId!,
      );

      if (mounted) {
        widget.onRequestSuccess(response);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.carafe,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Request SACCO Admin Access',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a SACCO to request admin access for:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // SACCO Selection
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedSaccoId,
                    hint: const Text('Select SACCO'),
                    isExpanded: true,
                    items: widget.availableSaccos.map((sacco) {
                      return DropdownMenuItem<int>(
                        value: sacco['id'],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sacco['name'] ?? 'Unknown SACCO',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (sacco['description'] != null && 
                                sacco['description'].isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                sacco['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting ? null : (value) {
                      setState(() {
                        _selectedSaccoId = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Reason TextField
              const Text(
                'Reason for request:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                enabled: !_isSubmitting,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Explain why you want to become an admin for this SACCO...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.carafe.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.carafe.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.carafe,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your request will be reviewed by the system administrator. You will be notified once your request is approved or rejected.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.carafe,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}