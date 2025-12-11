# Example: E-Commerce - Prevent Double Checkout

## Problem Statement

In e-commerce applications, users often click the "Place Order" or "Checkout" button multiple times, especially during slow network conditions. This can result in:

- Duplicate orders charged to the customer
- Inventory issues (over-selling)
- Customer service complaints
- Payment gateway issues

## Solution: Throttled Button

Use `ThrottledInkWell` or `ThrottledBuilder` to prevent rapid successive clicks on critical payment buttons.

## Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class CheckoutButton extends StatelessWidget {
  final VoidCallback onCheckout;

  const CheckoutButton({Key? key, required this.onCheckout}) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return ThrottledInkWell(
      duration: Duration(seconds: 1), // Prevent clicks for 1 second
      onTap: onCheckout,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            "Place Order - \$199.99",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

**Result:** Second click ignored for 1 second - No duplicate orders! ✅

## Advanced Implementation with Loading State

For better UX, show loading indicator and disable button during payment processing:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Future<void> _processPayment() async {
    // Simulate payment processing
    await Future.delayed(Duration(seconds: 2));

    // Process payment
    final success = await PaymentService.processOrder(
      amount: 199.99,
      items: _cartItems,
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderConfirmationPage()),
      );
    } else {
      throw Exception('Payment failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Column(
        children: [
          // Cart summary
          Expanded(child: CartSummaryWidget()),

          // Checkout button with auto loading state
          Padding(
            padding: EdgeInsets.all(16),
            child: AsyncThrottledCallbackBuilder(
              onPressed: _processPayment,
              onError: (error, stack) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment failed: $error')),
                );
              },
              builder: (context, callback, isLoading) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : callback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                              Text(
                                'Processing...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : Text(
                            'Place Order - \$199.99',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Key Features

✅ **Prevents duplicate orders** - First click executes, subsequent clicks blocked
✅ **Auto-managed loading state** - No manual boolean flags needed
✅ **Button auto-disabled** - UX feedback during processing
✅ **Error handling built-in** - `onError` callback for failed payments
✅ **Auto mounted checks** - Prevents crashes if user navigates away

## Comparison: Manual vs Library

### Without flutter_event_limiter (Manual):

```dart
class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  DateTime? _lastClickTime;

  void _onCheckoutPressed() async {
    // Manual throttle check
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) < Duration(seconds: 1)) {
      return; // Ignore rapid clicks
    }
    _lastClickTime = now;

    // Manual loading state
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _processPayment();
      if (!mounted) return; // Must remember this!
      // Navigate to success page
    } catch (e) {
      if (!mounted) return; // Must remember this!
      // Show error
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _onCheckoutPressed,
      child: _isProcessing ? CircularProgressIndicator() : Text('Checkout'),
    );
  }
}
```

**Issues:** 25+ lines, manual state management, easy to forget `mounted` checks

### With flutter_event_limiter:

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async => await _processPayment(),
  onError: (error, stack) => showError(error),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback,
      child: isLoading ? CircularProgressIndicator() : Text('Checkout'),
    );
  },
)
```

**Benefits:** 10 lines, auto state management, auto `mounted` checks ✅

## Related Examples

- [Form Submission](./form-submission.md) - Similar pattern for forms
- [Chat App](./chat-app.md) - Preventing message spam
- [Search](./search.md) - Debouncing search input

## Learn More

- [Throttle vs Debounce](../guides/throttle-vs-debounce.md)
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)
- [Migration from RxDart](../migration/from-rxdart.md)
