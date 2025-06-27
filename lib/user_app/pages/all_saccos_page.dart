import 'package:flutter/material.dart';
import '../utils/constants.dart';
// import '../widgets/loading_widget.dart';
// import '../widgets/error_widget.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'route', 'sacco', 'location'
  bool _showRouteSearch = false;
  String _sortBy = 'name'; // 'name', 'rating', 'vehicle_count'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _filteredSaccos = List.from(widget.saccos);
    _searchController.addListener(_onSearchChanged);
    _applySorting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterAndSortSaccos();
    });
  }

  // Replace your _filterAndSortSaccos method with this updated version
  void _filterAndSortSaccos() {
    // First filter
    if (_searchQuery.isEmpty) {
      _filteredSaccos = List.from(widget.saccos);
    } else {
      _filteredSaccos = widget.saccos.where((sacco) {
        final name = (sacco['name']?.toString() ?? '').toLowerCase();
        final location = (sacco['location']?.toString() ?? '').toLowerCase();
        
        // Handle routes - extract route strings from your nested structure
        String routesText = '';
        final routes = sacco['routes'] as List<dynamic>? ?? [];
        if (routes.isNotEmpty) {
          final routeStrings = <String>[];
          for (final route in routes) {
            final routeData = route['routes'] as List<dynamic>? ?? [];
            for (final r in routeData) {
              final startLocation = r['start_location']?.toString() ?? '';
              final endLocation = r['end_location']?.toString() ?? '';
              if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
                routeStrings.add('$startLocation - $endLocation');
              }
            }
          }
          routesText = routeStrings.join(' ').toLowerCase();
        }
        
        switch (_selectedFilter) {
          case 'route':
            return routesText.contains(_searchQuery);
          case 'sacco':
            return name.contains(_searchQuery);
          case 'location':
            return location.contains(_searchQuery);
          case 'all':
          default:
            return name.contains(_searchQuery) || 
                  location.contains(_searchQuery) || 
                  routesText.contains(_searchQuery);
        }
      }).toList();
    }
    
    // Then sort
    _applySorting();
  }

  // Replace your _applySorting method with this updated version
  void _applySorting() {
    _filteredSaccos.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (_sortBy) {
        case 'rating':
          // Calculate average rating from your data structure
          final aOwnerRating = (a['avg_owner_rating'] ?? 0.0) as double;
          final aPassengerRating = (a['avg_passenger_rating'] ?? 0.0) as double;
          aValue = aOwnerRating > 0 || aPassengerRating > 0 
              ? (aOwnerRating + aPassengerRating) / 2 
              : 0.0;
              
          final bOwnerRating = (b['avg_owner_rating'] ?? 0.0) as double;
          final bPassengerRating = (b['avg_passenger_rating'] ?? 0.0) as double;
          bValue = bOwnerRating > 0 || bPassengerRating > 0 
              ? (bOwnerRating + bPassengerRating) / 2 
              : 0.0;
          break;
        case 'vehicle_count':
          // Use total_routes from your data structure
          aValue = a['total_routes'] ?? 0;
          bValue = b['total_routes'] ?? 0;
          break;
        case 'name':
        default:
          aValue = (a['name']?.toString() ?? '').toLowerCase();
          bValue = (b['name']?.toString() ?? '').toLowerCase();
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
    });
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
                  _filterAndSortSaccos();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Saccos (${_filteredSaccos.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              _showRouteSearch ? Icons.search_off : Icons.route,
              color: _showRouteSearch ? AppColors.orange : AppColors.white,
            ),
            onPressed: () {
              setState(() {
                _showRouteSearch = !_showRouteSearch;
                if (_showRouteSearch) {
                  _selectedFilter = 'route';
                  _searchController.text = '';
                } else {
                  _selectedFilter = 'all';
                  _searchController.text = '';
                }
                _filterAndSortSaccos();
              });
            },
            tooltip: _showRouteSearch ? 'Exit Route Search' : 'Search by Route',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort Saccos',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: _buildSaccosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: _showRouteSearch ? AppColors.orange.withOpacity(0.05) : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            if (_showRouteSearch) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: AppColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        'Route Search Mode Active',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showRouteSearch = false;
                          _selectedFilter = 'all';
                          _searchController.text = '';
                          _filterAndSortSaccos();
                        });
                      },
                      child: Text(
                        'Exit',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
            ],
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _showRouteSearch 
                    ? 'Search routes (e.g., Nairobi-Nakuru, CBD-Westlands)...'
                    : 'Search saccos...',
                prefixIcon: Icon(
                  _showRouteSearch ? Icons.route : Icons.search, 
                  color: _showRouteSearch ? AppColors.orange : AppColors.grey,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: BorderSide(
                    color: _showRouteSearch ? AppColors.orange : AppColors.lightGrey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: BorderSide(
                    color: _showRouteSearch ? AppColors.orange : AppColors.brown,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
            ),
            if (!_showRouteSearch) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Row(
                children: [
                  Text(
                    'Filter by:',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          _buildFilterChip('Sacco', 'sacco'),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          _buildFilterChip('Route', 'route'),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          _buildFilterChip('Location', 'location'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildRouteSearchHelp(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.white : AppColors.grey,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          if (value == 'route') {
            _showRouteSearch = true;
          }
          _filterAndSortSaccos();
        });
      },
      backgroundColor: AppColors.lightGrey,
      selectedColor: value == 'route' ? AppColors.orange : AppColors.brown,
      checkmarkColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRouteSearchHelp() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Route Search Tips:',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Search for specific routes like "Nairobi-Nakuru" or "CBD-Westlands"\n• Use partial matches like "CBD" or "Westlands"\n• Search for route numbers like "Route 46" or "46"',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaccosList() {
    if (_filteredSaccos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh functionality can be added here if needed
        setState(() {
          _filteredSaccos = List.from(widget.saccos);
          _filterAndSortSaccos();
        });
      },
      color: AppColors.brown,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _filteredSaccos.length,
        itemBuilder: (context, index) {
          final sacco = _filteredSaccos[index];
          return _buildSaccoCard(sacco, index);
        },
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
              _searchQuery.isEmpty ? Icons.business : Icons.search_off,
              size: 64,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _searchQuery.isEmpty 
                ? 'No Saccos Available'
                : 'No Results Found',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              _searchQuery.isEmpty
                ? 'There are currently no saccos available. Check back later for new opportunities.'
                : 'No saccos match your search criteria. Try adjusting your search terms or filters.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFilter = 'all';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaccoCard(dynamic sacco, int index) {
    final name = sacco['name']?.toString() ?? 'Unknown Sacco';
    final location = sacco['location']?.toString() ?? 'Unknown Location';
    
    // Handle routes - your data has routes as an array with nested route objects
    String routesText = '';
    final routes = sacco['routes'] as List<dynamic>? ?? [];
    final totalRoutes = sacco['total_routes'] ?? 0;
    
    // Extract route information from the nested structure
    if (routes.isNotEmpty) {
      final routeStrings = <String>[];
      for (final route in routes) {
        // Check if this route object has a 'routes' array
        if (route is Map<String, dynamic> && route.containsKey('routes')) {
          final routeData = route['routes'] as List<dynamic>? ?? [];
          for (final r in routeData) {
            final startLocation = r['start_location']?.toString() ?? '';
            final endLocation = r['end_location']?.toString() ?? '';
            if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
              routeStrings.add('$startLocation - $endLocation');
            }
          }
        }
      }
      routesText = routeStrings.join(', ');
    }
    
    // If routesText is still empty but we have total_routes > 0, 
    // it means routes exist but in a different format
    final hasRoutes = routesText.isNotEmpty || totalRoutes > 0;
    
    // Use average of both ratings
    final ownerRating = (sacco['avg_owner_rating'] ?? 0.0) as double;
    final passengerRating = (sacco['avg_passenger_rating'] ?? 0.0) as double;
    final avgRating = ownerRating > 0 || passengerRating > 0 
        ? (ownerRating + passengerRating) / 2 
        : 0.0;
    
    final contactNumber = sacco['contact_number']?.toString() ?? '';
    final email = sacco['email']?.toString() ?? '';
    
    // Create description from available contact info
    String description = '';
    if (contactNumber.isNotEmpty) description += 'Contact: $contactNumber';
    if (email.isNotEmpty) {
      if (description.isNotEmpty) description += ' | ';
      description += 'Email: $email';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: InkWell(
        onTap: () => widget.onSaccoTap(sacco['id']),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.blue.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w600,
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
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.lightGrey,
                    size: 16,
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  description,
                  style: AppTextStyles.body2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Routes section - only show if we have routes
              if (hasRoutes) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (_showRouteSearch && _searchQuery.isNotEmpty && 
                          routesText.toLowerCase().contains(_searchQuery)) 
                        ? AppColors.orange.withOpacity(0.2)
                        : AppColors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: (_showRouteSearch && _searchQuery.isNotEmpty && 
                            routesText.toLowerCase().contains(_searchQuery))
                        ? Border.all(color: AppColors.orange, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 14,
                        color: (_showRouteSearch && _searchQuery.isNotEmpty && 
                              routesText.toLowerCase().contains(_searchQuery))
                            ? AppColors.orange
                            : AppColors.purple,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          routesText.isNotEmpty 
                              ? 'Routes: $routesText'
                              : 'Routes: $totalRoutes route${totalRoutes == 1 ? '' : 's'} available',
                          style: AppTextStyles.caption.copyWith(
                            color: (_showRouteSearch && _searchQuery.isNotEmpty && 
                                  routesText.toLowerCase().contains(_searchQuery))
                                ? AppColors.orange
                                : AppColors.purple,
                            fontWeight: (_showRouteSearch && _searchQuery.isNotEmpty && 
                                        routesText.toLowerCase().contains(_searchQuery))
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.paddingSmall),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: avgRating > 0 
                          ? AppColors.orange.withOpacity(0.1)
                          : AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: avgRating > 0 ? AppColors.orange : AppColors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : 'No rating',
                          style: AppTextStyles.caption.copyWith(
                            color: avgRating > 0 ? AppColors.orange : AppColors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  // Only show route count if there are actually routes
                  if (totalRoutes > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route,
                            color: AppColors.green,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalRoutes route${totalRoutes == 1 ? '' : 's'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'No routes',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '#${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}