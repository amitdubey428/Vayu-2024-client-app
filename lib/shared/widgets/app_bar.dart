import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';

class VayuAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VayuAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(
        'Vayu',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications,
              color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),
        IconButton(
          icon: Icon(Icons.person,
              color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () {
            Navigator.pushNamed(context, Routes.profile);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
