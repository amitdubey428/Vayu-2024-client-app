import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/blocs/user/user_bloc.dart';
import 'package:vayu_flutter_app/blocs/user/user_event.dart';
import 'package:vayu_flutter_app/blocs/user/user_state.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _occupationController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late DateTime? _dateOfBirth;
  late String? _gender;
  List<String> _interests = [];
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _occupationController = TextEditingController(text: widget.user.occupation);
    _countryController = TextEditingController(text: widget.user.country);
    _stateController = TextEditingController(text: widget.user.state);
    _dateOfBirth = widget.user.birthDate;
    _gender = widget.user.gender;
    _interests = List.from(widget.user.interests ?? []);
    _isPublic = widget.user.visibleToPublic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal,
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            SnackbarUtil.showSnackbar('Profile updated successfully!',
                type: SnackbarType.success);
            Navigator.pop(context);
          } else if (state is UserError) {
            SnackbarUtil.showSnackbar(
                'Failed to update profile: ${state.message}',
                type: SnackbarType.error);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildTextField(_fullNameController, 'Full Name', Icons.person),
                _buildTextField(_emailController, 'Email', Icons.email),
                _buildTextField(
                    _occupationController, 'Occupation', Icons.work),
                _buildTextField(_countryController, 'Country', Icons.flag),
                _buildTextField(_stateController, 'State', Icons.location_city),
                _buildDateOfBirthPicker(),
                _buildGenderDropdown(),
                _buildInterestsSection(),
                _buildPublicProfileSwitch(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal,
            child: Text(
              widget.user.fullName?.isNotEmpty == true
                  ? widget.user.fullName!.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.user.phoneNumber,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        controller: controller,
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        hintText: "Enter your $label",
      ),
    );
  }

  Widget _buildDateOfBirthPicker() {
    return ListTile(
      leading: const Icon(Icons.cake, color: Colors.teal),
      title: const Text('Date of Birth'),
      subtitle: Text(_dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
          : 'Not set'),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _dateOfBirth) {
          setState(() {
            _dateOfBirth = picked;
          });
        }
      },
    );
  }

  Widget _buildGenderDropdown() {
    return ListTile(
      leading: const Icon(Icons.person_outline, color: Colors.teal),
      title: const Text('Gender'),
      trailing: DropdownButton<String>(
        value: _gender,
        hint: const Text('Select'),
        onChanged: (String? newValue) {
          setState(() {
            _gender = newValue;
          });
        },
        items: <String>['Male', 'Female', 'Other', 'Prefer not to say']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Travel Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          children: [
            ..._interests.map((interest) => Chip(
                  label: Text(interest),
                  onDeleted: () {
                    setState(() {
                      _interests.remove(interest);
                    });
                  },
                )),
            ActionChip(
              label: const Text('Add'),
              onPressed: _showAddInterestDialog,
              avatar: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicProfileSwitch() {
    return SwitchListTile(
      title: const Text('Public Profile'),
      subtitle: const Text('Allow other travelers to view your profile'),
      value: _isPublic,
      onChanged: (value) {
        setState(() {
          _isPublic = value;
        });
      },
      activeColor: Colors.teal,
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _updateProfile,
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }

  void _showAddInterestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newInterest = '';
        return AlertDialog(
          title: const Text('Add a Travel Interest'),
          content: TextField(
            onChanged: (value) {
              newInterest = value;
            },
            decoration: const InputDecoration(
                hintText: "e.g., Hiking, Photography, Food"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (newInterest.isNotEmpty) {
                  setState(() {
                    _interests.add(newInterest);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateProfile() {
    final updatedUser = widget.user.copyWith(
      fullName: _fullNameController.text,
      email: _emailController.text,
      occupation: _occupationController.text,
      country: _countryController.text,
      state: _stateController.text,
      birthDate: _dateOfBirth,
      gender: _gender,
      interests: _interests,
      visibleToPublic: _isPublic,
    );

    context.read<UserBloc>().add(UpdateUser(updatedUser));
  }
}
