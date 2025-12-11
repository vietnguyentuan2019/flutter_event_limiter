# Getting Started with flutter_event_limiter

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_event_limiter: ^1.1.2
```

Then run:

```bash
flutter pub get
```

## Import

```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';
```

## Quick Start: 3 Common Scenarios

### 1. Prevent Button Double-Clicks (Throttle)

**Problem:** User clicks "Submit" multiple times → Duplicate submissions

**Solution:**
```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500), // Block for 500ms after first click
  onTap: () {
    print('Submitting...');
    submitForm();
  },
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.blue,
    child: Text('Submit', style: TextStyle(color: Colors.white)),
  ),
)
```

[See full E-Commerce example →](./examples/e-commerce.md)

---

### 2. Search Input (Debounce)

**Problem:** API called on every keystroke → Network spam, wrong results

**Solution:**
```dart
AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300), // Wait 300ms after typing stops
  onChanged: (text) async {
    print('Searching for: $text');
    return await ProductApi.search(text);
  },
  onSuccess: (products) {
    setState(() => _searchResults = products);
  },
  onLoadingChanged: (isLoading) {
    setState(() => _isSearching = isLoading);
  },
  builder: (controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search products...',
        suffixIcon: _isSearching
            ? Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.search),
      ),
    );
  },
)
```

[See full Search example →](./examples/search.md)

---

### 3. Form Submission with Loading UI (Async Throttle)

**Problem:** No loading feedback during submission → User clicks again

**Solution:**
```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async {
    // Validate
    if (!_formKey.currentState!.validate()) {
      throw Exception('Please fix form errors');
    }

    // Submit
    await UserApi.register(
      name: _nameController.text,
      email: _emailController.text,
    );

    // Navigate
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SuccessPage()),
    );
  },
  onError: (error, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  },
  builder: (context, callback, isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : callback, // Auto-disable when loading
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : Text('Register'),
      ),
    );
  },
)
```

[See full Form example →](./examples/form-submission.md)

---

## Core Concepts

### When to Use Throttle vs Debounce?

**Use Throttle when:**
- User expects immediate feedback (button clicks)
- First action is most important
- Rate limiting required (scroll, resize)

**Use Debounce when:**
- Waiting for user to finish (typing, dragging)
- Only final value matters (search query)
- Expensive operations (API calls, calculations)

[Learn more →](./guides/throttle-vs-debounce.md)

---

## Widget Patterns

### Pattern 1: Simple Wrapper (Pre-built)

Best for: Quick implementation, common use cases

```dart
// Material button with throttle
ThrottledInkWell(
  onTap: () => action(),
  child: Text("Click Me"),
)

// Text input with debounce
DebouncedTextController(
  onChanged: (text) => search(text),
)
```

### Pattern 2: Universal Builder (Flexible)

Best for: Custom widgets, maximum flexibility

```dart
// Works with ANY widget
ThrottledBuilder(
  builder: (context, throttle) {
    return CupertinoButton(
      onPressed: throttle(() => action()),
      child: Text("Click Me"),
    );
  },
)
```

### Pattern 3: Async Callback Builder (Loading State)

Best for: Async operations, auto loading state

```dart
// Built-in loading state management
AsyncThrottledCallbackBuilder(
  onPressed: () async => await submitForm(),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback,
      child: isLoading ? Loading() : Text("Submit"),
    );
  },
)
```

---

## Next Steps

### Learn More
- [Throttle vs Debounce Explained](./guides/throttle-vs-debounce.md) - Visual guide
- [FAQ](./faq.md) - Common questions answered

### See Examples
- [E-Commerce](./examples/e-commerce.md) - Prevent double checkout
- [Search](./examples/search.md) - Race condition prevention
- [Form Submission](./examples/form-submission.md) - Loading state
- [Chat App](./examples/chat-app.md) - Message spam prevention

### Migration Guides
- [From easy_debounce](./migration/from-easy-debounce.md)
- [From flutter_smart_debouncer](./migration/from-flutter-smart-debouncer.md)
- [From rxdart](./migration/from-rxdart.md)

### API Reference
- [Full documentation on pub.dev](https://pub.dev/documentation/flutter_event_limiter)

---

## Need Help?

- 📚 [FAQ](./faq.md)
- 💬 [GitHub Discussions](https://github.com/vietnguyentuan2019/flutter_event_limiter/discussions)
- 🐛 [Report Issues](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues)
