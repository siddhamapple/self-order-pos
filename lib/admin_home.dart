import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'printer/printer_service.dart';
import 'admin_expenses_screen.dart';
import 'admin_withdrawals_screen.dart';
// NOTE: Assuming 'admin/stats_filter_bar.dart' is local or replaced by the definitions below.

// --- Custom/Assumed definitions for StatsFilterBar and StatsRange ---
enum StatsRange { today, yesterday, thisWeek, thisMonth, custom }

class StatsFilterBar extends StatelessWidget {
  final StatsRange selectedRange;
  final Function(StatsRange, DateTimeRange?) onRangeChanged;

  const StatsFilterBar({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  String _getRangeText() {
    switch (selectedRange) {
      case StatsRange.today:
        return 'Today';
      case StatsRange.yesterday:
        return 'Yesterday';
      case StatsRange.thisWeek:
        return 'This Week';
      case StatsRange.thisMonth:
        return 'This Month';
      case StatsRange.custom:
        return 'Custom Range';
    }
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final now = DateTime.now();
    
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      currentDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.purple,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      final adjustedRange = DateTimeRange(
        start: newRange.start,
        end: newRange.end.add(const Duration(days: 1)),
      );
      
      onRangeChanged(StatsRange.custom, adjustedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StatsRange>(
          value: selectedRange,
          onChanged: (StatsRange? newValue) {
            if (newValue == StatsRange.custom) {
              _selectCustomRange(context);
            } else if (newValue != null) {
              onRangeChanged(newValue, null);
            }
          },
          items: StatsRange.values.map((StatsRange range) {
            return DropdownMenuItem<StatsRange>(
              value: range,
              child: Text(
                range.toString().split('.').last,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          hint: Text(_getRangeText()),
        ),
      ),
    );
  }
}
// -------------------------------------------------------------

// 🧩 STEP 1: Converted to StatefulWidget
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentTabIndex = 0;

  Future<void> _showAddMenuItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController(text: "laphing");

    bool spiceSupported = true;
    bool isActive = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Add Menu Item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: "Category (e.g. laphing, momos, combos)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: spiceSupported,
                          onChanged: (v) {
                            setModalState(() {
                              spiceSupported = v ?? false;
                            });
                          },
                        ),
                        const Text("Spice selectable"),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isActive,
                          onChanged: (v) {
                            setModalState(() {
                              isActive = v ?? false;
                            });
                          },
                        ),
                        const Text("Active"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    final category =
                        categoryController.text.trim().toLowerCase();

                    if (name.isEmpty || priceText.isEmpty) {
                      return;
                    }

                    final price = int.tryParse(priceText) ?? 0;

                    await FirebaseFirestore.instance
                        .collection('menu_items')
                        .add({
                      'name': name,
                      'price': price,
                      'category': category,
                      'spice_supported': spiceSupported,
                      'is_active': isActive,
                      'image_url': "",
                    });

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMenuItemDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final priceController =
        TextEditingController(text: data['price']?.toString() ?? '');
    final categoryController =
        TextEditingController(text: data['category'] ?? '');

    bool spiceSupported = data['spice_supported'] ?? false;
    bool isActive = data['is_active'] ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Edit Menu Item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: spiceSupported,
                          onChanged: (v) {
                            setModalState(() {
                              spiceSupported = v ?? false;
                            });
                          },
                        ),
                        const Text("Spice selectable"),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isActive,
                          onChanged: (v) {
                            setModalState(() {
                              isActive = v ?? false;
                            });
                          },
                        ),
                        const Text("Active"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price =
                        int.tryParse(priceController.text.trim()) ?? 0;
                    final category =
                        categoryController.text.trim().toLowerCase();

                    if (name.isEmpty || price <= 0) return;

                    await FirebaseFirestore.instance
                        .collection('menu_items')
                        .doc(docId)
                        .update({
                      'name': name,
                      'price': price,
                      'category': category,
                      'spice_supported': spiceSupported,
                      'is_active': isActive,
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🧩 STEP 2: Update DefaultTabController logic
    return DefaultTabController(
      length: 5,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          // Add listener to update state when tab changes
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              // Only setState if index actually changed to prevent loops
              if (_currentTabIndex != tabController.index) {
                setState(() {
                  _currentTabIndex = tabController.index;
                });
              }
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Panel'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Menu'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Withdrawals'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                AdminMenuTab(),
                AdminOrdersTab(),
                AdminExpensesScreen(),
                AdminWithdrawalsScreen(),
                AdminStatsTab(),
              ],
            ),
            // 🧩 STEP 3: Conditionally show FloatingActionButton
            floatingActionButton: _currentTabIndex == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _showAddMenuItemDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AdminHome State to call the edit dialog function
    final adminHomeState = context.findAncestorStateOfType<_AdminHomeState>();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menu_items')
          .orderBy('category')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading menu items'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No menu items found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'No name';
            final price = (data['price'] ?? 0).toString();
            final category = data['category'] ?? 'uncategorized';
            final isActive = (data['is_active'] ?? true) as bool;
            final spiceSupported = (data['spice_supported'] ?? false) as bool;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "₹$price · $category${spiceSupported ? ' · spice' : ''}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Call the dialog function from the parent state
                        adminHomeState?._showEditMenuItemDialog(context, doc.id, data);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// ✅ UPDATED ADMIN ORDERS TAB (Stateful + Date Filters + Details)
// -------------------------------------------------------------
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  DateTimeRange? selectedRange;
  // Track active label for UI highlighting (Simple Approach)
  String activeFilterLabel = "Today";

  // 🧩 STEP 2 — DATE FILTER ENGINE
  DateTime get _now => DateTime.now();

  DateTimeRange get todayRange => DateTimeRange(
        start: DateTime(_now.year, _now.month, _now.day),
        end: DateTime(_now.year, _now.month, _now.day)
            .add(const Duration(days: 1)),
      );

  DateTimeRange get weekRange => DateTimeRange(
        start: _now.subtract(const Duration(days: 7)),
        end: _now,
      );

  DateTimeRange get monthRange => DateTimeRange(
        start: DateTime(_now.year, _now.month, 1),
        end: _now,
      );

  DateTimeRange get quarterRange => DateTimeRange(
        start: DateTime(_now.year, ((_now.month - 1) ~/ 3) * 3 + 1),
        end: _now,
      );

  @override
  void initState() {
    super.initState();
    // 🧩 STEP 3 — DEFAULT = TODAY
    selectedRange = todayRange;
  }

  // 🧩 STEP 4 — QUERY WITH DATE FILTER (No Limit)
  Stream<QuerySnapshot> _ordersStream() {
    // If range is somehow null, default to today to be safe
    final range = selectedRange ?? todayRange;
    final start = Timestamp.fromDate(range.start);
    final end = Timestamp.fromDate(range.end);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('created_at', isGreaterThanOrEqualTo: start)
        .where('created_at', isLessThan: end)
        .orderBy('created_at', descending: true)
        // .limit(50)  <-- 🛑 REMOVED LIMIT
        .snapshots();
  }

  Future<void> _reprint(BuildContext context, Map<String, dynamic> data) async {
    final receipt = data['receipt_data'];
    if (receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt data not found")),
      );
      return;
    }

    try {
      await PrinterService.printReceipt(
        token: receipt['token'],
        paymentMode: receipt['paymentMode'],
        items: List<Map<String, dynamic>>.from(receipt['items']),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reprint successful")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reprint failed: $e")),
      );
    }
  }

