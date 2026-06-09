import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://dwyfjwwgrtdspgdaifyv.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eWZqd3dncnRkc3BnZGFpZnl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4ODA5MDEsImV4cCI6MjA5MjQ1NjkwMX0.bMdpGdBGPmnwHhe_bBp7ybgPnl5nIbbLYiLDF3UhG1g';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}