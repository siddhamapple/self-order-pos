import 'package:cloud_firestore/cloud_firestore.dart';

// 🧠 STEP 4.1 — Create Finance Models
class ExpenseSummary {
  final int total;
  final Map<String, int> byCategory;
  final Map<String, int> byPerson;

  ExpenseSummary({
    required this.total,
    required this.byCategory,
    required this.byPerson,
  });
}

class WithdrawalSummary {
  final int total;
  final Map<String, int> byPerson;
  final Map<String, int> byMode;
  final Map<String, Map<String, int>> personModeSplit;

  WithdrawalSummary({
    required this.total,
    required this.byPerson,
    required this.byMode,
    required this.personModeSplit,
  });
}
// ------------------------------------

class FinanceSummary {
  final double totalRevenue;
  final double cashRevenue;
  final double upiRevenue;

  final double totalExpenses;
  final Map<String, double> expensesByPerson;

  final double totalWithdrawals;
  final Map<String, double> withdrawalsByPerson;

  final double bankBalance;

  FinanceSummary({
    required this.totalRevenue,
    required this.cashRevenue,
    required this.upiRevenue,
    required this.totalExpenses,
    required this.expensesByPerson,
    required this.totalWithdrawals,
    required this.withdrawalsByPerson,
    required this.bankBalance,
  });
}

class FinanceService {
  static Future<FinanceSummary> calculate(
    DateTime start,
    DateTime end,
  ) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    // -------- ORDERS --------
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('created_at', isGreaterThanOrEqualTo: startTs)
        .where('created_at', isLessThan: endTs)
        .get();

    double totalRevenue = 0;
    double cashRevenue = 0;
    double upiRevenue = 0;

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final amount = (data['total_amount'] ?? 0).toDouble();
      final method = data['payment_method'] ?? 'cash';

      totalRevenue += amount;
      if (method == 'cash') cashRevenue += amount;
      if (method == 'upi') upiRevenue += amount;
    }

    // -------- EXPENSES (OLD LOGIC) --------
    final expenseSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThan: endTs)
        .get();

    double totalExpenses = 0;
    final expensesByPerson = <String, double>{};

    for (final doc in expenseSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final person = data['paid_by'] ?? 'Unknown';

      totalExpenses += amount;
      expensesByPerson[person] =
          (expensesByPerson[person] ?? 0) + amount;
    }

    // -------- WITHDRAWALS (OLD LOGIC) --------
    final withdrawalSnap = await FirebaseFirestore.instance
        .collection('withdrawals')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThan: endTs)
        .get();

    double totalWithdrawals = 0;
    final withdrawalsByPerson = <String, double>{};

    for (final doc in withdrawalSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final person = data['withdrawn_by'] ?? 'Unknown';

      totalWithdrawals += amount;
      withdrawalsByPerson[person] =
          (withdrawalsByPerson[person] ?? 0) + amount;
    }

    final bankBalance =
        totalRevenue - totalExpenses - totalWithdrawals;

    return FinanceSummary(
      totalRevenue: totalRevenue,
      cashRevenue: cashRevenue,
      upiRevenue: upiRevenue,
      totalExpenses: totalExpenses,
      expensesByPerson: expensesByPerson,
      totalWithdrawals: totalWithdrawals,
      withdrawalsByPerson: withdrawalsByPerson,
      bankBalance: bankBalance,
    );
  }

  // 🧠 STEP 4.2 — Expense Analytics Engine
  static ExpenseSummary calculateExpenses(
      List<QueryDocumentSnapshot> docs) {
    int total = 0;
    final Map<String, int> byCategory = {};
    final Map<String, int> byPerson = {};

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      // Ensure we use .toInt() here as the new model uses int
      final amount = (d['amount'] ?? 0).toInt();
      final category = d['category'] ?? 'Other';
      final person = d['paid_by'] ?? 'Unknown';

      total += amount;
      byCategory[category] = (byCategory[category] ?? 0) + amount;
      byPerson[person] = (byPerson[person] ?? 0) + amount;
    }

    return ExpenseSummary(
      total: total,
      byCategory: byCategory,
      byPerson: byPerson,
    );
  }

  // 🧠 STEP 4.3 — Withdrawal Analytics Engine
  static WithdrawalSummary calculateWithdrawals(
      List<QueryDocumentSnapshot> docs) {
    int total = 0;

    final Map<String, int> byPerson = {};
    final Map<String, int> byMode = {};
    final Map<String, Map<String, int>> personModeSplit = {};

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      // Ensure we use .toInt() here as the new model uses int
      final amount = (d['amount'] ?? 0).toInt();
      final person = d['withdrawn_by'] ?? 'Unknown';
      final mode = d['mode'] ?? 'Cash';

      total += amount;

      byPerson[person] = (byPerson[person] ?? 0) + amount;
      byMode[mode] = (byMode[mode] ?? 0) + amount;

      personModeSplit.putIfAbsent(person, () => {});
      personModeSplit[person]![mode] =
          (personModeSplit[person]![mode] ?? 0) + amount;
    }

    return WithdrawalSummary(
      total: total,
      byPerson: byPerson,
      byMode: byMode,
      personModeSplit: personModeSplit,
    );
  }
}