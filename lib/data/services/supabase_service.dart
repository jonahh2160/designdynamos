import  'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/env/env.dart';


class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supbaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  static Future<AuthResponse> signInWithTestUser(){
    return client.auth.signInWithPassword(
      email: 'elongsworth37@gmail.com',
      password: 'test123',
    );
  }

  static Future<void> signOut() => client.auth.signOut();


}