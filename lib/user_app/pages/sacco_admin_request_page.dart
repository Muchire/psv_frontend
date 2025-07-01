import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psv_frontend/services/sacco_admin_service.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';

class SaccoAdminRequestPage extends StatefulWidget {
  const SaccoAdminRequestPage({super.key});

  @override
  State<SaccoAdminRequestPage> createState() => _SaccoAdminRequestPageState();
}

class _SaccoAdminRequestPageState extends State<SaccoAdminRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  
  int? selectedSaccoId;
  List<dynamic> saccos = [];
  bool isLoading = false;
  bool enteringNewSacco = false;

  // New sacco form controllers
  final _saccoName = TextEditingController();
  final _location = TextEditingController();
  final _dateEstablished = TextEditingController();
  final _regNumber = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();

  // Financial metrics controllers - Updated to match service field names
  final Map<String, TextEditingController> _financialControllers = {
    'avg_monthly_revenue_per_vehicle': TextEditingController(),
    'operational_costs': TextEditingController(),
    'net_profit_margin': TextEditingController(),
    'owner_average_profit': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    fetchSaccos();
  }

  @override
  void dispose() {
    _saccoName.dispose();
    _location.dispose();
    _dateEstablished.dispose();
    _regNumber.dispose();
    _contact.dispose();
    _email.dispose();
    _website.dispose();
    _financialControllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchSaccos() async {
    try {
      final result = await ApiService.getSaccos();
      setState(() {
        saccos = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch saccos: $e')),
      );
    }
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Submit the SACCO admin request
      final response = await ApiService.submitSaccoAdminRequest(
        saccoId: enteringNewSacco ? null : selectedSaccoId,
        saccoName: enteringNewSacco ? _saccoName.text.trim() : null,
        location: enteringNewSacco ? _location.text.trim() : null,
        dateEstablished: enteringNewSacco ? _dateEstablished.text.trim() : null,
        registrationNumber: enteringNewSacco ? _regNumber.text.trim() : null,
        contactNumber: enteringNewSacco ? _contact.text.trim() : null,
        email: enteringNewSacco ? _email.text.trim() : null,
        website: enteringNewSacco ? _website.text.trim() : null,
      );

      // If creating a new SACCO and financial metrics are provided, save them
      if (enteringNewSacco && _hasFinancialData()) {
        try {
          // Get the new SACCO ID from response
          int newSaccoId = response['sacco_id'] ?? response['id'];
          await _saveFinancialMetrics(newSaccoId);
        } catch (financialError) {
          // Don't fail the entire request if financial metrics fail
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('SACCO created successfully, but failed to save financial metrics: $financialError'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _hasFinancialData() {
    return _financialControllers.values.any((controller) => controller.text.isNotEmpty);
  }

  Future<void> _saveFinancialMetrics(int saccoId) async {
    // Prepare financial metrics data with correct field names
    double? avgRevenuePerVehicle;
    double? operationalCosts;
    double? netProfitMargin;
    double? ownerAverageProfit;

    final avgRevenueText = _financialControllers['avg_monthly_revenue_per_vehicle']?.text;
    if (avgRevenueText != null && avgRevenueText.isNotEmpty) {
      avgRevenuePerVehicle = double.tryParse(avgRevenueText);
    }

    final operationalCostsText = _financialControllers['operational_costs']?.text;
    if (operationalCostsText != null && operationalCostsText.isNotEmpty) {
      operationalCosts = double.tryParse(operationalCostsText);
    }

    final netProfitMarginText = _financialControllers['net_profit_margin']?.text;
    if (netProfitMarginText != null && netProfitMarginText.isNotEmpty) {
      netProfitMargin = double.tryParse(netProfitMarginText);
    }

    final ownerAvgProfitText = _financialControllers['owner_average_profit']?.text;
    if (ownerAvgProfitText != null && ownerAvgProfitText.isNotEmpty) {
      ownerAverageProfit = double.tryParse(ownerAvgProfitText);
    }

    // Only call the service if at least one metric is provided
    if (avgRevenuePerVehicle != null || 
        operationalCosts != null || 
        netProfitMargin != null || 
        ownerAverageProfit != null) {
      
      await SaccoAdminService.updateSaccoFinancialMetrics(
        saccoId,
        avgRevenuePerVehicle: avgRevenuePerVehicle,
        operationalCosts: operationalCosts,
        netProfitMargin: netProfitMargin,
        ownerAverageProfit: ownerAverageProfit,
      );
    }
  }

  String _getDisplayName(String fieldName) {
    switch (fieldName) {
      case 'avg_monthly_revenue_per_vehicle':
        return 'Average Monthly Revenue per Vehicle';
      case 'operational_costs':
        return 'Operational Costs';
      case 'net_profit_margin':
        return 'Net Profit Margin';
      case 'owner_average_profit':
        return 'Owner Average Profit';
      default:
        return fieldName;
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Admin Access"),
        backgroundColor: AppColors.carafe,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: _buildProgressIndicator(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _buildSaccoSelectionPage(),
            if (enteringNewSacco) _buildSaccoDetailsPage(),
            if (enteringNewSacco) _buildFinancialMetricsPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildProgressIndicator() {
    int totalPages = enteringNewSacco ? 3 : 1;
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: List.generate(totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentPage ? AppColors.carafe : AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSaccoSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SACCO Selection',
            style: AppTextStyles.heading2.copyWith(color: AppColors.carafe),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Choose whether to join an existing SACCO or register a new one.',
            style: AppTextStyles.body1.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          
          Card(
            elevation: 2,
            child: SwitchListTile(
              title: const Text("Register a new SACCO"),
              subtitle: const Text("Create and manage a new SACCO"),
              value: enteringNewSacco,
              activeColor: AppColors.carafe,
              onChanged: (val) {
                setState(() {
                  enteringNewSacco = val;
                  _currentPage = 0;
                });
                if (val) {
                  _nextPage();
                }
              },
            ),
          ),

          if (!enteringNewSacco) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Existing SACCO',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    DropdownButtonFormField<int>(
                      value: selectedSaccoId,
                      items: saccos.map<DropdownMenuItem<int>>((sacco) {
                        return DropdownMenuItem<int>(
                          value: sacco['id'],
                          child: Text(sacco['name']),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: "Select SACCO",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => selectedSaccoId = value),
                      validator: (value) =>
                          value == null ? "Please select a sacco" : null,
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

  Widget _buildSaccoDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: ListView(
        children: [
          Text(
            'SACCO Details',
            style: AppTextStyles.heading2.copyWith(color: AppColors.carafe),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Enter the basic information for your new SACCO.',
            style: AppTextStyles.body1.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                children: [
                  TextFormField(
                    controller: _saccoName,
                    decoration: const InputDecoration(
                      labelText: 'SACCO Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _dateEstablished,
                    decoration: const InputDecoration(
                      labelText: 'Date Established (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _regNumber,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _contact,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty ? "Required field" : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextFormField(
                    controller: _website,
                    decoration: const InputDecoration(
                      labelText: 'Website (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.web),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: ListView(
        children: [
          Text(
            'Financial Metrics',
            style: AppTextStyles.heading2.copyWith(color: AppColors.carafe),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Set up financial metrics to help vehicle owners understand earning potential (Optional).',
            style: AppTextStyles.body1.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                children: [
                  _buildFinancialMetricInput(
                    _financialControllers['avg_monthly_revenue_per_vehicle']!,
                    'Average Monthly Revenue per Vehicle',
                    'Monthly revenue per vehicle',
                    'KSh ',
                    Icons.monetization_on,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildFinancialMetricInput(
                    _financialControllers['operational_costs']!,
                    'Operational Costs',
                    'Monthly operational costs per vehicle',
                    'KSh ',
                    Icons.trending_down,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildFinancialMetricInput(
                    _financialControllers['net_profit_margin']!,
                    'Net Profit Margin',
                    'Profit margin percentage',
                    '',
                    Icons.show_chart,
                    '%',
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildFinancialMetricInput(
                    _financialControllers['owner_average_profit']!,
                    'Owner Average Profit',
                    'Average monthly profit for vehicle owners',
                    'KSh ',
                    Icons.business,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricInput(
    TextEditingController controller,
    String label,
    String hint,
    String prefix,
    IconData icon, [
    String suffix = '',
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.carafe, size: 20),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.carafe, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            OutlinedButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.carafe,
                side: BorderSide(color: AppColors.carafe),
              ),
            )
          else
            const SizedBox(),
          
          if (_currentPage < (enteringNewSacco ? 2 : 0))
            ElevatedButton.icon(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.carafe,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isLoading ? null : submitRequest,
              icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send),
              label: Text(isLoading ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.carafe,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}