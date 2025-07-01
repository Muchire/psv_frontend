// lib/user_app/pages/sacco_routes_page.dart
import 'package:flutter/material.dart';
import '../../services/sacco_admin_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class SaccoRoutesPage extends StatefulWidget {
  const SaccoRoutesPage({super.key});

  @override
  State<SaccoRoutesPage> createState() => _SaccoRoutesPageState();
}

class _SaccoRoutesPageState extends State<SaccoRoutesPage> {
  List<dynamic> _routes = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadDashboardData();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final routes = await SaccoAdminService.getRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final dashboardData = await SaccoAdminService.getDashboardData();
      setState(() {
        _dashboardData = dashboardData;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes Management'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          // Finances Button
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _showFinancesBottomSheet(),
            tooltip: 'Financial Management',
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
            tooltip: 'Refresh Routes',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: LoadingWidget())
              : _error != null
              ? Center(
                child: ErrorDisplayWidget(error: _error!, onRetry: _loadRoutes),
              )
              : _buildRoutesContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRouteDialog(),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        tooltip: 'Add New Route',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Financial Management Bottom Sheet
  void _showFinancesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _FinancesBottomSheet(
                    routes: _routes,
                    dashboardData: _dashboardData,
                    scrollController: scrollController,
                    onFinancialUpdate: () {
                      _loadRoutes();
                      _loadDashboardData();
                    },
                  ),
                ),
          ),
    );
  }

  Widget _buildRoutesContent() {
    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: AppColors.grey),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No routes found',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Add your first route to get started',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton.icon(
              onPressed: () => _showAddRouteDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return _buildRouteCard(route);
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    // Extract route data with proper null safety
    final routeId = route['id']?.toString() ?? '?';
    final startLocation = route['start_location']?.toString() ?? 'Unknown';
    final endLocation = route['end_location']?.toString() ?? 'Unknown';
    final distance = route['distance']?.toString();
    final duration = route['duration']?.toString();
    final fare = route['fare']?.toString();
    final stops =
        (route['stops'] as List<dynamic>?)?.cast<dynamic>() ?? <dynamic>[];

    // Create route name from start to end location
    final routeName = '$startLocation → $endLocation';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brown,
          child: Text(
            routeId,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          routeName,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              children: [
                // Stops count
                Icon(Icons.location_on, size: 16, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  '${stops.length} ${stops.length == 1 ? 'stop' : 'stops'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),

                // Fare if available
                if (fare != null && fare.isNotEmpty) ...[
                  Icon(Icons.attach_money, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('KSh $fare', style: AppTextStyles.caption),
                  const SizedBox(width: AppDimensions.paddingMedium),
                ],

                // Distance if available
                if (distance != null && distance.isNotEmpty) ...[
                  Icon(Icons.straighten, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('${distance}km', style: AppTextStyles.caption),
                ],
              ],
            ),
            if (duration != null && duration.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('${duration} mins', style: AppTextStyles.caption),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditRouteDialog(route);
                break;
              case 'financial':
                _showRouteFinancialDialog(route);
                break;
              case 'delete':
                _showDeleteConfirmation(route);
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Route'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'financial',
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Financial Data'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Route', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brown.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Location',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                                Text(
                                  startLocation,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Location',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                                Text(
                                  endLocation,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if ((distance != null && distance.isNotEmpty) ||
                          (duration != null && duration.isNotEmpty) ||
                          (fare != null && fare.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (distance != null && distance.isNotEmpty) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distance',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${distance}km',
                                      style: AppTextStyles.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (duration != null && duration.isNotEmpty) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${duration} mins',
                                      style: AppTextStyles.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (fare != null && fare.isNotEmpty) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fare',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    Text(
                                      'KSh $fare',
                                      style: AppTextStyles.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Route Journey Section
                Text(
                  'Route Journey',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),

                // Route journey visualization
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // Start location
                      _buildJourneyStop(startLocation, 'START', true, false),

                      // Intermediate stops
                      if (stops.isNotEmpty)
                        ...stops.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stop = entry.value;

                          String stopName = 'Unknown Stop';
                          if (stop is Map<String, dynamic>) {
                            stopName =
                                stop['stage_name']?.toString() ??
                                stop['name']?.toString() ??
                                'Unknown Stop';
                          } else if (stop is String) {
                            stopName = stop;
                          }

                          return _buildJourneyStop(
                            stopName,
                            'STOP ${index + 1}',
                            false,
                            false,
                          );
                        }),

                      // End location
                      _buildJourneyStop(endLocation, 'END', false, true),
                    ],
                  ),
                ),

                // No stops message
                if (stops.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No intermediate stops configured',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStop(
    String name,
    String label,
    bool isStart,
    bool isEnd,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor:
                    isStart || isEnd ? AppColors.brown : AppColors.grey,
                child: Icon(
                  isStart
                      ? Icons.play_arrow
                      : isEnd
                      ? Icons.stop
                      : Icons.circle,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!isEnd)
                Container(
                  width: 2,
                  height: 24,
                  color: AppColors.grey.withOpacity(0.5),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    isStart || isEnd
                        ? AppColors.brown.withOpacity(0.1)
                        : AppColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      isStart || isEnd
                          ? AppColors.brown.withOpacity(0.3)
                          : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight:
                            isStart || isEnd
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isStart || isEnd ? AppColors.brown : AppColors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => _RouteFormDialog(
            title: 'Add New Route',
            onSave: (routeData) async {
              try {
                await SaccoAdminService.createRoute(routeData);
                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Route created successfully');
                  _loadRoutes();
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Failed to create route: $e');
                }
              }
            },
          ),
    );
  }

  void _showEditRouteDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => _RouteFormDialog(
            title: 'Edit Route',
            initialRoute: route,
            onSave: (routeData) async {
              try {
                await SaccoAdminService.updateRoute(route['id'], routeData);
                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Route updated successfully');
                  _loadRoutes();
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Failed to update route: $e');
                }
              }
            },
          ),
    );
  }

  void _showRouteFinancialDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => _RouteFinancialDialog(
            route: route,
            onUpdate: () {
              _loadRoutes();
              _loadDashboardData();
            },
          ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> route) {
    final routeName = '${route['start_location']} → ${route['end_location']}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete Route'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$routeName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await SaccoAdminService.deleteRoute(route['id']);
                  if (mounted) {
                    _showSuccessSnackBar('Route deleted successfully');
                    _loadRoutes();
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Failed to delete route: $e');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.brown,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ==================== FINANCIAL COMPONENTS ====================

class _FinancesBottomSheet extends StatefulWidget {
  final List<dynamic> routes;
  final Map<String, dynamic>? dashboardData;
  final ScrollController scrollController;
  final VoidCallback onFinancialUpdate;

  const _FinancesBottomSheet({
    required this.routes,
    required this.dashboardData,
    required this.scrollController,
    required this.onFinancialUpdate,
  });

  @override
  State<_FinancesBottomSheet> createState() => _FinancesBottomSheetState();
}

class _FinancesBottomSheetState extends State<_FinancesBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _financialMetrics;
  bool _isLoadingMetrics = false;
  bool _canEditMetrics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFinancialMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialMetrics() async {
    if (widget.dashboardData == null) return;

    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      final saccoId = widget.dashboardData!['sacco']?['id'];
      if (saccoId != null) {
        final canEdit = await SaccoAdminService.canEditFinancialMetrics(
          saccoId,
        );
        final metrics = await SaccoAdminService.getSaccoFinancialMetrics(
          saccoId,
        );

        setState(() {
          _canEditMetrics = canEdit;
          _financialMetrics = metrics;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMetrics = false;
      });
      print('Error loading financial metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.brown),
              const SizedBox(width: 8),
              Text(
                'Financial Management',
                style: AppTextStyles.heading2.copyWith(color: AppColors.brown),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: AppColors.brown,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.brown,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Route Finances'),
            Tab(text: 'Sacco Metrics'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRouteFinancesTab(),
              _buildSaccoMetricsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          if (widget.dashboardData != null) ...[
            Text(
              'Financial Overview',
              style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
            ),
            const SizedBox(height: 16),

            // Summary cards based on dashboard data
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Routes',
                    widget.routes.length.toString(),
                    Icons.route,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Active Routes',
                    widget.routes
                        .where((route) => route['fare'] != null)
                        .length
                        .toString(),
                    Icons.timeline,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Financial Metrics Preview
          if (_financialMetrics != null) ...[
            Text(
              'Key Metrics',
              style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
            ),
            const SizedBox(height: 12),

            _buildMetricCard(
              'Avg Revenue per Vehicle',
              'KSh ${_financialMetrics!['avg_revenue_per_vehicle']?.toString() ?? 'N/A'}',
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(height: 8),

            _buildMetricCard(
              'Operational Costs',
              'KSh ${_financialMetrics!['operational_costs']?.toString() ?? 'N/A'}',
              Icons.trending_down,
              Colors.orange,
            ),
            const SizedBox(height: 8),

            _buildMetricCard(
              'Net Profit Margin',
              '${_financialMetrics!['net_profit_margin']?.toString() ?? 'N/A'}%',
              Icons.trending_up,
              Colors.blue,
            ),
          ],

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            'Update Route Finances',
            Icons.route,
            () => _tabController.animateTo(1),
          ),
          const SizedBox(height: 8),

          _buildActionButton(
            'Manage Sacco Metrics',
            Icons.business,
            () => _tabController.animateTo(2),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFinancesTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Financial Data',
            style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
          ),
          const SizedBox(height: 16),

          if (widget.routes.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.route, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('No routes available', style: AppTextStyles.body1),
                ],
              ),
            )
          else
            ...widget.routes
                .map((route) => _buildRouteFinancialCard(route))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSaccoMetricsTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sacco Financial Metrics',
                style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
              ),
              const Spacer(),
              if (_canEditMetrics)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditSaccoMetricsDialog(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingMetrics)
            const Center(child: CircularProgressIndicator())
          else if (_financialMetrics == null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No financial metrics available',
                    style: AppTextStyles.body1,
                  ),
                  if (_canEditMetrics) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showEditSaccoMetricsDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Add Financial Metrics'),
                    ),
                  ],
                ],
              ),
            )
          else
            Column(
              children: [
                _buildMetricCard(
                  'Total Vehicles',
                  _financialMetrics!['total_vehicles']?.toString() ?? 'N/A',
                  Icons.directions_bus,
                  Colors.blue,
                ),
                const SizedBox(height: 12),

                _buildMetricCard(
                  'Average Revenue per Vehicle',
                  'KSh ${_financialMetrics!['avg_revenue_per_vehicle']?.toString() ?? 'N/A'}',
                  Icons.attach_money,
                  Colors.green,
                ),
                const SizedBox(height: 12),

                _buildMetricCard(
                  'Monthly Operational Costs',
                  'KSh ${_financialMetrics!['operational_costs']?.toString() ?? 'N/A'}',
                  Icons.trending_down,
                  Colors.orange,
                ),
                const SizedBox(height: 12),

                _buildMetricCard(
                  'Net Profit Margin',
                  '${_financialMetrics!['net_profit_margin']?.toString() ?? 'N/A'}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
                const SizedBox(height: 12),

                _buildMetricCard(
                  'Average Daily Passengers',
                  _financialMetrics!['avg_daily_passengers']?.toString() ??
                      'N/A',
                  Icons.people,
                  Colors.teal,
                ),
                const SizedBox(height: 12),

                _buildMetricCard(
                  'Fuel Cost per KM',
                  'KSh ${_financialMetrics!['fuel_cost_per_km']?.toString() ?? 'N/A'}',
                  Icons.local_gas_station,
                  Colors.red,
                ),

                if (!_canEditMetrics) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You don\'t have permission to edit these metrics. Contact your administrator.',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.heading2.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.body2.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.brown.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brown),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: AppColors.brown, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteFinancialCard(Map<String, dynamic> route) {
    final routeName = '${route['start_location']} → ${route['end_location']}';
    final fare = route['fare']?.toString();
    final routeId = route['id']?.toString() ?? '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brown,
                  child: Text(
                    routeId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fare != null)
                        Text(
                          'Fare: KSh $fare',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRouteFinancialEditDialog(route),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSaccoMetricsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _SaccoMetricsDialog(
            initialMetrics: _financialMetrics,
            saccoId: widget.dashboardData?['sacco']?['id'],
            onSave: () {
              _loadFinancialMetrics();
              widget.onFinancialUpdate();
            },
          ),
    );
  }

  void _showRouteFinancialEditDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder:
          (context) => _RouteFinancialDialog(
            route: route,
            onUpdate: () {
              widget.onFinancialUpdate();
            },
          ),
    );
  }
}

