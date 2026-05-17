import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UpiQrScreen extends StatelessWidget {
  final int amount;
  final int token;
  final String upiId;
  final String name;

  const UpiQrScreen({
    super.key,
    required this.amount,
    required this.token,
    required this.upiId,
    required this.name,
  });

  String get upiUrl {
    return "upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=Token%20$token";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // DARK BACKGROUND
      appBar: AppBar(
        title: Text("UPI Payment - Token #$token"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            Text(
              "Scan to pay ₹$amount",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            /// ✅ WHITE CARD FOR QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: upiUrl,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Use any UPI app (GPay, PhonePe, Paytm, etc.) to scan.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'token': token,
                  'paymentMethod': 'upi',
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // RED BUTTON
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "I have paid",
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
