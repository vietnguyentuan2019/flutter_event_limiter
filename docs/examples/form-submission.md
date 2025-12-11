# Example: Form Submission with Auto Loading State

## Problem Statement

Form submissions often have these issues:

- **Duplicate submissions:** User clicks "Submit" multiple times → Multiple API calls
- **No feedback:** User unsure if form is processing
- **Poor error handling:** Errors not communicated clearly
- **Manual state management:** Lots of boilerplate for loading/error states

## Solution: Async Throttled Callback Builder

Use `AsyncThrottledCallbackBuilder` to throttle submission, show loading state, and handle errors automatically.

## Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      throw Exception('Please fix form errors');
    }

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    // Submit to backend
    final success = await UserApi.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!success) {
      throw Exception('Registration failed. Email may already exist.');
    }

    // Navigate to success page
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 8) return 'Min 8 characters';
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Submit button with auto loading state
              AsyncThrottledCallbackBuilder(
                onPressed: _submitForm,
                onError: (error, stack) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                builder: (context, callback, isLoading) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : callback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey,
                      ),
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
                          : Text(
                              'Register',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

## Advanced: Multi-Step Form

```dart
class MultiStepForm extends StatefulWidget {
  @override
  _MultiStepFormState createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  Future<void> _submitStep() async {
    if (!_formKeys[_currentStep].currentState!.validate()) {
      throw Exception('Please complete all required fields');
    }

    // Save step data
    await _saveStepData(_currentStep);

    // Move to next step or finish
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      await _finalSubmit();
    }
  }

  Future<void> _saveStepData(int step) async {
    await Future.delayed(Duration(milliseconds: 500));
    // Save to backend or local storage
  }

  Future<void> _finalSubmit() async {
    await UserApi.submitRegistration(_allFormData);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration - Step ${_currentStep + 1}/3'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: null, // Disabled, use our custom button
        controlsBuilder: (context, details) {
          return Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: Text('Back'),
                  ),
                SizedBox(width: 12),
                Expanded(
                  child: AsyncThrottledCallbackBuilder(
                    onPressed: _submitStep,
                    onError: (error, stack) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    },
                    builder: (context, callback, isLoading) {
                      return ElevatedButton(
                        onPressed: isLoading ? null : callback,
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep < 2 ? 'Continue' : 'Finish',
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text('Personal Info'),
            content: Form(key: _formKeys[0], child: _buildStep1()),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: Text('Account Details'),
            content: Form(key: _formKeys[1], child: _buildStep2()),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: Text('Preferences'),
            content: Form(key: _formKeys[2], child: _buildStep3()),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    // Personal info fields
    return Column(/* ... */);
  }

  Widget _buildStep2() {
    // Account details fields
    return Column(/* ... */);
  }

  Widget _buildStep3() {
    // Preferences fields
    return Column(/* ... */);
  }
}
```

## Comparison: Manual vs Library

### Without flutter_event_limiter (Manual):

```dart
class _FormState extends State<RegistrationForm> {
  bool _isSubmitting = false;
  DateTime? _lastSubmitTime;

  void _onSubmit() async {
    // Manual throttle check
    final now = DateTime.now();
    if (_lastSubmitTime != null &&
        now.difference(_lastSubmitTime!) < Duration(seconds: 1)) {
      return; // Ignore rapid clicks
    }
    _lastSubmitTime = now;

    // Manual loading state
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!_formKey.currentState!.validate()) {
        setState(() => _isSubmitting = false);
        return;
      }

      await _submitForm();

      if (!mounted) return; // Must remember this!
      Navigator.pushReplacement(context, /* ... */);
    } catch (e) {
      if (!mounted) return; // Must remember this!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _onSubmit,
      child: _isSubmitting
          ? CircularProgressIndicator()
          : Text('Submit'),
    );
  }
}
```

**Issues:** 40+ lines, manual state management, easy to forget `mounted` checks

### With flutter_event_limiter:

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async {
    if (!_formKey.currentState!.validate()) {
      throw Exception('Form invalid');
    }
    await _submitForm();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, /* ... */);
  },
  onError: (error, stack) => showError(error),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback,
      child: isLoading ? CircularProgressIndicator() : Text('Submit'),
    );
  },
)
```

**Benefits:** 15 lines, auto state management, built-in error handling ✅

## Key Features

✅ **Prevents duplicate submissions** - Throttle ensures one submission at a time
✅ **Auto-managed loading state** - No manual boolean flags needed
✅ **Button auto-disabled** - UX feedback during processing
✅ **Error handling built-in** - `onError` callback for failed submissions
✅ **Auto mounted checks** - Prevents crashes if user navigates away
✅ **Works with validation** - Integrates seamlessly with Flutter's Form validation

## Best Practices

### 1. Validate Before Submitting

```dart
onPressed: () async {
  if (!_formKey.currentState!.validate()) {
    throw Exception('Please fix errors');
  }
  await _submitToApi();
},
```

### 2. Show Specific Error Messages

```dart
onError: (error, stack) {
  String message;
  if (error.toString().contains('network')) {
    message = 'Check your internet connection';
  } else if (error.toString().contains('email')) {
    message = 'Email already registered';
  } else {
    message = 'Something went wrong';
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
},
```

### 3. Disable Form During Submission

```dart
builder: (context, callback, isLoading) {
  return AbsorbPointer(
    absorbing: isLoading, // Disable entire form while loading
    child: Column(
      children: [
        TextFormField(...), // Disabled during submission
        TextFormField(...),
        ElevatedButton(
          onPressed: isLoading ? null : callback,
          child: isLoading ? Loading() : Text('Submit'),
        ),
      ],
    ),
  );
},
```

## Related Examples

- [E-Commerce](./e-commerce.md) - Similar pattern for checkout
- [Search](./search.md) - Debounced form input
- [Chat App](./chat-app.md) - Message sending throttling

## Learn More

- [Throttle vs Debounce](../guides/throttle-vs-debounce.md)
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)
- [Error Handling Best Practices](../guides/error-handling.md)
