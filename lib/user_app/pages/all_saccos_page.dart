import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AllSaccosPage extends StatefulWidget {
  final List<dynamic> saccos;
  final Function(dynamic) onSaccoTap;

  const AllSaccosPage({
    super.key,
    required this.saccos,
    required this.onSaccoTap,
  });

  @override
  State<AllSaccosPage> createState() => _AllSaccosPageState();
}

class _AllSaccosPageState extends State<AllSaccosPage> {
  List<dynamic> _filteredSaccos = [];
  List<dynamic> _searchResults = [];
  String _sortBy = 'name'; // 'name', 'rating', 'vehicle_count'
  bool _sortAscending = true;
  String _selectedTab = 'all'; // 'all', 'search'
  List<String> _recentSearches = [];

  // Controllers for search dialogs - removed location search controller
  final TextEditingController _generalSearchController = TextEditingController();
  final TextEditingController _routeSearchController = TextEditingController();

  bool _isGeneralSearching = false;
  bool _isRouteSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredSaccos = List.from(widget.saccos);
    _applySorting();
  }

  @override
  void dispose() {
    _generalSearchController.dispose();
    _routeSearchController.dispose();
    super.dispose();
  }

  // Helper method to safely get numeric value
  int _safeGetInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is Map) {
      // If it's a map, try to get a count or length
      return value.length;
    }
    if (value is List) {
      return value.length;
    }
    return defaultValue;
  }

  // Helper method to safely get double value
  double _safeGetDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Helper method to safely get string value
  String _safeGetString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Helper method to calculate route count
  int _calculateRouteCount(dynamic sacco) {
    try {
      // First try to get total_routes directly
      final totalRoutes = sacco['total_routes'];
      if (totalRoutes != null && totalRoutes is int) {
        return totalRoutes;
      }

      // If that fails, calculate from routes array
      final routes = sacco['routes'];
      if (routes == null) return 0;
      
      if (routes is List) {
        int count = 0;
        for (final route in routes) {
          if (route is Map<String, dynamic> && route.containsKey('routes')) {
            final routeData = route['routes'];
            if (routeData is List) {
              count += routeData.length;
            }
          } else if (route is Map) {
            count += 1;
          }
        }
        return count;
      }
      
      return 0;
    } catch (e) {
      print('Error calculating route count: $e');
      return 0;
    }
  }

  void _applySorting() {
    final listToSort = _selectedTab == 'search' ? _searchResults : _filteredSaccos;
    
    listToSort.sort((a, b) {
      dynamic aValue, bValue;
      
      try {
        switch (_sortBy) {
          case 'rating':
            final aOwnerRating = _safeGetDouble(a['avg_owner_rating']);
            final aPassengerRating = _safeGetDouble(a['avg_passenger_rating']);
            aValue = aOwnerRating > 0 || aPassengerRating > 0 
                ? (aOwnerRating + aPassengerRating) / 2 
                : 0.0;
                
            final bOwnerRating = _safeGetDouble(b['avg_owner_rating']);
            final bPassengerRating = _safeGetDouble(b['avg_passenger_rating']);
            bValue = bOwnerRating > 0 || bPassengerRating > 0 
                ? (bOwnerRating + bPassengerRating) / 2 
                : 0.0;
            break;
          case 'vehicle_count':
            aValue = _calculateRouteCount(a);
            bValue = _calculateRouteCount(b);
            break;
          case 'name':
          default:
            aValue = _safeGetString(a['name']).toLowerCase();
            bValue = _safeGetString(b['name']).toLowerCase();
            break;
        }
        
        int comparison;
        if (aValue is String && bValue is String) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }
        
        return _sortAscending ? comparison : -comparison;
      } catch (e) {
        print('Error in sorting: $e');
        // Fallback to name sorting if there's an error
        final aName = _safeGetString(a['name']).toLowerCase();
        final bName = _safeGetString(b['name']).toLowerCase();
        return _sortAscending ? aName.compareTo(bName) : bName.compareTo(aName);
      }
    });
  }

  Future<void> _performGeneralSearch() async {
    if (_generalSearchController.text.isEmpty) {
      _showErrorSnackBar('Please enter a search term');
      return;
    }

    setState(() => _isGeneralSearching = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate search delay
      
      final query = _generalSearchController.text.toLowerCase();
      final results = widget.saccos.where((sacco) {
        final name = _safeGetString(sacco['name']).toLowerCase();
        final location = _safeGetString(sacco['location']).toLowerCase();
        final email = _safeGetString(sacco['email']).toLowerCase();
        final contact = _safeGetString(sacco['contact_number']).toLowerCase();
        
        return name.contains(query) || 
               location.contains(query) || 
               email.contains(query) || 
               contact.contains(query);
      }).toList();

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, _generalSearchController.text);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }

      setState(() {
        _searchResults = results;
        _selectedTab = 'search';
      });
      
      _applySorting();
      Navigator.pop(context); // Close the dialog
    } catch (e) {
      _showErrorSnackBar('Search failed: $e');
    } finally {
      setState(() => _isGeneralSearching = false);
    }
  }

  Future<void> _performRouteSearch() async {
    if (_routeSearchController.text.isEmpty) {
      _showErrorSnackBar('Please enter a route to search');
      return;
    }

    setState(() => _isRouteSearching = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final query = _routeSearchController.text.toLowerCase();
      final results = widget.saccos.where((sacco) {
        try {
          final routes = sacco['routes'];
          String routesText = '';
          
          if (routes is List && routes.isNotEmpty) {
            final routeStrings = <String>[];
            for (final route in routes) {
              if (route is Map<String, dynamic> && route.containsKey('routes')) {
                final routeData = route['routes'];
                if (routeData is List) {
                  for (final r in routeData) {
                    if (r is Map) {
                      final startLocation = _safeGetString(r['start_location']);
                      final endLocation = _safeGetString(r['end_location']);
                      if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
                        routeStrings.add('$startLocation - $endLocation');
                      }
                    }
                  }
                }
              }
            }
            routesText = routeStrings.join(' ').toLowerCase();
          }
          
          return routesText.contains(query);
        } catch (e) {
          print('Error searching routes for sacco: $e');
          return false;
        }
      }).toList();

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, _routeSearchController.text);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }

      setState(() {
        _searchResults = results;
        _selectedTab = 'search';
      });
      
      _applySorting();
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Route search failed: $e');
    } finally {
      setState(() => _isRouteSearching = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showGeneralSearchDialog() {
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
                  controller: _generalSearchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name, location, contact...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.brown),
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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: AppColors.grey),
                      title: Text(search, style: AppTextStyles.body2),
                      onTap: () {
                        _generalSearchController.text = search;
                      },
                    );
                  })),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGeneralSearching ? null : _performGeneralSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brown,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGeneralSearching
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
                      'Search by Route',
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
                  controller: _routeSearchController,
                  decoration: InputDecoration(
                    labelText: 'Route (e.g., Nairobi-Nakuru, CBD-Westlands)',
                    prefixIcon: const Icon(Icons.route, color: AppColors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Search Tips:',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Search for routes like "Nairobi-Nakuru"\n• Try partial matches like "CBD" or "Westlands"\n• Search for route numbers like "Route 46"',
                        style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                      ),
                    ],
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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: AppColors.grey),
                      title: Text(search, style: AppTextStyles.body2),
                      onTap: () {
                        _routeSearchController.text = search;
                      },
                    );
                  })),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRouteSearching ? null : _performRouteSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sort Saccos',
            style: AppTextStyles.heading3.copyWith(color: AppColors.brown),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Name'),
                leading: Radio<String>(
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  activeColor: AppColors.brown,
                ),
              ),
              ListTile(
                title: const Text('Rating'),
                leading: Radio<String>(
                  value: 'rating',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  activeColor: AppColors.brown,
                ),
              ),
              ListTile(
                title: const Text('Vehicle Count'),
                leading: Radio<String>(
                  value: 'vehicle_count',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  activeColor: AppColors.brown,
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Ascending Order'),
                value: _sortAscending,
                onChanged: (value) {
                  setState(() {
                    _sortAscending = value;
                  });
                },
                activeColor: AppColors.brown,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _applySorting();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTab == 'search' ? _searchResults : _filteredSaccos;
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'All Saccos (${currentList.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort Saccos',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _filteredSaccos = List.from(widget.saccos);
            _searchResults.clear();
            _selectedTab = 'all';
            _applySorting();
          });
        },
        color: AppColors.brown,
        child: CustomScrollView(
          slivers: [
            // Search Actions Section - now scrollable
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
                      'Search Saccos',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 16),
                    // Only General Search and Route Search - removed Location Search
                    Row(
                      children: [
                        Expanded(
                          child: _buildSearchCard(
                            'General Search',
                            'Search by name, location, contact',
                            Icons.search,
                            AppColors.brown,
                            _showGeneralSearchDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSearchCard(
                            'Route Search',
                            'Find saccos by specific routes',
                            Icons.route,
                            AppColors.orange,
                            _showRouteSearchDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Navigation
            if (_searchResults.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('All Saccos', 'all'),
                      _buildTabButton('Search Results', 'search'),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],

            // Saccos List
            currentList.isEmpty
                ? SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sacco = currentList[index];
                          return _buildSaccoCard(sacco, index);
                        },
                        childCount: currentList.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
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
    return Expanded(
      child: InkWell(
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.brown,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 'search' ? Icons.search_off : Icons.business,
              size: 64,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _selectedTab == 'search' 
                ? 'No Search Results'
                : 'No Saccos Available',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              _selectedTab == 'search'
                ? 'No saccos match your search criteria. Try different search terms.'
                : 'There are currently no saccos available. Check back later for new opportunities.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedTab == 'search') ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchResults.clear();
                    _selectedTab = 'all';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Back to All Saccos'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaccoCard(dynamic sacco, int index) {
    try {
      final name = _safeGetString(sacco['name'], defaultValue: 'Unknown Sacco');
      final location = _safeGetString(sacco['location'], defaultValue: 'Unknown Location');
      final email = _safeGetString(sacco['email']);
      final contact = _safeGetString(sacco['contact_number']);
      
      // Handle routes with improved safety
      String routesText = '';
      final routes = sacco['routes'];
      final totalRoutes = _calculateRouteCount(sacco);
      
      if (routes is List && routes.isNotEmpty) {
        final routeStrings = <String>[];
        for (final route in routes) {
          try {
            if (route is Map<String, dynamic> && route.containsKey('routes')) {
              final routeData = route['routes'];
              if (routeData is List) {
                for (final r in routeData) {
                  if (r is Map) {
                    final startLocation = _safeGetString(r['start_location']);
                    final endLocation = _safeGetString(r['end_location']);
                    if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
                      routeStrings.add('$startLocation - $endLocation');
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('Error processing route: $e');
            continue;
          }
        }
        routesText = routeStrings.join(', ');
      }

      // Calculate average rating with improved safety
      final ownerRating = _safeGetDouble(sacco['avg_owner_rating']);
      final passengerRating = _safeGetDouble(sacco['avg_passenger_rating']);
      final avgRating = ownerRating > 0 || passengerRating > 0 
          ? (ownerRating + passengerRating) / 2 
          : 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.3)),
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
            try {
              widget.onSaccoTap(sacco);
            } catch (e) {
              print('Error on sacco tap: $e');
              _showErrorSnackBar('Error opening sacco details');
            }
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
                              name,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                    location,
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (avgRating > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Contact Information
                  if (contact.isNotEmpty || email.isNotEmpty) ...[
                    Row(
                      children: [
                        if (contact.isNotEmpty) ...[
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: AppColors.brown,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contact,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brown,
                            ),
                          ),
                        ],
                        if (contact.isNotEmpty && email.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 12,
                            color: AppColors.lightGrey,
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (email.isNotEmpty) ...[
                          Icon(
                            Icons.email,
                            size: 16,
                            color: AppColors.brown,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brown,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Routes Information
                  if (routesText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 16,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Routes ($totalRoutes)',
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routesText,
                            style: AppTextStyles.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No route information available',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  
                  // Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (totalRoutes > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalRoutes ${totalRoutes == 1 ? 'Route' : 'Routes'}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.brown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.brown,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error building sacco card: $e');
        // Return a simple error card if there's an issue
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error loading sacco data',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
}