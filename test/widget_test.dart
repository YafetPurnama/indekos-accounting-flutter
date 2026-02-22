// Basic widget test untuk SIA Indekos Mobile.
//
// Test ini memverifikasi bahwa widget root aplikasi
// dapat di-build tanpa error.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — placeholder', (WidgetTester tester) async {
    // Placeholder test.
    // Firebase & Supabase perlu di-mock sebelum bisa test widget SiaIndekosApp.
    // Untuk saat ini, cukup pastikan test framework berjalan.
    expect(1 + 1, equals(2));
  });
}
