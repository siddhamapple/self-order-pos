import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'checkout_screen.dart';
import 'printer/printer_service.dart';
import 'upi_qr_screen.dart'; // ✅ Make sure this file exists

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

/// ---------------- MENU ITEM IMAGE ----------------
class MenuItemImage extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const MenuItemImage({
    super.key,
    this.imageUrl,
    this.height = 110,
  });

  Widget _placeholder() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood,
        size: 36,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    if (imageUrl!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}

/// ---------------- MAIN MENU SCREEN ----------------
class _MenuScreenState extends State<MenuScreen> {
  // Cart: key = menu_item doc id
  final Map<String, _CartItem> _cart = {};

  int get totalItems =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalAmount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity * item.price);

  void _addToCart(String id, String name, int price, bool spiceSupported) {
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id] = _cart[id]!.copyWith(
          quantity: _cart[id]!.quantity + 1,
        );
      } else {
        _cart[id] = _CartItem(
          id: id,
          name: name,
          price: price,
          quantity: 1,
          spiceSupported: spiceSupported,
        );
      }
    });
  }

  void _removeFromCart(String id) {
    if (!_cart.containsKey(id)) return;
    final current = _cart[id]!;
    setState(() {
      if (current.quantity > 1) {
        _cart[id] = current.copyWith(quantity: current.quantity - 1);
      } else {
        _cart.remove(id);
      }
    });
  }

  /// ✅ 1. Helper to Print Receipt & Show Success Dialog
  Future<void> _finalizeOrder(int token, String method) async {
    // Snapshot items for receipt before clearing cart
    final itemsForReceipt = _cart.values.map((item) {
      return {
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      };
    }).toList();

    // Try Printing
    final bool printed = await PrinterService.tryPrintReceipt(
      token: token,
      paymentMode: method,
      items: itemsForReceipt,
    );

    if (!printed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Printer not connected. Order placed, you can reprint later.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Clear Cart
    setState(() {
      _cart.clear();
    });

    // Show Success Dialog
    final bool isCash = method == 'cash';
    final String message = isCash
        ? "Token #$token\n\nThanks! Please proceed to the counter to make cash payment and collect your bill."
        : "Token #$token\n\nThanks! Your UPI order is verified. Please collect your bill from the counter.";

    if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Order Placed"),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  /// ✅ 2. Updated Checkout Logic (FIXED orderId REMOVED)
  Future<void> _goToCheckout(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cart: _cart.map(
            (key, value) => MapEntry(
              key,
              {
                'id': value.id,
                'name': value.name,
                'price': value.price,
                'quantity': value.quantity,
                'spiceSupported': value.spiceSupported,
              },
            ),
          ),
        ),
      ),
    );

    // ✅ CHECK RESULT FROM CHECKOUT SCREEN
    if (result != null &&
        (result['paymentMethod'] == 'cash' ||
            result['paymentMethod'] == 'upi')) {
      
      final String method = result['paymentMethod'];
      final int token = result['token'];

      if (method == 'cash') {
        // --- FLOW A: CASH ---
        await _finalizeOrder(token, 'cash');
      } else {
        // --- FLOW B: UPI ---
        if (!mounted) return;
        
        final qrResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpiQrScreen(
              amount: totalAmount,
              token: token,
              upiId: "test@upi", // temp
              name: "Laphing POS",
              // orderId: result['orderId'], // 🔥 DELETED
            ),
          ),
        );

        // If QR Screen returns true/success, then finalize.
        if (qrResult == true) {
          await _finalizeOrder(token, 'upi');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Here"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .where('is_active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No items found"));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount = 2;
              double aspectRatio = 0.72;

              if (width >= 900) {
                crossAxisCount = 4;
                aspectRatio = 0.85;
              } else if (width >= 600) {
                crossAxisCount = 3;
                aspectRatio = 0.80;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final id = doc.id;
                  final name = data['name'] ?? 'No name';
                  final price = (data['price'] ?? 0) as int;
                  final spiceSupported =
                      (data['spice_supported'] ?? false) as bool;
                  final String? imagePath =
                      (data['image_asset'] ?? data['image_url']) as String?;

                  final quantityInCart = _cart[id]?.quantity ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MenuItemImage(
                          imageUrl: imagePath,
                          height: 95,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹$price",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        if (spiceSupported)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              "Spice selectable",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: quantityInCart > 0
                                  ? () => _removeFromCart(id)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.white,
                            ),
                            Text(
                              quantityInCart.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _addToCart(id, name, price, spiceSupported),
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: totalItems == 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: const Color(0xFF141414),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$totalItems item(s)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Total: ₹$totalAmount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _goToCheckout(context),
                    child: const Text("Proceed"),
                  ),
                ],
              ),
            ),
    );
  }
}

/// ---------------- CART MODEL ----------------
class _CartItem {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final bool spiceSupported;

  const _CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.spiceSupported,
  });

  _CartItem copyWith({int? quantity}) {
    return _CartItem(
      id: id,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      spiceSupported: spiceSupported,
    );
  }
}