import 'package:flutter/material.dart';

class ReceiptItem {
  final String name;
  final int quantity;
  final int price;
  final String spiceLevel;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.spiceLevel,
  });
}

class ReceiptPrinter {
  static Future<void> printOrderReceipt({
    required BuildContext context,
    required String shopName,
    required String shopAddress,
    required int tokenNumber,
    required int totalAmount,
    required String paymentMethod,
    required List<ReceiptItem> items,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          shopName,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shopAddress),
            const Divider(),
            Text(
              'TOKEN #$tokenNumber',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...items.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}'
                        '${item.spiceLevel != "None" ? " (${item.spiceLevel})" : ""}',
                      ),
                    ),
                    Text(
                      '₹${item.price * item.quantity}',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style:
                      TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$totalAmount',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Payment: ${paymentMethod.toUpperCase()}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
