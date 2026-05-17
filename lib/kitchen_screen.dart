import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  Stream<QuerySnapshot> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(60)
        .snapshots();
  }

  Future<void> _updateStatus(
    String orderId,
    String status, {
    String? cancelReason,
  }) async {
    final data = <String, dynamic>{
      'kitchen_status': status,
    };

    if (status == 'cancelled') {
      data['cancel_reason'] = cancelReason ?? 'Cancelled by kitchen';
      data['cancelled_at'] = FieldValue.serverTimestamp();
    }

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update(data);
  }

  // ✅ STEP 2: UPDATED STATUS COLORS
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.deepPurple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ STEP 2: UPDATED STATUS LABELS
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Orders'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading orders'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          // ✅ STEP 3: VISIBILITY FILTER (Using 'completed')
          final visibleOrders = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['kitchen_status'] ?? 'pending';

            // Always show active orders
            if (status != 'completed' && status != 'cancelled') return true;

            // For completed/cancelled, only show for 60 seconds
            final ts = data['created_at'];
            if (ts is! Timestamp) return false;

            return now.difference(ts.toDate()).inSeconds < 60;
          }).toList();

          if (visibleOrders.isEmpty) {
            return const Center(
              child: Text(
                'No active orders',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visibleOrders.length,
            itemBuilder: (context, index) {
              final doc = visibleOrders[index];
              final data = doc.data() as Map<String, dynamic>;

              final token = data['token_number'] ?? 0;
              final totalAmount = data['total_amount'] ?? 0;
              final paymentMethod =
                  (data['payment_method'] ?? 'cash') as String;
              final status = (data['kitchen_status'] ?? 'pending') as String;
              final items =
                  (data['items'] as List<dynamic>? ?? []).cast<Map>();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                // Slight tint for completed/cancelled rows
                color: status == 'completed'
                    ? Colors.green.withOpacity(0.08)
                    : status == 'cancelled'
                        ? Colors.red.withOpacity(0.08)
                        : const Color(0xFF1E1E1E), // Dark card background
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Token #$token',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // ✅ Fix White-on-White
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ITEMS
                      ...items.map((item) {
                        final name = item['name'] ?? '';
                        final qty = item['quantity'] ?? 0;
                        final spice = item['spice_level'] ?? 'None';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              // ✅ STEP 5: FIX WHITE-ON-WHITE
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                'x$qty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (spice != 'None') ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Spice: $spice',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.amber, // Highlight spice
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      // FOOTER (Amount & Payment)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹$totalAmount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // ✅ Fix White-on-White
                            ),
                          ),
                          Text(
                            paymentMethod.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: paymentMethod == 'cash'
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ✅ STEP 4: NEW ACTION BUTTON LOGIC
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. PENDING → PREPARING
                          if (status == 'pending')
                            ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(doc.id, 'preparing'),
                              child: const Text('Start Preparing'),
                            ),

                          // 2. PREPARING → READY
                          if (status == 'preparing')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              onPressed: () => _updateStatus(doc.id, 'ready'),
                              child: const Text('Mark Ready'),
                            ),

                          // 3. READY → COMPLETED
                          if (status == 'ready')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () =>
                                  _updateStatus(doc.id, 'completed'),
                              child: const Text('Mark Completed'),
                            ),

                          const SizedBox(width: 8),

                          // 4. CANCEL (Allowed unless completed/cancelled)
                          if (status != 'completed' && status != 'cancelled')
                            TextButton(
                              onPressed: () async {
                                final controller = TextEditingController();

                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancel Order'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Reason (optional)',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Back'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Cancel Order'),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok == true) {
                                  await _updateStatus(
                                    doc.id,
                                    'cancelled',
                                    cancelReason: controller.text.trim(),
                                  );
                                }
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}