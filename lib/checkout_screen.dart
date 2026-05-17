import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'upi_qr_screen.dart'; // Removed: Navigation is now handled by the parent widget

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = "cash";
  Map<String, String> spiceLevel = {};
  bool _isPlacing = false;

  int get totalAmount {
    int sum = 0;
    widget.cart.forEach((key, value) {
      final price = (value["price"] as num).toInt();
      final qty = (value["quantity"] as num).toInt();
      sum += price * qty;
    });
    return sum;
  }

  Future<int> _getNextToken() async {
    final settingsRef = FirebaseFirestore.instance
        .collection('settings')
        .doc('token_counter');

    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snap = await transaction.get(settingsRef);

      final now = DateTime.now();
      final today =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      int token;

      if (!snap.exists) {
        token = 1;
      } else {
        final data = snap.data() as Map<String, dynamic>;
        final lastDate = data['last_date'] as String?;
        final lastToken = (data['last_token'] ?? 0) as int;

        token = (lastDate == today) ? lastToken + 1 : 1;
      }

      transaction.set(settingsRef, {
        'last_token': token,
        'last_date': today,
      });

      return token;
    });
  }

  // ✅ EXACT CODE — REPLACED submitOrder()
  Future<void> submitOrder() async {
    if (_isPlacing) return;
    setState(() => _isPlacing = true);

    try {
      final newToken = await _getNextToken();
      final now = DateTime.now();

      final List<Map<String, dynamic>> orderItems =
          widget.cart.entries.map((entry) {
        final item = entry.value;
        return {
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'spice_level': item['spiceSupported']
              ? (spiceLevel[entry.key] ?? "Medium")
              : "None",
        };
      }).toList();

      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      final baseOrderData = {
        'token_number': newToken,
        'items': orderItems,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash'
            ? 'payment_success'
            : 'payment_pending',
        'razorpay_order_id': null,
        'razorpay_payment_id': null,
        'kitchen_status': paymentMethod == 'cash' ? 'pending' : 'blocked',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          now.add(const Duration(seconds: 150)),
        ),
        'source': 'pos_tablet',
      };

      await orderRef.set(baseOrderData);

      // ✅ CASH FLOW (UNCHANGED UX)
      if (paymentMethod == 'cash') {
        Navigator.pop(context, {
          'token': newToken,
          'paymentMethod': 'cash',
        });
        return;
      }

      // ✅ UPI FLOW (DO NOT PLACE ORDER YET)
      Navigator.pop(context, {
       // 'orderId': orderRef.id,
        'token': newToken,
        'amount': totalAmount,
        'paymentMethod': 'upi',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout error: $e")),
      );
      setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: cart.entries.map((entry) {
                  final key = entry.key;
                  final item = entry.value;

                  return Card(
                    color: Colors.white, // ✅ LIGHT CARD
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${item['price']} × ${item['quantity']}",
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          if (item['spiceSupported'])
                            DropdownButton<String>(
                              value: spiceLevel[key] ?? "Medium",
                              dropdownColor: Colors.white,
                              items: ["Low", "Medium", "High"]
                                  .map(
                                    (level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(
                                        "Spice: $level",
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  spiceLevel[key] = value!;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Select Payment Method",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: "cash",
                  groupValue: paymentMethod,
                  onChanged: (v) => setState(() => paymentMethod = v!),
                ),
                const Text("Cash", style: TextStyle(color: Colors.white)),
                Radio<String>(
                  value: "upi",
                  groupValue: paymentMethod,
                  onChanged: (v) => setState(() => paymentMethod = v!),
                ),
                const Text("UPI", style: TextStyle(color: Colors.white)),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              "Total: ₹$totalAmount",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFC94A),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isPlacing ? null : submitOrder,
              child: Text(_isPlacing ? "Placing..." : "Place Order"),
            ),
          ],
        ),
      ),
    );
  }
}