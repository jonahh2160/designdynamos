import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/core/env/env.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
  }

  static Future<AuthResponse> signInWithTestUser() {
    return client.auth.signInWithPassword(
      //elongsworth37@gmail.com or edmundlongsworthwork@gmail.com
      email: 'edmundlongsworthwork@gmail.com',
      password: 'test321',
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static SupabaseClient get client => Supabase.instance.client;
}
