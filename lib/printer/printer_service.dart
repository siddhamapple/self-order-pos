import 'package:intl/intl.dart';
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PrinterService {
  static final BlueThermalPrinterPlus _printer = BlueThermalPrinterPlus();
  static Future<void> reprintFromOrderDoc(
  Map<String, dynamic> receiptData,
) async {
  await _ensureConnected();

  await printReceipt(
    token: receiptData['token'],
    paymentMode: receiptData['paymentMode'],
    items: List<Map<String, dynamic>>.from(
      receiptData['items'],
    ),
  );
}

  static Future<void> _ensureConnected() async {
    final devices = await _printer.getBondedDevices();

    final device = devices.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains('SR'),
      orElse: () => throw Exception("Printer not found"),
    );

    final bool isConnected = await _printer.isConnected ?? false;
    if (!isConnected) {
      await _printer.connect(device);
    }
  }
  static Future<bool> tryPrintReceipt({
  required int token,
  required String paymentMode,
  required List<Map<String, dynamic>> items,
}) async {
  try {
    await printReceipt(
      token: token,
      paymentMode: paymentMode,
      items: items,
    );
    return true;
  } catch (e) {
    debugPrint('🟥 Printer error: $e');
    return false;
  }
}

  static Future<void> _printLogo() async {
  final ByteData data =
      await rootBundle.load('assets/images/logo_black_384.png');
  final Uint8List bytes = data.buffer.asUint8List();

  _printer.printImageBytes(bytes);
  _printer.printNewLine();
}

  static Future<void> printReceipt({
    

    required int token,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
  }) async {
     await _ensureConnected();

  // ✅ PRINT LOGO FIRST
    await _printLogo();
    

    final now = DateTime.now();
    int grandTotal = 0;

    _printer.printNewLine();
   
    _printer.printCustom('In front of Sandwedges, RDC', 1, 1);
    _printer.printNewLine();

    _printer.printCustom('TOKEN NO: $token', 2, 1);
    _printer.printCustom(
      'Date: ${DateFormat('dd MMM yyyy').format(now)}',
      1,
      0,
    );
    _printer.printCustom(
      'Time: ${DateFormat('hh:mm a').format(now)}',
      1,
      0,
    );

    _printer.printNewLine();
    _printer.printCustom(
      'PAYMENT : ${paymentMode.toUpperCase()}',
      2,
      0,
    );

    _printer.printCustom('--------------------------------', 1, 1);

    for (final item in items) {
      final String name = item['name'];
      final int qty = item['quantity'];
      final int unitPrice = item['price'];
      final int lineTotal = qty * unitPrice;
      grandTotal += lineTotal;

      // Item name (full width, wraps safely)
      _printer.printCustom(name, 1, 0);

      // Qty x Price aligned
      _printer.printLeftRight(
        '  $qty x $unitPrice',
        'Rs $lineTotal',
        1,
      );

      _printer.printNewLine();
    }

    _printer.printCustom('--------------------------------', 1, 1);

    // TOTAL BOX
    _printer.printLeftRight(
      'TOTAL',
      'Rs $grandTotal',
      3,
    );

    _printer.printCustom('--------------------------------', 1, 1);

    _printer.printCustom('Thank you, please visit again!', 1, 1);
    _printer.printNewLine();
    
    _printer.printCustom('For feedback:', 1, 0);
    _printer.printCustom('+91 98991 85376  -> Siddham Jain', 1, 0);
    _printer.printCustom('+91 96676 00343  -> Aman Goyal', 1, 0);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();

    _printer.paperCut();
  }
}
