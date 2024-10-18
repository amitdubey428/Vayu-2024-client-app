// lib/features/user/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/blocs/user/user_bloc.dart';
import 'package:vayu_flutter_app/blocs/user/user_event.dart';
import 'package:vayu_flutter_app/blocs/user/user_state.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/features/user/screens/edit_profile_screen.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserBloc>()..add(LoadUser()),
      child: const ProfileContent(),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const CustomLoadingIndicator(message: 'Loading profile...');
          } else if (state is UserLoaded) {
            return _buildProfileContent(context, state.user);
          } else if (state is UserError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, user),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user),
              _buildInfoSection(user),
              _buildInterestsSection(user),
              _buildAccountInfoSection(user),
              _buildActionButtons(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(user.fullName ?? 'Profile',
            style: const TextStyle(color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade700, Colors.teal.shade500],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => _navigateToEditProfile(context, user),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.teal.shade200,
            child: Text(
              user.fullName?.isNotEmpty == true
                  ? user.fullName!.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'Name not set',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email ?? 'Email not set',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserModel user) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.phone, 'Phone', user.phoneNumber),
            _buildInfoTile(Icons.cake, 'Birthday', _formatDate(user.birthDate)),
            _buildInfoTile(
                Icons.work, 'Occupation', user.occupation ?? 'Not set'),
            _buildInfoTile(
                Icons.location_on,
                'Location',
                '${user.country ?? ''}${user.country != null && user.state != null ? ', ' : ''}${user.state ?? ''}'
                    .trim()),
            _buildInfoTile(Icons.visibility, 'Profile Visibility',
                user.visibleToPublic ? 'Public' : 'Private'),
            _buildInfoTile(Icons.pie_chart, 'Profile Completion',
                '${user.profileCompletion}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSmallInfoTile(Icons.access_time, 'Last Login',
                _formatDateTime(user.lastLogin)),
            _buildSmallInfoTile(Icons.calendar_today, 'Account Created',
                _formatDateTime(user.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $value',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMMM d, yyyy').format(date.toLocal());
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not available';

    DateTime? dt;
    if (dateTime is DateTime) {
      dt = dateTime;
    } else if (dateTime is String) {
      try {
        dt = DateTime.parse(dateTime);
      } catch (e) {
        return 'Invalid date';
      }
    }

    if (dt == null) return 'Invalid date';

    return DateFormat('MMMM d, yyyy - h:mm a').format(dt.toLocal());
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(UserModel user) {
    if (user.interests == null || user.interests!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests!
                  .map((interest) => Chip(
                        label: Text(interest),
                        backgroundColor: Colors.teal.shade100,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _showDeleteAccountDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Delete Account', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, UserModel user) {
    final userBloc = context.read<UserBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: userBloc,
          child: EditProfileScreen(user: user),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<UserBloc>().add(DeleteUser());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await getIt<AuthNotifier>().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.signInSignUpPage);
      }
    } catch (e) {
      SnackbarUtil.showSnackbar('Failed to logout: $e',
          type: SnackbarType.error);
    }
  }
}
