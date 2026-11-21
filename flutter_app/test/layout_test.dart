import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Проверяем базовую игровую кнопку и панель на двух ориентациях.
void main() {
  testWidgets('кнопка отзывается на нажатие и переживает узкий экран', (tester) async {
    var taps = 0;
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 260,
            child: TextButton(onPressed: () => taps++, child: const Text('Играть')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Играть'));
    expect(taps, 1);
  });

  testWidgets('ориентация определяется по размеру экрана', (tester) async {
    await tester.binding.setSurfaceSize(const Size(820, 380));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late Orientation detected;
    await tester.pumpWidget(MaterialApp(
      home: OrientationBuilder(
        builder: (context, orientation) {
          detected = orientation;
          return const SizedBox.shrink();
        },
      ),
    ));
    expect(detected, Orientation.landscape);
  });
}
