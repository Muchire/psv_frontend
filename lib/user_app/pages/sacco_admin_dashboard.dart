import 'package:flutter/material.dart';
import "../utils/constants.dart";

class SaccoAdminDashboard extends StatefulWidget {
  const SaccoAdminDashboard({super.key});

  @override
  State<SaccoAdminDashboard> createState() => _SaccoAdminDashboardState();
}

class _SaccoAdminDashboardState extends State<SaccoAdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacco Admin Dashboard'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showComingSoon('Notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showComingSoon('Settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildQuickStatsSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildQuickActionsSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildManagementSection(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildReportsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brown, AppColors.carafe],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.white,
                  size: 32,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Admin!',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Manage your Sacco operations from here',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.white.withAlpha(25),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Quick Overview',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Active Members', '245'),
                _buildQuickStat('Total Loans', '150'),
                _buildQuickStat('Deposits Today', 'KSh 45,000'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withAlpha(25),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Members',
                '1,245',
                Icons.people,
                AppColors.green,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Active Loans',
                '324',
                Icons.account_balance_wallet,
                AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Deposits',
                'KSh 2.5M',
                Icons.savings,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Pending Applications',
                '12',
                Icons.pending_actions,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppDimensions.paddingSmall,
          mainAxisSpacing: AppDimensions.paddingSmall,
          children: [
            _buildActionCard(
              'Add Member',
              Icons.person_add,
              AppColors.green,
              () => _showComingSoon('Add Member'),
            ),
            _buildActionCard(
              'Process Loan',
              Icons.monetization_on,
              AppColors.orange,
              () => _showComingSoon('Process Loan'),
            ),
            _buildActionCard(
              'Record Deposit',
              Icons.account_balance,
              AppColors.blue,
              () => _showComingSoon('Record Deposit'),
            ),
            _buildActionCard(
              'Send Notice',
              Icons.notifications_active,
              Colors.purple,
              () => _showComingSoon('Send Notice'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _buildManagementItem(
          'Member Management',
          'View, add, edit, and manage member information',
          Icons.people_outline,
          () => _showComingSoon('Member Management'),
        ),
        _buildManagementItem(
          'Loan Management',
          'Process loan applications and track repayments',
          Icons.account_balance_wallet_outlined,
          () => _showComingSoon('Loan Management'),
        ),
        _buildManagementItem(
          'Financial Records',
          'Track deposits, withdrawals, and account balances',
          Icons.receipt_long,
          () => _showComingSoon('Financial Records'),
        ),
        _buildManagementItem(
          'System Settings',
          'Configure system parameters and user permissions',
          Icons.settings_outlined,
          () => _showComingSoon('System Settings'),
        ),
      ],
    );
  }

  Widget _buildManagementItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brown.withAlpha(25),
          child: Icon(icon, color: AppColors.brown),
        ),
        title: Text(
          title,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Analytics',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.brown,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                'Monthly Report',
                'Generate comprehensive monthly reports',
                Icons.bar_chart,
                () => _showComingSoon('Monthly Report'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: _buildReportCard(
                'Member Analytics',
                'View member activity and statistics',
                Icons.analytics,
                () => _showComingSoon('Member Analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brown, size: 32),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index != 0) {
          _showComingSoon('Navigation Item ${index + 1}');
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.brown,
      unselectedItemColor: AppColors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Members',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Loans',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.construction,
                color: AppColors.brown,
              ),
              const SizedBox(width: 8),
              Text(
                'Coming Soon',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.brown,
                ),
              ),
            ],
          ),
          content: Text(
            '$feature feature is currently under development and will be available soon!',
            style: AppTextStyles.body1,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brown,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}