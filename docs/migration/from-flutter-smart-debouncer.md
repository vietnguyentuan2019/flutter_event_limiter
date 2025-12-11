# Migration Guide: From flutter_smart_debouncer

## Why Migrate?

`flutter_event_limiter` uses a universal builder pattern that works with **any** Flutter widget, while `flutter_smart_debouncer` locks you into specific hard-coded widgets.

## Key Improvements

- **Universal Builder Pattern** - Works with Material, Cupertino, custom widgets, and third-party UI libraries
- **Not widget-locked** - Use CupertinoButton, FloatingActionButton, or any custom widget
- **Built-in loading state** - Integrated loading state management
- **More flexible** - Adapt to any UI framework or design system
- **Future-proof** - Not tied to specific widget implementations

## Migration Examples

### Example 1: Button Throttling

**Before** (flutter_smart_debouncer):
```dart
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

SmartDebouncerButton(
  onPressed: () => submit(),
  child: Text("Submit"),
)
```

**Limitation:** You're locked into `SmartDebouncerButton`. What if you need a `CupertinoButton`, `FloatingActionButton`, or custom widget?

**After** (flutter_event_limiter):
```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

// Option 1: Material Design
ThrottledBuilder(
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => submit()),
      child: Text("Submit"),
    );
  },
)

// Option 2: Cupertino (iOS style)
ThrottledBuilder(
  builder: (context, throttle) {
    return CupertinoButton(
      onPressed: throttle(() => submit()),
      child: Text("Submit"),
    );
  },
)

// Option 3: Custom Widget
ThrottledBuilder(
  builder: (context, throttle) {
    return MyCustomButton(
      onTap: throttle(() => submit()),
      label: "Submit",
    );
  },
)

// Option 4: Pre-built wrapper (if you don't need customization)
ThrottledInkWell(
  onTap: () => submit(),
  child: Text("Submit"),
)
```

### Example 2: Text Field Debouncing

**Before** (flutter_smart_debouncer):
```dart
SmartDebouncerTextField(
  onChanged: (text) => search(text),
  decoration: InputDecoration(hintText: "Search"),
)
```

**Limitation:** Locked into `SmartDebouncerTextField` implementation.

**After** (flutter_event_limiter):
```dart
// Works with TextField, TextFormField, CupertinoTextField, or custom input
DebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) => search(text),
  builder: (controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: "Search"),
      // Add any TextField properties you need
    );
  },
)

// Or with async search:
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (results) => setState(() => _results = results),
  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
  builder: (controller) {
    return CupertinoTextField(
      controller: controller,
      placeholder: "Search",
      // Full Cupertino customization
    );
  },
)
```

## Flexibility Examples

### Use Case: Multi-Platform App

**Scenario:** You need Material Design on Android and Cupertino on iOS.

**With flutter_smart_debouncer:**
```dart
// Problem: Hard-coded widgets don't adapt to platform
SmartDebouncerButton(
  onPressed: () => submit(),
  child: Text("Submit"),
)
// Same Material button on both platforms
```

**With flutter_event_limiter:**
```dart
// Solution: Platform-adaptive UI
ThrottledBuilder(
  builder: (context, throttle) {
    return Platform.isIOS
        ? CupertinoButton(
            onPressed: throttle(() => submit()),
            child: Text("Submit"),
          )
        : ElevatedButton(
            onPressed: throttle(() => submit()),
            child: Text("Submit"),
          );
  },
)
```

### Use Case: Custom Design System

**Scenario:** Your company has a custom button component.

**With flutter_smart_debouncer:**
```dart
// Problem: Can't use your custom components
SmartDebouncerButton(...) // Doesn't match your design system
```

**With flutter_event_limiter:**
```dart
// Solution: Use your custom components
ThrottledBuilder(
  builder: (context, throttle) {
    return CompanyBrandButton(
      onPressed: throttle(() => submit()),
      variant: ButtonVariant.primary,
      label: "Submit",
    );
  },
)
```

### Use Case: Third-Party UI Library

**Scenario:** Using a UI library like `flutter_neumorphic` or `getwidget`.

**With flutter_smart_debouncer:**
```dart
// Problem: Incompatible with third-party widgets
SmartDebouncerButton(...) // Can't use NeuButton, GFButton, etc.
```

**With flutter_event_limiter:**
```dart
// Solution: Works with any widget library
ThrottledBuilder(
  builder: (context, throttle) {
    return NeuButton(
      onPressed: throttle(() => submit()),
      child: Text("Submit"),
    );
  },
)
```

## Migration Patterns

### Pattern 1: Simple Button Migration

```dart
// Before
SmartDebouncerButton(
  onPressed: () => action(),
  child: Text("Click Me"),
)

// After (quick replacement)
ThrottledInkWell(
  onTap: () => action(),
  child: Text("Click Me"),
)

// After (flexible approach)
ThrottledBuilder(
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => action()),
      style: ElevatedButton.styleFrom(...), // Full customization
      child: Text("Click Me"),
    );
  },
)
```

### Pattern 2: Text Field Migration

```dart
// Before
SmartDebouncerTextField(
  onChanged: (text) => search(text),
  decoration: InputDecoration(hintText: "Search"),
)

// After
DebouncedTextController(
  onChanged: (text) => search(text),
  builder: (controller) {
    return TextFormField( // Or TextField, CupertinoTextField
      controller: controller,
      decoration: InputDecoration(hintText: "Search"),
      validator: (text) => ..., // Add validation
      // Any other properties you need
    );
  },
)
```

## Migration Checklist

- [ ] Remove `flutter_smart_debouncer` from `pubspec.yaml`
- [ ] Add `flutter_event_limiter` to dependencies
- [ ] Replace `SmartDebouncerButton` with `ThrottledBuilder` or `ThrottledInkWell`
- [ ] Replace `SmartDebouncerTextField` with `DebouncedTextController`
- [ ] Customize widgets to match your design requirements
- [ ] Consider using platform-adaptive widgets if building cross-platform
- [ ] Update tests to use flutter_event_limiter's testing approach

## Benefits Summary

| Feature | flutter_smart_debouncer | flutter_event_limiter |
|---------|------------------------|----------------------|
| Works with Material | ✅ | ✅ |
| Works with Cupertino | ❌ | ✅ |
| Works with custom widgets | ❌ | ✅ |
| Works with third-party UI libs | ❌ | ✅ |
| Platform-adaptive | ❌ | ✅ |
| Design system friendly | ❌ | ✅ |
| Built-in loading state | ❌ | ✅ |

## Need Help?

- See [Getting Started Guide](../getting-started.md) for basics
- Check [FAQ](../faq.md) for common questions
- Browse [Examples](../../example/) for real-world usage
- Open an issue on [GitHub](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues) for migration support
