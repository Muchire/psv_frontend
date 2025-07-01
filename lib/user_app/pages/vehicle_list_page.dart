import 'package:flutter/material.dart';
import '/services/vehicle_api_service.dart';
import '../utils/constants.dart';
import 'vehicle_detail_page.dart';


class VehicleListPage extends StatefulWidget {
  const VehicleListPage({Key? key}) : super(key: key);

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await VehicleOwnerService.getVehicles();
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load vehicles: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVehicles() async {
    await _loadVehicles();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  List<dynamic> get _filteredVehicles {
    if (_searchQuery.isEmpty) return _vehicles;
    
    return _vehicles.where((vehicle) {
      final plateNumber = vehicle['plate_number']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return plateNumber.contains(query);
    }).toList();
  }

void _navigateToVehicleDetail(dynamic vehicle) async {
  // Extract the vehicle ID from the vehicle object
  final vehicleId = vehicle['id'];
  
  if (vehicleId == null) {
    _showErrorSnackBar('Vehicle ID not found');
    return;
  }
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VehicleDetailPage(vehicleId: vehicleId),
    ),
  );
  
  // Optional: Refresh the list if the vehicle was updated
  if (result == true) {
    _refreshVehicles();
  }
}

  void _showAddVehicleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVehicleBottomSheet(
        onVehicleAdded: () {
          _refreshVehicles();
          _showSuccessSnackBar('Vehicle added successfully!');
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vehicle'),
          content: Text(
            'Are you sure you want to delete ${vehicle['plate_number']}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteVehicle(vehicle['id']);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVehicle(dynamic vehicleId) async {
    try {
      await VehicleOwnerService.deleteVehicle(vehicleId);
      _showSuccessSnackBar('Vehicle deleted successfully');
      _refreshVehicles();
    } catch (e) {
      _showErrorSnackBar('Failed to delete vehicle: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text(
          'My Vehicles',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brown),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVehicles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by plate number...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.brown),
                ),
                filled: true,
                fillColor: AppColors.lightGrey,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Vehicle Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: AppColors.white,
            child: Text(
              '${_filteredVehicles.length} vehicle${_filteredVehicles.length != 1 ? 's' : ''} found',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            ),
          ),
          
          // Vehicle List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshVehicles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = _filteredVehicles[index];
                            return _buildVehicleCard(vehicle);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brown,
        onPressed: _showAddVehicleDialog,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No vehicles added yet'
                : 'No vehicles match your search',
            style: AppTextStyles.heading3.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first vehicle to get started'
                : 'Try adjusting your search terms',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }


  // Also fix the vehicle card tap handler
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final plateNumber = vehicle['plate_number'] ?? 'Unknown';
    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    final year = vehicle['year']?.toString() ?? '';
    final vehicleType = vehicle['vehicle_type'] ?? '';
    final color = vehicle['color'] ?? '';
    final saccoName = vehicle['sacco_name'];
    final isActive = vehicle['is_active'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToVehicleDetail(vehicle), // Pass the whole vehicle object
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Vehicle Icon
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getVehicleIcon(vehicleType),
                      color: AppColors.brown,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Vehicle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plateNumber,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.success : AppColors.warning,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$make $model ${year.isNotEmpty ? '($year)' : ''}',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // More Options
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          // Navigate to edit vehicle page or show edit dialog
                          _navigateToVehicleDetail(vehicle);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(vehicle);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.brown),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Vehicle Details Row
              Row(
                children: [
                  _buildDetailChip(
                    Icons.palette,
                    color.isNotEmpty ? color : 'Unknown',
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.category,
                    VehicleOwnerService.getVehicleTypeDisplayName(vehicleType),
                  ),
                ],
              ),
              
              if (saccoName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.brown,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sacco: $saccoName',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.brown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'matatu':
        return Icons.directions_bus;
      case 'bus':
        return Icons.directions_bus;
      case 'taxi':
        return Icons.local_taxi;
      case 'boda_boda':
        return Icons.motorcycle;
      case 'tuk_tuk':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }
}

