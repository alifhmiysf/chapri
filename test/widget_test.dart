import 'package:flutter_test/flutter_test.dart';
import 'package:chapri/app.dart'; // Sesuaikan dengan lokasi file ChapriApp Anda

void main() {
  testWidgets('Aplikasi ChapriApp berhasil dimuat', (WidgetTester tester) async {
    // Memuat ChapriApp dari file app.dart
    await tester.pumpWidget(const ChapriApp());

    // Memastikan bahwa widget ChapriApp ada di dalam tree
    expect(find.byType(ChapriApp), findsOneWidget);
  });
}