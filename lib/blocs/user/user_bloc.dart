// lib/blocs/user/user_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/blocs/user/user_event.dart';
import 'package:vayu_flutter_app/blocs/user/user_state.dart';
import 'package:vayu_flutter_app/data/repositories/user_repository.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;
  final AuthNotifier _authNotifier;

  UserBloc()
      : _userRepository = getIt<UserRepository>(),
        _authNotifier = getIt<AuthNotifier>(),
        super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await _userRepository.getCurrentUser();
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final result = await _authNotifier.updateUserProfile(event.user);
      if (result == "success") {
        emit(UserLoaded(event.user));
      } else {
        emit(UserError(result ?? "Failed to update user"));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      await _userRepository.deleteAccount();
      emit(UserInitial());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
