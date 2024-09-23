// lib/blocs/user/user_event.dart

import 'package:equatable/equatable.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {}

class UpdateUser extends UserEvent {
  final UserModel user;

  const UpdateUser(this.user);

  @override
  List<Object> get props => [user];
}

class DeleteUser extends UserEvent {}
