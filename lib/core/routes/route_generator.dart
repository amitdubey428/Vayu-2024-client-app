// lib/routes/route_generator.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/blocs/expense/expense_bloc.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/data/repositories/expense_repository.dart';
import 'package:vayu_flutter_app/features/auth/screens/email_verification_screen.dart';
import 'package:vayu_flutter_app/features/auth/screens/phone_auth_screen.dart';
import 'package:vayu_flutter_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vayu_flutter_app/features/expenses/screens/add_edit_expense_screen.dart';
import 'package:vayu_flutter_app/features/expenses/screens/expense_details_screen.dart';
import 'package:vayu_flutter_app/features/expenses/screens/trip_expense_dashboard.dart';
import 'package:vayu_flutter_app/features/onboarding/screens/welcome.dart';
import 'package:vayu_flutter_app/features/trips/screens/add_edit_activity_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/add_edit_day_plan_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/add_edit_stay_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/all_trips_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/create_trip_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/join_trip_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/trip_detail_screen.dart';
import 'package:vayu_flutter_app/features/user/screens/edit_profile_screen.dart';
import 'package:vayu_flutter_app/features/user/screens/profile_screen.dart';
import 'route_names.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.welcomePage:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case Routes.emailVerification:
        return MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen());
      case Routes.homePage:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case Routes.tripDetails:
        final arguments = settings.arguments as Map<String, dynamic>;
        final tripId = arguments['tripId'] as int;
        final tripName = arguments['tripName'] as String;
        return MaterialPageRoute(
          builder: (_) => TripDetailScreen(tripId: tripId, tripName: tripName),
        );
      case Routes.allTrips:
        return MaterialPageRoute(builder: (_) => const AllTripsScreen());
      case Routes.createTrip:
        return MaterialPageRoute(builder: (_) => const CreateTripScreen());
      case Routes.joinTrip:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) =>
              JoinTripScreen(invitationCode: args['invitationCode']),
        );
      case Routes.addEditDayPlan:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddEditDayPlanScreen(
            tripId: args['tripId'] as int,
            dayPlan: args['dayPlan'],
          ),
        );

      case Routes.addEditStay:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddEditStayScreen(
            stay: args['stay'],
            date: args['date'] as DateTime,
            tripId: args['tripId'],
          ),
        );
      case Routes.addEditActivity:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddEditActivityScreen(
            activity: args?['activity'],
            tripId: args!['tripId'],
          ),
        );
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case Routes.editProfile:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: user),
        );
      case Routes.tripExpenseDashboard:
        final trip = settings.arguments as TripModel;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => ExpenseBloc(getIt<ExpenseRepository>()),
            child: TripExpenseDashboard(trip: trip),
          ),
        );
      case Routes.addEditExpense:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => BlocProvider<ExpenseBloc>(
            create: (context) => ExpenseBloc(getIt<ExpenseRepository>()),
            child: Builder(
              builder: (context) => AddEditExpenseScreen(
                tripId: arguments['tripId'],
                expense: arguments['expense'],
                tripParticipants: arguments['tripParticipants'] ?? [],
                expenseBloc: context.read<ExpenseBloc>(),
              ),
            ),
          ),
        );
      case Routes.expenseDetails:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ExpenseDetailsScreen(
            expense: arguments['expense'],
            tripParticipants: arguments['tripParticipants'],
            onExpenseUpdated: arguments['onExpenseUpdated'],
            expenseBloc: arguments['expenseBloc'],
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const PhoneAuthScreen());
    }
  }
}