// ==================== DIALOG COMPONENTS ====================

class _RouteFormDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialRoute;
  final Function(Map<String, dynamic>) onSave;

  const _RouteFormDialog({
    required this.title,
    this.initialRoute,
    required this.onSave,
  });

  @override
  State<_RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<_RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _fareController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  final TextEditingController _ownerAvgProfitController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialRoute != null) {
      final route = widget.initialRoute!;
      _startLocationController.text = route['start_location']?.toString() ?? '';
      _endLocationController.text = route['end_location']?.toString() ?? '';
      _distanceController.text = route['distance']?.toString() ?? '';
      _durationController.text = route['duration']?.toString() ?? '';
      _fareController.text = route['fare']?.toString() ?? '';

      final stops = route['stops'] as List? ?? [];
      for (int i = 0; i < stops.length; i++) {
        final controller = TextEditingController();
        if (stops[i] is Map) {
          controller.text =
              stops[i]['stage_name']?.toString() ??
              stops[i]['name']?.toString() ??
              '';
        } else {
          controller.text = stops[i].toString();
        }
        _stopControllers.add(controller);
      }
    }
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _fareController.dispose();
    for (final controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _startLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _endLocationController,
                  decoration: const InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Distance (km)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _fareController,
                  decoration: const InputDecoration(
                    labelText: 'Fare (KSh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Intermediate stops section
                Row(
                  children: [
                    Text(
                      'Intermediate Stops',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addStop,
                    ),
                  ],
                ),

                ..._stopControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Stop ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _removeStop(index),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoute,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  void _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final routeData = {
      'start_location': _startLocationController.text.trim(),
      'end_location': _endLocationController.text.trim(),
      'distance':
          _distanceController.text.trim().isNotEmpty
              ? double.tryParse(_distanceController.text.trim())
              : null,
      'duration':
          _durationController.text.trim().isNotEmpty
              ? int.tryParse(_durationController.text.trim())
              : null,
      'fare':
          _fareController.text.trim().isNotEmpty
              ? double.tryParse(_fareController.text.trim())
              : null,
      'stops':
          _stopControllers
              .map((controller) => controller.text.trim())
              .where((stop) => stop.isNotEmpty)
              .toList(),
    };

    try {
      await widget.onSave(routeData);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      rethrow;
    }
  }
}

