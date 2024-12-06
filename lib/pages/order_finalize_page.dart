import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models/product.dart';
import '../core/models/payment_method.dart';
import '../core/models/coupon.dart';

class OrderFinalizePage extends StatefulWidget {
  const OrderFinalizePage({super.key});

  @override
  State<OrderFinalizePage> createState() => _OrderFinalizePageState();
}

class _OrderFinalizePageState extends State<OrderFinalizePage> {
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _amountTenderedController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _amountTenderedController.dispose();
    super.dispose();
  }

  void _handlePayment(BuildContext context, CartState cartState) {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    if (_selectedPaymentMethod == PaymentMethod.cash) {
      final amountTendered = double.tryParse(_amountTenderedController.text);
      if (amountTendered == null || amountTendered < cartState.total) {
        setState(() {
          _errorMessage = 'Please enter a valid amount equal to or greater than the total';
        });
        return;
      }
    }

    // TODO: Process payment based on selected method
    // For now, just show a success message and clear the cart
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Text('Payment processed via ${_selectedPaymentMethod!.displayName}'),
        actions: [
          TextButton(
            onPressed: () {
              cartState.clearCart();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    return Card(
      elevation: _selectedPaymentMethod == method ? 4 : 1,
      color: _selectedPaymentMethod == method ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
            _errorMessage = null;
            // Clear amount tendered if switching from cash
            if (method != PaymentMethod.cash) {
              _amountTenderedController.clear();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                method.icon,
                size: 32,
                color: _selectedPaymentMethod == method ? Colors.blue : Colors.grey[700],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: _selectedPaymentMethod == method ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedPaymentMethod == method)
                const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipButton(CartState cartState, int percentage) {
    final isSelected = cartState.tipPercentage == percentage;
    return ElevatedButton(
      onPressed: () => cartState.setTipPercentage(percentage.toDouble()),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        '$percentage%',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomTipButton(CartState cartState) {
    final isCustom = cartState.tipPercentage > 0 &&
        cartState.tipPercentage != 10 &&
        cartState.tipPercentage != 15 &&
        cartState.tipPercentage != 20;
    
    return ElevatedButton(
      onPressed: () => _showCustomTipDialog(context, cartState),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isCustom ? Colors.blue : Colors.grey[200],
        foregroundColor: isCustom ? Colors.white : Colors.black87,
        elevation: isCustom ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        isCustom ? '${cartState.tipPercentage.toStringAsFixed(1)}%' : 'Custom',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNoTipButton(CartState cartState) {
    final isSelected = cartState.tipPercentage == 0;
    return ElevatedButton(
      onPressed: () => cartState.setTipPercentage(0),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isSelected ? Colors.red : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'No Tip',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCustomTipDialog(BuildContext context, CartState cartState) {
    final controller = TextEditingController(
      text: cartState.tipPercentage > 0 &&
              cartState.tipPercentage != 10 &&
              cartState.tipPercentage != 15 &&
              cartState.tipPercentage != 20
          ? cartState.tipPercentage.toString()
          : '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Tip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tip Percentage',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (controller.text.isNotEmpty)
              FutureBuilder(
                future: Future.delayed(Duration.zero, () {
                  final percentage = double.tryParse(controller.text) ?? 0;
                  return cartState.subtotal * (percentage / 100);
                }),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Tip Amount: \$${snapshot.data!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final percentage = double.tryParse(controller.text);
              if (percentage != null && percentage >= 0) {
                cartState.setTipPercentage(percentage);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog(BuildContext context, CartState cartState) {
    final controller = TextEditingController();
    String? errorText;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enter Coupon Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: '6-digit code',
                  errorText: errorText,
                  counterText: '${controller.text.length}/6',
                ),
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    controller.text = value.toUpperCase();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                    errorText = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.length != 6) {
                  setState(() {
                    errorText = 'Code must be 6 digits';
                  });
                  return;
                }
                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                  setState(() {
                    errorText = 'Code must contain only numbers';
                  });
                  return;
                }

                // For testing: 
                // Codes starting with 1: 10% off
                // Codes starting with 2: 20% off
                // Codes starting with 5: $5 off
                // Codes starting with 9: $10 off
                final firstDigit = int.parse(code[0]);
                final coupon = Coupon(
                  code: code,
                  amount: switch (firstDigit) {
                    1 => 10.0,
                    2 => 20.0,
                    5 => 5.0,
                    9 => 10.0,
                    _ => 5.0,
                  },
                  description: switch (firstDigit) {
                    1 => '10% off entire order',
                    2 => '20% off entire order',
                    5 => '\$5.00 off order',
                    9 => '\$10.00 off order',
                    _ => '\$5.00 off order',
                  },
                  isPercentage: firstDigit == 1 || firstDigit == 2,
                );
                
                cartState.addCoupon(coupon);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartState cartState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Coupons & Discounts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCouponDialog(context, cartState),
              icon: const Icon(Icons.add),
              label: const Text('Add Coupon'),
            ),
          ],
        ),
        if (cartState.coupons.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ...cartState.coupons.map((coupon) => ListTile(
                  title: Text(coupon.code),
                  subtitle: Text(coupon.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        coupon.isPercentage
                            ? '-${coupon.amount.toStringAsFixed(0)}%'
                            : '-\$${coupon.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => cartState.removeCoupon(coupon),
                        color: Colors.red,
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
        if (cartState.couponDiscount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Total Savings: -\$${cartState.couponDiscount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          // Left side - Order Items
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: item.product.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(item.product.imageUrl!),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {
                                        // Handle image load error
                                      },
                                    )
                                  : null,
                              color: Colors.grey[200],
                            ),
                            child: item.product.imageUrl == null
                                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                                : null,
                          ),
                          title: Text(item.product.name),
                          subtitle: Row(
                            children: [
                              // Quantity adjustment controls
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: item.quantity > 1
                                    ? () => cartState.updateQuantity(index, item.quantity - 1)
                                    : null,
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(
                                width: 40,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final controller = TextEditingController(
                                          text: item.quantity.toString(),
                                        );
                                        return AlertDialog(
                                          title: const Text('Edit Quantity'),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Quantity',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final newQuantity = int.tryParse(controller.text);
                                                if (newQuantity != null && newQuantity > 0) {
                                                  cartState.updateQuantity(index, newQuantity);
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: const Text('Update'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => cartState.updateQuantity(index, item.quantity + 1),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              if (item.product.includesHst)
                                const Text(
                                  'HST Included',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${item.product.price.toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('\$${cartState.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HST (13%):'),
                            Text('\$${cartState.hst.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tip section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tip:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${cartState.tipAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (cartState.tipPercentage > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '(${cartState.tipPercentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildTipButton(cartState, 10),
                                _buildTipButton(cartState, 15),
                                _buildTipButton(cartState, 20),
                                _buildCustomTipButton(cartState),
                                _buildNoTipButton(cartState),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        // Order summary section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('\$${cartState.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Coupons section
                            _buildCouponSection(cartState),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '\$${cartState.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side - Payment Options
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPaymentOption(PaymentMethod.cash),
                            const SizedBox(height: 8),
                            _buildPaymentOption(PaymentMethod.creditCard),
                            const SizedBox(height: 8),
                            _buildPaymentOption(PaymentMethod.debitCard),
                            const SizedBox(height: 8),
                            _buildPaymentOption(PaymentMethod.cashless),
                            const SizedBox(height: 8),
                            _buildPaymentOption(PaymentMethod.points),
                            const SizedBox(height: 8),
                            _buildPaymentOption(PaymentMethod.onAccount),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedPaymentMethod == PaymentMethod.cash) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountTenderedController,
                        decoration: InputDecoration(
                          labelText: 'Amount Tendered',
                          prefixText: '\$',
                          border: const OutlineInputBorder(),
                          errorText: _errorMessage,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 8),
                      if (_amountTenderedController.text.isNotEmpty)
                        Text(
                          'Change: \$${(double.tryParse(_amountTenderedController.text) ?? 0 - cartState.total).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _handlePayment(context, cartState),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Process Payment',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
