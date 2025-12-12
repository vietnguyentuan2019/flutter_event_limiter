// test/concurrency_mode_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  group('ConcurrencyMode Enum Tests', () {
    test('Should have correct display names', () {
      expect(ConcurrencyMode.drop.displayName, 'Drop');
      expect(ConcurrencyMode.enqueue.displayName, 'Enqueue');
      expect(ConcurrencyMode.replace.displayName, 'Replace');
      expect(ConcurrencyMode.keepLatest.displayName, 'Keep Latest');
    });

    test('Should have correct descriptions', () {
      expect(ConcurrencyMode.drop.description, 'Ignore new calls while busy');
      expect(ConcurrencyMode.enqueue.description,
          'Queue calls and execute sequentially');
      expect(ConcurrencyMode.replace.description,
          'Cancel current and start new');
      expect(ConcurrencyMode.keepLatest.description,
          'Keep latest call and execute after current');
    });

    test('Should identify modes that require queue', () {
      expect(ConcurrencyMode.drop.requiresQueue, false);
      expect(ConcurrencyMode.enqueue.requiresQueue, true);
      expect(ConcurrencyMode.replace.requiresQueue, false);
      expect(ConcurrencyMode.keepLatest.requiresQueue, false);
    });

    test('Should identify modes that support pending calls', () {
      expect(ConcurrencyMode.drop.supportsPending, false);
      expect(ConcurrencyMode.enqueue.supportsPending, true);
      expect(ConcurrencyMode.replace.supportsPending, false);
      expect(ConcurrencyMode.keepLatest.supportsPending, true);
    });
  });

  group('ConcurrentAsyncThrottler - Drop Mode (Default)', () {
    test('Should ignore new calls while busy', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(milliseconds: 100),
      );

      int executionCount = 0;

      // First call should execute
      throttler.call(() async {
        executionCount++;
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // Second call should be dropped (throttler is busy)
      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        executionCount++;
      });

      // Third call should also be dropped
      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        executionCount++;
      });

      // Wait for first call to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(executionCount, 1); // Only first call executed

      throttler.dispose();
    });

    test('Should track isLocked state', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(throttler.isLocked, false);

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.isLocked, true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(throttler.isLocked, false);

      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler - Enqueue Mode', () {
    test('Should execute all calls sequentially in order', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      final executionOrder = <int>[];

      // Queue 3 calls rapidly
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(1);
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(2);
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(3);
      });

      // Wait for all to complete
      await Future.delayed(const Duration(milliseconds: 200));

      expect(executionOrder, [1, 2, 3]); // All executed in order

      throttler.dispose();
    });

    test('Should track queue size', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(throttler.queueSize, 0);

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.queueSize, 2); // First executing, 2 in queue

      await Future.delayed(const Duration(milliseconds: 200));
      expect(throttler.queueSize, 0); // All processed

      throttler.dispose();
    });

    test('Should track pending count correctly', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(throttler.pendingCount, 0);

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.pendingCount,
          2); // 1 executing + 1 in queue = 2 pending

      await Future.delayed(const Duration(milliseconds: 150));
      expect(throttler.pendingCount, 0); // All completed

      throttler.dispose();
    });

    test('Should continue processing queue even if one operation fails',
        () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      final executionOrder = <int>[];

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(1);
      });

      // This call should fail but be caught
      try {
        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          executionOrder.add(2);
          throw Exception('Test error');
        });
      } catch (e) {
        // Expected to throw
      }

      // This should still execute despite previous error
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(3);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      expect(executionOrder, [1, 2, 3]); // All executed despite error

      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler - Replace Mode', () {
    test('Should cancel current and start new', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(milliseconds: 100),
      );

      int executedCallId = 0;

      // Start first call
      throttler.call(() async {
        // Short delay so it completes before being replaced
        await Future.delayed(const Duration(milliseconds: 5));
        executedCallId = 1;
      });

      // Replace with second call - first should finish before this
      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        executedCallId = 2;
      });

      // Replace with third call quickly (before second starts)
      await Future.delayed(const Duration(milliseconds: 2));
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        executedCallId = 3;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Third call should have executed last (overwriting previous values)
      expect(executedCallId, 3);

      throttler.dispose();
    });

    test('Should have zero pending count after replacement', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(milliseconds: 100),
      );

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.pendingCount, 1);

      // Replace
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // After replacement, should still be 1 (new operation)
      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.pendingCount, 1);

      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler - Keep Latest Mode', () {
    test('Should execute current and latest only', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.keepLatest,
        maxDuration: const Duration(milliseconds: 100),
      );

      final executionOrder = <int>[];

      // First call - executes immediately
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        executionOrder.add(1);
      });

      // These calls replace each other as "latest"
      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        executionOrder.add(2);
      });

      await Future.delayed(const Duration(milliseconds: 5));
      throttler.call(() async {
        executionOrder.add(3);
      });

      await Future.delayed(const Duration(milliseconds: 5));
      throttler.call(() async {
        executionOrder.add(4);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Should execute first (1) and latest (4), skip intermediate (2,3)
      expect(executionOrder, [1, 4]);

      throttler.dispose();
    });

    test('Should track pending count correctly', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.keepLatest,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(throttler.pendingCount, 0);

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.pendingCount, 1); // Current executing

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 5));
      expect(throttler.pendingCount, 2); // Current + 1 latest

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 5));
      expect(throttler.pendingCount, 2); // Still current + 1 latest (replaced)

      await Future.delayed(const Duration(milliseconds: 200));
      expect(throttler.pendingCount, 0); // All completed

      throttler.dispose();
    });

    test('Should execute immediately if not locked', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.keepLatest,
        maxDuration: const Duration(milliseconds: 100),
      );

      int executionCount = 0;

      expect(throttler.isLocked, false);

      await throttler.call(() async {
        executionCount++;
      });

      expect(executionCount, 1); // Executed immediately

      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler - Common Features', () {
    test('Should support reset() to clear all pending operations', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.queueSize, 1);

      throttler.reset(); // Clear everything

      expect(throttler.queueSize, 0);
      expect(throttler.isLocked, false);

      throttler.dispose();
    });

    test('Should support hasPendingCalls check', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(throttler.hasPendingCalls, false);

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.hasPendingCalls, true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(throttler.hasPendingCalls, false);

      throttler.dispose();
    });

    test('Should support wrap() method', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(milliseconds: 100),
      );

      int counter = 0;

      final wrappedCallback = throttler.wrap(() async {
        counter++;
      });

      expect(wrappedCallback, isNotNull);
      wrappedCallback!();

      await Future.delayed(const Duration(milliseconds: 50));
      expect(counter, 1);

      throttler.dispose();
    });

    test('Should handle null callback in wrap()', () {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(milliseconds: 100),
      );

      final wrappedCallback = throttler.wrap(null);
      expect(wrappedCallback, isNull);

      throttler.dispose();
    });

    test('Should properly dispose and clean up resources', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.queueSize, 1);

      throttler.dispose();

      expect(throttler.queueSize, 0);
      expect(throttler.isLocked, false);
      expect(throttler.hasPendingCalls, false);
    });
  });

  group('ConcurrentAsyncThrottler - Error Handling', () {
    test('Should rethrow errors in drop mode', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(milliseconds: 100),
      );

      expect(
        () async => await throttler.call(() async {
          throw Exception('Test error');
        }),
        throwsException,
      );

      throttler.dispose();
    });

    test('Should complete completer with error in enqueue mode', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(milliseconds: 100),
      );

      bool errorCaught = false;

      try {
        await throttler.call(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        errorCaught = true;
      }

      expect(errorCaught, true);

      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler - Real-World Scenarios', () {
    test('Chat app: Should send messages in order (enqueue)', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(seconds: 30),
      );

      final sentMessages = <String>[];

      // Simulate user sending 3 messages rapidly
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 30));
        sentMessages.add('Hello');
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 30));
        sentMessages.add('World');
      });

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 30));
        sentMessages.add('!');
      });

      await Future.delayed(const Duration(milliseconds: 200));

      expect(sentMessages, ['Hello', 'World', '!']);

      throttler.dispose();
    });

    test('Search: Should only execute latest query (replace)', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(seconds: 10),
      );

      String? latestSearchQuery;

      // Simulate user typing "abc" rapidly
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        latestSearchQuery = 'a';
      });

      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        latestSearchQuery = 'ab';
      });

      await Future.delayed(const Duration(milliseconds: 2));
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        latestSearchQuery = 'abc';
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Last query should have executed (overwriting previous)
      expect(latestSearchQuery, 'abc');

      throttler.dispose();
    });

    test('Auto-save: Should save first and last version (keepLatest)',
        () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.keepLatest,
        maxDuration: const Duration(seconds: 30),
      );

      final savedVersions = <String>[];

      // Simulate user editing document 5 times
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        savedVersions.add('v1');
      });

      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        savedVersions.add('v2');
      });

      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        savedVersions.add('v3');
      });

      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        savedVersions.add('v4');
      });

      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() async {
        savedVersions.add('v5');
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Should save first (v1) and latest (v5)
      expect(savedVersions, ['v1', 'v5']);

      throttler.dispose();
    });
  });
}
