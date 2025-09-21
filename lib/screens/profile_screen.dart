import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../utils/crypto_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _record;

  // Controllers for editable fields
  final _fullName = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _currentAddress = TextEditingController();
  String _participationArea = '';
  final _occupation = TextEditingController();
  final _policeStation = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _alternateMobileNumber = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _collegeDetails = TextEditingController();
  String _gender = '';
  final _qualification = TextEditingController();
  final _ngoAffiliation = TextEditingController();
  final _availableTime = TextEditingController();
  final _bloodGroup = TextEditingController();
  String _willingToWork = '';

  // Read-only
  final _email = TextEditingController();
  final _identityNumbers = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final emailLower = user.email?.toLowerCase();
      if (emailLower == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final res = await Supabase.instance.client
          .from('registrations')
          .select()
          .ilike('email', emailLower)
          .order('created_at', ascending: false)
          .limit(1);

      if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
        _record = res.first as Map<String, dynamic>;
        _fullName.text = (_record!['full_name'] ?? '').toString();
        _permanentAddress.text = (_record!['permanent_address'] ?? '').toString();
        _currentAddress.text = (_record!['current_address'] ?? '').toString();
        _participationArea = (_record!['participation_area'] ?? '').toString();
        _occupation.text = (_record!['occupation'] ?? '').toString();
        _policeStation.text = (_record!['police_station'] ?? '').toString();
        _mobileNumber.text = CryptoHelper.decryptText((_record!['mobile_number'] ?? '').toString());
        _alternateMobileNumber.text = CryptoHelper.decryptText((_record!['alternate_mobile_number'] ?? '').toString());
        _dateOfBirth.text = (_record!['date_of_birth'] ?? '').toString();
        _collegeDetails.text = (_record!['college_details'] ?? '').toString();
        _gender = (_record!['gender'] ?? '').toString();
        _qualification.text = (_record!['qualification'] ?? '').toString();
        _ngoAffiliation.text = (_record!['ngo_affiliation'] ?? '').toString();
        _availableTime.text = (_record!['available_time'] ?? '').toString();
        _bloodGroup.text = (_record!['blood_group'] ?? '').toString();
        _willingToWork = (_record!['willing_to_work'] ?? '').toString();
        _email.text = (_record!['email'] ?? '').toString();
        _identityNumbers.text = CryptoHelper.decryptAadhaarInIdentityString((_record!['identity_numbers'] ?? '').toString());
      }
    } catch (e) {
      // ignore but show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _loading = true);
      final user = Supabase.instance.client.auth.currentUser;
      final emailLower = user?.email?.toLowerCase();
      if (emailLower == null) return;
      final update = {
        'full_name': _fullName.text,
        'permanent_address': _permanentAddress.text,
        'current_address': _currentAddress.text,
        'participation_area': _participationArea,
        'occupation': _occupation.text,
        'police_station': _policeStation.text,
        'mobile_number': CryptoHelper.encryptText(_mobileNumber.text),
        'alternate_mobile_number': _alternateMobileNumber.text.isNotEmpty ? CryptoHelper.encryptText(_alternateMobileNumber.text) : null,
        'date_of_birth': _dateOfBirth.text, // assume already ISO
        'college_details': _collegeDetails.text.isNotEmpty ? _collegeDetails.text : null,
        'gender': _gender,
        'qualification': _qualification.text,
        'ngo_affiliation': _ngoAffiliation.text.isNotEmpty ? _ngoAffiliation.text : null,
        'available_time': _availableTime.text,
        'blood_group': _bloodGroup.text,
        'willing_to_work': _willingToWork,
      };
      await Supabase.instance.client
          .from('registrations')
          .update(update)
          .ilike('email', emailLower);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  String _mapEnumToParticipation(String enumValue) {
    switch (enumValue) {
      case 'traffic_management':
        return 'Traffic Management';
      case 'school_awareness':
        return 'School/College Awareness Programs';
      case 'senior_citizens':
        return 'Senior Citizen Visits';
      case 'social_media_volunteer':
        return 'Social Media Promotion';
      case 'crowd_management':
        return 'Festival Crowd Management';
      default:
        return 'Traffic Management';
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _permanentAddress.dispose();
    _currentAddress.dispose();
    _occupation.dispose();
    _policeStation.dispose();
    _mobileNumber.dispose();
    _alternateMobileNumber.dispose();
    _dateOfBirth.dispose();
    _collegeDetails.dispose();
    _qualification.dispose();
    _ngoAffiliation.dispose();
    _availableTime.dispose();
    _bloodGroup.dispose();
    _email.dispose();
    _identityNumbers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => context.push('/status'),
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.purple),
            onPressed: _loading ? null : _save,
            tooltip: 'Save',
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _readonlyField('Email', _email.text),
                  _readonlyField('Identity Numbers', _identityNumbers.text),
                  const SizedBox(height: 12),
                  _editField('Full Name', _fullName),
                  _editField('Permanent Address', _permanentAddress, maxLines: 2),
                  _editField('Current Address', _currentAddress, maxLines: 2),
                  _dropdownField('Participation Area', _mapEnumToParticipation(_participationArea), [
                    'Traffic Management',
                    'School/College Awareness Programs',
                    'Senior Citizen Visits',
                    'Social Media Promotion',
                    'Festival Crowd Management'
                  ], (v) => setState(() => _participationArea = _mapParticipationToEnum(v))),
                  _editField('Occupation', _occupation),
                  _editField('Police Station', _policeStation),
                  _editField('Mobile Number', _mobileNumber, keyboardType: TextInputType.phone),
                  _editField('Alternate Mobile Number', _alternateMobileNumber, keyboardType: TextInputType.phone),
                  _editField('Date of Birth (YYYY-MM-DD)', _dateOfBirth),
                  _editField('College Details', _collegeDetails),
                  _dropdownField('Gender', _gender, ['Male', 'Female', 'Prefer not to say'], (v) => setState(() => _gender = v)),
                  _editField('Qualification', _qualification),
                  _editField('NGO Affiliation', _ngoAffiliation),
                  _editField('Available Time', _availableTime),
                  _editField('Blood Group', _bloodGroup),
                  _dropdownField('Willing to Work', _willingToWork, ['Yes', 'No'], (v) => setState(() => _willingToWork = v)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value.isEmpty ? '-' : value),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _editField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dropdownField(String label, String current, List<String> options, ValueChanged<String> onChanged) {
    final value = options.contains(current) ? current : (options.isNotEmpty ? options.first : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
