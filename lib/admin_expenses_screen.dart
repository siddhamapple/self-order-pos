import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() =>
      _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  // 1. State variables
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  String selectedPerson = 'Siddham Jain';
  
  // Updated default to match new list
  String selectedCategory = 'Raw Material'; 
  DateTime selectedDate = DateTime.now();

  final people = ['Siddham Jain', 'Aman Goyal'];
  
  // ✅ 2. Updated Categories List
  final categories = [
    'Labour', 
    'Cart', 
    'Raw Material', 
    'Disposable', 
    'Nagar Nigam', 
    'Miscellaneous'
  ];

  // 2. Add Expense Logic
  Future<void> _addExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await FirebaseFirestore.instance.collection('expenses').add({
      'amount': amount,
      'spent_by': selectedPerson,
      'category': selectedCategory,
      'note': _noteController.text.trim(),
      'date': Timestamp.fromDate(selectedDate),
      'created_at': FieldValue.serverTimestamp(),
    });

    _amountController.clear();
    _noteController.clear();
  }

  // Helper methods
  InputDecoration _commonInputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      // Ensure label is visible on dark bg
      labelStyle: const TextStyle(color: Colors.white70), 
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  // Summary Card Helper
  Widget _personSummaryCard({
    required String name,
    required double totalExpense,
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
            Text("Total Expense: ₹${totalExpense.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
  
  // Expense Form Widget
  Widget _expenseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white), // White input text
          decoration: _commonInputDecoration(labelText: "Amount"),
        ),
        const SizedBox(height: 12),

        // Spent By - ✅ FIX: White Text & Dark Dropdown
        DropdownButtonFormField<String>(
          value: selectedPerson,
          dropdownColor: Colors.grey[900], // Dark background for menu
          style: const TextStyle(color: Colors.white, fontSize: 16), // White text for selected item
          items: people
              .map((p) => DropdownMenuItem(
                    value: p, 
                    child: Text(p, style: const TextStyle(color: Colors.white)), // White text for items
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedPerson = v!),
          decoration: _commonInputDecoration(labelText: "Spent By"),
        ),
        const SizedBox(height: 12),

        // Category - ✅ FIX: White Text & Dark Dropdown
        DropdownButtonFormField<String>(
          value: selectedCategory,
          dropdownColor: Colors.grey[900], // Dark background for menu
          style: const TextStyle(color: Colors.white, fontSize: 16), // White text for selected item
          items: categories
              .map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(c, style: const TextStyle(color: Colors.white)), // White text for items
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedCategory = v!),
          decoration: _commonInputDecoration(labelText: "Category"),
        ),
        const SizedBox(height: 12),

        // Note
        TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white), // White input text
          decoration: _commonInputDecoration(labelText: "Note"),
        ),

        const SizedBox(height: 12),

        // Date Picker
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
          label: Text(
            "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              // Ensure date picker is readable
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark(),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: _addExpense,
          child: const Text("Add Expense"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin · Expenses")),
      
      // FIX: Use a single ListView for the entire body content so everything scrolls together
      body: ListView(
        children: [
          // 1. Expense Form (Scrollable)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _expenseForm(),
          ),
          
          const Divider(color: Colors.white24),

          // 2. Date Range Filters (Scrollable)
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
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => fromDate = picked);
                  },
                  child: Text(
                    fromDate == null
                        ? "From date"
                        : "From: ${_formatDate(Timestamp.fromDate(fromDate!))}",
                    style: const TextStyle(color: Colors.blueAccent),
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
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => toDate = picked);
                  },
                  child: Text(
                    toDate == null
                        ? "To date"
                        : "To: ${_formatDate(Timestamp.fromDate(toDate!))}",
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. StreamBuilder for Summary and Logs (Scrollable)
          StreamBuilder<QuerySnapshot>(
            stream: () {
              Query query = FirebaseFirestore.instance.collection('expenses');

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
                    child: Text('Error: ${snapshot.error.toString()}', style: const TextStyle(color: Colors.red)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              
              // Calculate summaries
              double siddhamTotal = 0;
              double amanTotal = 0;
              
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final person = data['spent_by'];

                if (person == 'Siddham Jain') {
                  siddhamTotal += amount;
                }

                if (person == 'Aman Goyal') {
                  amanTotal += amount;
                }
              }

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 80),
                    child: Text('No expenses recorded for this period.', style: TextStyle(color: Colors.white70)),
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
                              totalExpense: siddhamTotal,
                            )),
                            Expanded(child: _personSummaryCard(
                              name: "Aman Goyal",
                              totalExpense: amanTotal,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Expense Logs:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  
                  // Expense List Items
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      color: const Color(0xFF1C1C1C),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "₹${data['amount']} • ${data['category']}", 
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${data['spent_by']} — ${data['note'] ?? ''} · ${_formatDate(data['date'])}",
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('expenses')
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