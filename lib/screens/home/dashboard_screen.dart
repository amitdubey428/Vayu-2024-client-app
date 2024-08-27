import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/widgets/app_bar.dart';
import 'package:vayu_flutter_app/widgets/bottom_navigation.dart';
import 'package:vayu_flutter_app/widgets/trip_overview.dart';
import 'package:vayu_flutter_app/widgets/quick_actions.dart';
import 'package:vayu_flutter_app/widgets/recent_activity.dart';
import 'dart:developer' as developer;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<TripOverviewState> _tripOverviewKey = GlobalKey();

  Future<void> _refreshDashboard() async {
    await _tripOverviewKey.currentState?.refreshTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VayuAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TripOverview(key: _tripOverviewKey),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: QuickActions(),
              ),
              const SizedBox(height: 24), // Add space before Recent Activity
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: RecentActivity(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VayuBottomNavigation(),
    );
  }

  Widget _buildWelcomeSection() {
    var authNotifier = getIt<AuthNotifier>();
    final user = authNotifier.currentUser;
    final userName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName
        : 'Traveler';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready for your next adventure?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
