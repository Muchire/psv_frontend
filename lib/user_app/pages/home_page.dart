import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'sacco_detail_page.dart';
import 'profile_page.dart';
import 'route_detail_page.dart';

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
  String _selectedTab = 'saccos';
  List<String> _recentSearches = [];

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
      
      // Add to recent searches
      final searchQuery = '${_fromController.text} → ${_toController.text}';
      if (!_recentSearches.contains(searchQuery)) {
        setState(() {
          _recentSearches.insert(0, searchQuery);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
      
      setState(() {
        _searchResults = results;
        _selectedTab = 'search';
      });
      Navigator.pop(context); // Close the popup
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
      final results = await _searchSaccosLocal(_saccoSearchController.text);
      
      setState(() {
        _saccoSearchResults = results;
        _selectedTab = 'sacco_search';
      });
      Navigator.pop(context); // Close the popup
    } catch (e) {
      _showErrorSnackBar('Sacco search failed: $e');
    } finally {
      setState(() => _isSaccoSearching = false);
    }
  }

  Future<List<dynamic>> _searchSaccosLocal(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
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

  void _showRouteSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Routes',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'From',
                    prefixIcon: const Icon(Icons.location_on, color: AppColors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'To',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Recent Searches',
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(_recentSearches.take(3).map((search) {
                    final parts = search.split(' → ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: AppColors.grey),
                      title: Text(search, style: AppTextStyles.body2),
                      onTap: () {
                        _fromController.text = parts[0];
                        _toController.text = parts[1];
                      },
                    );
                  })),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRouteSearching ? null : _searchRoutes,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isRouteSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Text('Search Routes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaccoSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Saccos',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _saccoSearchController,
                  decoration: InputDecoration(
                    labelText: 'Sacco Name',
                    prefixIcon: const Icon(Icons.search, color: AppColors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaccoSearching ? null : _searchSaccos,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaccoSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Text('Search Saccos'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('PSV Finder',style: AppTextStyles.heading1),
        shadowColor: AppColors.brown,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.brown),
        elevation: 0,
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            color: AppColors.brown,
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
          // Search Actions Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Search',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchCard(
                        'Search Routes',
                        'Find routes between locations',
                        Icons.route,
                        _showRouteSearchDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSearchCard(
                        'Search Saccos',
                        'Find specific Sacco companies',
                        Icons.business,
                        _showSaccoSearchDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('All Saccos', 'saccos'),
                  _buildTabButton('All Routes', 'routes'),
                  if (_searchResults.isNotEmpty)
                    _buildTabButton('Route Results', 'search'),
                  if (_saccoSearchResults.isNotEmpty)
                    _buildTabButton('Sacco Results', 'sacco_search'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.brown,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 20,
        ),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
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
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      itemCount: saccos.length,
      itemBuilder: (context, index) {
        final sacco = saccos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.brown,
              radius: 24,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_city, size: 16, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(sacco['location'] ?? 'Location', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.brown),
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
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteDetailPage(
                    routeId: route['id'],
                    routeName: '${route['start_location']} → ${route['end_location']}',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'KES ${route['fare']}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route['duration']} hrs',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (route['description'] != null && route['description'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      route['description'],
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
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