// Add Vehicle Bottom Sheet
class AddVehicleBottomSheet extends StatefulWidget {
  final VoidCallback onVehicleAdded;

  const AddVehicleBottomSheet({
    Key? key,
    required this.onVehicleAdded,
  }) : super(key: key);

  @override
  State<AddVehicleBottomSheet> createState() => _AddVehicleBottomSheetState();
}

class _AddVehicleBottomSheetState extends State<AddVehicleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _seatingCapacityController = TextEditingController();
  final _fuelConsumptionController = TextEditingController();

  String _selectedVehicleType = 'matatu';
  String _selectedFuelType = 'petrol';
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'matatu',
    'bus',
    'taxi',
    'boda_boda',
    'tuk_tuk',
  ];

  final List<String> _fuelTypes = [
    'petrol',
    'diesel',
    'electric',
    'hybrid',
  ];

  @override
  void dispose() {
    _plateNumberController.dispose();
    _registrationNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _seatingCapacityController.dispose();
    _fuelConsumptionController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicleData = {
        'plate_number': _plateNumberController.text.trim().toUpperCase(),
        'registration_number': _registrationNumberController.text.trim().toUpperCase(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'color': _colorController.text.trim(),
        'vehicle_type': _selectedVehicleType,
        'seating_capacity': int.parse(_seatingCapacityController.text.trim()),
        'fuel_type': _selectedFuelType,
        'fuel_consumption_per_km': double.parse(_fuelConsumptionController.text.trim()),
      };

      await VehicleOwnerService.registerVehicle(vehicleData);
      
      Navigator.of(context).pop();
      widget.onVehicleAdded();
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Add New Vehicle',
                  style: AppTextStyles.heading2,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guidance Text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Please provide accurate vehicle information. All fields marked with * are required.',
                        style: AppTextStyles.body2.copyWith(color: AppColors.grey),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Plate Number
                    TextFormField(
                      controller: _plateNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number *',
                        hintText: 'e.g., KDA 123A',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Plate number is required';
                        }
                        if (value.trim().length < 6) {
                          return 'Please enter a valid plate number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Registration Number
                    TextFormField(
                      controller: _registrationNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number *',
                        hintText: 'Vehicle registration number',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Registration number is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Make and Model Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _makeController,
                            decoration: const InputDecoration(
                              labelText: 'Make *',
                              hintText: 'e.g., Toyota',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Make is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model *',
                              hintText: 'e.g., Hiace',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Model is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Year and Color Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Year *',
                              hintText: 'e.g., 2020',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Year is required';
                              }
                              final year = int.tryParse(value.trim());
                              if (year == null) {
                                return 'Enter valid year';
                              }
                              final currentYear = DateTime.now().year;
                              if (year < 1980 || year > currentYear + 1) {
                                return 'Year must be 1980-${currentYear + 1}';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color *',
                              hintText: 'e.g., White',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Color is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: _vehicleTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(VehicleOwnerService.getVehicleTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fuel Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: _fuelTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(VehicleOwnerService.getFuelTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFuelType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Seating Capacity and Fuel Consumption Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _seatingCapacityController,
                            decoration: const InputDecoration(
                              labelText: 'Seating Capacity *',
                              hintText: 'Number of seats',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Capacity required';
                              }
                              final capacity = int.tryParse(value.trim());
                              if (capacity == null || capacity < 1 || capacity > 100) {
                                return 'Enter 1-100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _fuelConsumptionController,
                            decoration: const InputDecoration(
                              labelText: 'Fuel Consumption (L/Km) *',
                              hintText: 'Liters per kilometer',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final consumption = double.tryParse(value.trim());
                              if (consumption == null || consumption <= 0 || consumption > 1) {
                                return 'Enter 0.01-1.0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brown,
                          foregroundColor: AppColors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: AppColors.white)
                            : const Text('Add Vehicle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}