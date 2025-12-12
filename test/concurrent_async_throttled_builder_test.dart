// test/concurrent_async_throttled_builder_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  group('ConcurrentAsyncThrottledBuilder Widget Tests', () {
    testWidgets('Should execute callback when button is tapped',
        (WidgetTester tester) async {
      int executionCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop,
              onPressed: () async {
                executionCount++;
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      expect(executionCount, 0);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(executionCount, 1);
    });

    testWidgets('Should handle errors with onError callback',
        (WidgetTester tester) async {
      String? errorMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop,
              onPressed: () async {
                throw Exception('Test error');
              },
              onError: (error, stack) {
                errorMessage = error.toString();
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      expect(errorMessage, isNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(errorMessage, contains('Test error'));
    });

    testWidgets('Should call onSuccess after successful execution',
        (WidgetTester tester) async {
      bool successCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop,
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 10));
              },
              onSuccess: () {
                successCalled = true;
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      expect(successCalled, false);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(successCalled, true);
    });

    testWidgets('Should work with drop mode (default)',
        (WidgetTester tester) async {
      int executionCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop, // Explicit drop mode
              onPressed: () async {
                executionCount++;
                await Future.delayed(const Duration(milliseconds: 50));
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      // Tap multiple times rapidly
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 10));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 10));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 10));

      await tester.pumpAndSettle();

      // Only first tap should execute (others dropped)
      expect(executionCount, 1);
    });

    testWidgets('Should work with replace mode',
        (WidgetTester tester) async {
      String? lastResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.replace,
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 5));
                lastResult = 'result';
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(lastResult, 'result');
    });

    testWidgets('Should handle null onPressed gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop,
              onPressed: null, // Null callback
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull); // Should be disabled
    });

    testWidgets('Should properly dispose when widget is removed',
        (WidgetTester tester) async {
      bool showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget)
                      ConcurrentAsyncThrottledBuilder(
                        mode: ConcurrencyMode.enqueue,
                        onPressed: () async {
                          await Future.delayed(const Duration(milliseconds: 50));
                        },
                        builder: (context, callback, loading, _) {
                          return ElevatedButton(
                            onPressed: callback,
                            child: const Text('Submit'),
                          );
                        },
                      ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showWidget = false);
                      },
                      child: const Text('Remove'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);

      // Remove widget
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Submit'), findsNothing);
      // Should not throw or leak memory
    });

    testWidgets('Should support debug mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcurrentAsyncThrottledBuilder(
              mode: ConcurrencyMode.drop,
              debugMode: true,
              name: 'test-throttler',
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 10));
              },
              builder: (context, callback, loading, _) {
                return ElevatedButton(
                  onPressed: callback,
                  child: const Text('Submit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should not throw (debug logs are printed)
    });
  });
}
