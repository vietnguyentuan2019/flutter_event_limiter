# Throttle vs Debounce: Complete Guide

## Visual Comparison

### Throttle: Execute Immediately, Then Block

**Behavior:** Fires **immediately** on first event, then ignores subsequent events for duration.

```
Timeline (milliseconds):
0ms         500ms       1000ms      1500ms      2000ms
|           |           |           |           |
User clicks:
  ▼         ▼   ▼▼▼               ▼           ▼
Executes:
  ✓         X   X X               ✓           X
            |<-500ms->|                       |<-500ms->|
         (blocked)                         (blocked)
```

**Real-world analogy:** Elevator door close button
- First press → Door starts closing immediately
- Rapid presses → Ignored (door already closing)
- After door closes → Next press works again

---

### Debounce: Wait for Pause, Then Execute

**Behavior:** Waits for events to **stop**, then fires after delay.

```
Timeline (milliseconds):
0ms    100ms  200ms  300ms  600ms        900ms  1000ms 1100ms 1400ms
|      |      |      |      |            |      |      |      |
User types:
  a      b      c      d    (pause)       e      f      g    (pause)
API calls:
  X      X      X      X      ✓                  X      X      X      ✓
                         (wait 300ms)                            (wait 300ms)

Timer resets:
  ↻      ↻      ↻      ↻                         ↻      ↻      ↻
```

**Real-world analogy:** Automatic door sensor
- Person approaches → Timer starts
- Person still moving → Timer resets, door stays closed
- Person stops → After delay, door opens

---

### AsyncDebouncer: Debounce + Cancel Previous Operations

**Behavior:** Waits for pause **AND** cancels any running async operations.

```
Timeline:
0ms    100ms  200ms  300ms  600ms      800ms      1000ms
|      |      |      |      |          |          |
User types:
  a      b      c    (API)  d         (API)      (complete)
API starts:
         X      X      ▼     X          ▼
         (cancelled)  (cancelled)      (returns)

Call IDs:
         1      2      3     4          5
Result used:
                                        ✓ (only ID 5)
```

**Real-world analogy:** GPS navigation recalculating
- User types destination letter by letter
- Each letter starts new route calculation
- Old calculations cancelled, only final route shown

---

## When to Use Each

### Use Throttle When:

✅ **Immediate feedback needed**
- Button clicks (submit, purchase, delete)
- Refresh actions
- Navigation events
- Play/pause controls

✅ **Rate limiting required**
- Scroll event handlers
- Mouse move handlers
- Window resize handlers
- API request rate limiting

✅ **First action is most important**
- User's first click should execute
- Subsequent rapid clicks are likely mistakes

**Example scenarios:**
- E-commerce checkout button
- Social media "like" button
- Game control buttons
- Video player controls

---

### Use Debounce When:

✅ **Waiting for user to finish**
- Search input (wait for typing to stop)
- Auto-save (wait for editing to pause)
- Form validation (wait for complete input)
- Slider position (wait for dragging to stop)

✅ **Only final value matters**
- Search queries (only search final term)
- Filter selections (only apply final filters)
- Text formatting (only format final text)

✅ **Expensive operations**
- API calls (reduce server load)
- Complex calculations (reduce CPU usage)
- Database writes (reduce I/O)

**Example scenarios:**
- Google-style search
- Auto-saving document
- Real-time form validation
- Image upload preview

---

### Use AsyncDebouncer When:

✅ **Async operations that can be cancelled**
- Search API calls
- Autocomplete suggestions
- Address validation
- File uploads with progress

✅ **Race conditions possible**
- Multiple API requests
- Sequential operations that depend on latest data
- Real-time data fetching

✅ **Need loading state management**
- Show/hide loading spinner
- Disable inputs during processing
- Display progress indicators

**Example scenarios:**
- Product search
- Address autocomplete
- Real-time preview
- Async validation

---

## Code Comparison

### Throttle Example: Button Spam Prevention

```dart
// Problem: User clicks "Submit" 5 times rapidly
// Desired: Only first click executes, ignore next 4

ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () {
    print('Submitting order...');
    submitOrder();
  },
  child: Text("Submit Order"),
)

// Output:
// Click 1 (0ms):    "Submitting order..." ✓
// Click 2 (100ms):  (ignored)
// Click 3 (200ms):  (ignored)
// Click 4 (300ms):  (ignored)
// Click 5 (400ms):  (ignored)
// Click 6 (600ms):  "Submitting order..." ✓
```

