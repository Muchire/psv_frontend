import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'welcome_page.dart';
import 'sacco_admin_request_page.dart';
import 'sacco_admin_dashboard.dart';
import 'vehicle_owner_dashboard.dart';
import 'vehicle_registration.dart';
import 'home_page.dart';

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
    _initializeProfile();
  }

  // Initialize profile with better error handling
  Future<void> _initializeProfile() async {
    await _loadUserProfile();
    await _loadUserReviews();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      print('Profile loaded: $profile'); // Debug print

      if (mounted) {
        setState(() {
          _userProfile = profile;
        });

        // Ensure user has a current_role set
        await _ensureUserRole();
      }
    } catch (e) {
      print('Error loading profile: $e'); // Debug print
      if (mounted) {
        _showErrorSnackBar('Failed to load profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Ensure user has a valid current_role
  Future<void> _ensureUserRole() async {
    if (_userProfile == null) return;

    final currentRole = _userProfile?['current_role'];

    // If no current role is set, default to passenger
    if (currentRole == null || currentRole.isEmpty) {
      try {
        await _switchUserMode('passenger', showSuccess: false);
      } catch (e) {
        // If switching fails, manually set it in local state
        if (mounted) {
          setState(() {
            _userProfile!['current_role'] = 'passenger';
          });
        }
      }
    }
  }

  Future<void> _loadUserReviews() async {
    if (!mounted) return;

    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ApiService.getUserReviews(limit: 3);
      if (mounted) {
        setState(() {
          _userReviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        _showErrorSnackBar('Failed to load reviews: $e');
      }
    }
  }

  Future<void> _switchUserMode(String mode, {bool showSuccess = true}) async {
    if (!mounted) return;

    setState(() => _isSwitchingMode = true);
    try {
      final response = await ApiService.switchUserMode(mode);

      if (!mounted) return;

      if (showSuccess) {
        _showSuccessSnackBar(
          response['message'] ?? 'Switched to $mode mode successfully!',
        );
      }

      // Update the local profile with the new role information
      if (_userProfile != null && response['user'] != null) {
        setState(() {
          _userProfile!['current_role'] = response['user']['current_role'];
        });
      }

      // Handle navigation based on the role - only navigate if showSuccess is true
      if (showSuccess) {
        await _navigateBasedOnRole(mode);
      }
    } catch (e) {
      if (mounted) {
        if (showSuccess) {
          _showErrorSnackBar('Failed to switch mode: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitchingMode = false);
      }
    }
  }

  Future<void> _navigateBasedOnRole(String mode) async {
    if (!mounted) return;

    switch (mode) {
      case 'vehicle_owner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VehicleOwnerDashboard()),
        );
        break;
      case 'sacco_admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SaccoAdminDashboard()),
        );
        break;
      case 'passenger':
        // Stay on profile page for passenger role
        break;
    }
  }

  // Navigate to home page based on user's current role
  void _navigateToHome() {
    final currentRole = _userProfile?['current_role'] ?? 'passenger';

    switch (currentRole) {
      case 'vehicle_owner':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VehicleOwnerDashboard()),
        );
        break;
      case 'sacco_admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SaccoAdminDashboard()),
        );
        break;
      case 'passenger':
      default:
        // Navigate to passenger home/dashboard
        // Replace 'PassengerDashboard()' with your actual passenger home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const HomePage(), // Temporary - replace with actual passenger dashboard
          ),
        );
        break;
    }
  }

  // Updated _showVehicleRegistrationDialog method
  Future<void> _showVehicleRegistrationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VehicleRegistrationDialog(
          onRegistrationSuccess: (response) {
            // First close the dialog
            Navigator.of(context).pop();

            // Update the user profile to reflect the new vehicle owner status
            setState(() {
              _userProfile!['is_vehicle_owner'] = true;
              _userProfile!['current_role'] = 'vehicle_owner';
            });

            // Show success message
            _showSuccessSnackBar(
              'Vehicle registered successfully! Welcome to Vehicle Owner dashboard.',
            );

            // Navigate to vehicle owner dashboard using pushReplacement to replace current screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VehicleOwnerDashboard()),
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
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Profile updated successfully!');
                    await _loadUserProfile();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showErrorSnackBar('Failed to update profile: $e');
                  }
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
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Password changed successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showErrorSnackBar('Failed to change password: $e');
                  }
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
                try {
                  await ApiService.removeToken();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brown),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }

  // Get all available roles (roles the user has access to)
  List<String> _getAllAvailableRoles() {
    if (_userProfile == null) return ['passenger'];

    List<String> availableRoles = [];

    // Always include passenger
    if (_userProfile!['is_passenger'] == true ||
        _userProfile!['is_passenger'] == null) {
      availableRoles.add('passenger');
    }

    if (_userProfile!['is_vehicle_owner'] == true) {
      availableRoles.add('vehicle_owner');
    }

    if (_userProfile!['is_sacco_admin'] == true) {
      availableRoles.add('sacco_admin');
    }

    return availableRoles.isEmpty ? ['passenger'] : availableRoles;
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

  // Helper method to get role color
  Color _getRoleColor(String role) {
    switch (role) {
      case 'vehicle_owner':
        return AppColors.brown;
      case 'sacco_admin':
        return AppColors.carafe;
      case 'passenger':
        return AppColors.tan;
      default:
        return AppColors.tan;
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
                case 'home':
                  _navigateToHome();
                  break;
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
                    value: 'home',
                    child: Row(
                      children: [
                        Icon(Icons.home, color: AppColors.brown),
                        SizedBox(width: 8),
                        Text('Home'),
                      ],
                    ),
                  ),
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
                        Icon(Icons.logout, color: AppColors.brown),
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
                    _buildRoleSwitchingSection(),
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

    final currentRole = _userProfile?['current_role'] ?? 'passenger';

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
            backgroundColor: AppColors.brown,
            child: Text(
              displayName.isNotEmpty
                  ? displayName.substring(0, 1).toUpperCase()
                  : 'U',
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

          // Current Role Display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor(currentRole),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(currentRole),
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current: ${_getRoleDisplayName(currentRole)}',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitchingSection() {
    final availableRoles = _getAllAvailableRoles();
    final currentRole = _userProfile?['current_role'] ?? 'passenger';

    // Only show if user has multiple roles
    if (availableRoles.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Switch Role', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Choose which role you want to use',
            style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Role buttons
          Wrap(
            spacing: AppDimensions.paddingSmall,
            runSpacing: AppDimensions.paddingSmall,
            children:
                availableRoles.map((role) {
                  final isCurrentRole = role == currentRole;
                  final roleColor = _getRoleColor(role);

                  return SizedBox(
                    width:
                        (MediaQuery.of(context).size.width - 80) /
                        2, // Half width minus margins
                    child: ElevatedButton(
                      onPressed:
                          _isSwitchingMode
                              ? null
                              : isCurrentRole
                              ? null
                              : () => _handleRoleSwitch(role),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCurrentRole ? Colors.grey[300] : roleColor,
                        foregroundColor:
                            isCurrentRole ? Colors.grey[600] : AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMedium,
                          horizontal: AppDimensions.paddingSmall,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getRoleIcon(role), size: 24),
                          const SizedBox(height: 4),
                          Text(
                            _getRoleDisplayName(role),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isCurrentRole) ...[
                            const SizedBox(height: 2),
                            const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),

          if (_isSwitchingMode) ...[
            const SizedBox(height: AppDimensions.paddingMedium),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Switching role...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleRoleSwitch(String role) {
    _switchUserMode(role);
  }

  Widget _buildUserModeSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Access', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Vehicle Owner Request/Registration
          if (_shouldShowVehicleOwnerRequest()) ...[
            _buildActionCard(
              icon: Icons.directions_car,
              title: 'Become a Vehicle Owner',
              subtitle:
                  'Register your vehicle and start offering transport services',
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
          if (!_shouldShowVehicleOwnerRequest() &&
              !_shouldShowSaccoAdminRequest()) ...[
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
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: color,
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: _buildStatItem(
                  'Reviews',
                  _userProfile?['total_reviews']?.toString() ?? '0',
                  Icons.star,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  _userProfile?['average_rating']?.toStringAsFixed(1) ?? '0.0',
                  Icons.thumb_up,
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
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brown, size: 28),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
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
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Reviews', style: AppTextStyles.heading2),
              if (_userReviews.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to full reviews page
                    // You can implement this later
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),

          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_userReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'No reviews yet',
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Complete trips to receive reviews',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            )
          else
            Column(
              children:
                  _userReviews
                      .map((review) => _buildReviewItem(review))
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brown,
                child: Text(
                  (review['reviewer_name'] ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewer_name'] ?? 'Anonymous',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${review['rating'] ?? 0}/5',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review['created_at']),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingSmall),
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading2),
          const SizedBox(height: AppDimensions.paddingMedium),

          _buildSettingsItem(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: _updateProfile,
          ),

          _buildSettingsItem(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _changePassword,
          ),

          _buildSettingsItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              // Navigate to notifications settings
              // You can implement this later
              _showInfoSnackBar('Notifications settings coming soon!');
            },
          ),

          _buildSettingsItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // Navigate to help & support
              // You can implement this later
              _showInfoSnackBar('Help & Support coming soon!');
            },
          ),

          _buildSettingsItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              // Show about dialog
              _showAboutDialog();
            },
          ),

          const Divider(),

          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error : AppColors.brown,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.brown,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          color: isDestructive ? AppColors.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? AppColors.brown : Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.brown),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transport App'),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text('Developed for SACCO management and passenger services.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}