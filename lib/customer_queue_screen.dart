import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerQueueScreen extends StatelessWidget {
  const CustomerQueueScreen({super.key});

  Stream<QuerySnapshot> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(30)
        .snapshots();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Preparing';
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Ready';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Order Queue'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docs = snapshot.data!.docs;

          // Show only active orders
          final visibleOrders = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['kitchen_status'] ?? 'pending';
            return status != 'cancelled';
          }).toList();

          if (visibleOrders.isEmpty) {
            return const Center(
              child: Text(
                'No active orders',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // good for TV / tablet
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: visibleOrders.length,
            itemBuilder: (context, index) {
              final data =
                  visibleOrders[index].data() as Map<String, dynamic>;

              final token = data['token_number'] ?? 0;
              final status =
                  (data['kitchen_status'] ?? 'pending') as String;

              return Container(
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _statusColor(status),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TOKEN',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$token',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