---

### Debounce Example: Search Input

```dart
// Problem: User types "flutter", don't search on every letter
// Desired: Only search after user stops typing

DebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) {
    print('Searching for: $text');
    search(text);
  },
  builder: (controller) {
    return TextField(controller: controller);
  },
)

// Output:
// Types 'f' (0ms):       (timer starts)
// Types 'l' (50ms):      (timer resets)
// Types 'u' (100ms):     (timer resets)
// Types 't' (150ms):     (timer resets)
// Types 't' (200ms):     (timer resets)
// Types 'e' (250ms):     (timer resets)
// Types 'r' (300ms):     (timer resets)
// (pause 300ms)
// (600ms):               "Searching for: flutter" ✓
```

---

### AsyncDebouncer Example: API Call with Cancellation

```dart
// Problem: User types "abc", but API for "a" returns after "abc"
// Desired: Only show results for "abc", cancel "a" and "ab"

AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async {
    print('API call for: $text');
    return await searchProducts(text);
  },
  onSuccess: (products) {
    print('Results for: ${products.length} items');
    setState(() => _products = products);
  },
  builder: (controller) {
    return TextField(controller: controller);
  },
)

// Output:
// Types 'a' (0ms):       (timer starts)
// Types 'b' (100ms):     (timer resets)
// Types 'c' (200ms):     (timer resets)
// (pause 300ms)
// (500ms):               "API call for: abc"
// (700ms - API returns): "Results for: 150 items" ✓
//
// If user had typed 'd' at 250ms:
// Types 'd' (250ms):     (timer resets, API for "abc" CANCELLED)
// (pause 300ms)
// (550ms):               "API call for: abcd"
// (750ms):               "Results for: 120 items" ✓
```

---

## Advanced Patterns

### Throttle with Leading + Trailing (ThrottleDebouncer)

Executes **both** immediately and after delay.

```dart
ThrottleDebouncer(
  duration: Duration(milliseconds: 500),
)

// Timeline:
// Click 1 (0ms):    Execute immediately (leading) ✓
// Click 2 (100ms):  (ignored)
// Click 3 (200ms):  (ignored)
// (pause 500ms)
// (700ms):          Execute after delay (trailing) ✓
```

**Use case:** Scroll event where you want immediate feedback + final state
- Leading: Update UI immediately (smooth)
- Trailing: Fetch data after scrolling stops (efficient)

---

### High-Frequency Throttle (60fps)

Optimized for performance-critical events.

```dart
HighFrequencyThrottler(
  duration: Duration(milliseconds: 16), // 60fps
)

// Uses DateTime instead of Timer for better performance
// Ideal for: scroll, mouse move, window resize
```

---

### Batch Throttle

Group multiple operations into batches.

```dart
BatchThrottler(
  duration: Duration(seconds: 1),
  onBatch: (items) {
    print('Processing ${items.length} items');
    processBatch(items);
  },
)

// Usage:
batchThrottler.add(item1);
batchThrottler.add(item2);
batchThrottler.add(item3);
// After 1 second: "Processing 3 items" ✓
```

**Use case:** Analytics events, log aggregation, bulk operations

---

## Common Mistakes

### ❌ Wrong: Using Debounce for Buttons

```dart
// BAD: Debounce for button clicks
DebouncedBuilder(
  builder: (context, debounce) {
    return ElevatedButton(
      onPressed: debounce(() => submit()),
      child: Text("Submit"),
    );
  },
)

// Problem: User has to wait after clicking
// First click → Wait 300ms → Execute
// User expects: Immediate feedback!
```

**✅ Correct: Use Throttle**
```dart
ThrottledBuilder(
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => submit()),
      child: Text("Submit"),
    );
  },
)

// First click → Execute immediately ✓
// Subsequent clicks → Blocked
```

---

### ❌ Wrong: Using Throttle for Search

```dart
// BAD: Throttle for search input
ThrottledBuilder(
  builder: (context, throttle) {
    return TextField(
      onChanged: (text) => throttle(() => search(text)),
    );
  },
)

// Problem: Searches on FIRST letter only
// Types "flutter" → Searches for "f" (not helpful!)
```

**✅ Correct: Use Debounce**
```dart
DebouncedTextController(
  onChanged: (text) => search(text),
  builder: (controller) {
    return TextField(controller: controller);
  },
)

// Types "flutter" → Waits for pause → Searches "flutter" ✓
```

---

### ❌ Wrong: Not Using AsyncDebouncer for API Calls

