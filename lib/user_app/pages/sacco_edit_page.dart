// lib/user_app/pages/sacco_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sacco_admin_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class SaccoEditPage extends StatefulWidget {
  const SaccoEditPage({super.key});

  @override
  State<SaccoEditPage> createState() => _SaccoEditPageState();
}

class _SaccoEditPageState extends State<SaccoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  Map<String, dynamic>? _saccoData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaccoDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadSaccoDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await SaccoAdminService.getSaccoDetails();
      setState(() {
        _saccoData = data;
        _populateFields();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _populateFields() {
    if (_saccoData != null) {
      _nameController.text = _saccoData!['name'] ?? '';
      _locationController.text = _saccoData!['location'] ?? '';
      _descriptionController.text = _saccoData!['description'] ?? '';
      _phoneController.text = _saccoData!['phone'] ?? '';
      _emailController.text = _saccoData!['email'] ?? '';
      _websiteController.text = _saccoData!['website'] ?? '';
      _addressController.text = _saccoData!['address'] ?? '';
      _emergencyContactController.text = _saccoData!['emergency_contact'] ?? '';
    }
  }

  Future<void> _saveSaccoDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final updateData = {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'address': _addressController.text.trim(),
      'emergency_contact': _emergencyContactController.text.trim(),
    };

    try {
      await SaccoAdminService.updateSaccoDetails(updateData);
      if (mounted) {
        _showSuccessSnackBar('Sacco details updated successfully');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update sacco details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sacco Information'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          if (!_isLoading && _saccoData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSaccoDetails,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? Center(
                  child: ErrorDisplayWidget(
                    error: _error!,
                    onRetry: _loadSaccoDetails,
                  ),
                )
              : _buildEditForm(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Information', Icons.info),
            _buildBasicInfoSection(),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildSectionHeader('Contact Information', Icons.contact_phone),
            _buildContactInfoSection(),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildSectionHeader('Additional Information', Icons.description),
            _buildAdditionalInfoSection(),
            
            const SizedBox(height: 100), // Space for bottom actions
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.brown,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Sacco Name *',
                prefixIcon: Icon(Icons.business, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter sacco name';
                }
                if (value.trim().length < 3) {
                  return 'Sacco name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location *',
                prefixIcon: Icon(Icons.location_on, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Main operating location/city',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Brief description of your sacco services',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Primary contact number',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Official email address',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'Website',
                prefixIcon: Icon(Icons.web, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Website URL (optional)',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^https?://').hasMatch(value)) {
                    return 'Website URL must start with http:// or https://';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _emergencyContactController,
              decoration: InputDecoration(
                labelText: 'Emergency Contact',
                prefixIcon: Icon(Icons.emergency, color: Colors.red),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: '24/7 emergency contact number',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Physical Address',
                prefixIcon: Icon(Icons.home, color: AppColors.brown),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown),
                ),
                helperText: 'Full physical address of main office',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.brown.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.brown,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Text(
                      'Note: Changes to sacco information may take some time to reflect across the platform. Essential information like name and location are required.',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.brown),
                foregroundColor: AppColors.brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSaccoDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Saving...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(width: 8),
                        const Text('Save Changes'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}