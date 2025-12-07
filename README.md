# Flutter Event Limiter 🛡️

[![pub package](https://img.shields.io/pub/v/flutter_event_limiter.svg)](https://pub.dev/packages/flutter_event_limiter)
[![Pub Points](https://img.shields.io/pub/points/flutter_event_limiter)](https://pub.dev/packages/flutter_event_limiter/score)
[![Tests](https://img.shields.io/badge/tests-48%20passing-brightgreen.svg)](https://github.com/vietnguyentuan2019/flutter_event_limiter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**The production-ready event management system for Flutter.**

Handle **Throttling** (anti-spam) and **Debouncing** (search APIs) with built-in safety against race conditions, memory leaks, and "setState after dispose" crashes.

> **Why this package?**
> Most libraries require you to manually manage `Timer` disposal and `mounted` checks. We handle that automatically. Plus, we give you built-in loading states and work with **ANY** widget.

---

## ⚡ The 30-Second Demo

### The Old Way (Manual & Risky)
15+ lines. Easy to forget `dispose` or `mounted` checks.

```dart
// ❌ Boilerplate & Error Prone
Timer? _timer;
bool _loading = false;

void onSearch(String text) {
  _timer?.cancel();
  _timer = Timer(Duration(milliseconds: 300), () async {
    setState(() => _loading = true);
    try {
      final result = await api.search(text);
      if (!mounted) return; // Must remember this!
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  });
}

@override
void dispose() {
  _timer?.cancel(); // Must remember this too!
  super.dispose();
}
```

### The New Way (Safe & Clean)
3 lines. Auto-dispose. Auto-mounted check. Auto-loading state.

```dart
// ✅ Clean & Safe
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result),
  onLoadingChanged: (loading) => setState(() => _loading = loading), // ✨ Magic!
)
```

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🧩 **Universal Builders** | Use with ANY widget (Material, Cupertino, Custom UI). Not locked to specific buttons/textfields. |
| 🛡️ **Auto-Safety** | Automatically checks `mounted` before callbacks. Automatically disposes timers. |
| ⏳ **Loading State** | `isLoading` state is provided automatically. No need to create boolean flags. |
| 🏁 **Race Condition Fix** | Automatically cancels previous async operations when a new one starts (Essential for Search). |
| 📉 **Zero Boilerplate** | Reduces code by ~80% compared to manual implementation. |

---

## 🚀 Usage Examples

### 1. Prevent Button Double-Clicks (Throttle)

Stop users from accidentally spamming payment buttons or API calls.

```dart
ThrottledInkWell(
  onTap: () => submitOrder(), // 👈 Only runs once per 500ms
  child: Text("Submit Order"),
)

// OR use with ANY widget:
ThrottledBuilder(
  builder: (context, throttle) {
    return CupertinoButton(
      onPressed: throttle(() => submitOrder()),
      child: Text("Submit"),
    );
  },
)
```

### 2. Smart Search Bar (Async Debounce)

Waits for the user to stop typing. Automatically cancels old network requests to prevent wrong results.

```dart
AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await api.search(text),

  // ✅ Only called if widget is mounted AND it's the latest result
  onSuccess: (products) => setState(() => _products = products),

  // ✅ Auto-manage loading spinner
  onLoadingChanged: (isLoading) => setState(() => _loading = isLoading),
)
```

### 3. Form Submission with Loading UI

Disable the button and show a spinner while the async task runs.

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async => await uploadFile(),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      // Auto-disable button when loading
      onPressed: isLoading ? null : callback,
      child: isLoading
          ? CircularProgressIndicator()
          : Text("Upload"),
    );
  },
)
```

---

## 📊 Feature Comparison

How `flutter_event_limiter` improves upon common patterns:

| Feature | Raw Utility Libs | Stream Libs (Rx) | Hard-Coded Widget Libs | flutter_event_limiter |
|---------|------------------|------------------|------------------------|----------------------|
| **Approach** | Manual | Reactive | Fixed Widgets | Builder Pattern |
| **Works with Any Widget** | ❌ | ❌ | ❌ | ✅ |
| **Auto Mounted Check** | ❌ | ❌ | ❌ | ✅ |
| **Auto Loading State** | ❌ | ❌ | ❌ | ✅ |
| **Prevents Race Conditions** | ❌ | ✅ | ⚠️ | ✅ |
| **Setup Difficulty** | Medium | Hard | Easy | Easy |

**Note:** While libraries like RxDart are powerful for complex stream transformations, `flutter_event_limiter` is optimized specifically for UI event handling with zero setup.

---

## 🎨 Universal Builder Pattern

**The Power of Flexibility:** Unlike libraries that lock you into specific widgets, our builder pattern works with **everything**.

### Example 1: Custom FAB with Throttle

```dart
ThrottledBuilder(
  duration: Duration(seconds: 1),
  builder: (context, throttle) {
    return FloatingActionButton(
      onPressed: throttle(() => saveData()),
      child: Icon(Icons.save),
    );
  },
)
```

### Example 2: Cupertino Button with Debounce

```dart
DebouncedBuilder(
  duration: Duration(milliseconds: 500),
  builder: (context, debounce) {
    return CupertinoButton(
      onPressed: debounce(() => updateSettings()),
      child: Text("Save"),
    );
  },
)
```

### Example 3: Custom Slider with Debounce

```dart
DebouncedBuilder(
  builder: (context, debounce) {
    return Slider(
      value: _volume,
      onChanged: (value) => debounce(() {
        setState(() => _volume = value);
        api.updateVolume(value);
      }),
    );
  },
)
```

**Why this matters:** Works with Material, Cupertino, Custom Widgets, or any third-party UI library.

---

## 📚 Complete Widget Reference

### 🛡️ Throttling (Anti-Spam for Buttons)

Executes **immediately**, then blocks for duration.

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Buttons with Material ripple effect |
| `ThrottledTapWidget` | Buttons without ripple |
| `ThrottledBuilder` | **Universal** - Works with ANY widget |
| `AsyncThrottledCallbackBuilder` | Async operations with auto loading state |
| `AsyncThrottledCallback` | Async operations (manual mounted check) |
| `Throttler` | Direct class usage (advanced) |

**When to use:** Button clicks, form submissions, prevent spam clicks

---

### ⏱️ Debouncing (Search, Auto-save)

Waits for **pause**, then executes.

| Widget | Use Case |
|--------|----------|
| `DebouncedTextController` | Basic text input debouncing |
| `AsyncDebouncedTextController` | Search API with auto-cancel & loading state |
| `DebouncedBuilder` | **Universal** - Works with ANY widget |
| `AsyncDebouncedCallbackBuilder` | Async with loading state |
| `Debouncer` | Direct class usage (advanced) |

**When to use:** Search input, auto-save, real-time validation

---

### 🎮 High-Frequency Events

| Widget | Use Case |
|--------|----------|
| `HighFrequencyThrottler` | Scroll, mouse move, resize (60fps max, zero Timer overhead) |

---

## 💼 Real-World Scenarios

### 🛒 E-Commerce: Prevent Double Checkout

**Problem:** User clicks "Place Order" twice during slow network → Payment charged twice.

```dart
ThrottledInkWell(
  onTap: () async => await placeOrder(),
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.green,
    child: Text("Place Order - \$199.99"),
  ),
)
// ✅ Second click ignored for 500ms - No duplicate orders
```

---

### 🔍 Search with Race Condition Prevention

**Problem:** User types "abc", API for "a" returns after "abc" → Wrong results displayed.

```dart
AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await searchProducts(text),
  onSuccess: (products) => setState(() => _products = products),
  onLoadingChanged: (loading) => setState(() => _searching = loading),
)
// ✅ Old API calls auto-cancelled
// ✅ Only latest result displayed
```

---

### 📝 Form with Auto Loading State

**Problem:** No feedback during submission → User clicks again → Duplicate submit.

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async {
    await validateForm();
    await submitForm();
    if (!context.mounted) return;
    Navigator.pop(context);
  },
  onError: (error, stack) => showSnackBar('Failed: $error'),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback,
      child: isLoading ? CircularProgressIndicator() : Text("Submit"),
    );
  },
)
// ✅ Button auto-disabled during submit
// ✅ Loading indicator auto-managed
```

---

### 💬 Chat App: Prevent Message Spam

**Problem:** User presses Enter rapidly → Sends duplicate messages.

```dart
ThrottledBuilder(
  duration: Duration(seconds: 1),
  builder: (context, throttle) {
    return IconButton(
      onPressed: throttle(() => sendMessage(_controller.text)),
      icon: Icon(Icons.send),
    );
  },
)
// ✅ Max 1 message per second
```

---

## 🎓 Throttle vs Debounce: Which One?

### Throttle (Anti-Spam)

**Fires immediately**, then ignores clicks for a duration.

```
User clicks: ▼     ▼   ▼▼▼       ▼
Executes:    ✓     X   X X       ✓
             |<-500ms->|         |<-500ms->|
```

**Use for:** Buttons, Submits, Refresh actions

---

### Debounce (Delay)

**Waits for a pause** in action, then fires.

```
User types:  a  b  c  d ... (pause) ... e  f  g
Executes:                   ✓                   ✓
             |<--300ms wait-->|     |<--300ms wait-->|
```

**Use for:** Search bars, Auto-save, Slider values

---

### AsyncDebouncer (Debounce + Auto-Cancel)

**Waits for pause + Cancels previous async operations.**

```
User types:  a    b    c  (API starts) ... d
API calls:   X    X    ▼ (running...)   X (cancelled)
Result used:                            ✓ (only 'd')
```

**Use for:** Search APIs, autocomplete, async validation

---

## 🔄 Migration from Other Libraries

### From `easy_debounce`

**Why migrate?** Stop managing string IDs manually. Stop worrying about memory leaks.

```dart
// Before: Manual ID management, easy to forget dispose
import 'package:easy_debounce/easy_debounce.dart';

void onSearch(String text) {
  EasyDebounce.debounce(
    'search-tag', // ❌ Manage ID manually
    Duration(milliseconds: 300),
    () async {
      final result = await api.search(text);
      if (!mounted) return; // ❌ Easy to forget
      setState(() => _results = result);
    },
  );
}

@override
void dispose() {
  EasyDebounce.cancel('search-tag'); // ❌ Easy to forget
  super.dispose();
}

// After: Auto-everything, 70% less code
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (results) => setState(() => _results = results),
)
// ✅ Auto-dispose, auto mounted check, no ID management
```

**Benefits:**
- ✅ No string ID management
- ✅ Auto-dispose (zero memory leaks)
- ✅ Built-in loading state
- ✅ Auto race condition prevention

---

### From `flutter_smart_debouncer`

**Why migrate?** Stop being locked into hard-coded widgets. Use ANY widget you want.

```dart
// Before: Locked to specific widget
SmartDebouncerButton(
  onPressed: () => submit(),
  child: Text("Submit"),
)
// ❌ What if you need CupertinoButton? FloatingActionButton? Custom widget?

// After: Universal builder - Use ANY widget
ThrottledBuilder(
  builder: (context, throttle) {
    return CupertinoButton( // Or FloatingActionButton, Custom, etc.
      onPressed: throttle(() => submit()),
      child: Text("Submit"),
    );
  },
)
```

**Benefits:**
- ✅ Works with ANY widget (Material, Cupertino, Custom)
- ✅ Not locked into specific UI components
- ✅ More flexible and future-proof
- ✅ Built-in loading state

---

### From `rxdart`

**Why migrate?** For simple UI events, you don't need Stream complexity.

```dart
// Before: 15+ lines with Stream/BehaviorSubject
final _searchController = BehaviorSubject<String>();

@override
void initState() {
  super.initState();
  _searchController.stream
    .debounceTime(Duration(milliseconds: 300))
    .listen((text) async {
      final result = await api.search(text);
      if (!mounted) return;
      setState(() => _result = result);
    });
}

@override
void dispose() {
  _searchController.close();
  super.dispose();
}

// After: 3 lines, no Stream knowledge needed
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result),
)
```

**Benefits:**
- ✅ 80% less boilerplate
- ✅ No need to learn Streams/Subjects/Operators
- ✅ Auto mounted check (zero crashes)
- ✅ Flutter-first design (optimized for UI events)

**When to still use RxDart:**
- Complex reactive state management across multiple screens
- Need advanced operators (`combineLatest`, `switchMap`, etc.)
- Building reactive architecture (BLoC pattern)

---

## 🔧 Advanced Features

### Custom Durations

```dart
ThrottledInkWell(
  duration: Duration(seconds: 1), // Configurable
  onTap: () => submit(),
  child: Text('Submit'),
)
```

### Reset Throttle Manually

```dart
final throttler = Throttler();

InkWell(
  onTap: throttler.wrap(() => handleTap()),
  child: Text('Tap me'),
)

// Reset to allow immediate next call
throttler.reset();

// Check current state
if (throttler.isThrottled) {
  print('Currently blocked');
}
```

### Flush Debouncer (Execute Immediately)

```dart
final controller = DebouncedTextController(
  onChanged: (text) => search(text),
);

// User presses Enter → Execute immediately without waiting
onSubmit() {
  controller.flush(); // Cancels timer, executes now
}
```

### Manual Cancel

```dart
final debouncer = AsyncDebouncer();

// Start debounced operation
debouncer.run(() async => await api.call());

// Cancel all pending operations
debouncer.cancel();
```

---

## ⚠️ Common Pitfalls

### 1. Forgetting Mounted Check with Builder Widgets

```dart
// ❌ BAD - Will crash if widget unmounts during async operation
AsyncDebouncedBuilder(
  builder: (context, debounce) {
    return TextField(
      onChanged: (text) => debounce(() async {
        final result = await api.search(text);
        setState(() => _result = result); // ❌ Crash if unmounted!
      }),
    );
  },
)

// ✅ GOOD - Always check mounted
AsyncDebouncedBuilder(
  builder: (context, debounce) {
    return TextField(
      onChanged: (text) => debounce(() async {
        final result = await api.search(text);
        if (!mounted) return; // ✅ Safe
        setState(() => _result = result);
      }),
    );
  },
)

// ✅ BETTER - Use CallbackBuilder for automatic mounted check
AsyncDebouncedCallbackBuilder(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result), // ✅ Auto-checks mounted
  builder: (context, callback, isLoading) => TextField(onChanged: callback),
)
```

### 2. Not Handling Null from AsyncDebouncer

```dart
// ❌ BAD - Can crash if result is null (cancelled)
final result = await asyncDebouncer.run(() async => await api.call());
processResult(result); // ❌ Crash if cancelled

// ✅ GOOD - Check for cancellation
final result = await asyncDebouncer.run(() async => await api.call());
if (result == null) return; // Operation was cancelled
processResult(result); // ✅ Safe
```

### 3. Providing Both `controller` and `initialValue`

```dart
// ❌ BAD - Will throw assertion error
DebouncedTextController(
  controller: myController,
  initialValue: "test", // ❌ Conflict!
  onChanged: (text) => search(text),
)

// ✅ GOOD - Use controller only
final controller = TextEditingController(text: "initial");
DebouncedTextController(
  controller: controller,
  onChanged: (text) => search(text),
)

// ✅ GOOD - Use initialValue only
DebouncedTextController(
  initialValue: "initial",
  onChanged: (text) => search(text),
)
```

---

## ❓ FAQ

### Q: Can I use this with GetX/Riverpod/Bloc?

**A:** Yes! State-management agnostic.

```dart
// GetX
ThrottledInkWell(
  onTap: () => Get.find<MyController>().submit(),
  child: Text("Submit"),
)

// Riverpod
AsyncDebouncedTextController(
  onChanged: (text) async => await ref.read(searchProvider.notifier).search(text),
  onSuccess: (results) => /* update state */,
)

// Bloc
ThrottledBuilder(
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => context.read<MyBloc>().add(SubmitEvent())),
      child: Text("Submit"),
    );
  },
)
```

### Q: How to test widgets using this library?

```dart
testWidgets('throttle blocks rapid clicks', (tester) async {
  int clickCount = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: ThrottledInkWell(
        duration: Duration(milliseconds: 500),
        onTap: () => clickCount++,
        child: Text('Tap'),
      ),
    ),
  );

  await tester.tap(find.text('Tap'));
  await tester.pump();
  expect(clickCount, 1);

  await tester.tap(find.text('Tap')); // Blocked
  await tester.pump();
  expect(clickCount, 1); // Still 1!

  await tester.pumpAndSettle(Duration(milliseconds: 500));

  await tester.tap(find.text('Tap')); // Works again
  await tester.pump();
  expect(clickCount, 2);
});
```

### Q: Performance overhead?

**A:** Near-zero!
- **Throttle/Debounce:** ~0.01ms per call
- **High-Frequency Throttler:** ~0.001ms (100x faster, uses `DateTime` instead of `Timer`)
- **Memory:** ~40 bytes per controller

---

## 🛠 Installation

```yaml
dependencies:
  flutter_event_limiter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

Import:

```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';
```

---

## 🤝 Contributing

We welcome contributions! Please feel free to check the issues or submit a PR.

- **Bugs:** Open an issue with a reproduction sample.
- **Features:** Discuss new features in issues before implementing.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

## 📮 Support

- 📧 **Issues:** [GitHub Issues](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/vietnguyentuan2019/flutter_event_limiter/discussions)
- ⭐ **Star this repo** if you find it useful!

---

<p align="center">Made with ❤️ for the Flutter community</p>
