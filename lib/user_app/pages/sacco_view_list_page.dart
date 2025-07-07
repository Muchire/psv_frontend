import 'package:flutter/material.dart';
import 'package:psv_frontend/services/vehicle_api_service.dart';

class SaccoVehiclesPage extends StatefulWidget {
  final int? saccoId; // Optional sacco ID
  
  const SaccoVehiclesPage({Key? key, this.saccoId}) : super(key: key);

  @override
  State<SaccoVehiclesPage> createState() => _SaccoVehiclesPageState();
}

class _SaccoVehiclesPageState extends State<SaccoVehiclesPage> {
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final Map<String, dynamic> data;
      if (widget.saccoId != null) {
        // Use explicit sacco ID
        data = await VehicleOwnerService.getSaccoVehiclesById(widget.saccoId!);
      } else {
        // Auto-detect from admin
        data = await VehicleOwnerService.getSaccoVehicles();
      }
      
      setState(() {
        vehicleData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saccoId != null 
            ? 'Sacco Vehicles (ID: ${widget.saccoId})' 
            : 'My Sacco Vehicles'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading vehicles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVehicles,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (vehicleData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Column(
      children: [
        _buildSaccoInfoCard(),
        Expanded(
          child: _buildVehiclesList(),
        ),
      ],
    );
  }

  Widget _buildSaccoInfoCard() {
    final saccoInfo = vehicleData!['sacco_info'];
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saccoInfo['name'] ?? 'Unknown Sacco',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.directions_car,
                  label: 'Total Vehicles',
                  value: '${saccoInfo['total_vehicles'] ?? 0}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.check_circle,
                  label: 'Active',
                  value: '${saccoInfo['active_vehicles'] ?? 0}',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    final vehicles = vehicleData!['vehicles'] as List<dynamic>;
    
    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final isActive = vehicle['is_active'] ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        vehicle['registration_number'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVehicleDetails(vehicle),
            const SizedBox(height: 16),
            _buildOwnerInfo(vehicle),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(Map<String, dynamic> vehicle) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.category,
            label: 'Type',
            value: vehicle['vehicle_type'] ?? 'N/A',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.calendar_today,
            label: 'Year',
            value: '${vehicle['year'] ?? 'N/A'}',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.people,
            label: 'Capacity',
            value: '${vehicle['capacity'] ?? 'N/A'}',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(Map<String, dynamic> vehicle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _getInitials(vehicle['owner_name'] ?? 'Unknown'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner: ${vehicle['owner_name'] ?? 'Unknown'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (vehicle['owner_email'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    vehicle['owner_email'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (vehicle['owner_phone'] != null)
            IconButton(
              icon: const Icon(Icons.phone, size: 20),
              onPressed: () {
                // Add phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phone: ${vehicle['owner_phone']}'),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.email, size: 20),
            onPressed: () {
              // Add email functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email: ${vehicle['owner_email'] ?? 'No email'}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}