  // ✅ MODAL FUNCTION FOR ORDER DETAILS
  void _showOrderReceipt(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map>();
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Center(
                child: Column(
                  children: [
                    Text(
                      "Token #${data['token_number']}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt != null
                          ? "${createdAt.day}/${createdAt.month}/${createdAt.year} "
                              "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}"
                          : "",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // ITEMS
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        "x${item['quantity']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if ((item['spice_level'] ?? 'None') != 'None')
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            "(${item['spice_level']})",
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const Divider(height: 24),

              // TOTAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "₹${data['total_amount']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // PAYMENT & STATUS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (data['payment_method'] ?? 'cash').toString().toUpperCase(),
                    style: TextStyle(
                      color: data['payment_method'] == 'cash'
                          ? Colors.brown
                          : Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Chip(
                    label: Text(
                      (data['kitchen_status'] ?? 'pending')
                          .toString()
                          .toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blueGrey,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // CLOSE
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🧩 STEP 5 — FILTER BAR UI
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip("Today", todayRange),
              _filterChip("Week", weekRange),
              _filterChip("Month", monthRange),
              _filterChip("Quarter", quarterRange),
              _customRangeButton(),
            ],
          ),
        ),

        // Expanded List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ordersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                    child: Text("No orders found for this period"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['kitchen_status'] ?? 'pending';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      // ✅ CLICKABLE ORDER TILE
                      onTap: () => _showOrderReceipt(context, data),
                      child: ListTile(
                        title: Text(
                          "Token #${data['token_number']} · ₹${data['total_amount']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                                "${data['payment_method'].toString().toUpperCase()}"),
                            const SizedBox(height: 4),
                            // 🧩 STEP 6 — STATUS GROUPING
                            Chip(
                              label: Text(
                                status.toString().toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                              backgroundColor: _statusColor(status),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () => _reprint(context, data),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, DateTimeRange range) {
    final isSelected = activeFilterLabel == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              selectedRange = range;
              activeFilterLabel = label;
            });
          }
        },
      ),
    );
  }

  Widget _customRangeButton() {
    final isSelected = activeFilterLabel == "Custom";
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16),
            SizedBox(width: 4),
            Text("Custom"),
          ],
        ),
        selected: isSelected,
        onSelected: (_) async {
          // Use Dark Theme for Picker visibility
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024, 1, 1),
            lastDate: DateTime.now(),
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.purple,
                    onPrimary: Colors.white,
                    surface: Colors.black,
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: Colors.black,
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            // ✅ FIX: Add 1 day to the end date here too
            final adjustedRange = DateTimeRange(
              start: picked.start,
              end: picked.end.add(const Duration(days: 1)),
            );

