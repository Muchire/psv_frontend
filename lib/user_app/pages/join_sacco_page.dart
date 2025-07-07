import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '/services/vehicle_api_service.dart';

class JoinSaccoPage extends StatefulWidget {
  final int saccoId;
  final String saccoName;

  const JoinSaccoPage({
    Key? key,
    required this.saccoId,
    required this.saccoName,
  }) : super(key: key);

  @override
  State<JoinSaccoPage> createState() => _JoinSaccoPageState();
}

class _JoinSaccoPageState extends State<JoinSaccoPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _reasonController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingVehicles = true;
  bool _isLoadingDocuments = false;
  List<dynamic> _allVehicles = [];
  List<dynamic> _availableVehicles = [];
  List<dynamic>? _cachedPendingRequests; 

  
  // Updated document structure to match server requirements
  final Map<String, PlatformFile?> _requiredDocuments = {
    'logbook': null,
    'insurance': null,
    'inspection': null,
    'license': null,
    'permit': null,
  };
  
  // Track existing documents from server
  final Map<String, Map<String, dynamic>> _existingDocuments = {};
  
  List<dynamic> _userVehicles = [];
  int? _selectedVehicleId;
  
  // Form fields
  String? _selectedRoutePreference;
  int? _selectedExperienceYears;
  bool _hasInsurance = false;
  bool _hasValidLicense = false;
  bool _agreeToTerms = false;

  final List<String> _routePreferences = [
    'City routes',
    'Highway routes',
    'Mixed routes',
    'No preference'
  ];

  final List<int> _experienceOptions = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
  ];

  final Map<String, String> _documentLabels = {
    'logbook': 'Vehicle Logbook',
    'insurance': 'Insurance Certificate',
    'inspection': 'Inspection Certificate',
    'license': 'Driving License',
    'permit': 'PSV Permit',
  };

  @override
  void initState() {
    super.initState();
    _loadUserVehicles();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _reasonController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserVehicles() async {
    try {
      // First, get all user vehicles
      final vehicles = await VehicleOwnerService.getVehicles();
      
      setState(() {
        _allVehicles = vehicles;
      });

      // Filter vehicles to only include those without SACCO or pending requests
      await _filterAvailableVehicles(vehicles);
      
    } catch (e) {
      setState(() {
        _isLoadingVehicles = false;
      });
      _showErrorDialog('Failed to load your vehicles: $e');
    }
  }
  // Add this new method to filter available vehicles
  Future<void> _filterAvailableVehicles(List<dynamic> vehicles) async {
    List<dynamic> availableVehicles = [];
    
    for (var vehicle in vehicles) {
      try {
        final vehicleId = vehicle['id'];
        
        // Check if vehicle has SACCO details
        bool hasActiveSacco = false;
        bool hasPendingRequest = false;
        
        try {
          // Check if vehicle is already in a SACCO
          final saccoDetails = await VehicleOwnerService.getVehicleWithSacco(vehicleId);
          
          // If the vehicle has sacco_id or is_sacco_member is true, it's already in a SACCO
          if (saccoDetails != null && 
              (saccoDetails['sacco_id'] != null || 
               saccoDetails['is_sacco_member'] == true)) {
            hasActiveSacco = true;
          }
        } catch (e) {
          // If 404 or similar error, vehicle doesn't have SACCO details
          print('No SACCO details for vehicle $vehicleId: $e');
        }
        
        // If vehicle doesn't have active SACCO, check for pending requests
        if (!hasActiveSacco) {
          try {
            // Check for pending requests for this specific vehicle
            // You might need to create a method to get pending requests for a specific vehicle
            final pendingRequests = await _getVehiclePendingRequests(vehicleId);
            hasPendingRequest = pendingRequests.isNotEmpty;
          } catch (e) {
            print('Error checking pending requests for vehicle $vehicleId: $e');
            // If error checking pending requests, assume no pending requests
          }
        }
        
        // Only add vehicle if it doesn't have active SACCO and no pending requests
        if (!hasActiveSacco && !hasPendingRequest) {
          availableVehicles.add(vehicle);
        }
        
      } catch (e) {
        print('Error processing vehicle ${vehicle['id']}: $e');
        // In case of error, include the vehicle (fail-safe approach)
        availableVehicles.add(vehicle);
      }
    }
    
    setState(() {
      _availableVehicles = availableVehicles;
      _userVehicles = availableVehicles; // Update the existing variable
      _isLoadingVehicles = false;
      
      // Auto-select first vehicle if only one available
      if (availableVehicles.length == 1) {
        _selectedVehicleId = availableVehicles[0]['id'];
        _loadVehicleDocuments(availableVehicles[0]['id']);
      }
    });
  }

  // Add this helper method to check pending requests for a specific vehicle using cached data


  // Add this helper method to check pending requests for a specific vehicle
  Future<List<dynamic>> _getVehiclePendingRequests(int vehicleId) async {
    try {
      // Use client-side filtering of all pending requests for this SACCO
      final allPendingRequests = await VehicleOwnerService.getPendingSaccoRequests(widget.saccoId.toString());
      
      // Filter requests that match this vehicle ID
      final vehicleRequests = allPendingRequests.where((request) {
        // Check different possible structures for vehicle ID
        if (request['vehicle_id'] != null) {
          return request['vehicle_id'] == vehicleId;
        } else if (request['vehicle'] != null && request['vehicle']['id'] != null) {
          return request['vehicle']['id'] == vehicleId;
        } else if (request['vehicle_details'] != null && request['vehicle_details']['id'] != null) {
          return request['vehicle_details']['id'] == vehicleId;
        }
        return false;
      }).toList();
      
      print('Found ${vehicleRequests.length} pending requests for vehicle $vehicleId');
      return vehicleRequests;
      
    } catch (e) {
      print('Error getting pending requests for vehicle $vehicleId: $e');
      // Return empty list if can't check - this is a fail-safe approach
      // You might want to return [] to be conservative, or throw the error
      // to prevent vehicles from being shown if the check fails
      return [];
    }
  }


  Future<void> _loadVehicleDocuments(int vehicleId) async {
    setState(() {
      _isLoadingDocuments = true;
    });

    try {
      final documents = await VehicleOwnerService.getVehicleDocuments(vehicleId);
      
      setState(() {
        _existingDocuments.clear();
        
        // Process existing documents
        for (var doc in documents) {
          final docType = doc['document_type']?.toString().toLowerCase();
          if (docType != null && _requiredDocuments.containsKey(docType)) {
            _existingDocuments[docType] = doc;
          }
        }
        
        _isLoadingDocuments = false;
      });

      print('Loaded ${_existingDocuments.length} existing documents for vehicle $vehicleId');
      
    } catch (e) {
      setState(() {
        _isLoadingDocuments = false;
      });
      print('Error loading vehicle documents: $e');
      // Don't show error dialog for this - it's not critical, just means no existing documents
    }
  }

  Future<void> _pickDocumentForType(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _requiredDocuments[documentType] = result.files.first;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    }
  }

  void _removeDocument(String documentType) {
    setState(() {
      _requiredDocuments[documentType] = null;
    });
  }

  bool _areAllDocumentsAvailable() {
    // Check if all required documents are either uploaded as new files or exist on server
    return _requiredDocuments.keys.every((docType) => 
      _requiredDocuments[docType] != null || _existingDocuments.containsKey(docType)
    );
  }

  List<String> _getMissingDocuments() {
    return _requiredDocuments.entries
        .where((entry) => entry.value == null && !_existingDocuments.containsKey(entry.key))
        .map((entry) => _documentLabels[entry.key] ?? entry.key)
        .toList();
  }

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      _showErrorDialog('Please select a vehicle to join with');
      return;
    }

    if (_selectedExperienceYears == null) {
      _showErrorDialog('Please select your years of driving experience');
      return;
    }

    if (!_areAllDocumentsAvailable()) {
      final missing = _getMissingDocuments();
      _showErrorDialog('Please upload all required documents. Missing: ${missing.join(', ')}');
      return;
    }

    if (!_agreeToTerms) {
      _showErrorDialog('Please agree to the terms and conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare request data
      final requestData = {
        'sacco_id': widget.saccoId,
        'vehicle_id': _selectedVehicleId,
        'message': _messageController.text.trim(),
        'experience_years': _selectedExperienceYears,
        'reason_for_joining': _reasonController.text.trim(),
        'license_number': _licenseNumberController.text.trim(),
        'route_preference': _selectedRoutePreference,
        'has_insurance': _hasInsurance,
        'has_valid_license': _hasValidLicense,
        'additional_info': {
          'documents_count': _requiredDocuments.values.where((f) => f != null).length + _existingDocuments.length,
          'application_type': 'standard',
          'existing_documents': _existingDocuments.keys.toList(),
        }
      };

      // Only include new documents that need to be uploaded
      final newDocuments = <String, PlatformFile>{};
      _requiredDocuments.forEach((key, value) {
        if (value != null) {
          newDocuments[key] = value;
        }
      });

      // Use the updated submission method
      final response = await VehicleOwnerService.submitJoinRequestWithDocuments(
        widget.saccoId,
        _selectedVehicleId!,
        requestData,
        newDocuments, // Only upload new documents
      );

      print('Join request submitted successfully: $response');
      _showSuccessDialog();
      
    } catch (e) {
      print('Error submitting join request: $e');
      _showErrorDialog('Failed to submit join request: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your application to join ${widget.saccoName} has been submitted successfully!'),
              const SizedBox(height: 12),
              const Text(
                'What happens next:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('• SACCO management will review your application'),
              const Text('• You will be notified of the decision via the app'),
              const Text('• Check your notifications regularly for updates'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleSelectionCard() {
    if (_isLoadingVehicles) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Show different messages based on vehicle availability
    if (_allVehicles.isEmpty) {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 48),
              const SizedBox(height: 12),
              const Text(
                'No Vehicles Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to add a vehicle before joining a SACCO. '
                'Please go back and add a vehicle first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_availableVehicles.isEmpty) {
      return Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 48),
              const SizedBox(height: 12),
              const Text(
                'No Available Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All your vehicles are either already in a SACCO or have pending applications. '
                'You can only join a SACCO with vehicles that are not currently associated with any SACCO.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Select Available Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Showing ${_availableVehicles.length} of ${_allVehicles.length} vehicles (excluding those already in SACCOs or with pending applications)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            
            // Vehicle selection list
            ...(_availableVehicles.map((vehicle) {
              final isSelected = _selectedVehicleId == vehicle['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? Colors.green[50] : null,
                ),
                child: RadioListTile<int>(
                  title: Text(
                    '${vehicle['make']} ${vehicle['model']}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Registration: ${vehicle['registration_number']}'),
                      Text('Year: ${vehicle['year']}'),
                      if (vehicle['route'] != null)
                        Text('Current Route: ${vehicle['route']}'),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: vehicle['id'],
                  groupValue: _selectedVehicleId,
                  onChanged: (int? value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                    if (value != null) {
                      _loadVehicleDocuments(value);
                    }
                  },
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocumentsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_upload, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingDocuments)
                  const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload new documents or use existing ones from your vehicle',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Document upload cards
            ..._requiredDocuments.keys.map((documentType) {
              final file = _requiredDocuments[documentType];
              final existingDoc = _existingDocuments[documentType];
              final label = _documentLabels[documentType] ?? documentType;
              final hasNewFile = file != null;
              final hasExistingDoc = existingDoc != null;
              final isComplete = hasNewFile || hasExistingDoc;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isComplete ? Colors.green : Colors.red.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isComplete ? Colors.green[50] : Colors.red[50],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isComplete ? Icons.check_circle : Icons.upload_file,
                            color: isComplete ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isComplete ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                          if (hasNewFile)
                            IconButton(
                              onPressed: () => _removeDocument(documentType),
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      
                      // Show existing document info
                      if (hasExistingDoc && !hasNewFile) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Using existing: ${existingDoc['document_name'] ?? 'Uploaded document'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Show new file info
                      if (hasNewFile) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.insert_drive_file, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'New: ${file.name}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _pickDocumentForType(documentType),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasNewFile ? Colors.green[100] : 
                                           hasExistingDoc ? Colors.orange[100] : Colors.green[50],
                            foregroundColor: hasNewFile ? Colors.green[700] : 
                                           hasExistingDoc ? Colors.orange[700] : Colors.green[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            hasNewFile ? 'Replace Document' : 
                            hasExistingDoc ? 'Upload New Version' : 'Upload Document',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Upload status summary
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _areAllDocumentsAvailable() ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _areAllDocumentsAvailable() ? Icons.check_circle : Icons.warning,
                    color: _areAllDocumentsAvailable() ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _areAllDocumentsAvailable()
                          ? 'All required documents are available!'
                          : 'Please provide all ${_requiredDocuments.length} required documents to continue',
                      style: TextStyle(
                        color: _areAllDocumentsAvailable() ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join ${widget.saccoName}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, 
                               color: Colors.green[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Apply to Join ${widget.saccoName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please fill out this application form to request to join this SACCO. '
                        'All information will be reviewed by the SACCO management.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Vehicle Selection Section
              _buildVehicleSelectionCard(),

              // Only show the rest of the form if vehicles are available
              if (_userVehicles.isNotEmpty) ...[
                const SizedBox(height: 20),

                // Personal Information Section
                _buildSectionHeader('Personal Information', Icons.person),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Driving License Number *',
                    hintText: 'Enter your valid driving license number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'License number is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Experience Years Dropdown
                DropdownButtonFormField<int>(
                  value: _selectedExperienceYears,
                  decoration: const InputDecoration(
                    labelText: 'Years of Driving Experience *',
                    hintText: 'Select your years of driving experience',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.history),
                  ),
                  items: _experienceOptions.map((int years) {
                    return DropdownMenuItem<int>(
                      value: years,
                      child: Text(years == 0 ? 'Less than 1 year' : 
                                 years == 1 ? '1 year' : '$years years'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedExperienceYears = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your years of experience';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRoutePreference,
                  decoration: const InputDecoration(
                    labelText: 'Route Preference',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route),
                  ),
                  items: _routePreferences.map((String route) {
                    return DropdownMenuItem<String>(
                      value: route,
                      child: Text(route),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRoutePreference = newValue;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Vehicle & Documentation Section
                _buildSectionHeader('Vehicle & Documentation', Icons.directions_car),
                const SizedBox(height: 12),

                CheckboxListTile(
                  title: const Text('I have valid vehicle insurance'),
                  subtitle: const Text('Current and comprehensive insurance coverage'),
                  value: _hasInsurance,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasInsurance = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                CheckboxListTile(
                  title: const Text('I have a valid driving license'),
                  subtitle: const Text('Current PSV license or equivalent'),
                  value: _hasValidLicense,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasValidLicense = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 20),

                // Required Documents Section
                _buildRequiredDocumentsSection(),

                const SizedBox(height: 20),

                // Reason for Joining Section
                _buildSectionHeader('Application Details', Icons.assignment),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Joining *',
                    hintText: 'Why do you want to join this SACCO?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason for joining';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Additional Information',
                    hintText: 'Any additional information you would like to share...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                // Terms and Conditions
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CheckboxListTile(
                      title: const Text(
                        'I agree to the terms and conditions',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'By checking this box, I confirm that all information provided is accurate '
                        'and I agree to abide by the SACCO\'s rules and regulations.',
                      ),
                      value: _agreeToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_areAllDocumentsAvailable()) ? null : _submitJoinRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Submitting Request...'),
                            ],
                          )
                        : Text(
                            _areAllDocumentsAvailable()
                                ? 'Submit Join Request'
                                : 'Provide All Documents First',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }
  // Add this method to validate form completeness
  bool _isFormValid() {
    return _selectedVehicleId != null &&
           _selectedExperienceYears != null &&
           _licenseNumberController.text.trim().isNotEmpty &&
           _reasonController.text.trim().isNotEmpty &&
           _areAllDocumentsAvailable() &&
           _agreeToTerms;
  }

  // // Add this method to show document preview
  // Widget _buildDocumentPreview(String documentType, PlatformFile file) {
  //   return Container(
  //     margin: const EdgeInsets.only(top: 8),
  //     padding: const EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[100],
  //       borderRadius: BorderRadius.circular(4),
  //       border: Border.all(color: Colors.grey[300]!),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           _getFileIcon(file.extension?.toLowerCase() ?? ''),
  //           size: 20,
  //           color: Colors.blue[600],
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 file.name,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               Text(
  //                 '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
  //                 style: TextStyle(
  //                   fontSize: 10,
  //                   color: Colors.grey[600],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         IconButton(
  //           onPressed: () => _removeDocument(documentType),
  //           icon: const Icon(Icons.close, size: 16),
  //           constraints: const BoxConstraints(),
  //           padding: EdgeInsets.zero,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Helper method to get appropriate file icon
  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Add this method to handle back navigation with confirmation
  Future<bool> _onWillPop() async {
    if (_isFormValid() && !_isLoading) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Application?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to go back?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  // Add validation for license number format
  String? _validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    
    // Basic license number validation (adjust pattern as needed)
    final licensePattern = RegExp(r'^[A-Z0-9]{6,15}$');
    if (!licensePattern.hasMatch(value.trim().toUpperCase())) {
      return 'Please enter a valid license number';
    }
    
    return null;
  }

  // Add method to clear form data
  void _clearFormData() {
    _messageController.clear();
    _reasonController.clear();
    _licenseNumberController.clear();
    
    setState(() {
      _selectedVehicleId = null;
      _selectedRoutePreference = null;
      _selectedExperienceYears = null;
      _hasInsurance = false;
      _hasValidLicense = false;
      _agreeToTerms = false;
      
      // Clear document selections
      _requiredDocuments.updateAll((key, value) => null);
      _existingDocuments.clear();
    });
  }
}