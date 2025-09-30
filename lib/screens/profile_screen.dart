import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../utils/crypto_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _record;
  String? _verificationStatus;

  // Controllers for editable fields
  final _fullName = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _currentAddress = TextEditingController();
  String _participationArea = '';
  final _occupation = TextEditingController();
  String _policeStation = '';
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

  final List<String> validOptions = [
    'Select Police Station',
    'KALWA POLICE STATION',
    'MUMBRA POLICE STATION',
    'NAUPADA POLICE STATION',
    'RABODI POLICE STATION',
    'SHILDOIGHAR POLICE STATION',
    'THANENAGAR POLICE STATION',
    'BHIWANDI POLICE STATION',
    'BHOIWADA POLICE STATION',
    'KONGAON POLICE STATION',
    'NARPOLI POLICE STATION',
    'NIZAMPURA POLICE STATION',
    'SHANTINAGAR POLICE STATION',
    'BAZARPETH POLICE STATION',
    'DOMBIWALI POLICE STATION',
    'KHADAKPADA POLICE STATION',
    'KOLSHEWADI POLICE STATION',
    'MAHATMA PHULE CHOUK POLICE STATION',
    'MANPADA POLICE STATION',
    'TILAKNAGAR POLICE STATION',
    'VISHNUNAGAR POLICE STATION',
    'AMBARNATH POLICE STATION',
    'BADALAPUR EAST POLICE STATION',
    'BADALAPUR WEST POLICE STATION',
    'CETRAL POLICE STATION',
    'HILLLINE POLICE STATION',
    'SHIVAJINAGAR POLICE STATION',
    'ULHASNAGAR POLICE STATION',
    'VITTHALWADI POLICE STATION',
    'CHITALSAR POLICE STATION',
    'KAPURBAWADI POLICE STATION',
    'KASARWADAWALI POLICE STATION',
    'KOPARI POLICE STATION',
    'SHRINAGAR POLICE STATION',
    'VARTAKNAGAR POLICE STATION',
    'WAGALE ESTATE POLICE STATION'
  ];

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
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final res = await Supabase.instance.client
          .from('registrations')
          .select()
          .ilike('email', email)
          .order('created_at', ascending: false)
          .limit(1);

      if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
        _record = res.first as Map<String, dynamic>;
        _verificationStatus = _record!['verification_status']?.toString();
        _fullName.text = (_record!['full_name'] ?? '').toString();
        _permanentAddress.text = (_record!['permanent_address'] ?? '').toString();
        _currentAddress.text = (_record!['current_address'] ?? '').toString();
        _participationArea = (_record!['participation_area'] ?? '').toString();
        _occupation.text = (_record!['occupation'] ?? '').toString();
        _policeStation = (_record!['police_station'] ?? '').toString();
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
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) return;
      final update = {
        'full_name': _fullName.text,
        'permanent_address': _permanentAddress.text,
        'current_address': _currentAddress.text,
        'participation_area': _participationArea,
        'occupation': _occupation.text,
        'police_station': _policeStation,
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
          .ilike('email', email);
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
            onPressed: () {
              final normalized = (_verificationStatus ?? '').trim().toLowerCase();
              if (normalized == 'verified' || normalized == 'approve' || normalized == 'approved') {
                context.push('/dashboard');
              } else {
                context.push('/status');
              }
            },
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
                  _dropdownField('Police Station', _policeStation, validOptions, (v) => setState(() => _policeStation = v)),
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
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.push('/availability-status'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text(' Availability History', style: TextStyle(color: Colors.white)),
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
          isExpanded: true,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
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
