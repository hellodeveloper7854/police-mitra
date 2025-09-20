import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _currentAddressController = TextEditingController();
  String _participation = 'Traffic Management';
  String _policeStation = 'Select Police Station';
  String _occupation = 'Select Occupation';
  final _mobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _academicDetailsController = TextEditingController();
  final _panCardController = TextEditingController();
  final _aadharCardController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _gender = 'Male';
  bool _accepted1 = false;
  bool _accepted2 = false;
  bool _accepted3 = false;
  bool _accepted4 = false;

  @override
  void initState() {
    super.initState();
    // Ensure initial values are valid
    if (!['Select Occupation', 'Service/Job', 'Business', 'Student', 'House Wife', 'Unemployed'].contains(_occupation)) {
      _occupation = 'Select Occupation';
    }
    if (!['Traffic Management', 'Visiting Schools and Colleges to create awareness through PPT on various social topics', 'Visiting Senior Citizens in your Vicinity/Area', 'Working as Volunteer to Promote the Social Media Content shared by Local Police station', 'Crowd management during festival season'].contains(_participation)) {
      _participation = 'Traffic Management';
    }
    if (!['Yes', 'No'].contains(_willingToWork)) {
      _willingToWork = 'Yes';
    }
    if (!['Male', 'Female', 'Prefer not to say'].contains(_gender)) {
      _gender = 'Male';
    }
    if (!['Select Police Station', 'Ambernath', 'Badalpur(E)', 'Badalpur(W)', 'Bazarpeth', 'Bhiwandi City', 'Bhoiwada', 'Central', 'Dombivli(Ramnagar)', 'HillLine', 'Kalwa', 'Kapurbawadi', 'Khadakpada', 'Kholsewadi', 'Kongaon', 'Kopari', 'Mahatma Phule Chowk', 'Manpada', 'Mumbra', 'Narpoli', 'Naupada', 'Nizampura', 'Rabodi', 'Shanti Nagar', 'Shil DyaGhar', 'Shivaji Nagar', 'Shrinagar', 'Thane Nagar', 'Tilak Nagar', 'Ulhasnagar', 'Vartak Nagar', 'Vishnu Nagar', 'Vitthalwadi', 'Wagle Estate'].contains(_policeStation)) {
      _policeStation = 'Select Police Station';
    }
    if (!['Select Blood Group', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(_bloodGroup)) {
      _bloodGroup = 'Select Blood Group';
    }
    if (!['Select Day', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].contains(_selectedDay)) {
      _selectedDay = 'Select Day';
    }
  }
  final _qualificationController = TextEditingController();
  final _ngoController = TextEditingController();
  final _timeController = TextEditingController();
  String _bloodGroup = 'Select Blood Group';
  String _selectedDay = 'Select Day';
  File? _selectedImage;
  String _willingToWork = 'Yes';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _mobileController.dispose();
    _alternateMobileController.dispose();
    _dobController.dispose();
    _collegeNameController.dispose();
    _academicDetailsController.dispose();
    _panCardController.dispose();
    _aadharCardController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _qualificationController.dispose();
    _ngoController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'पोलिस मित्र',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Create Account Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Enroll for ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Police Mitra',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Full Name Field
                  _buildTextField(
                    controller: _fullNameController,
                    hintText: 'Enter Full Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // Permanent Address Field
                  _buildTextField(
                    controller: _permanentAddressController,
                    hintText: 'Enter Permanent Address',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your permanent address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // Current Address Field
                  _buildTextField(
                    controller: _currentAddressController,
                    hintText: 'Enter Current Address',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // Participation Field
                  _buildParticipationDropdown(),
                  const SizedBox(height: 15),
                  // Occupation Field
                  _buildOccupationDropdown(),
                  const SizedBox(height: 15),
                  // Police Station Field
                  _buildPoliceStationDropdown(),
                  const SizedBox(height: 15),
                  // Mobile and Alternate Mobile Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on small screens
                        return Column(
                          children: [
                            _buildTextField(
                              controller: _mobileController,
                              hintText: 'Mobile Number',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _alternateMobileController,
                              hintText: 'Alternate Mobile Number',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        );
                      } else {
                        // Row layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _mobileController,
                                hintText: 'Mobile Number',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                controller: _alternateMobileController,
                                hintText: 'Alternate Mobile Number',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // DOB Field
                  _buildTextField(
                    controller: _dobController,
                    hintText: 'Date Of Birth (DD/MM/YYYY)',
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _dobController.text =
                            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your date of birth';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // College Name and Academic Details Fields (conditional)
                  if (_occupation == 'Student') ...[
                    _buildTextField(
                      controller: _collegeNameController,
                      hintText: 'Enter Name of College',
                      validator: (value) {
                        if (_occupation == 'Student' && (value == null || value.isEmpty)) {
                          return 'Please enter your college name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _academicDetailsController,
                      hintText: 'Enter Academic Details',
                      validator: (value) {
                        if (_occupation == 'Student' && (value == null || value.isEmpty)) {
                          return 'Please enter your academic details';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                  // Pan Card and Aadhar Card Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on small screens
                        return Column(
                          children: [
                            // _buildTextField(
                            //   controller: _panCardController,
                            //   hintText: 'Pan Card Number',
                            //   validator: (value) {
                            //     if (value == null || value.isEmpty) {
                            //       return 'Please enter PAN card number';
                            //     }
                            //     return null;
                            //   },
                            // ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _aadharCardController,
                              hintText: 'Aadhar Card Number',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Aadhar card number';
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                      } else {
                        // Row layout for larger screens
                        return Row(
                          children: [
                            // Expanded(
                            //   child: _buildTextField(
                            //     controller: _panCardController,
                            //     hintText: 'Pan Card Number',
                            //     validator: (value) {
                            //       if (value == null || value.isEmpty) {
                            //         return 'Please enter PAN card number';
                            //       }
                            //       return null;
                            //     },
                            //   ),
                            // ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                controller: _aadharCardController,
                                hintText: 'Aadhar Card Number',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Aadhar card number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // Qualification Field
                  _buildTextField(
                    controller: _qualificationController,
                    hintText: 'Enter Qualification',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your qualification';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // NGO/Social Institution Field
                  _buildTextField(
                    controller: _ngoController,
                    hintText: 'Are you working with any NGO/Social Institution? (Mention name)',
                  ),
                  const SizedBox(height: 15),
                  // Day and Time Availability Field
                  const Text(
                    'Specify Day and Time to work as Police Mitra/Volunteer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on small screens
                        return Column(
                          children: [
                            _buildDayDropdown(),
                            const SizedBox(height: 15),
                            _buildTimeField(),
                          ],
                        );
                      } else {
                        // Row layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _buildDayDropdown(),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTimeField(),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // Blood Group Field
                  _buildBloodGroupDropdown(),
                  const SizedBox(height: 15),
                  // Willing to Work Dropdown
                  // _buildWillingToWorkDropdown(),
                  // const SizedBox(height: 15),
                  // Email and Gender Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on small screens
                        return Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'Enter Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildDropdownField(),
                          ],
                        );
                      } else {
                        // Row layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                hintText: 'Enter Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildDropdownField(),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Enter Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        bool accepted = await _showAcceptanceDialog();
                        if (!accepted) return;
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            final response = await Supabase.instance.client.auth.signUp(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                            if (response.user != null && Supabase.instance.client.auth.currentSession != null) {
                              await Supabase.instance.client.from('registrations').insert({
                                'full_name': _fullNameController.text,
                                'permanent_address': _permanentAddressController.text,
                                'current_address': _currentAddressController.text,
                                'participation_area': _mapParticipationToEnum(_participation),
                                'occupation': _occupation,
                                'police_station': _policeStation,
                                'mobile_number': _mobileController.text,
                                'alternate_mobile_number': _alternateMobileController.text.isNotEmpty ? _alternateMobileController.text : null,
                                'date_of_birth': _toIsoDate(_dobController.text),
                                'college_details': _occupation == 'Student' ? '${_collegeNameController.text} - ${_academicDetailsController.text}' : null,
                                'identity_numbers': 'PAN:${_panCardController.text},AADHAR:${_aadharCardController.text}',
                                'gender': _gender,
                                'qualification': _qualificationController.text,
                                'ngo_affiliation': _ngoController.text.isNotEmpty ? _ngoController.text : null,
                                'available_time': '${_selectedDay} ${_timeController.text}',
                                'blood_group': _bloodGroup,
                                'willing_to_work': _willingToWork,
                                'email': _emailController.text.trim().toLowerCase(),
                                'police_mitra_acceptance': true,
                              });
                              if (mounted) context.go('/thank-you');
                            } else if (response.user != null && Supabase.instance.client.auth.currentSession == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please verify your email, then sign in to complete registration.'),
                                  ),
                                );
                                context.go('/thank-you');
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signup failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Do you have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 
  Future<bool> _showAcceptanceDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Terms and Conditions'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Police Mitra should always maintain humility and proper attitude as this service will bridge the gap with citizens.'),
                      value: _accepted1,
                      onChanged: (value) => setState(() => _accepted1 = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Always follow code of conduct as guided.'),
                      value: _accepted2,
                      onChanged: (value) => setState(() => _accepted2 = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('For any misconduct observed there will be cancellation of membership.'),
                      value: _accepted3,
                      onChanged: (value) => setState(() => _accepted3 = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('All rights of membership reserved with Police department.'),
                      value: _accepted4,
                      onChanged: (value) => setState(() => _accepted4 = value ?? false),
                    ),
                      CheckboxListTile(
                      title: const Text('Are you willing to work as Police Mitra/Volunteer?.'),
                      value: _accepted4,
                      onChanged: (value) => setState(() => _accepted4 = value ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (_accepted1 && _accepted2 && _accepted3 && _accepted4) ? () => Navigator.of(context).pop(true) : null,
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  String _mapParticipationToEnum(String label) {
    switch (label) {
      case 'Traffic Management':
        return 'traffic_management';
      case 'School/College Awareness Programs':
        return 'school_awareness';
      case 'Senior Citizen Visits':
        return 'senior_citizens';
      case 'Social Media Promotion':
        return 'social_media_volunteer';
      case 'Festival Crowd Management':
        return 'crowd_management';
      default:
        return 'traffic_management';
    }
  }

  String _toIsoDate(String input) {
    // Expects DD/MM/YYYY from the UI and converts to YYYY-MM-DD for Supabase date type
    try {
      final parts = input.split('/');
      if (parts.length != 3) return input; // fallback unchanged if unexpected
      final dd = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      final yyyy = parts[2];
      return '$yyyy-$mm-$dd';
    } catch (_) {
      return input; // if anything goes wrong, send as-is
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _buildDropdownField() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Male', 'Female', 'Prefer not to say'];
    if (!validOptions.contains(_gender)) {
      _gender = 'Male';
    }

    return DropdownButtonFormField<String>(
      value: _gender,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Gender',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _gender = value!;
        });
      },
    );
  }

  Widget _buildOccupationDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Select Occupation', 'Service/Job', 'Business', 'Student', 'House Wife', 'Unemployed'];
    if (!validOptions.contains(_occupation)) {
      _occupation = 'Select Occupation';
    }

    return DropdownButtonFormField<String>(
      value: _occupation,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Occupation',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _occupation = value!;
        });
      },
      validator: (value) {
        if (value == null || value == 'Select Occupation') {
          return 'Please select your occupation';
        }
        return null;
      },
    );
  }

  Widget _buildParticipationDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = [
      'Traffic Management',
      'School/College Awareness Programs',
      'Senior Citizen Visits',
      'Social Media Promotion',
      'Festival Crowd Management'
    ];
    if (!validOptions.contains(_participation)) {
      _participation = 'Traffic Management';
    }

    return DropdownButtonFormField<String>(
      value: _participation,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Participation Option',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _participation = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a participation option';
        }
        return null;
      },
    );
  }

  Widget _buildWillingToWorkDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Yes', 'No'];
    if (!validOptions.contains(_willingToWork)) {
      _willingToWork = 'Yes';
    }

    return DropdownButtonFormField<String>(
      value: _willingToWork,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Are you willing to work as Police Mitra/Volunteer?',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _willingToWork = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an option';
        }
        return null;
      },
    );
  }

  Widget _buildPoliceStationDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Select Police Station',"KALWA POLICE STATION",
    "MUMBRA POLICE STATION",
    "NAUPADA POLICE STATION",
    "RABODI POLICE STATION",
    "SHILDOIGHAR POLICE STATION",
    "THANENAGAR POLICE STATION", "BHIWANDI POLICE STATION",
    "BHOIWADA POLICE STATION",
    "KONGAON POLICE STATION",
    "NARPOLI POLICE STATION",
    "NIZAMPURA POLICE STATION",
    "SHANTINAGAR POLICE STATION", "BAZARPETH POLICE STATION",
    "DOMBIWALI POLICE STATION",
    "KHADAKPADA POLICE STATION",
    "KOLSHEWADI POLICE STATION",
    "MAHATMA PHULE CHOUK POLICE STATION",
    "MANPADA POLICE STATION",
    "TILAKNAGAR POLICE STATION",
    "VISHNUNAGAR POLICE STATION","AMBARNATH POLICE STATION",
    "BADALAPUR EAST POLICE STATION",
    "BADALAPUR WEST POLICE STATION",
    "CETRAL POLICE STATION",
    "HILLLINE POLICE STATION",
    "SHIVAJINAGAR POLICE STATION",
    "ULHASNAGAR POLICE STATION",
    "VITTHALWADI POLICE STATION",  "CHITALSAR POLICE STATION",
    "KAPURBAWADI POLICE STATION",
    "KASARWADAWALI POLICE STATION",
    "KOPARI POLICE STATION",
    "SHRINAGAR POLICE STATION",
    "VARTAKNAGAR POLICE STATION",
    "WAGALE ESTATE POLICE STATION"];
    if (!validOptions.contains(_policeStation)) {
      _policeStation = 'Select Police Station';
    }

    return DropdownButtonFormField<String>(
      value: _policeStation,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Near Police Station',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _policeStation = value!;
        });
      },
      validator: (value) {
        if (value == null || value == 'Select Police Station') {
          return 'Please select a police station';
        }
        return null;
      },
    );
  }

  Widget _buildBloodGroupDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Select Blood Group', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (!validOptions.contains(_bloodGroup)) {
      _bloodGroup = 'Select Blood Group';
    }

    return DropdownButtonFormField<String>(
      value: _bloodGroup,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Blood Group',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _bloodGroup = value!;
        });
      },
      validator: (value) {
        if (value == null || value == 'Select Blood Group') {
          return 'Please select your blood group';
        }
        return null;
      },
    );
  }

  Widget _buildDayDropdown() {
    // Ensure the current value is valid, reset if not
    final validOptions = ['Select Day', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (!validOptions.contains(_selectedDay)) {
      _selectedDay = 'Select Day';
    }

    return DropdownButtonFormField<String>(
      value: _selectedDay,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select Day',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      items: validOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDay = value!;
        });
      },
      validator: (value) {
        if (value == null || value == 'Select Day') {
          return 'Please select a day';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            _timeController.text = pickedTime.format(context);
          });
        }
      },
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Select Time',
        hintStyle: const TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a time';
        }
        return null;
      },
    );
  }
}