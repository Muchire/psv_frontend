import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'sacco_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _saccoSearchController = TextEditingController();
  
  List<dynamic> _saccos = [];
  List<dynamic> _routes = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _saccoSearchResults = [];
  bool _isLoading = false;
  bool _isRouteSearching = false;
  bool _isSaccoSearching = false;
  String _selectedTab = 'saccos'; // 'saccos', 'routes', 'search', 'sacco_search'
  String _searchMode = 'routes'; // 'routes' or 'saccos'

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final saccos = await ApiService.getSaccos();
      final routes = await ApiService.getRoutes();
      setState(() {
        _saccos = saccos;
        _routes = routes;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchRoutes() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      _showErrorSnackBar('Please enter both origin and destination');
      return;
    }

    setState(() => _isRouteSearching = true);
    try {
      final results = await ApiService.searchRoutes(
        from: _fromController.text,
        to: _toController.text,
      );
      setState(() {
        _searchResults = results;
        _selectedTab = 'search';
      });
    } catch (e) {
      _showErrorSnackBar('Route search failed: $e');
    } finally {
      setState(() => _isRouteSearching = false);
    }
  }

  Future<void> _searchSaccos() async {
    if (_saccoSearchController.text.isEmpty) {
      _showErrorSnackBar('Please enter a Sacco name to search');
      return;
    }

    setState(() => _isSaccoSearching = true);
    try {
      // If your API service doesn't have a searchSaccos method, you can filter locally
      // or add this method to your API service
      final results = await _searchSaccosLocal(_saccoSearchController.text);
      
      setState(() {
        _saccoSearchResults = results;
        _selectedTab = 'sacco_search';
      });
    } catch (e) {
      _showErrorSnackBar('Sacco search failed: $e');
    } finally {
      setState(() => _isSaccoSearching = false);
    }
  }

  // Local search function - replace with API call if available
  Future<List<dynamic>> _searchSaccosLocal(String query) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    return _saccos.where((sacco) {
      final name = (sacco['name'] ?? '').toLowerCase();
      final description = (sacco['description'] ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || description.contains(searchQuery);
    }).toList();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      if (_searchMode == 'routes') {
        _fromController.clear();
        _toController.clear();
        _searchResults.clear();
      } else {
        _saccoSearchController.clear();
        _saccoSearchResults.clear();
      }
      _selectedTab = _searchMode == 'routes' ? 'routes' : 'saccos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Mode Toggle
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchModeButton('Search Routes', 'routes'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSearchModeButton('Search Saccos', 'saccos'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Search Fields
                if (_searchMode == 'routes') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromController,
                          decoration: const InputDecoration(
                            hintText: 'From',
                            prefixIcon: Icon(Icons.location_on, color: AppColors.brown),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Expanded(
                        child: TextField(
                          controller: _toController,
                          decoration: const InputDecoration(
                            hintText: 'To',
                            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.brown),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _saccoSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Sacco name...',
                      prefixIcon: Icon(Icons.search, color: AppColors.brown),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDimensions.paddingMedium),
                
                // Search Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _searchMode == 'routes'
                            ? (_isRouteSearching ? null : _searchRoutes)
                            : (_isSaccoSearching ? null : _searchSaccos),
                        child: _searchMode == 'routes'
                            ? (_isRouteSearching
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Text('Search Routes'))
                            : (_isSaccoSearching
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Text('Search Saccos')),
                      ),
                    ),
                    if ((_searchMode == 'routes' && (_searchResults.isNotEmpty || _fromController.text.isNotEmpty || _toController.text.isNotEmpty)) ||
                        (_searchMode == 'saccos' && (_saccoSearchResults.isNotEmpty || _saccoSearchController.text.isNotEmpty))) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _clearSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Navigation
          Container(
            color: AppColors.lightGrey,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('Saccos', 'saccos'),
                  _buildTabButton('All Routes', 'routes'),
                  if (_searchResults.isNotEmpty)
                    _buildTabButton('Route Results', 'search'),
                  if (_saccoSearchResults.isNotEmpty)
                    _buildTabButton('Sacco Results', 'sacco_search'),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeButton(String title, String mode) {
    final isSelected = _searchMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _searchMode = mode;
          // Clear previous search results when switching modes
          if (mode == 'routes') {
            _saccoSearchResults.clear();
            if (_selectedTab == 'sacco_search') {
              _selectedTab = 'routes';
            }
          } else {
            _searchResults.clear();
            if (_selectedTab == 'search') {
              _selectedTab = 'saccos';
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brown : AppColors.grey,
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.brown,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingMedium,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.brown : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.brown,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 'saccos':
        return _buildSaccosList(_saccos);
      case 'routes':
        return _buildRoutesList(_routes);
      case 'search':
        return _buildRoutesList(_searchResults);
      case 'sacco_search':
        return _buildSaccosList(_saccoSearchResults);
      default:
        return _buildSaccosList(_saccos);
    }
  }

  Widget _buildSaccosList(List<dynamic> saccos) {
    if (saccos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _selectedTab == 'sacco_search' ? 'No saccos found' : 'No saccos available',
              style: AppTextStyles.body1,
            ),
            if (_selectedTab == 'sacco_search')
              Text(
                'Try a different search term',
                style: AppTextStyles.caption,
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: saccos.length,
      itemBuilder: (context, index) {
        final sacco = saccos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.tan,
              child: Text(
                sacco['name']?.substring(0, 1).toUpperCase() ?? 'S',
                style: AppTextStyles.heading3.copyWith(color: AppColors.carafe),
              ),
            ),
            title: Text(
              sacco['name'] ?? 'Unknown Sacco',
              style: AppTextStyles.heading3,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sacco['description'] ?? 'No description available',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(sacco['contact_phone'] ?? 'No phone', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.brown),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SaccoDetailPage(saccoId: sacco['id']),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoutesList(List<dynamic> routes) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _selectedTab == 'search' ? 'No routes found' : 'No routes available',
              style: AppTextStyles.body1,
            ),
            if (_selectedTab == 'search')
              Text(
                'Try different locations',
                style: AppTextStyles.caption,
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${route['start_location']} → ${route['end_location']}',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sacco: ${route['sacco_name'] ?? 'Unknown'}',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KES ${route['fare']}',
                          style: AppTextStyles.heading3.copyWith(color: AppColors.success),
                        ),
                        Text(
                          '${route['duration']} mins',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                if (route['description'] != null && route['description'].isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    route['description'],
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _saccoSearchController.dispose();
    super.dispose();
  }
}