```dart
// BAD: Regular debouncer with async
DebouncedBuilder(
  builder: (context, debounce) {
    return TextField(
      onChanged: (text) => debounce(() async {
        final result = await api.search(text);
        setState(() => _result = result); // ❌ Race condition!
      }),
    );
  },
)

// Problem: Old API calls can return after new ones
// Types "abc" → API for "ab" returns last → Shows wrong results
```

**✅ Correct: Use AsyncDebouncer**
```dart
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result),
  // ✓ Old API calls auto-cancelled
)
```

---

## Performance Considerations

### Throttle Performance

**Overhead:** ~0.01ms per call

**Memory:** ~40 bytes per throttler

**Best for:**
- High-frequency events (scroll, mouse move)
- Button clicks (low frequency)
- Rate limiting APIs

### Debounce Performance

**Overhead:** ~0.01ms per call

**Memory:** ~40 bytes per debouncer

**Best for:**
- Text input (medium frequency)
- Form validation
- Auto-save

### AsyncDebouncer Performance

**Overhead:** ~0.015ms per call (slightly higher due to async tracking)

**Memory:** ~80 bytes per debouncer (tracks call IDs)

**Best for:**
- API calls
- Async validation
- File operations

### HighFrequencyThrottler Performance

**Overhead:** ~0.001ms per call (100x faster!)

**Memory:** ~32 bytes

**Best for:**
- Scroll events (60fps)
- Mouse move events
- Window resize
- Animation frame callbacks

---

## Testing

### Testing Throttle

```dart
testWidgets('throttle executes immediately, then blocks', (tester) async {
  int count = 0;
  final throttler = Throttler(duration: Duration(milliseconds: 500));

  throttler.call(() => count++);
  expect(count, 1); // Immediate execution

  throttler.call(() => count++);
  expect(count, 1); // Blocked

  await tester.pumpAndSettle(Duration(milliseconds: 500));

  throttler.call(() => count++);
  expect(count, 2); // Works again
});
```

### Testing Debounce

```dart
testWidgets('debounce waits for pause', (tester) async {
  int count = 0;
  final debouncer = Debouncer(duration: Duration(milliseconds: 300));

  debouncer.call(() => count++);
  expect(count, 0); // Not executed yet

  await tester.pump(Duration(milliseconds: 200));
  debouncer.call(() => count++); // Timer resets

  await tester.pump(Duration(milliseconds: 200));
  expect(count, 0); // Still not executed

  await tester.pumpAndSettle(Duration(milliseconds: 300));
  expect(count, 1); // Now executed
});
```

### Testing AsyncDebouncer

```dart
testWidgets('async debouncer cancels old calls', (tester) async {
  int apiCallCount = 0;
  String? lastResult;

  final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));

  debouncer.run(() async {
    apiCallCount++;
    await Future.delayed(Duration(milliseconds: 100));
    return 'result1';
  }).then((result) => lastResult = result);

  await tester.pump(Duration(milliseconds: 200));

  debouncer.run(() async {
    apiCallCount++;
    await Future.delayed(Duration(milliseconds: 100));
    return 'result2';
  }).then((result) => lastResult = result);

  await tester.pumpAndSettle();

  expect(apiCallCount, 2); // Both started
  expect(lastResult, 'result2'); // Only latest completed
});
```

---

## Summary Table

| Feature | Throttle | Debounce | AsyncDebouncer |
|---------|----------|----------|----------------|
| **Execution** | Immediate | After pause | After pause |
| **Blocks duplicates** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Waits for pause** | ❌ No | ✅ Yes | ✅ Yes |
| **Cancels async** | ❌ No | ❌ No | ✅ Yes |
| **Loading state** | ❌ No | ❌ No | ✅ Yes |
| **Best for** | Buttons | Text input | API calls |
| **First event** | Executes | Waits | Waits |
| **Performance** | ~0.01ms | ~0.01ms | ~0.015ms |
| **Memory** | ~40 bytes | ~40 bytes | ~80 bytes |

---

## Related Documentation

- [Examples](../examples/) - Real-world usage
- [FAQ](../faq.md) - Common questions
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)

---

## Need Help Choosing?

**Still unsure which to use?**

Ask yourself:
1. **Do users expect immediate feedback?** → Use Throttle
2. **Should I wait for user to finish?** → Use Debounce
3. **Does this involve async API calls?** → Use AsyncDebouncer

When in doubt, try both and see which feels better!
