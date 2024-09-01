import 'package:flutter/material.dart';

mixin RefreshableDashboard<T extends StatefulWidget> on State<T> {
  void refreshDashboard();
}
