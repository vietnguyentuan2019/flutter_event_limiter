// test/v1_1_0_features_test.dart
// Comprehensive tests for v1.1.0 new features

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  group('v1.1.0 Feature Tests', () {
    group('Debug Mode Tests', () {
      test('Throttler debug mode should log messages', () async {
        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          debugMode: true,
          name: 'test-throttler',
        );
        int counter = 0;

        throttler.call(() => counter++);
        throttler.call(() => counter++);

        expect(counter, 1);
        throttler.dispose();
      });

      test('Debouncer debug mode should work', () async {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          debugMode: true,
          name: 'test-debouncer',
        );
        int counter = 0;

        debouncer.call(() => counter++);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(counter, 1);
        debouncer.dispose();
      });

      test('AsyncDebouncer debug mode should work', () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 10),
          debugMode: true,
          name: 'test-async-debouncer',
        );

        final result = await debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          return 42;
        });

        expect(result, 42);
        debouncer.dispose();
      });

      test('AsyncThrottler debug mode should work', () async {
        final throttler = AsyncThrottler(
          debugMode: true,
          name: 'test-async-throttler',
        );
        int counter = 0;

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          counter++;
        });

        expect(counter, 1);
        throttler.dispose();
      });
    });

    group('Performance Metrics Tests', () {
      test('Throttler onMetrics should track execution time', () async {
        Duration? capturedDuration;
        bool? capturedExecuted;

        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          onMetrics: (duration, executed) {
            capturedDuration = duration;
            capturedExecuted = executed;
          },
        );

        throttler.call(() {});
        expect(capturedExecuted, true);
        expect(capturedDuration, isNotNull);

        // Blocked call should report not executed
        throttler.call(() {});
        expect(capturedExecuted, false);
        expect(capturedDuration, Duration.zero);

        throttler.dispose();
      });

      test('Debouncer onMetrics should track timing', () async {
        Duration? capturedDuration;
        bool? capturedCancelled;

        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          onMetrics: (duration, cancelled) {
            capturedDuration = duration;
            capturedCancelled = cancelled;
          },
        );

        debouncer.call(() {});
        debouncer.call(() {}); // Should trigger cancel metric for first call

        expect(capturedCancelled, true);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(capturedCancelled, false);
        expect(capturedDuration, isNotNull);

        debouncer.dispose();
      });

      test('AsyncDebouncer onMetrics should track async operations', () async {
        Duration? capturedDuration;
        bool? capturedCancelled;

        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 10),
          onMetrics: (duration, cancelled) {
            capturedDuration = duration;
            capturedCancelled = cancelled;
          },
        );

        await debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          return 42;
        });

        expect(capturedCancelled, false);
        expect(capturedDuration, isNotNull);
        expect(capturedDuration!.inMilliseconds, greaterThan(0));

        debouncer.dispose();
      });

      test('AsyncThrottler onMetrics should track async execution', () async {
        Duration? capturedDuration;
        bool? capturedExecuted;

        final throttler = AsyncThrottler(
          onMetrics: (duration, executed) {
            capturedDuration = duration;
            capturedExecuted = executed;
          },
        );

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
        });

        expect(capturedExecuted, true);
        expect(capturedDuration, isNotNull);
        expect(capturedDuration!.inMilliseconds, greaterThan(0));

        throttler.dispose();
      });
    });

    group('Conditional Throttling Tests', () {
      test('Throttler enabled=false should bypass throttle', () {
        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          enabled: false,
        );
        int counter = 0;

        throttler.call(() => counter++);
        throttler.call(() => counter++);
        throttler.call(() => counter++);

        expect(counter, 3); // All calls should execute

        throttler.dispose();
      });

      test('Debouncer enabled=false should bypass debounce', () async {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 100),
          enabled: false,
        );
        int counter = 0;

        debouncer.call(() => counter++);
        debouncer.call(() => counter++);

        expect(counter, 2); // All calls should execute immediately

        debouncer.dispose();
      });

      test('AsyncDebouncer enabled=false should bypass debounce', () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 100),
          enabled: false,
        );
        int counter = 0;

        final result1 = await debouncer.run(() async {
          counter++;
          return 1;
        });
        final result2 = await debouncer.run(() async {
          counter++;
          return 2;
        });

        expect(counter, 2);
        expect(result1, 1);
        expect(result2, 2);

        debouncer.dispose();
      });

      test('AsyncThrottler enabled=false should bypass throttle', () async {
        final throttler = AsyncThrottler(
          enabled: false,
        );
        int counter = 0;

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          counter++;
        });

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          counter++;
        });

        expect(counter, 2); // Both should execute

        throttler.dispose();
      });
    });

    group('Custom Cooldown per Call Tests', () {
      test('Throttler callWithDuration should override default duration',
          () async {
        final throttler = Throttler(
          duration: const Duration(seconds: 10), // Long default
        );
        int counter = 0;

        throttler.callWithDuration(
          () => counter++,
          const Duration(milliseconds: 50), // Short custom
        );
        expect(counter, 1);

        // Should still be throttled with short duration
        throttler.call(() => counter++);
        expect(counter, 1);

        // Wait for short duration
        await Future.delayed(const Duration(milliseconds: 100));

        // Should execute now
        throttler.call(() => counter++);
        expect(counter, 2);

        throttler.dispose();
      });

      test('Debouncer callWithDuration should override default duration',
          () async {
        final debouncer = Debouncer(
          duration: const Duration(seconds: 10), // Long default
        );
        int counter = 0;

        debouncer.callWithDuration(
          () => counter++,
          const Duration(milliseconds: 50), // Short custom
        );

        expect(counter, 0);

        // Wait for short duration
        await Future.delayed(const Duration(milliseconds: 100));
        expect(counter, 1);

        debouncer.dispose();
      });
    });

    group('Reset on Error Tests', () {
      test('Throttler resetOnError should reset state on exception', () {
        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          resetOnError: true,
        );
        int counter = 0;

        // First call throws error
        expect(
          () => throttler.call(() {
            counter++;
            throw Exception('Test error');
          }),
          throwsException,
        );
        expect(counter, 1);

        // Should be reset, so next call should execute
        throttler.call(() => counter++);
        expect(counter, 2);

        throttler.dispose();
      });

      test('Debouncer resetOnError should cancel on exception', () async {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          resetOnError: true,
        );
        int counter = 0;

        // Schedule a debounce that will throw
        debouncer.call(() {
          counter++;
          throw Exception('Test error');
        });

        // Wait for debounce to execute
        await Future.delayed(const Duration(milliseconds: 100));

        // The callback was called (counter incremented) but then threw
        // The debouncer should have been cancelled/reset after the error
        expect(counter, 1);
        expect(debouncer.isPending, false); // Should be cancelled

        debouncer.dispose();
      });

      test('AsyncDebouncer resetOnError should handle errors', () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 10),
          resetOnError: true,
        );
        int counter = 0;

        try {
          await debouncer.run(() async {
            counter++;
            throw Exception('Test error');
          });
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(counter, 1);
        }

        // Should be reset and work again
        final result = await debouncer.run(() async {
          counter++;
          return 42;
        });
        expect(result, 42);
        expect(counter, 2);

        debouncer.dispose();
      });

      test('AsyncThrottler resetOnError should unlock on error', () async {
        final throttler = AsyncThrottler(
          resetOnError: true,
        );
        int counter = 0;

        try {
          await throttler.call(() async {
            counter++;
            throw Exception('Test error');
          });
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(counter, 1);
        }

        // Should be reset (unlocked) and work again
        expect(throttler.isLocked, false);
        await throttler.call(() async {
          counter++;
        });
        expect(counter, 2);

        throttler.dispose();
      });
    });

    group('Batch Execution Tests', () {
      test('BatchThrottler should collect and execute batch', () async {
        final List<String> executedActions = [];

        final batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.add(() => executedActions.add('action1'));
        batcher.add(() => executedActions.add('action2'));
        batcher.add(() => executedActions.add('action3'));

        expect(executedActions, isEmpty);
        expect(batcher.pendingCount, 3);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(executedActions, ['action1', 'action2', 'action3']);
        expect(batcher.pendingCount, 0);

        batcher.dispose();
      });

      test('BatchThrottler flush should execute immediately', () {
        final List<String> executedActions = [];

        final batcher = BatchThrottler(
          duration: const Duration(seconds: 10), // Long duration
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.add(() => executedActions.add('action1'));
        batcher.add(() => executedActions.add('action2'));

        expect(executedActions, isEmpty);

        batcher.flush();

        expect(executedActions, ['action1', 'action2']);
        expect(batcher.pendingCount, 0);

        batcher.dispose();
      });

      test('BatchThrottler clear should remove pending actions', () {
        final List<String> executedActions = [];

        final batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.add(() => executedActions.add('action1'));
        batcher.add(() => executedActions.add('action2'));

        expect(batcher.pendingCount, 2);

        batcher.clear();

        expect(batcher.pendingCount, 0);
        expect(executedActions, isEmpty);

        batcher.dispose();
      });

      test('BatchThrottler with debug mode', () async {
        final List<String> executedActions = [];

        final batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
          debugMode: true,
          name: 'test-batch',
        );

        batcher.add(() => executedActions.add('action1'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(executedActions, ['action1']);

        batcher.dispose();
      });
    });

    group('Edge Cases Tests', () {
      test('Throttler should handle dispose during throttle', () {
        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
        );
        int counter = 0;

        throttler.call(() => counter++);
        expect(counter, 1);

        throttler.dispose();

        // After dispose, isThrottled should be false
        expect(throttler.isThrottled, false);
      });

      test('Debouncer should handle rapid rebuild scenario', () async {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
        );
        int counter = 0;

        // Simulate rapid rebuilds
        for (int i = 0; i < 10; i++) {
          debouncer.call(() => counter++);
        }

        expect(counter, 0);

        await Future.delayed(const Duration(milliseconds: 100));
        expect(counter, 1);

        debouncer.dispose();
      });

      test('AsyncDebouncer should handle dispose during async execution',
          () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 10),
        );

        final future = debouncer.run(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 42;
        });

        // Dispose while async operation is running
        await Future.delayed(const Duration(milliseconds: 20));
        debouncer.dispose();

        final result = await future;
        expect(result, null); // Should be cancelled
      });

      test('AsyncThrottler should handle hot reload scenario', () async {
        final throttler = AsyncThrottler();

        // Start async operation
        final future = throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Simulate hot reload (dispose and recreate)
        throttler.dispose();

        await future;

        expect(throttler.isLocked, false);
      });

      test('Multiple throttlers should work independently', () {
        final throttler1 = Throttler(
          duration: const Duration(milliseconds: 100),
        );
        final throttler2 = Throttler(
          duration: const Duration(milliseconds: 100),
        );
        int counter1 = 0;
        int counter2 = 0;

        throttler1.call(() => counter1++);
        throttler2.call(() => counter2++);

        expect(counter1, 1);
        expect(counter2, 1);

        throttler1.dispose();
        throttler2.dispose();
      });
    });

    group('Integration Tests', () {
      test('Combined features: debug + metrics + conditional', () {
        Duration? capturedDuration;
        bool? capturedExecuted;

        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          debugMode: true,
          name: 'integration-test',
          enabled: true,
          onMetrics: (duration, executed) {
            capturedDuration = duration;
            capturedExecuted = executed;
          },
        );
        int counter = 0;

        throttler.call(() => counter++);
        expect(counter, 1);
        expect(capturedExecuted, true);
        expect(capturedDuration, isNotNull);

        throttler.dispose();
      });

      test('Batch throttler with metrics tracking', () async {
        final List<String> executedActions = [];
        int batchCount = 0;

        final batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          onBatchExecute: (actions) {
            batchCount++;
            for (final action in actions) {
              action();
            }
          },
          debugMode: true,
          name: 'metrics-batch',
        );

        batcher.add(() => executedActions.add('a'));
        batcher.add(() => executedActions.add('b'));
        batcher.add(() => executedActions.add('c'));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(executedActions, ['a', 'b', 'c']);
        expect(batchCount, 1);

        batcher.dispose();
      });

      test('Error handling with resetOnError and onMetrics', () {
        bool? capturedExecuted;

        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
          resetOnError: true,
          onMetrics: (duration, executed) {
            capturedExecuted = executed;
          },
        );
        int successCount = 0;

        // First call throws
        expect(
          () => throttler.call(() => throw Exception('Error')),
          throwsException,
        );

        // Should be reset and work
        throttler.call(() => successCount++);
        expect(successCount, 1);
        expect(capturedExecuted, true);

        throttler.dispose();
      });
    });
  });
}
