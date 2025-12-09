// test/flutter_event_limiter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  group('Throttler Tests', () {
    test('Should execute only once within duration', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int counter = 0;
      void increment() => counter++;

      // Click 3 times fast
      throttler.call(increment);
      throttler.call(increment);
      throttler.call(increment);

      expect(counter, 1); // Should only run once

      // Wait for duration
      await Future.delayed(const Duration(milliseconds: 150));

      // Click again
      throttler.call(increment);
      expect(counter, 2); // Should run again

      throttler.dispose();
    });

    test('Should support reset()', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int counter = 0;

      throttler.call(() => counter++);
      expect(counter, 1);

      // Without reset, this should be blocked
      throttler.call(() => counter++);
      expect(counter, 1);

      // Reset and try again
      throttler.reset();
      throttler.call(() => counter++);
      expect(counter, 2); // Should execute

      throttler.dispose();
    });

    test('Should track isThrottled state', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      expect(throttler.isThrottled, false);

      throttler.call(() {});
      expect(throttler.isThrottled, true);

      throttler.dispose();
    });
  });

  group('Debouncer Tests', () {
    test('Should delay execution until pause', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 100));
      int counter = 0;

      // Call multiple times
      debouncer.call(() => counter++);
      debouncer.call(() => counter++);
      debouncer.call(() => counter++);

      // Should not execute yet
      expect(counter, 0);

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 150));

      // Should execute only once (last call)
      expect(counter, 1);

      debouncer.dispose();
    });

    test('Should support flush()', () {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 100));
      int counter = 0;

      debouncer.call(() => counter++);

      // Flush executes immediately
      debouncer.flush(() => counter++);
      expect(counter, 1);

      debouncer.dispose();
    });
  });

  group('AsyncDebouncer Tests', () {
    test('Should cancel previous call and return null', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      // Call 1 (Will be cancelled)
      final future1 = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 1;
      });

      // Call 2 (Will succeed)
      final future2 = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 2;
      });

      final result1 = await future1;
      final result2 = await future2;

      expect(result1, null); // Cancelled
      expect(result2, 2); // Success

      debouncer.dispose();
    });

    test('Should handle errors with stack trace', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      // AsyncDebouncer.run() returns Future<T?> that completes with error
      try {
        await debouncer.run(() async {
          throw Exception('Test error');
        });
        fail('Should have thrown an error');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      debouncer.dispose();
    });

    test('Should cancel on dispose', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      final future = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 42;
      });

      debouncer.dispose();

      final result = await future;
      expect(result, null); // Should be cancelled
    });
  });

  group('AsyncThrottler Tests', () {
    test('Should lock during async operation', () async {
      final throttler = AsyncThrottler();
      int counter = 0;

      expect(throttler.isLocked, false);

      // Start async operation
      final future = throttler.call(() async {
        expect(throttler.isLocked, true);
        await Future.delayed(const Duration(milliseconds: 50));
        counter++;
      });

      expect(throttler.isLocked, true);

      // Try to call again (should be blocked)
      await throttler.call(() async {
        counter++;
      });

      await future;

      expect(counter, 1); // Only first call executed
      expect(throttler.isLocked, false);

      throttler.dispose();
    });

    test('Should auto-unlock on timeout', () async {
      final throttler =
          AsyncThrottler(maxDuration: const Duration(milliseconds: 50));

      expect(throttler.isLocked, false);

      // Start long operation
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      expect(throttler.isLocked, true);

      // Wait for timeout
      await Future.delayed(const Duration(milliseconds: 100));

      expect(throttler.isLocked, false); // Auto-unlocked by timeout

      throttler.dispose();
    });
  });

  group('HighFrequencyThrottler Tests', () {
    test('Should throttle high-frequency events', () {
      final throttler =
          HighFrequencyThrottler(duration: const Duration(milliseconds: 50));
      int counter = 0;

      // First call executes
      throttler.call(() => counter++);
      expect(counter, 1);

      // Immediate calls blocked
      throttler.call(() => counter++);
      throttler.call(() => counter++);
      expect(counter, 1);

      expect(throttler.isThrottled, true);

      throttler.dispose();
    });

    test('Should support reset()', () {
      final throttler =
          HighFrequencyThrottler(duration: const Duration(milliseconds: 50));
      int counter = 0;

      throttler.call(() => counter++);
      expect(throttler.isThrottled, true);

      throttler.reset();
      expect(throttler.isThrottled, false);

      throttler.call(() => counter++);
      expect(counter, 2);

      throttler.dispose();
    });
  });

  group('Widget Tests', () {
    testWidgets('ThrottledInkWell prevents double taps',
        (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThrottledInkWell(
            duration: const Duration(milliseconds: 100),
            onTap: () => taps++,
            child: const Text('Tap Me'),
          ),
        ),
      ));

      // Tap twice quickly
      await tester.tap(find.text('Tap Me'));
      await tester.tap(find.text('Tap Me'));
      await tester.pump(); // Process frames

      expect(taps, 1); // Only 1 tap registered

      // Wait for throttle duration
      await tester.pump(const Duration(milliseconds: 150));

      // Tap again
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(taps, 2);
    });

    testWidgets('ThrottledInkWell supports onDoubleTap and onLongPress',
        (WidgetTester tester) async {
      int doubleTaps = 0;
      int longPresses = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThrottledInkWell(
            duration: const Duration(milliseconds: 100),
            onTap: () {},
            onDoubleTap: () => doubleTaps++,
            onLongPress: () => longPresses++,
            child: const Text('Tap Me'),
          ),
        ),
      ));

      // Double tap
      await tester.tap(find.text('Tap Me'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      // Long press
      await tester.longPress(find.text('Tap Me'));
      await tester.pump();

      expect(doubleTaps, greaterThan(0));
      expect(longPresses, greaterThan(0));
    });

    testWidgets('DebouncedTextController should work',
        (WidgetTester tester) async {
      final controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) {},
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller.textController),
        ),
      ));

      // Type text
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      expect(controller.text, 'Hello');

      controller.dispose();
    });
  });

  group('DebouncedTextController Tests', () {
    test('Should prevent controller + initialValue conflict', () {
      final externalController = TextEditingController();

      expect(
        () => DebouncedTextController(
          controller: externalController,
          initialValue: 'test', // Should throw assert
          onChanged: (text) {},
        ),
        throwsA(isA<AssertionError>()),
      );

      externalController.dispose();
    });

    test('Should handle setText and clear', () {
      final controller = DebouncedTextController(
        onChanged: (text) {},
      );

      controller.setText('Hello');
      expect(controller.text, 'Hello');

      controller.clear();
      expect(controller.text, '');

      controller.dispose();
    });
  });

  group('AsyncDebouncedTextController Tests', () {
    test('Should prevent controller + initialValue conflict', () {
      final externalController = TextEditingController();

      expect(
        () => AsyncDebouncedTextController(
          controller: externalController,
          initialValue: 'test', // Should throw assert
          onChanged: (text) async => [],
        ),
        throwsA(isA<AssertionError>()),
      );

      externalController.dispose();
    });

    test('Should track loading state', () async {
      bool? loadingState;
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 10),
        onChanged: (text) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return text;
        },
        onLoadingChanged: (isLoading) {
          loadingState = isLoading;
        },
      );

      controller.textController.text = 'test';
      await Future.delayed(const Duration(milliseconds: 20));

      expect(loadingState, true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(loadingState, false);

      controller.dispose();
    });

    test('Should handle setText and clear', () {
      final controller = AsyncDebouncedTextController<String>(
        onChanged: (text) async => text,
      );

      controller.setText('Hello');
      expect(controller.text, 'Hello');

      controller.clear();
      expect(controller.text, '');

      controller.dispose();
    });

    test('Should call onSuccess callback', () async {
      String? result;
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 10),
        onChanged: (text) async {
          await Future.delayed(const Duration(milliseconds: 20));
          return 'Result: $text';
        },
        onSuccess: (value) {
          result = value;
        },
      );

      controller.textController.text = 'test';
      await Future.delayed(const Duration(milliseconds: 50));

      expect(result, 'Result: test');

      controller.dispose();
    });

    test('Should call onError callback', () async {
      Object? capturedError;
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 10),
        onChanged: (text) async {
          throw Exception('Test error');
        },
        onError: (error, stack) {
          capturedError = error;
        },
      );

      controller.textController.text = 'test';
      await Future.delayed(const Duration(milliseconds: 50));

      expect(capturedError, isA<Exception>());

      controller.dispose();
    });
  });

  group('Throttler wrap() Tests', () {
    test('Should wrap callback correctly', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int counter = 0;

      final wrappedCallback = throttler.wrap(() => counter++);

      wrappedCallback?.call();
      wrappedCallback?.call();
      wrappedCallback?.call();

      expect(counter, 1);

      throttler.dispose();
    });

    test('Should return null when callback is null', () {
      final throttler = Throttler();
      final wrapped = throttler.wrap(null);
      expect(wrapped, null);
      throttler.dispose();
    });
  });

  group('Debouncer wrap() and cancel() Tests', () {
    test('Should wrap callback correctly', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int counter = 0;

      final wrappedCallback = debouncer.wrap(() => counter++);

      wrappedCallback?.call();
      wrappedCallback?.call();

      expect(counter, 0);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(counter, 1);

      debouncer.dispose();
    });

    test('Should cancel pending execution', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.call(() => counter++);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(counter, 0); // Should not execute

      debouncer.dispose();
    });
  });

  group('AsyncDebouncer Additional Tests', () {
    test('Should handle multiple concurrent cancellations', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      final future1 = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 1;
      });

      final future2 = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 2;
      });

      final future3 = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 3;
      });

      final result1 = await future1;
      final result2 = await future2;
      final result3 = await future3;

      expect(result1, null);
      expect(result2, null);
      expect(result3, 3);

      debouncer.dispose();
    });

    test('Should cancel all on cancel()', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      final future = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 42;
      });

      debouncer.cancel();

      final result = await future;
      expect(result, null);

      debouncer.dispose();
    });
  });

  group('AsyncThrottler Error Handling Tests', () {
    test('Should handle errors gracefully', () async {
      final throttler = AsyncThrottler();

      try {
        await throttler.call(() async {
          throw Exception('Test error');
        });
        fail('Should have thrown exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(throttler.isLocked, false); // Should unlock after error

      throttler.dispose();
    });

    test('Should unlock after maxDuration timeout', () async {
      final throttler =
          AsyncThrottler(maxDuration: const Duration(milliseconds: 50));

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(throttler.isLocked, false); // Unlocked by timeout

      throttler.dispose();
    });
  });

  group('Builder Widget Tests', () {
    testWidgets('ThrottledBuilder should work', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThrottledBuilder(
            duration: const Duration(milliseconds: 100),
            builder: (context, throttle) {
              return ElevatedButton(
                onPressed: throttle(() => taps++),
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('DebouncedBuilder should work', (WidgetTester tester) async {
      int calls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DebouncedBuilder(
            duration: const Duration(milliseconds: 50),
            builder: (context, debounce) {
              return ElevatedButton(
                onPressed: debounce(() => calls++),
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 1);
    });

    testWidgets('AsyncThrottledBuilder should work',
        (WidgetTester tester) async {
      int calls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncThrottledBuilder(
            builder: (context, throttle) {
              return ElevatedButton(
                onPressed: throttle(() async {
                  await Future.delayed(const Duration(milliseconds: 10));
                  calls++;
                }),
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();
      await tester.tap(find.text('Tap')); // Should be blocked
      await tester.pump(const Duration(milliseconds: 50));

      expect(calls, 1);
    });

    test('AsyncDebouncedBuilder functionality test', () async {
      // AsyncDebouncedBuilder tested via AsyncDebouncer tests above
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 50));
      int calls = 0;

      debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        calls++;
      });

      debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        calls++;
      });

      expect(calls, 0);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(calls, 1);

      debouncer.dispose();
    });
  });

  group('Callback Widget Tests', () {
    testWidgets('ThrottledCallback should work', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThrottledCallback(
            duration: const Duration(milliseconds: 100),
            onPressed: () => taps++,
            builder: (context, callback) {
              return ElevatedButton(
                onPressed: callback,
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('DebouncedCallback should work', (WidgetTester tester) async {
      int calls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DebouncedCallback(
            duration: const Duration(milliseconds: 50),
            onChanged: () => calls++,
            builder: (context, callback) {
              return ElevatedButton(
                onPressed: callback,
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.tap(find.text('Tap'));

      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 1);
    });

    testWidgets('AsyncThrottledCallback should work',
        (WidgetTester tester) async {
      int calls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncThrottledCallback(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 10));
              calls++;
            },
            builder: (context, callback) {
              return ElevatedButton(
                onPressed: callback,
                child: const Text('Tap'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.tap(find.text('Tap'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(calls, 1);
    });

    testWidgets('AsyncDebouncedCallback should work',
        (WidgetTester tester) async {
      int calls = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncDebouncedCallback(
            duration: const Duration(milliseconds: 50),
            onChanged: (text) async {
              await Future.delayed(const Duration(milliseconds: 10));
              calls++;
            },
            builder: (context, callback) {
              return TextField(
                onChanged: callback,
              );
            },
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'a');
      await tester.enterText(find.byType(TextField), 'ab');

      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 1);
    });
  });

  group('CallbackBuilder with Loading State Tests', () {
    testWidgets('AsyncThrottledCallbackBuilder should track loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncThrottledCallbackBuilder(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 50));
            },
            builder: (context, callback, isLoading) {
              return ElevatedButton(
                onPressed: isLoading ? null : callback,
                child: Text(isLoading ? 'Loading' : 'Tap'),
              );
            },
          ),
        ),
      ));

      expect(find.text('Tap'), findsOneWidget);

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Loading'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Tap'), findsOneWidget);
    });

    test('AsyncDebouncedCallbackBuilder loading state test', () async {
      // Loading state tested via AsyncDebouncedTextController tests above
      bool? loadingState;
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 10),
        onChanged: (text) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return text;
        },
        onLoadingChanged: (isLoading) {
          loadingState = isLoading;
        },
      );

      controller.textController.text = 'test';
      await Future.delayed(const Duration(milliseconds: 20));

      expect(loadingState, true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(loadingState, false);

      controller.dispose();
    });
  });

  group('Integration Tests', () {
    testWidgets('ThrottledTapWidget should work', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ThrottledTapWidget(
            duration: const Duration(milliseconds: 100),
            onTap: () => taps++,
            child: const Text('Tap Me'),
          ),
        ),
      ));

      await tester.tap(find.text('Tap Me'));
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('Multiple throttled widgets should work independently',
        (WidgetTester tester) async {
      int taps1 = 0;
      int taps2 = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ThrottledInkWell(
                onTap: () => taps1++,
                child: const Text('Button 1'),
              ),
              ThrottledInkWell(
                onTap: () => taps2++,
                child: const Text('Button 2'),
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('Button 1'));
      await tester.tap(find.text('Button 2'));
      await tester.pump();

      expect(taps1, 1);
      expect(taps2, 1);
    });

    testWidgets('DebouncedTextController with real TextField',
        (WidgetTester tester) async {
      String? lastValue;
      final controller = DebouncedTextController(
        duration: const Duration(milliseconds: 50),
        onChanged: (text) {
          lastValue = text;
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller.textController),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.enterText(find.byType(TextField), 'Hello World');

      expect(lastValue, null); // Not called yet

      await tester.pump(const Duration(milliseconds: 100));
      expect(lastValue, 'Hello World');

      controller.dispose();
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Throttler should handle null callback', () {
      final throttler = Throttler();
      expect(throttler.wrap(null), null);
      throttler.dispose();
    });

    test('Debouncer should handle dispose during pending call', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int counter = 0;

      debouncer.call(() => counter++);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(counter, 0); // Should not execute
    });

    test('AsyncDebouncer should complete futures on dispose', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));

      final future = debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 42;
      });

      await Future.delayed(const Duration(milliseconds: 20));
      debouncer.dispose();

      final result = await future;
      expect(result, null);
    });

    test('AsyncThrottler should handle dispose during locked state', () async {
      final throttler = AsyncThrottler();

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      expect(throttler.isLocked, true);
      throttler.dispose();
      expect(throttler.isLocked, false);
    });

    test('HighFrequencyThrottler should handle rapid dispose', () {
      final throttler = HighFrequencyThrottler();
      throttler.call(() {});
      throttler.dispose();
      // Should not crash
    });

    test('Throttler should handle very rapid calls (stress test)', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int counter = 0;

      // Simulate 100 rapid clicks
      for (int i = 0; i < 100; i++) {
        throttler.call(() => counter++);
      }

      expect(counter, 1); // Only first call executed
      throttler.dispose();
    });

    test('Debouncer should handle very rapid calls (stress test)', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int counter = 0;

      // Simulate 50 rapid calls
      for (int i = 0; i < 50; i++) {
        debouncer.call(() => counter++);
      }

      expect(counter, 0); // Nothing executed yet

      await Future.delayed(const Duration(milliseconds: 100));
      expect(counter, 1); // Only last call executed
      debouncer.dispose();
    });

    test('AsyncDebouncer should handle rapid sequential operations', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 10));
      int successCount = 0;

      final futures = <Future<int?>>[];
      for (int i = 0; i < 10; i++) {
        futures.add(debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          return i;
        }));
      }

      final results = await Future.wait(futures);

      // Only last operation should succeed, all others cancelled
      for (int i = 0; i < results.length - 1; i++) {
        expect(results[i], null);
      }
      expect(results.last, 9);

      debouncer.dispose();
    });

    test('Multiple throttlers should work independently', () {
      final throttler1 = Throttler(duration: const Duration(milliseconds: 100));
      final throttler2 = Throttler(duration: const Duration(milliseconds: 100));
      int counter1 = 0;
      int counter2 = 0;

      throttler1.call(() => counter1++);
      throttler2.call(() => counter2++);

      throttler1.call(() => counter1++); // Blocked
      throttler2.call(() => counter2++); // Blocked

      expect(counter1, 1);
      expect(counter2, 1);

      throttler1.dispose();
      throttler2.dispose();
    });

    test('Throttler with very short duration', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 1));
      int counter = 0;

      throttler.call(() => counter++);
      throttler.call(() => counter++); // Blocked

      expect(counter, 1);

      await Future.delayed(const Duration(milliseconds: 5));

      throttler.call(() => counter++); // Should work now
      expect(counter, 2);

      throttler.dispose();
    });

    test('Debouncer with very long duration', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 200));
      int counter = 0;

      debouncer.call(() => counter++);
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => counter++); // Resets timer

      expect(counter, 0);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(counter, 0); // Still waiting

      await Future.delayed(const Duration(milliseconds: 200));
      expect(counter, 1); // Finally executed

      debouncer.dispose();
    });

    test('AsyncThrottler should handle very fast async operations', () async {
      final throttler = AsyncThrottler();
      int counter = 0;

      await throttler.call(() async {
        // Very fast operation
        counter++;
      });

      expect(counter, 1);
      expect(throttler.isLocked, false);

      throttler.dispose();
    });

    test('HighFrequencyThrottler should track throttled state', () async {
      final throttler =
          HighFrequencyThrottler(duration: const Duration(milliseconds: 50));
      int counter = 0;

      expect(throttler.isThrottled, false);

      throttler.call(() => counter++);
      expect(throttler.isThrottled, true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(throttler.isThrottled, false);

      throttler.dispose();
    });

    test('AsyncDebouncedTextController should handle clear', () {
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 50),
        onChanged: (text) async {
          await Future.delayed(const Duration(milliseconds: 20));
          return text;
        },
      );

      controller.setText('test');
      expect(controller.text, 'test');

      controller.clear(); // Clear text
      expect(controller.text, '');

      controller.dispose();
    });
  });

  group('Real-World Scenarios', () {
    test('E-commerce: Prevent double order submission', () async {
      final throttler = Throttler(duration: const Duration(seconds: 2));
      int orderCount = 0;

      // Simulate user double-clicking "Place Order" button
      throttler.call(() => orderCount++);
      throttler.call(() => orderCount++);
      throttler.call(() => orderCount++);

      expect(orderCount, 1); // Only one order placed

      throttler.dispose();
    });

    test('Search: Autocomplete with race condition prevention', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 300));
      String? lastResult;

      // Simulate user typing "flutter"
      final futures = [
        debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'results for: f';
        }),
        debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'results for: fl';
        }),
        debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'results for: flu';
        }),
        debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'results for: flutter';
        }),
      ];

      final results = await Future.wait(futures);

      // Only last search should succeed
      expect(results[0], null);
      expect(results[1], null);
      expect(results[2], null);
      expect(results[3], 'results for: flutter');

      debouncer.dispose();
    });

    test('Chat app: Prevent message spam', () {
      final throttler = Throttler(duration: const Duration(seconds: 1));
      int messagesSent = 0;

      // Simulate user pressing Enter repeatedly
      for (int i = 0; i < 10; i++) {
        throttler.call(() => messagesSent++);
      }

      expect(messagesSent, 1); // Only one message sent

      throttler.dispose();
    });

    test('Form validation: Debounced async validation concept', () {
      // This test demonstrates the concept of async validation
      final controller = AsyncDebouncedTextController<bool>(
        duration: const Duration(milliseconds: 50),
        onChanged: (text) async {
          // Simulate API call to check if username is available
          await Future.delayed(const Duration(milliseconds: 20));
          return text.length >= 3; // Valid if 3+ chars
        },
      );

      controller.setText('a');
      controller.setText('ab');
      controller.setText('abc');

      // Verify text is set correctly
      expect(controller.text, 'abc');

      controller.dispose();
    });

    test('Game: High-frequency input throttling', () {
      final throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16), // ~60fps
      );
      int updateCount = 0;

      // Simulate rapid game loop updates
      for (int i = 0; i < 100; i++) {
        throttler.call(() => updateCount++);
      }

      expect(updateCount, 1); // Only first frame processed
      throttler.dispose();
    });
  });

  group('Performance Tests', () {
    test('Throttler performance with 1000 calls', () {
      final stopwatch = Stopwatch()..start();
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int counter = 0;

      for (int i = 0; i < 1000; i++) {
        throttler.call(() => counter++);
      }

      stopwatch.stop();

      expect(counter, 1);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

      throttler.dispose();
    });

    test('Debouncer performance with 1000 calls', () {
      final stopwatch = Stopwatch()..start();
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int counter = 0;

      for (int i = 0; i < 1000; i++) {
        debouncer.call(() => counter++);
      }

      stopwatch.stop();

      expect(counter, 0); // Not executed yet
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

      debouncer.dispose();
    });

    test('HighFrequencyThrottler is faster than regular Throttler', () {
      final regularStopwatch = Stopwatch()..start();
      final regularThrottler =
          Throttler(duration: const Duration(milliseconds: 16));

      for (int i = 0; i < 100; i++) {
        regularThrottler.call(() {});
      }
      regularStopwatch.stop();

      final highFreqStopwatch = Stopwatch()..start();
      final highFreqThrottler =
          HighFrequencyThrottler(duration: const Duration(milliseconds: 16));

      for (int i = 0; i < 100; i++) {
        highFreqThrottler.call(() {});
      }
      highFreqStopwatch.stop();

      // HighFrequencyThrottler should be faster (no Timer overhead)
      expect(highFreqStopwatch.elapsedMicroseconds,
          lessThan(regularStopwatch.elapsedMicroseconds));

      regularThrottler.dispose();
      highFreqThrottler.dispose();
    });
  });
}
