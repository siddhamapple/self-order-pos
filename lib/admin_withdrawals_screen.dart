import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() =>
      _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  // State variables
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  String selectedPerson = 'Siddham Jain';
  String selectedMode = 'Bank';
  DateTime selectedDate = DateTime.now();

  final people = ['Siddham Jain', 'Aman Goyal'];
  final modes = ['Bank', 'Cash', 'UPI'];

  Future<void> _addWithdrawal() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await FirebaseFirestore.instance.collection('withdrawals').add({
      'amount': amount,
      'withdrawn_by': selectedPerson,
      'mode': selectedMode, 
      'note': _noteController.text.trim(),
      'date': Timestamp.fromDate(selectedDate),
      'created_at': FieldValue.serverTimestamp(),
    });

    _amountController.clear();
    _noteController.clear();
  }

  // Helper method for the common InputDecoration style
  InputDecoration _commonInputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // DATE FORMAT HELPER
  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  // PERSON SUMMARY CARD HELPER
  Widget _personSummaryCard({
    required String name,
    required double cash,
    required double upi,
  }) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("Cash: ₹${cash.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70)),
            Text("UPI/Bank: ₹${upi.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // Withdrawal Form Widget (Now defined separately for clarity)
  Widget _withdrawalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: _commonInputDecoration(labelText: "Amount"),
        ),
        const SizedBox(height: 8),

        // Withdrawn By
        DropdownButtonFormField<String>(
          value: selectedPerson,
          items: people
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => selectedPerson = v!),
          decoration: _commonInputDecoration(labelText: "Withdrawn By"),
        ),
        const SizedBox(height: 8),

        // Mode
        DropdownButtonFormField<String>(
          value: selectedMode,
          items: modes
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => selectedMode = v!),
          decoration: _commonInputDecoration(labelText: "Mode"),
        ),
        const SizedBox(height: 8),

        // Note
        TextField(
          controller: _noteController,
          decoration: _commonInputDecoration(labelText: "Note"),
        ),

        const SizedBox(height: 12),

        // Date Picker for new withdrawal
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: _addWithdrawal,
          child: const Text("Add Withdrawal"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin · Withdrawals")),
      
      // FIX: Use a single ListView for the entire body content so everything scrolls together
      body: ListView(
        children: [
          // 1. Withdrawal Form (Now scrollable)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _withdrawalForm(),
          ),
          
          const Divider(),

          // 2. Date Range Filters (Now scrollable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fromDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => fromDate = picked);
                  },
                  child: Text(
                    fromDate == null
                        ? "From date"
                        : "From: ${_formatDate(Timestamp.fromDate(fromDate!))}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: toDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => toDate = picked);
                  },
                  child: Text(
                    toDate == null
                        ? "To date"
                        : "To: ${_formatDate(Timestamp.fromDate(toDate!))}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. StreamBuilder for Summary and Logs (Now handles variable height content seamlessly)
          StreamBuilder<QuerySnapshot>(
            stream: () {
              Query query = FirebaseFirestore.instance.collection('withdrawals');

              if (fromDate != null) {
                query = query.where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                      DateTime(fromDate!.year, fromDate!.month, fromDate!.day)),
                );
              }

              if (toDate != null) {
                query = query.where(
                  'date',
                  isLessThan: Timestamp.fromDate(
                    DateTime(toDate!.year, toDate!.month, toDate!.day)
                        .add(const Duration(days: 1)),
                  ),
                );
              }
              
              query = query.orderBy('date', descending: true);

              return query.snapshots();
            }(),
            
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error.toString()}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Return a non-expanded placeholder since we are inside a ListView
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              
              // Calculate summaries
              double siddhamCash = 0;
              double siddhamUpi = 0;
              double amanCash = 0;
              double amanUpi = 0;
              
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final person = data['withdrawn_by'];
                final mode = data['mode']; 

                if (person == 'Siddham Jain') {
                  if (mode == 'Cash') {
                    siddhamCash += amount;
                  } else if (mode == 'Bank' || mode == 'UPI') {
                    siddhamUpi += amount;
                  }
                }

                if (person == 'Aman Goyal') {
                  if (mode == 'Cash') {
                    amanCash += amount;
                  } else if (mode == 'Bank' || mode == 'UPI') {
                    amanUpi += amount;
                  }
                }
              }

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 80),
                    child: Text('No withdrawals recorded for this period.'),
                  ),
                );
              }

              // Return a Column containing the Summary and the List of Logs
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _personSummaryCard(
                              name: "Siddham Jain",
                              cash: siddhamCash,
                              upi: siddhamUpi,
                            )),
                            Expanded(child: _personSummaryCard(
                              name: "Aman Goyal",
                              cash: amanCash,
                              upi: amanUpi,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text("Withdrawal Logs:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  
                  // Withdrawals List Items (Using a Column as the parent is a ListView)
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      color: const Color(0xFF1C1C1C),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "₹${data['amount']} • ${data['mode']}", 
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${data['withdrawn_by']} — ${data['note'] ?? ''} · ${_formatDate(data['date'])}",
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('withdrawals')
                                .doc(doc.id)
                                .delete();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // Add extra padding at the bottom of the list
                  const SizedBox(height: 80), 
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}