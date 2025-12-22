/*
  Supabase Configuration

  IMPORTANT: Add your Supabase credentials here
  You can find these in your Supabase project settings:
  1. Go to https://app.supabase.com/projects
  2. Select your project
  3. Navigate to Settings > API
  4. Copy the URL and anon key

  SECURITY: Never commit real credentials to version control!
  Use environment variables or secure storage in production.
*/

class SupabaseConfig {
  // ⚠️ TODO: Replace with your Supabase project URL
  static const String supabaseUrl = 'https://fvrramczznzvupnsyain.supabase.co';

  // ⚠️ TODO: Replace with your Supabase anon key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2cnJhbWN6em56dnVwbnN5YWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzc4MDEsImV4cCI6MjA3OTc1MzgwMX0.qvIB4WwBWe_Gb1_Cm5-g_skFyjLMgneewkJQ3Ft7_Qk';

  /// Example:
  /// static const String supabaseUrl = 'https://your-project.supabase.co';
  /// static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
