import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'welcome_page.dart';
import 'sacco_admin_request_page.dart';
import 'sacco_admin_dashboard.dart';
import 'vehicle_owner_dashboard.dart';
import 'vehicle_registration.dart';

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

  // Show vehicle registration dialog
  Future<void> _showVehicleRegistrationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VehicleRegistrationDialog(
          onRegistrationSuccess: (response) {
            // Update the user profile to reflect the new vehicle owner status
            setState(() {
              _userProfile!['is_vehicle_owner'] = true;
              _userProfile!['current_role'] = 'vehicle_owner';
            });
            
            // Navigate to vehicle owner dashboard
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleOwnerDashboard(),
              ),
            );
          },
        );
      },
    );
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
    final isSaccoAdmin = _userProfile!['is_sacco_admin'] == true;

    // Show request only if user is passenger, not already a vehicle owner, and not a sacco admin
    return currentRole == 'passenger' && !isVehicleOwner && !isSaccoAdmin;
  }

  // Check if user should see sacco admin request option
  bool _shouldShowSaccoAdminRequest() {
    if (_userProfile == null) return false;
    
    final isSaccoAdmin = _userProfile!['is_sacco_admin'] == true;
    final isVehicleOwner = _userProfile!['is_vehicle_owner'] == true;
    
    // Show request only if user is not already a sacco admin and not a vehicle owner
    return !isSaccoAdmin && !isVehicleOwner;
  }

  // Helper method to get role display name
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'vehicle_owner':
        return 'Vehicle Owner';
      case 'sacco_admin':
        return 'SACCO Admin';
      case 'passenger':
        return 'Passenger';
      default:
        return 'Passenger';
    }
  }

  // Helper method to get role icon
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'vehicle_owner':
        return Icons.directions_car;
      case 'sacco_admin':
        return Icons.admin_panel_settings;
      case 'passenger':
        return Icons.person;
      default:
        return Icons.person;
    }
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
            itemBuilder: (context) => [
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
      body: _isLoading
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
    final displayName = fullName.isNotEmpty
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
                      onChanged: _isSwitchingMode
                          ? null
                          : (String? newRole) {
                              if (newRole != null &&
                                  newRole != _userProfile?['current_role']) {
                                _switchUserMode(newRole);
                              }
                            },
                      items: _getAvailableRolesForDropdown()
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
                                style: const TextStyle(
                                  color: AppColors.brown,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserModeSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Access',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Vehicle Owner Request/Registration
          if (_shouldShowVehicleOwnerRequest()) ...[
            _buildActionCard(
              icon: Icons.directions_car,
              title: 'Become a Vehicle Owner',
              subtitle: 'Register your vehicle and start offering transport services',
              buttonText: 'Register Vehicle',
              onTap: _showVehicleRegistrationDialog,
              color: AppColors.brown,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
          ],
          
          // SACCO Admin Request
          if (_shouldShowSaccoAdminRequest()) ...[
            _buildActionCard(
              icon: Icons.admin_panel_settings,
              title: 'Become a SACCO Admin',
              subtitle: 'Apply to manage SACCO operations and oversee vehicles',
              buttonText: 'Request Access',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SaccoAdminRequestPage(),
                  ),
                );
              },
              color: AppColors.carafe,
            ),
          ],

          // If user can't access any new roles, show info
          if (!_shouldShowVehicleOwnerRequest() && !_shouldShowSaccoAdminRequest()) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.brown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have access to all available account types.',
                      style: AppTextStyles.body2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Stats', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Trips',
                  _userProfile?['total_trips']?.toString() ?? '0',
                  Icons.route,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  _userProfile?['average_rating']?.toStringAsFixed(1) ?? '0.0',
                  Icons.star,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Reviews',
                  _userProfile?['total_reviews']?.toString() ?? '0',
                  Icons.rate_review,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brown, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Reviews', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingMedium),
          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_userReviews.isEmpty)
            Center(
              child: Text(
                'No reviews yet',
                style: AppTextStyles.body2.copyWith(color: Colors.grey),
              ),
            )
          else
            ..._userReviews.map((review) => _buildReviewItem(review)).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (review['rating'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: AppColors.brown,
                  size: 16,
                );
              }),
              const Spacer(),
              Text(
                review['created_at'] ?? '',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review['comment'], style: AppTextStyles.body2),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingMedium),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.brown),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _updateProfile,
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.brown),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}