class _RouteFinancialDialog extends StatefulWidget {
  final Map<String, dynamic> route;
  final VoidCallback onUpdate;

  const _RouteFinancialDialog({required this.route, required this.onUpdate});

  @override
  State<_RouteFinancialDialog> createState() => _RouteFinancialDialogState();
}

class _RouteFinancialDialogState extends State<_RouteFinancialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fareController = TextEditingController();
  final _dailyTripsController = TextEditingController();
  final _avgPassengersController = TextEditingController();
  bool _isLoading = false;
  
  var _ownerAvgProfitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fareController.text = widget.route['fare']?.toString() ?? '';
    _dailyTripsController.text = widget.route['daily_trips']?.toString() ?? '';
    _avgPassengersController.text =
        widget.route['avg_passengers']?.toString() ?? '';
  }

  @override
  void dispose() {
    _fareController.dispose();
    _dailyTripsController.dispose();
    _avgPassengersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeName =
        '${widget.route['start_location']} → ${widget.route['end_location']}';

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Route Financial Data'),
          Text(
            routeName,
            style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fareController,
              decoration: const InputDecoration(
                labelText: 'Fare per Trip (KSh)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter fare amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dailyTripsController,
              decoration: const InputDecoration(
                labelText: 'Average Daily Trips',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _avgPassengersController,
              decoration: const InputDecoration(
                labelText: 'Average Passengers per Trip',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveFinancialData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }
  Widget _buildOwnerAvgProfitField() {
    return TextFormField(
      controller: _ownerAvgProfitController,
      decoration: InputDecoration(
        labelText: 'Owner Average Profit (KSh)',
        hintText: 'Enter average profit per vehicle owner',
        prefixIcon: Icon(Icons.account_balance_wallet),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          if (double.parse(value) < 0) {
            return 'Profit cannot be negative';
          }
        }
        return null;
      },
    );
  }

  void _saveFinancialData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final financialData = {
        'fare': double.parse(_fareController.text.trim()),
        'daily_trips':
            _dailyTripsController.text.trim().isNotEmpty
                ? int.parse(_dailyTripsController.text.trim())
                : null,
        'avg_passengers':
            _avgPassengersController.text.trim().isNotEmpty
                ? int.parse(_avgPassengersController.text.trim())
                : null,
      };

      await SaccoAdminService.updateRouteFinancialData(
        widget.route['id'],
        financialData,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 8),
                const Text('Financial data updated successfully'),
              ],
            ),
            backgroundColor: AppColors.brown,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SaccoMetricsDialog extends StatefulWidget {
  final Map<String, dynamic>? initialMetrics;
  final int? saccoId;
  final VoidCallback onSave;

  const _SaccoMetricsDialog({
    this.initialMetrics,
    required this.saccoId,
    required this.onSave,
  });

  @override
  State<_SaccoMetricsDialog> createState() => _SaccoMetricsDialogState();
}

class _SaccoMetricsDialogState extends State<_SaccoMetricsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _totalVehiclesController = TextEditingController();
  final _avgRevenueController = TextEditingController();
  final _operationalCostsController = TextEditingController();
  final _profitMarginController = TextEditingController();
  final _avgPassengersController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final TextEditingController _ownerAvgProfitController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialMetrics != null) {
      final metrics = widget.initialMetrics!;
      _totalVehiclesController.text =
          metrics['total_vehicles']?.toString() ?? '';
      _avgRevenueController.text =
          metrics['avg_revenue_per_vehicle']?.toString() ?? '';
      _operationalCostsController.text =
          metrics['operational_costs']?.toString() ?? '';
      _profitMarginController.text =
          metrics['net_profit_margin']?.toString() ?? '';
      _avgPassengersController.text =
          metrics['avg_daily_passengers']?.toString() ?? '';
      _fuelCostController.text = metrics['fuel_cost_per_km']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _totalVehiclesController.dispose();
    _avgRevenueController.dispose();
    _operationalCostsController.dispose();
    _profitMarginController.dispose();
    _avgPassengersController.dispose();
    _fuelCostController.dispose();
    _ownerAvgProfitController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sacco Financial Metrics'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _totalVehiclesController,
                  decoration: const InputDecoration(
                    labelText: 'Total Vehicles',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter total vehicles';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _avgRevenueController,
                  decoration: const InputDecoration(
                    labelText: 'Avg Revenue per Vehicle (KSh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _operationalCostsController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Operational Costs (KSh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _profitMarginController,
                  decoration: const InputDecoration(
                    labelText: 'Net Profit Margin (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _avgPassengersController,
                  decoration: const InputDecoration(
                    labelText: 'Average Daily Passengers',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _fuelCostController,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Cost per KM (KSh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMetrics,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  void _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the correct method from SaccoAdminService
      await SaccoAdminService.updateSaccoFinancialMetrics(
        widget.saccoId!,
        avgRevenuePerVehicle:
            _avgRevenueController.text.trim().isNotEmpty
                ? double.parse(_avgRevenueController.text.trim())
                : null,
        operationalCosts:
            _operationalCostsController.text.trim().isNotEmpty
                ? double.parse(_operationalCostsController.text.trim())
                : null,
        netProfitMargin:
            _profitMarginController.text.trim().isNotEmpty
                ? double.parse(_profitMarginController.text.trim())
                : null,
        ownerAverageProfit:
            _ownerAvgProfitController.text.trim().isNotEmpty
                ? double.parse(_ownerAvgProfitController.text.trim())
                : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 8),
                const Text('Metrics updated successfully'),
              ],
            ),
            backgroundColor: AppColors.brown,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update metrics: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
