/// Konfigurasi koneksi ke Supabase.
/// URL dan Anon Key diambil dari Supabase Dashboard → Settings → API.

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi koneksi ke Supabase mengambil dari file .env yang aman.
class SupabaseConfig {
  SupabaseConfig._();

  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
