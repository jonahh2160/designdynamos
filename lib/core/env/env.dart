class Env {
  static const supabaseUrl = 
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const supbaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}