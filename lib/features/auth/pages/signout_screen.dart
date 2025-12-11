import 'package:designdynamos/features/auth/pages/login_page.dart';
import "package:flutter/material.dart";
import 'package:designdynamos/data/services/supabase_service.dart';

class SignOutScreen extends StatelessWidget {
  const SignOutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await SupabaseService.client.auth.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: Text('Sign Out'),
        ),
      ),
    );
  }
}
