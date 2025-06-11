import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../utils/constants.dart';

class SaccoAdminRequestPage extends StatefulWidget {
  const SaccoAdminRequestPage({super.key});

  @override
  State<SaccoAdminRequestPage> createState() => _SaccoAdminRequestPageState();
}

class _SaccoAdminRequestPageState extends State<SaccoAdminRequestPage> {
  final _formKey = GlobalKey<FormState>();
  int? selectedSaccoId;
  List<dynamic> saccos = [];
  bool isLoading = false;
  bool enteringNewSacco = false;

  // New sacco form controllers
  final _saccoName = TextEditingController();
  final _location = TextEditingController();
  final _dateEstablished = TextEditingController();
  final _regNumber = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSaccos();
  }

  Future<void> fetchSaccos() async {
    try {
      final result = await ApiService.getSaccos();
      setState(() {
        saccos = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch saccos: $e')),
      );
    }
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ApiService.submitSaccoAdminRequest(
        saccoId: enteringNewSacco ? null : selectedSaccoId,
        saccoName: enteringNewSacco ? _saccoName.text.trim() : null,
        location: enteringNewSacco ? _location.text.trim() : null,
        dateEstablished: enteringNewSacco ? _dateEstablished.text.trim() : null,
        registrationNumber: enteringNewSacco ? _regNumber.text.trim() : null,
        contactNumber: enteringNewSacco ? _contact.text.trim() : null,
        email: enteringNewSacco ? _email.text.trim() : null,
        website: enteringNewSacco ? _website.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Admin Access"),
        backgroundColor: AppColors.carafe,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text("Enter new Sacco details"),
                value: enteringNewSacco,
                onChanged: (val) {
                  setState(() => enteringNewSacco = val);
                },
              ),

              if (!enteringNewSacco)
                DropdownButtonFormField<int>(
                  value: selectedSaccoId,
                  items: saccos.map<DropdownMenuItem<int>>((sacco) {
                    return DropdownMenuItem<int>(
                      value: sacco['id'],
                      child: Text(sacco['name']),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: "Select Sacco"),
                  onChanged: (value) => setState(() => selectedSaccoId = value),
                  validator: (value) =>
                      value == null ? "Please select a sacco" : null,
                ),

              if (enteringNewSacco) ...[
                TextFormField(
                  controller: _saccoName,
                  decoration: const InputDecoration(labelText: 'Sacco Name'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _dateEstablished,
                  decoration: const InputDecoration(labelText: 'Date Established (YYYY-MM-DD)'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _regNumber,
                  decoration: const InputDecoration(labelText: 'Registration Number'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _contact,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                TextFormField(
                  controller: _website,
                  decoration: const InputDecoration(labelText: 'Website (optional)'),
                ),
              ],

              const SizedBox(height: AppDimensions.paddingLarge),

              ElevatedButton(
                onPressed: isLoading ? null : submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.carafe,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Request"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
