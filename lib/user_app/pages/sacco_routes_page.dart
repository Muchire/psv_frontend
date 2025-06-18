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

  @override
  void initState() {
    super.initState();
    _loadRoutes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes Management'),
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRoutes),
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
        child: const Icon(Icons.add),
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
    // Extract route data with proper fallbacks
    final routeId = route['id']?.toString() ?? '?';
    final startLocation = route['start_location']?.toString() ?? 'Unknown';
    final endLocation = route['end_location']?.toString() ?? 'Unknown';
    final distance = route['distance']?.toString();
    final duration = route['duration']?.toString();
    final fare = route['fare']?.toString();
    final stops = route['stops'] as List? ?? [];

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
                  '${stops.length} intermediate stops',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),

                // Fare if available
                if (fare != null) ...[
                  Icon(Icons.attach_money, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('KSh $fare', style: AppTextStyles.caption),
                  const SizedBox(width: AppDimensions.paddingMedium),
                ],

                // Distance if available
                if (distance != null) ...[
                  Icon(Icons.straighten, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('${distance}km', style: AppTextStyles.caption),
                ],
              ],
            ),
            if (duration != null) ...[
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
                      if (distance != null ||
                          duration != null ||
                          fare != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (distance != null) ...[
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
                            if (duration != null) ...[
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
                            if (fare != null) ...[
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
                          if (stop is Map) {
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
                        }).toList(),

                      // End location
                      _buildJourneyStop(endLocation, 'END', false, true),
                    ],
                  ),
                ),

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
                        Text(
                          'No intermediate stops configured',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      final route = widget.initialRoute!;
      _startLocationController.text = route['start_location'] ?? '';
      _endLocationController.text = route['end_location'] ?? '';
      _distanceController.text = route['distance']?.toString() ?? '';
      _durationController.text = route['duration']?.toString() ?? '';
      _fareController.text = route['fare']?.toString() ?? '';

      final stops = route['stops'] as List? ?? [];
      for (final stop in stops) {
        String stopName = '';
        if (stop is Map) {
          stopName =
              stop['stage_name']?.toString() ?? stop['name']?.toString() ?? '';
        } else if (stop is String) {
          stopName = stop;
        }
        _stopControllers.add(TextEditingController(text: stopName));
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start Location
                TextFormField(
                  controller: _startLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter start location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // End Location
                TextFormField(
                  controller: _endLocationController,
                  decoration: const InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter end location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Distance and Duration Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Distance (km)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final distance = double.tryParse(value);
                            if (distance == null || distance <= 0) {
                              return 'Enter valid distance';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final duration = int.tryParse(value);
                            if (duration == null || duration <= 0) {
                              return 'Enter valid duration';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Fare
                TextFormField(
                  controller: _fareController,
                  decoration: const InputDecoration(
                    labelText: 'Fare (KSh)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final fare = double.tryParse(value);
                      if (fare == null || fare <= 0) {
                        return 'Enter valid fare amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Intermediate Stops Section
                Row(
                  children: [
                    Text('Intermediate Stops', style: AppTextStyles.heading3),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _stopControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Stop'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSmall),

                // Stops List
                if (_stopControllers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey,
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
                        Text(
                          'No intermediate stops added',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(_stopControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stopControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Stop ${index + 1}',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter stop name';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _stopControllers[index].dispose();
                                _stopControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
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

  // In _RouteFormDialogState._saveRoute() method
 // Updated _saveRoute method in _RouteFormDialogState
  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare stops data with proper order
      final stops = _stopControllers
          .where((controller) => controller.text.trim().isNotEmpty)
          .map((controller) {
            final index = _stopControllers.indexOf(controller);
            return <String, dynamic>{
              'stage_name': controller.text.trim(),
              'order': index + 1, // Add order field starting from 1
            };
          })
          .toList();

      // Prepare route data with explicit typing
      final routeData = <String, dynamic>{
        'start_location': _startLocationController.text.trim(),
        'end_location': _endLocationController.text.trim(),
      };

      // Add stops if any exist (backend expects 'stops', not 'stops_data')
      if (stops.isNotEmpty) {
        routeData['stops'] = stops;
      }

      // Add optional fields if they have values
      if (_distanceController.text.trim().isNotEmpty) {
        final distance = double.tryParse(_distanceController.text.trim());
        if (distance != null && distance > 0) {
          routeData['distance'] = distance;
        }
      }

      if (_durationController.text.trim().isNotEmpty) {
        final duration = int.tryParse(_durationController.text.trim());
        if (duration != null && duration > 0) {
          routeData['duration'] = duration;
        }
      }

      if (_fareController.text.trim().isNotEmpty) {
        final fare = double.tryParse(_fareController.text.trim());
        if (fare != null && fare > 0) {
          routeData['fare'] = fare;
        }
      }

      // Debug: Print the data being sent
      print('=== Form Data ===');
      print('Route Data: $routeData');
      print('Stops Count: ${stops.length}');
      for (int i = 0; i < stops.length; i++) {
        print('Stop ${i + 1}: ${stops[i]}');
      }

      // Call the service method
      await widget.onSave(routeData);
    } catch (e) {
      print('Error in _saveRoute: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Re-throw so parent can handle it too
      rethrow;
    }
  }
}