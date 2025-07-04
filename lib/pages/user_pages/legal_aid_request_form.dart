import 'package:flutter/material.dart';
import 'package:is_project_1/models/profile_response.dart';
import 'package:is_project_1/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/legal_aid_requests.dart';
import '../../services/legal_aid_service.dart';
import 'legal_requests.dart';

class LegalAidRequestForm extends StatefulWidget {
  final LegalAidProvider? selectedProvider;

  const LegalAidRequestForm({Key? key, this.selectedProvider})
    : super(key: key);

  @override
  _LegalAidRequestFormState createState() => _LegalAidRequestFormState();
}

class _LegalAidRequestFormState extends State<LegalAidRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _legalNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProfileResponse? profile;

  List<LegalAidProvider> _allProviders = [];
  LegalAidProvider? _selectedProvider;
  String? _selectedExpertiseArea;
  bool _isLoadingProviders = false;
  bool _isSubmitting = false;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.selectedProvider;
    if (_selectedProvider != null) {
      _selectedExpertiseArea = _selectedProvider!.primaryExpertise;
    }
    _loadAllProviders();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Load profile data
      final profileData = await ApiService.getProfile();

      setState(() {
        profile = profileData;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllProviders() async {
    if (widget.selectedProvider != null)
      return; // Don't load if provider is already selected

    setState(() {
      _isLoadingProviders = true;
    });

    try {
      final providers = await LegalAidService.getLegalAidProviders();
      setState(() {
        _allProviders = providers;
        _isLoadingProviders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProviders = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading providers: $e')));
    }
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _nationalIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request Legal Aid',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.balance, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Legal Aid Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill out the form below to request legal assistance from qualified professionals.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Selected Provider Card (if provider is pre-selected)
              if (_selectedProvider != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _selectedProvider!.profileImage != null
                            ? NetworkImage(_selectedProvider!.profileImage!)
                            : null,
                        backgroundColor: Colors.green[100],
                        child: _selectedProvider!.profileImage == null
                            ? Icon(
                                Icons.person,
                                color: Colors.green[600],
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Provider',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _selectedProvider!.fullName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                            Text(
                              _selectedProvider!.allExpertiseAreas,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedProvider = null;
                            _selectedExpertiseArea = null;
                          });
                        },
                        child: Text(
                          'Change',
                          style: TextStyle(color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Legal Name Field
              _buildLabel('Legal Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _legalNameController,
                decoration: _buildInputDecoration('Enter your full legal name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your legal name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // National ID Field
              _buildLabel('National ID Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nationalIdController,
                decoration: _buildInputDecoration(
                  'Enter your national ID number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your national ID number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Request Title Field
              _buildLabel('Request Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(
                  'Brief title for your request',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a request title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description Field
              _buildLabel('Detailed Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration(
                  'Describe your legal situation in detail...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a detailed description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Please provide details about your legal situation and the type of assistance needed.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const SizedBox(height: 20),

              // Provider Selection (only show if no provider is pre-selected)
              if (_selectedProvider == null) ...[
                _buildLabel('Select Legal Aid Provider'),
                const SizedBox(height: 8),
                _isLoadingProviders
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<LegalAidProvider>(
                        value: _selectedProvider,
                        decoration: _buildInputDecoration(
                          'Select a legal aid provider',
                        ),
                        items: _allProviders.map((provider) {
                          return DropdownMenuItem<LegalAidProvider>(
                            value: provider,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  provider.primaryExpertise,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (LegalAidProvider? newValue) {
                          setState(() {
                            _selectedProvider = newValue;
                            _selectedExpertiseArea = newValue?.primaryExpertise;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a legal aid provider';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 20),
              ],

              // Expertise Area (read-only if provider is selected)
              if (_selectedProvider != null) ...[
                _buildLabel('Expertise Area'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedProvider!.allExpertiseAreas,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');

        if (userId == null) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to submit a request.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        print("Submitting request with providerId: ${_selectedProvider!.id}");

        final createdRequest = await LegalAidService.createLegalAidRequest(
          userId: userId,
          providerId: _selectedProvider!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        setState(() {
          _isSubmitting = false;
        });

        if (createdRequest != null) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Request Submitted'),
                content: Text(
                  'Your legal aid request has been submitted successfully to ${_selectedProvider!.fullName}. You will be contacted soon.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LegalRequestsScreen(),
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExpertiseChip(String expertise, String description) {
    return Chip(
      label: Text(expertise),
      backgroundColor: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: TextStyle(color: Colors.blue[800], fontSize: 14),
      onDeleted: () {
        // Handle chip deletion if needed
      },
    );
  }
}
