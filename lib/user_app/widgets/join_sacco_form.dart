// lib/widgets/join_sacco_form.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '/services/vehicle_api_service.dart';

class JoinSaccoForm extends StatefulWidget {
  final int saccoId;
  final String saccoName;
  final List<Map<String, dynamic>> userVehicles;
  final VoidCallback? onSuccess;

  const JoinSaccoForm({
    Key? key,
    required this.saccoId,
    required this.saccoName,
    required this.userVehicles,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<JoinSaccoForm> createState() => _JoinSaccoFormState();
}

class _JoinSaccoFormState extends State<JoinSaccoForm> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  
  int? _selectedVehicleId;
  bool _isLoading = false;
  
  // Document fields
  String? _drivingLicensePath;
  String? _vehicleLogbookPath;
  String? _insuranceCertPath;
  String? _ntvaLicensePath;
  String? _psvBadgePath;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          switch (documentType) {
            case 'driving_license':
              _drivingLicensePath = result.files.single.path;
              break;
            case 'vehicle_logbook':
              _vehicleLogbookPath = result.files.single.path;
              break;
            case 'insurance_cert':
              _insuranceCertPath = result.files.single.path;
              break;
            case 'ntva_license':
              _ntvaLicensePath = result.files.single.path;
              break;
            case 'psv_badge':
              _psvBadgePath = result.files.single.path;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestData = {
        'sacco': widget.saccoId,
        'vehicle': _selectedVehicleId,
        'message': _messageController.text.trim(),
        'documents': {
          if (_drivingLicensePath != null) 'driving_license': _drivingLicensePath,
          if (_vehicleLogbookPath != null) 'vehicle_logbook': _vehicleLogbookPath,
          if (_insuranceCertPath != null) 'insurance_certificate': _insuranceCertPath,
          if (_ntvaLicensePath != null) 'ntva_license': _ntvaLicensePath,
          if (_psvBadgePath != null) 'psv_badge': _psvBadgePath,
        }
      };

      await VehicleOwnerService.createJoinRequestForSacco(
        widget.saccoId, 
        requestData
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent to ${widget.saccoName} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDocumentUpload(String title, String documentType, String? currentPath) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: currentPath != null 
          ? Text('Selected: ${currentPath.split('/').last}', style: const TextStyle(color: Colors.green))
          : const Text('No file selected'),
        trailing: IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: () => _pickFile(documentType),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join ${widget.saccoName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Vehicle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.userVehicles.map((vehicle) {
                          return DropdownMenuItem<int>(
                            value: vehicle['id'],
                            child: Text('${vehicle['make']} ${vehicle['model']} - ${vehicle['license_plate']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedVehicleId = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Please select a vehicle';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message (Optional)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Additional message to the sacco admin',
                          border: OutlineInputBorder(),
                          hintText: 'Tell them why you want to join...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Documents Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Required Documents',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload the following documents (PDF, JPG, PNG format):',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDocumentUpload(
                        'Driving License', 
                        'driving_license', 
                        _drivingLicensePath
                      ),
                      _buildDocumentUpload(
                        'Vehicle Logbook', 
                        'vehicle_logbook', 
                        _vehicleLogbookPath
                      ),
                      _buildDocumentUpload(
                        'Insurance Certificate', 
                        'insurance_cert', 
                        _insuranceCertPath
                      ),
                      _buildDocumentUpload(
                        'NTVA License', 
                        'ntva_license', 
                        _ntvaLicensePath
                      ),
                      _buildDocumentUpload(
                        'PSV Badge', 
                        'psv_badge', 
                        _psvBadgePath
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Join Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}