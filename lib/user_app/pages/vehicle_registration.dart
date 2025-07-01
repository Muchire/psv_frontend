import 'package:flutter/material.dart';
import 'package:psv_frontend/services/vehicle_api_service.dart';
import '../utils/constants.dart';

class VehicleRegistrationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onRegistrationSuccess;
  
  const VehicleRegistrationDialog({
    super.key,
    required this.onRegistrationSuccess,
  });

  @override
  State<VehicleRegistrationDialog> createState() => _VehicleRegistrationDialogState();
}

class _VehicleRegistrationDialogState extends State<VehicleRegistrationDialog> {
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
  bool _isRegistering = false;

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

  final Map<String, String> _vehicleTypeLabels = {
    'matatu': 'Matatu',
    'bus': 'Bus',
    'taxi': 'Taxi',
    'boda_boda': 'Boda Boda',
    'tuk_tuk': 'Tuk Tuk',
  };

  final Map<String, String> _fuelTypeLabels = {
    'petrol': 'Petrol',
    'diesel': 'Diesel',
    'electric': 'Electric',
    'hybrid': 'Hybrid',
  };

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

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

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

      final response = await VehicleOwnerService.registerVehicle(vehicleData);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully! You are now a vehicle owner.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Call the callback to update the profile
      widget.onRegistrationSuccess(response);
      
      // Close the dialog
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register vehicle: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: const BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusMedium),
                  topRight: Radius.circular(AppDimensions.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: AppColors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Register Your Vehicle',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_vehicleTypeLabels[type] ?? type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedVehicleType = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a vehicle type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Plate Number and Registration Number Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _plateNumberController,
                              decoration: const InputDecoration(
                                labelText: 'License Plate',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.confirmation_number),
                                hintText: 'e.g., KBA 123A',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (value.trim().length < 6) {
                                  return 'Invalid format';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: TextFormField(
                              controller: _registrationNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Registration No.',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.assignment),
                                hintText: 'e.g., KBA123A',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Make and Model Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _makeController,
                              decoration: const InputDecoration(
                                labelText: 'Make',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., Toyota',
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., Hiace',
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Year and Color Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., 2020',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final year = int.tryParse(value.trim());
                                if (year == null || year < 1980 || year > DateTime.now().year + 1) {
                                  return 'Invalid year';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: TextFormField(
                              controller: _colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., White',
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Seating Capacity and Fuel Type Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seatingCapacityController,
                              decoration: const InputDecoration(
                                labelText: 'Seating Capacity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.airline_seat_recline_normal),
                                hintText: 'e.g., 14',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final capacity = int.tryParse(value.trim());
                                if (capacity == null || capacity < 1 || capacity > 100) {
                                  return 'Invalid (1-100)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedFuelType,
                              decoration: const InputDecoration(
                                labelText: 'Fuel Type',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_gas_station),
                              ),
                              items: _fuelTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_fuelTypeLabels[type] ?? type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedFuelType = value!);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Fuel Consumption
                      TextFormField(
                        controller: _fuelConsumptionController,
                        decoration: const InputDecoration(
                          labelText: 'Fuel Consumption (L/km)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                          hintText: 'e.g., 0.12',
                          helperText: 'Liters consumed per kilometer',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter fuel consumption';
                          }
                          final consumption = double.tryParse(value.trim());
                          if (consumption == null || consumption <= 0 || consumption > 1) {
                            return 'Enter valid consumption (0.01-1.0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingLarge),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.brown),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Once registered, you will have access to the Vehicle Owner Dashboard and can start offering transport services.',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isRegistering ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _registerVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Text('Register Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}