            setState(() {
              selectedRange = adjustedRange;
              activeFilterLabel = "Custom";
            });
          }
        },
      ),
    );
  }
}

// 🧠 STEP 3.1 — Add Revenue Model (TOP of file or bottom)
class RevenueStats {
  final int totalOrders;
  final int totalRevenue;
  final int cashRevenue;
  final int upiRevenue;
  final double avgOrderValue;
  final int workingDays;
  final String mostSoldItem;
  final String leastSoldItem;

  RevenueStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.cashRevenue,
    required this.upiRevenue,
    required this.avgOrderValue,
    required this.workingDays,
    required this.mostSoldItem,
    required this.leastSoldItem,
  });
}

class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  // 🔹 State for filter
  StatsRange _currentRange = StatsRange.today;
  DateTimeRange? _customRange;

  // ✅ STEP 1: WEEKLY HELPERS
  DateTime _startOfWeek(DateTime date) {
    final day = date.weekday; // Mon = 1, Sun = 7
    // Subtract days to get to Monday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: day - 1));
  }

  DateTime _endOfWeek(DateTime date) {
    // Start of week + 7 days - 1 microsecond (End of Sunday)
    return _startOfWeek(date)
        .add(const Duration(days: 7))
        .subtract(const Duration(microseconds: 1));
  }

  // ✅ STEP 2: FIX DATE LOGIC
  DateTimeRange _resolveDateRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_currentRange) {
      case StatsRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
        break;

      case StatsRange.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day)
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
        break;

      case StatsRange.thisWeek:
        start = _startOfWeek(now);
        end = _endOfWeek(now);
        break;

      case StatsRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        // Start of next month - 1 microsecond
        end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(microseconds: 1));
        break;

      case StatsRange.custom:
        if (_customRange != null) {
          return _customRange!;
        }
        // Default fallback
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
    }

    // Fallback for initialization
    if (_currentRange == StatsRange.custom && _customRange == null) {
      start = now.subtract(const Duration(days: 7));
      end = now;
    }

    return DateTimeRange(start: start, end: end);
  }

  // 🧠 STEP 3.2 — Revenue Calculator (VERY IMPORTANT)
  RevenueStats _calculateRevenue(List<QueryDocumentSnapshot> docs) {
    int totalRevenue = 0;
    int cashRevenue = 0;
    int upiRevenue = 0;

    final Map<String, int> itemCount = {};
    final Set<String> activeDays = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // ✅ FIX: Explicitly cast to 'num' first to handle Firestore data types safely.
      final int amount = (data['total_amount'] as num? ?? 0).toInt();

      final method = (data['payment_method'] ?? 'cash') as String;
      final createdAt = (data['created_at'] as Timestamp?)?.toDate();

      totalRevenue += amount;

      if (method == 'cash') cashRevenue += amount;
      if (method == 'upi') upiRevenue += amount;

      if (createdAt != null) {
        activeDays.add("${createdAt.year}-${createdAt.month}-${createdAt.day}");
      }

      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      for (final item in items) {
        final name = item['name'];
        final qty = (item['quantity'] ?? 1) as int;
        if (name != null) {
          itemCount[name] = (itemCount[name] ?? 0) + qty;
        }
      }
    }

    String mostSold = '—';
    String leastSold = '—';

    if (itemCount.isNotEmpty) {
      final sorted = itemCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostSold = sorted.first.key;
      leastSold = sorted.last.key;
    }

    return RevenueStats(
      totalOrders: docs.length,
      totalRevenue: totalRevenue,
      cashRevenue: cashRevenue,
      upiRevenue: upiRevenue,
      avgOrderValue: docs.isEmpty ? 0 : totalRevenue / docs.length,
      workingDays: activeDays.length,
      mostSoldItem: mostSold,
      leastSoldItem: leastSold,
    );
  }

  // 🧩 STEP 3.5 — Stat Card UI (Reusable)
  Widget _statCard(String title, String value) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _resolveDateRange();
    final startTs = Timestamp.fromDate(range.start);
    final endTs = Timestamp.fromDate(range.end);

    // ✅ STEP 4: FIX QUERIES WITH orderBy AND isLessThanOrEqualTo
    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('created_at', isGreaterThanOrEqualTo: startTs)
        .where('created_at', isLessThanOrEqualTo: endTs)
        .orderBy('created_at',
            descending: true); // 🔥 REQUIRED FOR RANGE QUERIES

    final expensesQuery = FirebaseFirestore.instance
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThanOrEqualTo: endTs)
        .orderBy('date', descending: true); // 🔥 REQUIRED

    final withdrawalsQuery = FirebaseFirestore.instance
        .collection('withdrawals')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThanOrEqualTo: endTs)
        .orderBy('date', descending: true); // 🔥 REQUIRED

    // Note: If you get a Firestore error in the console, click the link to create the index!

    return Column(
      children: [
        // 🔹 Step 1.5 — Add StatsFilterBar
        StatsFilterBar(
          selectedRange: _currentRange,
          onRangeChanged: (range, custom) {
            setState(() {
              _currentRange = range;
              _customRange = custom;
            });
          },
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // Display the selected range text
                _currentRange == StatsRange.custom
                    ? "Stats for: Custom Range"
                    : "Stats for: ${_currentRange.toString().split('.').last}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 🧠 STEP 3.4 — Use StreamBuilder (REPLACE OLD ONE)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ordersQuery.snapshots(),
            builder: (context, orderSnap) {
              // Handle error/loading for orders (outermost layer)
              if (orderSnap.hasError) {
                return Center(
                  child: Text('Error loading order stats: ${orderSnap.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }

              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orderDocs = orderSnap.data!.docs;
              final revenueStats = _calculateRevenue(orderDocs);
              final totalAmount = revenueStats.totalRevenue.toDouble();

              // 🧩 STEP 4.4.1 — NESTED STREAMBUILDERS
              return StreamBuilder<QuerySnapshot>(
                stream: expensesQuery.snapshots(),
                builder: (context, expenseSnap) {
                  // Handle error/loading for expenses
                  if (expenseSnap.hasError ||
                      expenseSnap.connectionState == ConnectionState.waiting) {
                    // Return a simplified loading/error state for nested builders
                    return const Center(child: Text("Loading expenses..."));
                  }

                  final expenseDocs = expenseSnap.data!.docs;

                  // 🧩 STEP 4.5 — DISPLAY EXPENSE & WITHDRAWAL STATS
                  double totalExpenses = 0;
                  final Map<String, double> expenseByPerson = {};

                  // 🔁 LOOP EXPENSE DOCS
                  for (final doc in expenseDocs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final amount = (d['amount'] ?? 0).toDouble();
                    final person = d['paid_by'] ?? 'Unknown';

                    totalExpenses += amount;
                    expenseByPerson[person] =
                        (expenseByPerson[person] ?? 0) + amount;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: withdrawalsQuery.snapshots(),
                    builder: (context, withdrawalSnap) {
                      // Handle error/loading for withdrawals (innermost layer)
                      if (withdrawalSnap.hasError ||
                          withdrawalSnap.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(
                            child: Text("Loading withdrawals..."));
                      }

                      final withdrawalDocs = withdrawalSnap.data!.docs;

                      double totalWithdrawals = 0;
                      final Map<String, double> withdrawalByPerson = {};
                      final Map<String, double> withdrawalByMode = {};

                      // 🔁 LOOP WITHDRAWALS
                      for (final doc in withdrawalDocs) {
                        final d = doc.data() as Map<String, dynamic>;
                        final amount = (d['amount'] ?? 0).toDouble();
                        final person = d['withdrawn_by'] ?? 'Unknown';
                        final mode = d['mode'] ?? 'cash';

                        totalWithdrawals += amount;

                        withdrawalByPerson[person] =
                            (withdrawalByPerson[person] ?? 0) + amount;

                        withdrawalByMode[mode] =
                            (withdrawalByMode[mode] ?? 0) + amount;
                      }

                      // 👇 ALL STATS UI GOES HERE
                      if (revenueStats.totalOrders == 0 &&
                          totalExpenses == 0 &&
                          totalWithdrawals == 0) {
                        return const Center(
                          child: Text(
                            "No financial data in this period.",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      // ✅ STEP 5 — NET FINANCIAL POSITION (CEO VIEW)
                      final netBalance =
                          totalAmount - totalExpenses - totalWithdrawals;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 🧠 EXECUTIVE CARD
                          Card(
                            color: netBalance >= 0
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            child: ListTile(
                              title: const Text(
                                "Net Available Balance",
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                "₹${netBalance.toInt()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Revenue Stats
                          _statCard("Total Revenue",
                              "₹${revenueStats.totalRevenue}"),
                          _statCard("Total Orders",
                              revenueStats.totalOrders.toString()),
                          _statCard(
                              "Cash Revenue", "₹${revenueStats.cashRevenue}"),
                          _statCard(
                              "UPI Revenue", "₹${revenueStats.upiRevenue}"),
                          _statCard("Avg Order Value",
                              "₹${revenueStats.avgOrderValue.toStringAsFixed(1)}"),
                          _statCard("Working Days",
                              revenueStats.workingDays.toString()),
                          _statCard(
                              "Most Sold Item", revenueStats.mostSoldItem),
                          _statCard(
                              "Least Sold Item", revenueStats.leastSoldItem),

                          const Divider(height: 32),

                          // Expense Stats
                          _statCard(
                              "Total Expenses", "₹${totalExpenses.toInt()}"),
                          ...expenseByPerson.entries.map(
                            (e) => _statCard("Expense • ${e.key}",
                                "₹${e.value.toInt()}"),
                          ),

                          const Divider(height: 32),

                          // Withdrawal Stats
                          _statCard("Total Withdrawals",
                              "₹${totalWithdrawals.toInt()}"),
                          // 👤 PER PERSON
                          ...withdrawalByPerson.entries.map(
                            (e) => _statCard("Withdrawn • ${e.key}",
                                "₹${e.value.toInt()}"),
                          ),
                          // 💳 PER MODE
                          ...withdrawalByMode.entries.map(
                            (e) => _statCard(
                                "Withdrawn • ${e.key.toUpperCase()}",
                                "₹${e.value.toInt()}"),
                          ),
                        ],
                      ); // End of ListView
                    }, // End of innermost StreamBuilder (withdrawalSnap) builder function
                  ); // End of StreamBuilder widget
                }, // End of middle StreamBuilder (expenseSnap) builder function
              ); // End of StreamBuilder widget
            }, // End of outermost StreamBuilder (orderSnap) builder function
          ), // End of StreamBuilder widget
        ), // End of Expanded
      ],
    ); // End of Column
  } // End of _AdminStatsTabState build method
} // End of _AdminStatsTabState class