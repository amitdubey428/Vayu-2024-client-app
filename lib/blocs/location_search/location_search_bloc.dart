import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';

// Events
abstract class LocationSearchEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SearchLocation extends LocationSearchEvent {
  final String query;
  SearchLocation(this.query);

  @override
  List<Object> get props => [query];
}

class ClearSearchResults extends LocationSearchEvent {} // Add this new event

// States
abstract class LocationSearchState extends Equatable {
  @override
  List<Object> get props => [];
}

class LocationSearchInitial extends LocationSearchState {}

class LocationSearchLoading extends LocationSearchState {}

class LocationSearchLoaded extends LocationSearchState {
  final List<Map<String, dynamic>> results;
  LocationSearchLoaded(this.results);

  @override
  List<Object> get props => [results];
}

class LocationSearchError extends LocationSearchState {
  final String message;
  LocationSearchError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class LocationSearchBloc
    extends Bloc<LocationSearchEvent, LocationSearchState> {
  final TripService _tripService;

  LocationSearchBloc(this._tripService) : super(LocationSearchInitial()) {
    on<SearchLocation>(_onSearchLocation);
    on<ClearSearchResults>(_onClearSearchResults);
  }

  Future<void> _onSearchLocation(
    SearchLocation event,
    Emitter<LocationSearchState> emit,
  ) async {
    emit(LocationSearchLoading());
    try {
      final results = await _tripService.searchLocations(event.query);
      emit(LocationSearchLoaded(results));
    } catch (e) {
      emit(LocationSearchError(e.toString()));
    }
  }

  void _onClearSearchResults(
      ClearSearchResults event, Emitter<LocationSearchState> emit) {
    emit(LocationSearchInitial());
  }
}
