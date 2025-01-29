# Flutter Event Limiter 🛡️

[![pub package](https://img.shields.io/pub/v/flutter_event_limiter.svg)](https://pub.dev/packages/flutter_event_limiter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Stop Spam Clicks. Fix Race Conditions. Prevent Memory Leaks.**

A production-ready library to handle **Throttling** (anti-spam) and **Debouncing** (search APIs) with built-in safety checks.

---

## 🚀 Why use this?

Standard Flutter `InkWell` or `Timer` usually leads to these bugs:

* ❌ **Double Click Crash:** User taps "Submit" twice → API calls twice → Database error.
* ❌ **Race Conditions:** User types "a", then "ab". API "a" returns *after* "ab" → UI shows wrong result.
* ❌ **Memory Leaks:** `setState() called after dispose()` when the API returns late.

**✅ This library fixes ALL of them automatically.**

### Comparison with Other Libraries

| Feature | `flutter_event_limiter` | `easy_debounce` | `rxdart` |
| :--- | :---: | :---: | :---: |
| **Prevents Double Clicks** | ✅ | ❌ | ⚠️ (Complex) |
| **Fixes Race Conditions** | ✅ (Auto-cancel) | ❌ | ✅ |
| **Auto `mounted` Check** | ✅ (Safe setState) | ❌ | ❌ |
| **Universal Builder** | ✅ (Works with ANY widget) | ❌ | ❌ |
| **Loading State Management** | ✅ (Built-in) | ❌ | ❌ |
| **Zero Boilerplate** | ✅ | ❌ | ❌ |
| **Memory Leak Prevention** | ✅ (Auto-dispose) | ⚠️ (Manual) | ⚠️ (Manual) |

---

## 📦 Installation

Add to your `pubspec.yaml`:

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

## 🔥 Quick Start

### 1. Prevent Double Clicks (Throttling)

Wrap your button. That's it. It ignores clicks for 500ms (configurable) after the first one.

```dart
ThrottledInkWell(
  onTap: () => submitOrder(), // 👈 Safe! Only runs once per 500ms
  onDoubleTap: () => handleDoubleTap(), // ✅ Also throttled!
  onLongPress: () => showMenu(), // ✅ Also throttled!
  child: Container(
    padding: EdgeInsets.all(12),
    child: Text("Submit Order"),
  ),
)
```

**Result:** No matter how fast the user clicks, `submitOrder()` only runs once every 500ms.

---

### 2. Search API with Auto-Cancel (Async Debouncing)

Perfect for search bars. It waits for the user to stop typing, and automatically cancels previous pending API calls to prevent UI flickering.

```dart
AsyncDebouncedTextController<List<User>>(
  // 1. Auto-waits 300ms after user stops typing
  // 2. Auto-cancels previous request if user keeps typing
  onChanged: (text) async => await api.searchUsers(text),

  // 3. Auto-checks 'mounted' before calling this
  onSuccess: (users) => setState(() => _users = users),

  // 4. Handles errors gracefully
  onError: (error, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Search failed: $error')),
    );
  },

  // 5. Manages loading state automatically
  onLoadingChanged: (isLoading) => setState(() => _loading = isLoading),
)
```

**What it does:**
- User types "a" → Timer starts (300ms)
- User types "ab" → Previous timer cancelled, new timer starts
- User stops typing → After 300ms, API call starts
- User types "abc" while "ab" API is running → "ab" result is ignored, only "abc" result is used

**Result:** Zero race conditions, zero memory leaks, smooth UX.

---

### 3. Form Submit with Loading State

Prevents double-submission and provides loading state out of the box.

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async {
    await api.uploadFile(); // 🔒 Button stays locked until this finishes
    Navigator.pop(context); // ✅ Auto-checks mounted before navigation
  },
  onError: (error, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $error')),
    );
  },
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback, // Disable when loading
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text("Upload"),
    );
  },
)
```

**Result:** Button disabled during upload, automatic error handling, zero boilerplate.

---

## 🧩 Advanced Usage: The "Builder" Pattern

Don't like our wrappers? Want to use a custom `GestureDetector`, `FloatingActionButton`, or `Slider`? Use the **Builders**. They give you a "wrapped" callback to use anywhere.

### Universal Throttler (For ANY Widget)

```dart
ThrottledBuilder(
  duration: Duration(seconds: 1),
  builder: (context, throttle) {
    return FloatingActionButton(
      // Wrap your callback with 'throttle()'
      onPressed: throttle(() => saveData()),
      child: Icon(Icons.save),
    );
  },
)
```

### Universal Debouncer (For ANY Widget)

```dart
DebouncedBuilder(
  duration: Duration(milliseconds: 500),
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

### Universal Async Throttle (For Custom Async Operations)

```dart
AsyncThrottledBuilder(
  maxDuration: Duration(seconds: 30), // Timeout for long operations
  builder: (context, throttle) {
    return CustomButton(
      onPressed: throttle(() async {
        try {
          await api.processLargeFile();
          if (!mounted) return; // ✅ Check mounted before context usage
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          showErrorDialog(context, e);
        }
      }),
    );
  },
)
```

**Note:** For async builders without automatic error handling, you must handle errors manually with try-catch.

---

## 📚 Complete Widget Reference

### Throttling (Prevent Spam Clicks)

| Widget | Use Case | Features |
|--------|----------|----------|
| `ThrottledInkWell` | Basic buttons with ripple | onTap, onDoubleTap, onLongPress |
| `ThrottledTapWidget` | Buttons without ripple | Custom GestureDetector |
| `ThrottledCallback` | Custom callback wrapper | Used by BaseButton |
| `ThrottledBuilder` | **Universal** (works with ANY widget) | Maximum flexibility |
| `Throttler` | Direct class usage (advanced) | Access to `isThrottled`, `reset()` |

### Debouncing (Search, Auto-save)

| Widget | Use Case | Features |
|--------|----------|----------|
| `DebouncedTextController` | Text input debouncing | Sync callback, manual mounted check |
| `AsyncDebouncedTextController` | Search API with loading state | Auto-cancel, loading state, error handling |
| `DebouncedCallback` | Custom callback wrapper | Sync operations |
| `DebouncedBuilder` | **Universal** (works with ANY widget) | Maximum flexibility |
| `Debouncer` | Direct class usage (advanced) | Access to `flush()`, `cancel()` |

### Async Operations (Form Submit, File Upload)

| Widget | Use Case | Features |
|--------|----------|----------|
| `AsyncThrottledCallbackBuilder` | Form submit with loading state | Auto loading, error handling, mounted check |
| `AsyncThrottledCallback` | Form submit (manual mounted check) | Simple wrapper |
| `AsyncThrottledBuilder` | **Universal** async throttle | Maximum flexibility |
| `AsyncDebouncedCallbackBuilder` | Search with loading state | Auto-cancel, loading state, error handling |
| `AsyncDebouncedCallback` | Search (manual mounted check) | Simple wrapper |
| `AsyncDebouncedBuilder` | **Universal** async debounce | Maximum flexibility |
| `AsyncDebouncer` | Direct class usage (advanced) | ID-based cancellation, `Future<T?>` |
| `AsyncThrottler` | Direct class usage (advanced) | Process-based locking, timeout |

### High-Frequency Events (Scroll, Resize)

| Widget | Use Case | Features |
|--------|----------|----------|
| `HighFrequencyThrottler` | 60fps events (scroll, mouse move) | DateTime-based, zero Timer overhead |

---

## ⚠️ Comparison: The Old Way vs The New Way

### ❌ The Old Way (Bad)

```dart
// Manually handling timer and cleanup... nightmare!
Timer? _timer;
bool _isLoading = false;

void onSearch(String text) {
  _timer?.cancel();
  _timer = Timer(Duration(milliseconds: 300), () async {
    setState(() => _isLoading = true);
    try {
      final result = await api.search(text);
      if (!mounted) return; // Must remember this!
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Must remember this again!
      setState(() => _isLoading = false);
      // Handle error...
    }
  });
}

@override
void dispose() {
  _timer?.cancel(); // Must remember this!
  super.dispose();
}
```

**Problems:**
- 15+ lines of boilerplate
- Easy to forget `mounted` check → crash
- Easy to forget `dispose()` → memory leak
- Manual loading state management
- Manual error handling

### ✅ The New Way (Good)

```dart
// Zero boilerplate. Auto-dispose. Auto-mounted check. Auto-loading state.
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result),
  onError: (e, stack) => showErrorDialog(e),
  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
)
```

**Benefits:**
- 4 lines of code
- Automatic `mounted` check
- Automatic `dispose()`
- Automatic loading state
- Automatic error handling
- Automatic race condition prevention

---

## 🎓 Understanding Throttle vs Debounce

### Throttle (Fire Immediately, Then Block)

```
User clicks: ▼     ▼   ▼▼▼       ▼
Executes:    ✓     X   X X       ✓
             |<-500ms->|         |<-500ms->|
```

**Use for:** Button clicks, scroll events, resize events

### Debounce (Wait for Pause, Then Fire)

```
User types:  a  b  c  d ... (pause) ... e  f  g
Executes:                   ✓                   ✓
             |<--300ms wait-->|     |<--300ms wait-->|
```

**Use for:** Search input, auto-save, real-time validation

### AsyncDebouncer (Debounce + Auto-Cancel)

```
User types:  a    b    c  (API for 'abc' starts) ... d
API calls:   X    X    ▼ (running...)            X (result ignored)
             |<-wait->|                          |<-wait->|
Result used:                                     ✓ (only 'd')
```

**Use for:** Search APIs, autocomplete, async validation

---

## 🔧 Advanced Features

### 1. Custom Durations

```dart
// Throttle with 1 second window
ThrottledInkWell(
  duration: Duration(seconds: 1),
  onTap: () => submit(),
  child: Text('Submit'),
)

// Debounce with 500ms delay
AsyncDebouncedTextController(
  duration: Duration(milliseconds: 500),
  onChanged: (text) async => await api.search(text),
)
```

### 2. Reset Throttle Manually

```dart
final throttler = Throttler();

// Use throttler
InkWell(
  onTap: throttler.wrap(() => handleTap()),
  child: Text('Tap me'),
)

// Reset throttle (allow immediate next call)
throttler.reset();

// Check state
if (throttler.isThrottled) {
  print('Currently blocked');
}
```

### 3. Flush Debouncer (Execute Immediately)

```dart
final controller = DebouncedTextController(
  onChanged: (text) => search(text),
);

// User presses Enter → Execute immediately without waiting
onSubmit() {
  controller.flush(); // Cancels timer and executes now
}
```

### 4. Manual Cancel

```dart
final debouncer = AsyncDebouncer();

// Start debounced operation
debouncer.run(() async => await api.call());

// Cancel all pending operations
debouncer.cancel();
```

---

## 🐛 Common Pitfalls

### 1. ❌ Forgetting Mounted Check with Builder Widgets

```dart
// ❌ BAD - AsyncDebouncedBuilder doesn't auto-check mounted
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
        if (!mounted) return; // ✅ Safe!
        setState(() => _result = result);
      }),
    );
  },
)

// ✅ BETTER - Use AsyncDebouncedCallbackBuilder for auto-check
AsyncDebouncedCallbackBuilder(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result), // ✅ Auto-checks mounted!
  builder: (context, callback, isLoading) => TextField(onChanged: callback),
)
```

### 2. ❌ Not Handling Null Results from AsyncDebouncer

```dart
// ❌ BAD - Null check missing
final result = await asyncDebouncer.run(() async => await api.call());
processResult(result); // ❌ Crash if result is null (cancelled)

// ✅ GOOD - Check for cancellation
final result = await asyncDebouncer.run(() async => await api.call());
if (result == null) return; // Cancelled by newer call
processResult(result); // ✅ Safe!
```

### 3. ❌ Providing Both `controller` and `initialValue`

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

## 🧪 Testing

Unit tests coming soon! (Contributions welcome)

---

## 📄 License

MIT License. See [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

---

## 📮 Support

- 📧 Issues: [GitHub Issues](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/vietnguyentuan2019/flutter_event_limiter/discussions)
- ⭐ Star this repo if you find it useful!

---

## 🎯 Roadmap

- [ ] Unit tests (60+ test cases)
- [ ] Integration tests with example app
- [ ] Performance benchmarks
- [ ] Video tutorials
- [ ] More examples (e-commerce, chat app, etc.)

---

**Made with ❤️ for the Flutter community**
