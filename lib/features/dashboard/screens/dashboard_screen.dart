import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/features/user/screens/profile_screen.dart';
import 'package:vayu_flutter_app/shared/mixins/refreshable_dashboard.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/features/dashboard/widgets/bottom_navigation.dart';
import 'package:vayu_flutter_app/features/dashboard/widgets/trip_overview.dart';
import 'package:vayu_flutter_app/features/dashboard/widgets/quick_actions.dart';
import 'package:vayu_flutter_app/features/dashboard/widgets/recent_activity.dart';
import 'package:vayu_flutter_app/features/trips/screens/all_trips_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RefreshableDashboard {
  int _currentIndex = 0;
  final GlobalKey<TripOverviewState> _tripOverviewKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  final GlobalKey<AllTripsScreenState> _allTripsScreenKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  Future<void> _refreshDashboard() async {
    await _tripOverviewKey.currentState?.refreshTrips();
    await _allTripsScreenKey.currentState?.refreshTrips();
    // Add more refresh logic for other widgets if needed
  }

  void _refreshAllTripsScreen() {
    _allTripsScreenKey.currentState?.refreshTrips();
  }

  @override
  void refreshDashboard() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshDashboard,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardContent(
              tripOverviewKey: _tripOverviewKey,
              scrollController: _scrollController,
            ),
            AllTripsScreen(
              key: _allTripsScreenKey,
              isInDashboard: true,
              parentScrollController: _scrollController,
            ),
            const Placeholder(), // Expenses screen
            const Placeholder(), // Chat screen
            const ProfileScreen(), // Profile screen
          ],
        ),
      ),
      bottomNavigationBar: VayuBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            // Assuming index 1 is for the AllTripsScreen
            _refreshAllTripsScreen();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class DashboardContent extends StatelessWidget {
  final GlobalKey<TripOverviewState> tripOverviewKey;
  final ScrollController scrollController;

  const DashboardContent({
    super.key,
    required this.tripOverviewKey,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: TripOverview(key: tripOverviewKey),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: QuickActions(
              onDashboardRefreshNeeded: () {
                tripOverviewKey.currentState?.refreshTrips();
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: RecentActivity(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    var authNotifier = getIt<AuthNotifier>();
    final user = authNotifier.currentUser;
    final userName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName
        : 'Traveler';

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready for your next adventure?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),
      ],
    );
  }
}
