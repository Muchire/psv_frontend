// lib/user_app/pages/financial_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sacco_admin_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class FinancialManagementPage extends StatefulWidget {
  final int saccoId;
  final String saccoName;

  const FinancialManagementPage({
    super.key,
    required this.saccoId,
    required this.saccoName,
  });

  @override
  State<FinancialManagementPage> createState() => _FinancialManagementPageState();
}

class _FinancialManagementPageState extends State<FinancialManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Financial metrics data
  Map<String, dynamic>? _financialMetrics;
  bool _isLoadingMetrics = true;
  String? _metricsError;
  bool _canEditMetrics = false;
  
  // Routes data for individual route management
  List<dynamic> _routes = [];
  bool _isLoadingRoutes = true;
  String? _routesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFinancialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    await Future.wait([
      _loadFinancialMetrics(),
      _loadRoutes(),
    ]);
  }

  Future<void> _loadFinancialMetrics() async {
    try {
      setState(() {
        _isLoadingMetrics = true;
        _metricsError = null;
      });

      // Check if user can edit financial metrics
      final canEdit = await SaccoAdminService.canEditFinancialMetrics(widget.saccoId);
      
      // Load financial metrics if user has permission
      Map<String, dynamic>? metricsResponse;
      if (canEdit) {
        metricsResponse = await SaccoAdminService.getSaccoFinancialMetrics(widget.saccoId);
      }

      setState(() {
        _canEditMetrics = canEdit;
        _financialMetrics = metricsResponse?['financial_metrics']; // Extract the nested financial_metrics
        _isLoadingMetrics = false;
      });
    } catch (e) {
      setState(() {
        _metricsError = e.toString();
        _isLoadingMetrics = false;
        _canEditMetrics = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoadingRoutes = true;
        _routesError = null;
      });

      final routes = await SaccoAdminService.getRoutes();
      setState(() {
        _routes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      setState(() {
        _routesError = e.toString();
        _isLoadingRoutes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Management'),
            Text(
              widget.saccoName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sacco Metrics', icon: Icon(Icons.analytics)),
            Tab(text: 'Route Finance', icon: Icon(Icons.route)),
          ],
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSaccoMetricsTab(),
          _buildRouteFinanceTab(),
        ],
      ),
    );
  }

  Widget _buildSaccoMetricsTab() {
    if (_isLoadingMetrics) {
      return const Center(child: LoadingWidget());
    }

    if (_metricsError != null) {
      return Center(
        child: ErrorDisplayWidget(
          error: _metricsError!,
          onRetry: _loadFinancialMetrics,
        ),
      );
    }

    if (!_canEditMetrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: AppColors.grey),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Access Restricted',
              style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'You don\'t have permission to view financial metrics',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFinancialMetrics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brown, AppColors.brown.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: AppColors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Overview',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'Manage your sacco\'s financial metrics',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showEditMetricsDialog(),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.brown,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Metrics Cards
            if (_financialMetrics != null)
              _buildMetricsGrid()
            else
              _buildNoMetricsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = _financialMetrics!;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.paddingMedium,
      mainAxisSpacing: AppDimensions.paddingMedium,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Monthly Revenue',
          'KSh ${_formatCurrency(metrics['avg_monthly_revenue_per_vehicle'])}',
          'per vehicle',
          Icons.trending_up,
          AppColors.green,
        ),
        _buildMetricCard(
          'Operational Costs',
          'KSh ${_formatCurrency(metrics['operational_costs'])}',
          'monthly',
          Icons.account_balance_wallet,
          Colors.orange,
        ),
        _buildMetricCard(
          'Net Profit Margin',
          '${_formatPercentage(metrics['net_profit_margin'])}%',
          'profit margin',
          Icons.percent,
          AppColors.blue,
        ),
        _buildMetricCard(
          'Owner Average Profit',
          'KSh ${_formatCurrency(metrics['owner_average_profit'])}',
          'monthly',
          Icons.person,
          AppColors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMetricsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppColors.grey),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No Financial Metrics',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Set up your financial metrics to track performance',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => _showEditMetricsDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Metrics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brown,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFinanceTab() {
    if (_isLoadingRoutes) {
      return const Center(child: LoadingWidget());
    }

    if (_routesError != null) {
      return Center(
        child: ErrorDisplayWidget(
          error: _routesError!,
          onRetry: _loadRoutes,
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: AppColors.grey),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No Routes Found',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Add routes to manage their financial data',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey),
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
          return _buildRouteFinanceCard(route);
        },
      ),
    );
  }

  Widget _buildRouteFinanceCard(Map<String, dynamic> route) {
    final routeId = route['id']?.toString() ?? '?';
    final startLocation = route['start_location']?.toString() ?? 'Unknown';
    final endLocation = route['end_location']?.toString() ?? 'Unknown';
    final routeName = '$startLocation → $endLocation';
    final fare = route['fare']?.toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.brown,
                  child: Text(
                    routeId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                          'Current Fare: KSh $fare',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit_financial':
                        _showEditRouteFinancialDialog(route);
                        break;
                      case 'view_earnings':
                        _showRouteEarningsDialog(route);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit_financial',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Financial Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'view_earnings',
                      child: Row(
                        children: [
                          Icon(Icons.calculate),
                          SizedBox(width: 8),
                          Text('View Earnings'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Financial Metrics Preview
            _buildRouteFinancialPreview(route),

            const SizedBox(height: AppDimensions.paddingMedium),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditRouteFinancialDialog(route),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Financial'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brown,
                      side: BorderSide(color: AppColors.brown),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRouteEarningsDialog(route),
                    icon: const Icon(Icons.calculate, size: 18),
                    label: const Text('View Earnings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brown,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteFinancialPreview(Map<String, dynamic> route) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brown.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetricItem(
                  'Daily Trips',
                  route['avg_daily_trips']?.toString() ?? 'Not set',
                  Icons.directions_bus,
                ),
              ),
              Expanded(
                child: _buildFinancialMetricItem(
                  'Peak Multiplier',
                  route['peak_hours_multiplier']?.toString() ?? 'Not set',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetricItem(
                  'Fuel Cost/km',
                  route['fuel_cost_per_km'] != null 
                      ? 'KSh ${route['fuel_cost_per_km']}'
                      : 'Not set',
                  Icons.local_gas_station,
                ),
              ),
              Expanded(
                child: _buildFinancialMetricItem(
                  'Maintenance/Month',
                  route['maintenance_cost_per_month'] != null 
                      ? 'KSh ${route['maintenance_cost_per_month']}'
                      : 'Not set',
                  Icons.build,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brown),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditMetricsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _FinancialMetricsDialog(
        initialMetrics: _financialMetrics,
        onSave: (metricsData) async {
          try {
            await SaccoAdminService.updateSaccoFinancialMetrics(
              widget.saccoId,
              avgRevenuePerVehicle: metricsData['avg_revenue_per_vehicle'],
              operationalCosts: metricsData['operational_costs'],
              netProfitMargin: metricsData['net_profit_margin'],
              ownerAverageProfit: metricsData['owner_average_profit'],
            );
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Financial metrics updated successfully');
              _loadFinancialMetrics();
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Failed to update metrics: $e');
            }
          }
        },
      ),
    );
  }

  void _showEditRouteFinancialDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _RouteFinancialDialog(
        route: route,
        onSave: (financialData) async {
          try {
            await SaccoAdminService.updateRouteFinancialData(
              route['id'],
              financialData,
            );
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Route financial data updated successfully');
              _loadRoutes();
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Failed to update route financial data: $e');
            }
          }
        },
      ),
    );
  }

  void _showRouteEarningsDialog(Map<String, dynamic> route) async {
    try {
      final earningsData = await SaccoAdminService.getRouteEarnings(route['id']);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => _RouteEarningsDialog(
            route: route,
            earningsData: earningsData,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load earnings data: $e');
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final double numValue = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
    return numValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatPercentage(dynamic value) {
    if (value == null) return '0';
    final double numValue = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
    return numValue.toStringAsFixed(1);
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

// Dialog for editing financial metrics
class _FinancialMetricsDialog extends StatefulWidget {
  final Map<String, dynamic>? initialMetrics;
  final Function(Map<String, dynamic>) onSave;

  const _FinancialMetricsDialog({
    this.initialMetrics,
    required this.onSave,
  });

  @override
  State<_FinancialMetricsDialog> createState() => _FinancialMetricsDialogState();
}

class _FinancialMetricsDialogState extends State<_FinancialMetricsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _avgRevenueController = TextEditingController();
  final _operationalCostsController = TextEditingController();
  final _profitMarginController = TextEditingController();
  final _ownerProfitController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMetrics != null) {
      final metrics = widget.initialMetrics!;
      _avgRevenueController.text = metrics['avg_monthly_revenue_per_vehicle']?.toString() ?? '';
      _operationalCostsController.text = metrics['operational_costs']?.toString() ?? '';
      _profitMarginController.text = metrics['net_profit_margin']?.toString() ?? '';
      _ownerProfitController.text = metrics['owner_average_profit']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _avgRevenueController.dispose();
    _operationalCostsController.dispose();
    _profitMarginController.dispose();
    _ownerProfitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Financial Metrics'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _avgRevenueController,
                  decoration: const InputDecoration(
                    labelText: 'Average Monthly Revenue per Vehicle (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final revenue = double.tryParse(value);
                      if (revenue == null || revenue < 0) {
                        return 'Enter valid revenue amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                TextFormField(
                  controller: _operationalCostsController,
                  decoration: const InputDecoration(
                    labelText: 'Operational Costs (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final costs = double.tryParse(value);
                      if (costs == null || costs < 0) {
                        return 'Enter valid cost amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                TextFormField(
                  controller: _profitMarginController,
                  decoration: const InputDecoration(
                    labelText: 'Net Profit Margin (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final margin = double.tryParse(value);
                      if (margin == null || margin < 0 || margin > 100) {
                        return 'Enter valid percentage (0-100)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                TextFormField(
                  controller: _ownerProfitController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Average Profit (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final profit = double.tryParse(value);
                      if (profit == null || profit < 0) {
                        return 'Enter valid profit amount';
                      }
                    }
                    return null;
                  },
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
          // Complete the _FinancialMetricsDialog and add the missing dialogs

  child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final metricsData = {
        'avg_revenue_per_vehicle': _avgRevenueController.text.isNotEmpty 
            ? double.parse(_avgRevenueController.text) 
            : null,
        'operational_costs': _operationalCostsController.text.isNotEmpty 
            ? double.parse(_operationalCostsController.text) 
            : null,
        'net_profit_margin': _profitMarginController.text.isNotEmpty 
            ? double.parse(_profitMarginController.text) 
            : null,
        'owner_average_profit': _ownerProfitController.text.isNotEmpty 
            ? double.parse(_ownerProfitController.text) 
            : null,
      };

      widget.onSave(metricsData);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving metrics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Dialog for editing route financial data
class _RouteFinancialDialog extends StatefulWidget {
  final Map<String, dynamic> route;
  final Function(Map<String, dynamic>) onSave;

  const _RouteFinancialDialog({
    required this.route,
    required this.onSave,
  });

  @override
  State<_RouteFinancialDialog> createState() => _RouteFinancialDialogState();
}

class _RouteFinancialDialogState extends State<_RouteFinancialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dailyTripsController = TextEditingController();
  final _peakMultiplierController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _maintenanceCostController = TextEditingController();
  final _driverCommissionController = TextEditingController();
  final _conductorCommissionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _dailyTripsController.text = route['avg_daily_trips']?.toString() ?? '';
    _peakMultiplierController.text = route['peak_hours_multiplier']?.toString() ?? '';
    _fuelCostController.text = route['fuel_cost_per_km']?.toString() ?? '';
    _maintenanceCostController.text = route['maintenance_cost_per_month']?.toString() ?? '';
    _driverCommissionController.text = route['driver_commission_percentage']?.toString() ?? '';
    _conductorCommissionController.text = route['conductor_commission_percentage']?.toString() ?? '';
  }

  @override
  void dispose() {
    _dailyTripsController.dispose();
    _peakMultiplierController.dispose();
    _fuelCostController.dispose();
    _maintenanceCostController.dispose();
    _driverCommissionController.dispose();
    _conductorCommissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeName = '${widget.route['start_location']} → ${widget.route['end_location']}';
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Route Financial Data'),
          Text(
            routeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Operations Section
                const Text(
                  'Operations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _dailyTripsController,
                  decoration: const InputDecoration(
                    labelText: 'Average Daily Trips',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bus),
                    helperText: 'Number of round trips per day',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final trips = double.tryParse(value);
                      if (trips == null || trips <= 0) {
                        return 'Enter valid number of trips';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _peakMultiplierController,
                  decoration: const InputDecoration(
                    labelText: 'Peak Hours Multiplier',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                    helperText: 'Fare multiplier during peak hours (e.g., 1.5)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final multiplier = double.tryParse(value);
                      if (multiplier == null || multiplier < 1) {
                        return 'Enter valid multiplier (≥ 1.0)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Costs Section
                const Text(
                  'Operating Costs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _fuelCostController,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Cost per KM (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_gas_station),
                    helperText: 'Average fuel cost per kilometer',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final cost = double.tryParse(value);
                      if (cost == null || cost < 0) {
                        return 'Enter valid fuel cost';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _maintenanceCostController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Cost per Month (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                    helperText: 'Monthly vehicle maintenance cost',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final cost = double.tryParse(value);
                      if (cost == null || cost < 0) {
                        return 'Enter valid maintenance cost';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Commissions Section
                const Text(
                  'Staff Commissions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _driverCommissionController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Commission (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    helperText: 'Driver commission percentage from earnings',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final commission = double.tryParse(value);
                      if (commission == null || commission < 0 || commission > 100) {
                        return 'Enter valid percentage (0-100)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _conductorCommissionController,
                  decoration: const InputDecoration(
                    labelText: 'Conductor Commission (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: 'Conductor commission percentage from earnings',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final commission = double.tryParse(value);
                      if (commission == null || commission < 0 || commission > 100) {
                        return 'Enter valid percentage (0-100)';
                      }
                    }
                    return null;
                  },
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
          onPressed: _isLoading ? null : _saveFinancialData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _saveFinancialData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final financialData = {
        'avg_daily_trips': _dailyTripsController.text.isNotEmpty 
            ? double.parse(_dailyTripsController.text) 
            : null,
        'peak_hours_multiplier': _peakMultiplierController.text.isNotEmpty 
            ? double.parse(_peakMultiplierController.text) 
            : null,
        'fuel_cost_per_km': _fuelCostController.text.isNotEmpty 
            ? double.parse(_fuelCostController.text) 
            : null,
        'maintenance_cost_per_month': _maintenanceCostController.text.isNotEmpty 
            ? double.parse(_maintenanceCostController.text) 
            : null,
        'driver_commission_percentage': _driverCommissionController.text.isNotEmpty 
            ? double.parse(_driverCommissionController.text) 
            : null,
        'conductor_commission_percentage': _conductorCommissionController.text.isNotEmpty 
            ? double.parse(_conductorCommissionController.text) 
            : null,
      };

      widget.onSave(financialData);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving financial data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Dialog for viewing route earnings calculations
class _RouteEarningsDialog extends StatelessWidget {
  final Map<String, dynamic> route;
  final Map<String, dynamic> earningsData;

  const _RouteEarningsDialog({
    required this.route,
    required this.earningsData,
  });

  @override
  Widget build(BuildContext context) {
    final routeName = '${route['start_location']} → ${route['end_location']}';
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Route Earnings Calculation'),
          Text(
            routeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Earnings
              _buildEarningsSection(
                'Daily Earnings',
                [
                  _EarningItem('Gross Revenue', earningsData['daily_gross_revenue']),
                  _EarningItem('Operating Costs', earningsData['daily_operating_costs']),
                  _EarningItem('Staff Commissions', earningsData['daily_staff_commissions']),
                  _EarningItem('Net Profit', earningsData['daily_net_profit'], isProfit: true),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Earnings
              _buildEarningsSection(
                'Weekly Earnings',
                [
                  _EarningItem('Gross Revenue', earningsData['weekly_gross_revenue']),
                  _EarningItem('Operating Costs', earningsData['weekly_operating_costs']),
                  _EarningItem('Staff Commissions', earningsData['weekly_staff_commissions']),
                  _EarningItem('Net Profit', earningsData['weekly_net_profit'], isProfit: true),
                ],
              ),
              const SizedBox(height: 24),

              // Monthly Earnings
              _buildEarningsSection(
                'Monthly Earnings',
                [
                  _EarningItem('Gross Revenue', earningsData['monthly_gross_revenue']),
                  _EarningItem('Operating Costs', earningsData['monthly_operating_costs']),
                  _EarningItem('Staff Commissions', earningsData['monthly_staff_commissions']),
                  _EarningItem('Net Profit', earningsData['monthly_net_profit'], isProfit: true),
                ],
              ),
              const SizedBox(height: 24),

              // Breakdown Information
              if (earningsData['calculation_details'] != null)
                _buildCalculationDetails(earningsData['calculation_details']),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () => _exportEarningsData(context),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSection(String title, List<_EarningItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brown.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildEarningRow(item)),
        ],
      ),
    );
  }

  Widget _buildEarningRow(_EarningItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: item.isProfit ? AppColors.brown : AppColors.grey,
              fontWeight: item.isProfit ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            'KSh ${_formatCurrency(item.value)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: item.isProfit 
                  ? (item.value != null && item.value! >= 0 ? AppColors.green : Colors.red)
                  : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationDetails(Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculation Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          if (details['distance_km'] != null)
            Text('Route Distance: ${details['distance_km']} km'),
          
          if (details['fare'] != null)
            Text('Base Fare: KSh ${details['fare']}'),
          
          if (details['avg_daily_trips'] != null)
            Text('Average Daily Trips: ${details['avg_daily_trips']}'),
          
          if (details['peak_multiplier'] != null)
            Text('Peak Hours Multiplier: ${details['peak_multiplier']}x'),
          
          if (details['fuel_cost_per_km'] != null)
            Text('Fuel Cost per KM: KSh ${details['fuel_cost_per_km']}'),
          
          if (details['maintenance_cost_monthly'] != null)
            Text('Monthly Maintenance: KSh ${details['maintenance_cost_monthly']}'),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final double numValue = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
    return numValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _exportEarningsData(BuildContext context) {
    // TODO: Implement earnings data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.brown,
      ),
    );
  }
}

// Helper class for earnings items
class _EarningItem {
  final String label;
  final dynamic value;
  final bool isProfit;

  _EarningItem(this.label, this.value, {this.isProfit = false});
}