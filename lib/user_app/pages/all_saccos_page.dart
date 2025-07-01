import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';
import 'vehicle_sacco_detail_page.dart';
import 'profile_page.dart';

class VehicleOwnerHomePage extends StatefulWidget {
  const VehicleOwnerHomePage({super.key});

  @override
  State<VehicleOwnerHomePage> createState() => _VehicleOwnerHomePageState();
}

class _VehicleOwnerHomePageState extends State<VehicleOwnerHomePage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _saccoSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _saccos = [];
  List<dynamic> _routes = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _saccoSearchResults = [];
  bool _isLoading = false;
  bool _isRouteSearching = false;
  bool _isSaccoSearching = false;
  String _selectedTab = 'saccos';
  List<String> _recentSearches = [];
  bool _showSearchSection = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _saccoSearchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && _showSearchSection) {
      setState(() {
        _showSearchSection = false;
      });
    } else if (_scrollController.offset <= 100 && !_showSearchSection) {
      setState(() {
        _showSearchSection = true;
      });
    }
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
      Navigator.pop(context);
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
      Navigator.pop(context);
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

  // Fixed navigation method with better error handling and null safety
  void _navigateToSaccoFromRoute(Map<String, dynamic> route) {
    try {
      int? saccoId;
      
      // Try multiple ways to extract sacco_id with proper null safety
      if (route.containsKey('sacco_id') && route['sacco_id'] != null) {
        final saccoIdValue = route['sacco_id'];
        if (saccoIdValue is int) {
          saccoId = saccoIdValue;
        } else if (saccoIdValue is String) {
          saccoId = int.tryParse(saccoIdValue);
        } else {
          saccoId = int.tryParse(saccoIdValue.toString());
        }
      } 
      
      // Try nested sacco object
      if (saccoId == null && route.containsKey('sacco') && route['sacco'] != null) {
        final saccoData = route['sacco'];
        if (saccoData is Map<String, dynamic>) {
          if (saccoData.containsKey('id') && saccoData['id'] != null) {
            final saccoIdValue = saccoData['id'];
            if (saccoIdValue is int) {
              saccoId = saccoIdValue;
            } else {
              saccoId = int.tryParse(saccoIdValue.toString());
            }
          }
        }
      }
      
      // Try to find sacco by name if ID is still not available
      if (saccoId == null) {
        String? saccoName;
        
        // Try different possible field names for sacco name
        if (route.containsKey('sacco_name') && route['sacco_name'] != null) {
          saccoName = route['sacco_name'].toString();
        } else if (route.containsKey('sacco') && route['sacco'] != null) {
          final saccoData = route['sacco'];
          if (saccoData is Map<String, dynamic> && saccoData.containsKey('name')) {
            saccoName = saccoData['name']?.toString();
          } else if (saccoData is String) {
            saccoName = saccoData;
          }
        } else if (route.containsKey('operator') && route['operator'] != null) {
          saccoName = route['operator'].toString();
        }
        
        if (saccoName != null && saccoName.isNotEmpty) {
          final matchingSacco = _saccos.cast<Map<String, dynamic>>().firstWhere(
            (sacco) {
              final name = sacco['name']?.toString().toLowerCase() ?? '';
              return name == saccoName!.toLowerCase();
            },
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingSacco.isNotEmpty && matchingSacco['id'] != null) {
            final saccoIdValue = matchingSacco['id'];
            if (saccoIdValue is int) {
              saccoId = saccoIdValue;
            } else {
              saccoId = int.tryParse(saccoIdValue.toString());
            }
          }
        }
      }

      if (saccoId != null && saccoId > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleSaccoDetailPage(saccoId: saccoId!),
          ),
        );
      } else {
        final routeName = '${route['start_location'] ?? route['from'] ?? 'Unknown'} → ${route['end_location'] ?? route['to'] ?? 'Unknown'}';
        _showErrorSnackBar('Cannot find Sacco details for route: $routeName');
        debugPrint('Route data: ${route.toString()}');
        debugPrint('Available saccos: ${_saccos.map((s) => {'id': s['id'], 'name': s['name']}).toList()}');
      }
    } catch (e) {
      _showErrorSnackBar('Error navigating to Sacco: $e');
      debugPrint('Navigation error: $e');
      debugPrint('Route data: ${route.toString()}');
    }
  }

  String _formatCurrency(String amount) {
    try {
      final double value = double.parse(amount.replaceAll(',', ''));
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    } catch (e) {
      return amount;
    }
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: const Text('Saccos', style: AppTextStyles.heading1),
            shadowColor: AppColors.brown,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.brown),
            elevation: 0,
            backgroundColor: AppColors.white,
            floating: true,
            snap: true,
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
          
          // Search Actions Section (collapsible)
          if (_showSearchSection)
            SliverToBoxAdapter(
              child: Container(
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
                      'Find Sacco Opportunities',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search for Saccos to join or explore profitable routes',
                      style: AppTextStyles.body2.copyWith(color: AppColors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSearchCard(
                            'Search Routes',
                            'Find profitable routes for your vehicle',
                            Icons.route,
                            _showRouteSearchDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSearchCard(
                            'Search Saccos',
                            'Find Sacco companies to join',
                            Icons.business,
                            _showSaccoSearchDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Tab Navigation (sticky) - Fixed overflow issue
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 60,
              child: Container(
                color: AppColors.white,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _buildTabButton('Available Saccos', 'saccos'),
                        _buildTabButton('All Routes', 'routes'),
                        if (_searchResults.isNotEmpty)
                          _buildTabButton('Route Results', 'search'),
                        if (_saccoSearchResults.isNotEmpty)
                          _buildTabButton('Sacco Results', 'sacco_search'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _buildSliverContent(),
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
          border: Border.all(color: AppColors.grey),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brown : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.brown,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent() {
    switch (_selectedTab) {
      case 'saccos':
        return _buildSliverSaccosList(_saccos);
      case 'routes':
        return _buildSliverRoutesList(_routes);
      case 'search':
        return _buildSliverRoutesList(_searchResults);
      case 'sacco_search':
        return _buildSliverSaccosList(_saccoSearchResults);
      default:
        return _buildSliverSaccosList(_saccos);
    }
  }

  Widget _buildSliverSaccosList(List<dynamic> saccos) {
    if (saccos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
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
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final sacco = saccos[index];
          final saccoMap = sacco as Map<String, dynamic>;
          
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                final saccoId = saccoMap['id'];
                if (saccoId != null) {
                  final id = saccoId is int ? saccoId : int.tryParse(saccoId.toString());
                  if (id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleSaccoDetailPage(saccoId: id),
                      ),
                    );
                  } else {
                    _showErrorSnackBar('Invalid Sacco ID');
                  }
                } else {
                  _showErrorSnackBar('Sacco ID not found');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Sacco Avatar
                    CircleAvatar(
                      backgroundColor: AppColors.brown,
                      radius: 28,
                      child: Text(
                        (saccoMap['name']?.toString() ?? 'S').substring(0, 1).toUpperCase(),
                        style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Sacco Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sacco Name
                          Text(
                            saccoMap['name']?.toString() ?? 'Unknown Sacco',
                            style: AppTextStyles.heading3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  saccoMap['location']?.toString() ?? 'Location not specified',
                                  style: AppTextStyles.body2.copyWith(color: AppColors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Join Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brown,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Join',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: saccos.length,
      ),
    );
  }

  Widget _buildSliverRoutesList(List<dynamic> routes) {
    if (routes.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
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
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final route = routes[index];
          final routeMap = route as Map<String, dynamic>;
          
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _navigateToSaccoFromRoute(routeMap),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route header with locations
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.route,
                            color: AppColors.brown,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: AppColors.brown),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      routeMap['start_location']?.toString() ?? 
                                      routeMap['from']?.toString() ?? 'Unknown',
                                      style: AppTextStyles.body2.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      routeMap['end_location']?.toString() ?? 
                                      routeMap['to']?.toString() ?? 'Unknown',
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppColors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Fare info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KSh ${_formatCurrency(routeMap['fare']?.toString() ?? '0')}',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brown,
                              ),
                            ),
                            Text(
                              'per trip',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Route details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Sacco info
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 16,
                                  color: AppColors.brown,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    routeMap['sacco_name']?.toString() ?? 
                                    routeMap['sacco']?['name']?.toString() ??
                                    routeMap['operator']?.toString() ?? 'Unknown Sacco',
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Distance info
                          if (routeMap['distance'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: AppColors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${routeMap['distance']} km',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          
                          // Duration info
                          if (routeMap['duration'] != null)
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  routeMap['duration'].toString(),
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _navigateToSaccoFromRoute(routeMap),
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.brown,
                          ),
                          label: Text(
                            'View Sacco',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.brown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: routes.length,
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for tab navigation
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}