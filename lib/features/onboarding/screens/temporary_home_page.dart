import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';

class TemporaryHomePage extends StatelessWidget {
  const TemporaryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Use Provider to access AuthNotifier and call logout
                  await context.read<AuthNotifier>().logout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
