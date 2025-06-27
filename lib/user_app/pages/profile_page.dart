import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'welcome_page.dart';
import 'sacco_admin_request_page.dart';
import 'sacco_admin_dashboard.dart';
import 'vehicle_owner_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<dynamic> _userReviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  bool _isSwitchingMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserReviews();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      print('Profile loaded: $profile'); // Debug print
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      print('Error loading profile: $e'); // Debug print
      _showErrorSnackBar('Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ApiService.getUserReviews(limit: 3);
      setState(() {
        _userReviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      _showErrorSnackBar('Failed to load reviews: $e');
    }
  }

  Future<void> _switchUserMode(String mode) async {
    setState(() => _isSwitchingMode = true);
    try {
      final response = await ApiService.switchUserMode(mode);
      print('Switch mode response: $response'); // Debug print

      _showSuccessSnackBar(
        response['message'] ?? 'Switched to $mode mode successfully!',
      );

      // Update the local profile with the new role information
      if (_userProfile != null && response['user'] != null) {
        setState(() {
          _userProfile!['current_role'] = response['user']['current_role'];
        });
      }

      // Handle navigation based on the role
      switch (mode) {
        case 'vehicle_owner':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleOwnerDashboard(),
            ),
          );
          break;
        case 'sacco_admin':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SaccoAdminDashboard(),
            ),
          );
          break;
        case 'passenger':
          break;
      }
    } catch (e) {
      print('Switch mode error: $e'); // Debug print
      _showErrorSnackBar('Failed to switch mode: $e');
    } finally {
      setState(() => _isSwitchingMode = false);
    }
  }

  Future<void> _updateProfile() async {
    final TextEditingController usernameController = TextEditingController(
      text: _userProfile?['username'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: _userProfile?['email'] ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: _userProfile?['phone_number'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.updateProfile(
                    username: usernameController.text,
                    email: emailController.text,
                    phoneNumber: phoneController.text,
                  );
                  Navigator.pop(context);
                  _showSuccessSnackBar('Profile updated successfully!');
                  await _loadUserProfile();
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Failed to update profile: $e');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.changePassword(
                    oldPassword: oldPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  Navigator.pop(context);
                  _showSuccessSnackBar('Password changed successfully!');
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Failed to change password: $e');
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.removeToken();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  // Helper method to get available roles for dropdown
  List<String> _getAvailableRolesForDropdown() {
    if (_userProfile == null) return [];

    final currentRole = _userProfile?['current_role'] as String? ?? 'passenger';
    List<String> availableRoles = [];

    // Add current role first
    availableRoles.add(currentRole);

    // Add other available roles
    if (_userProfile!['is_passenger'] == true && currentRole != 'passenger') {
      availableRoles.add('passenger');
    }

    if (_userProfile!['is_vehicle_owner'] == true &&
        currentRole != 'vehicle_owner') {
      availableRoles.add('vehicle_owner');
    }

    if (_userProfile!['is_sacco_admin'] == true &&
        currentRole != 'sacco_admin') {
      availableRoles.add('sacco_admin');
    }

    return availableRoles;
  }

  // Check if user should see vehicle owner request option
  bool _shouldShowVehicleOwnerRequest() {
    if (_userProfile == null) return false;

    final currentRole = _userProfile?['current_role'] as String? ?? 'passenger';
    final isVehicleOwner = _userProfile!['is_vehicle_owner'] == true;

    // Show request only if user is passenger and not already a vehicle owner
    return currentRole == 'passenger' && !isVehicleOwner;
  }

  // Check if user should see sacco admin request option
  bool _shouldShowSaccoAdminRequest() {
    if (_userProfile == null) return false;
    return !(_userProfile!['is_sacco_admin'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _updateProfile();
                  break;
                case 'password':
                  _changePassword();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.brown),
                        SizedBox(width: 8),
                        Text('Edit Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'password',
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: AppColors.brown),
                        SizedBox(width: 8),
                        Text('Change Password'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildUserModeSection(),
                    _buildStatsSection(),
                    _buildRecentReviewsSection(),
                    _buildSettingsSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _userProfile?['first_name'] ?? '';
    final lastName = _userProfile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName =
        fullName.isNotEmpty
            ? fullName
            : _userProfile?['username'] ?? 'Unknown User';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.tan,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                color: AppColors.carafe,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(displayName, style: AppTextStyles.heading1),
          Text(
            _userProfile?['email'] ?? 'No email',
            style: AppTextStyles.body2,
          ),
          if (_userProfile?['phone_number'] != null &&
              _userProfile!['phone_number'].isNotEmpty) ...[
            Text(_userProfile!['phone_number'], style: AppTextStyles.body2),
          ],
          const SizedBox(height: AppDimensions.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tan,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLarge,
                  ),
                ),
                child: Text(
                  _getRoleDisplayName(
                    _userProfile?['current_role'] ?? 'passenger',
                  ),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.carafe,
                  ),
                ),
              ),
              // Role switcher dropdown
              if (_getAvailableRolesForDropdown().length > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brown,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _userProfile?['current_role'] ?? 'passenger',
                      icon: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.white,
                        size: 16,
                      ),
                      dropdownColor: AppColors.white,
                      onChanged:
                          _isSwitchingMode
                              ? null
                              : (String? newRole) {
                                if (newRole != null &&
                                    newRole != _userProfile?['current_role']) {
                                  _switchUserMode(newRole);
                                }
                              },
                      items:
                          _getAvailableRolesForDropdown()
                              .map<DropdownMenuItem<String>>((String role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getRoleIcon(role),
                                        size: 16,
                                        color: AppColors.brown,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getRoleDisplayName(role),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.brown,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Member since ${_formatDate(_userProfile?['date_joined'])}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'passenger':
        return 'PASSENGER';
      case 'vehicle_owner':
        return 'VEHICLE OWNER';
      case 'sacco_admin':
        return 'SACCO ADMIN';
      default:
        return role.toUpperCase();
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildUserModeSection() {
    if (_userProfile == null) {
      return const SizedBox.shrink();
    }

    final shouldShowVehicleOwnerRequest = _shouldShowVehicleOwnerRequest();
    final shouldShowSaccoAdminRequest = _shouldShowSaccoAdminRequest();
    final currentRole = _userProfile?['current_role'] as String? ?? 'passenger';

    // If no requests are needed, don't show this section
    if (!shouldShowVehicleOwnerRequest && !shouldShowSaccoAdminRequest) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Vehicle Owner Request
          if (shouldShowVehicleOwnerRequest) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a Vehicle Owner',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register your vehicle and start earning by providing transport services',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to vehicle owner registration page
                          _showSuccessSnackBar(
                            'Vehicle owner registration coming soon!',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brown,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        icon: const Icon(Icons.directions_car),
                        label: const Text('Register as Vehicle Owner'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Sacco Admin Request
          if (shouldShowSaccoAdminRequest) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Become a Sacco Admin', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      'Request to become a Sacco Admin to manage transport services',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const SaccoAdminRequestPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brown,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Request to be a Sacco Admin'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Quick access to admin dashboard if user is already admin but in different mode
          if (_userProfile!['is_sacco_admin'] == true &&
              currentRole != 'sacco_admin') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: AppColors.brown,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are a Sacco Admin!',
                      style: AppTextStyles.heading3,
                    ),
                    Text(
                      'Switch to admin mode using the dropdown above',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'passenger':
        return Icons.person;
      case 'vehicle_owner':
        return Icons.directions_car;
      case 'sacco_admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Widget _buildStatsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Activity', style: AppTextStyles.heading3),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Reviews',
                  '${_userProfile?['reviews_count'] ?? 0}',
                  Icons.rate_review,
                ),
                _buildStatItem('Trips', '0', Icons.directions_bus),
                _buildStatItem(
                  'Account Status',
                  _userProfile?['is_active'] == true ? 'Active' : 'Inactive',
                  _userProfile?['is_active'] == true
                      ? Icons.check_circle
                      : Icons.cancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.brown, size: 32),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Reviews', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () {
                    // Navigate to full reviews page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _isLoadingReviews
                ? const Center(child: CircularProgressIndicator())
                : _userReviews.isEmpty
                ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: AppColors.grey,
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text('No reviews yet', style: AppTextStyles.body2),
                      Text(
                        'Start reviewing saccos to help other users',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : Column(
                  children:
                      _userReviews.map((review) {
                        return _buildReviewItem(review);
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['overall'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['sacco_name'] ?? 'Unknown Sacco',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'As ${_getRoleDisplayName(review['role'] ?? 'passenger')}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: AppColors.warning,
                      );
                    }),
                  ),
                  Text(
                    'Avg: ${review['average']?.toStringAsFixed(1) ?? '0.0'}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
          if (review['comment'] != null &&
              review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              review['comment'].toString(),
              style: AppTextStyles.body2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(review['created_at'] ?? '', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Text('Settings', style: AppTextStyles.heading3),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.brown),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your personal information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _updateProfile,
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.brown),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.brown),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to help page
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.brown),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PSV Finder',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 PSV Finder. All rights reserved.',
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
