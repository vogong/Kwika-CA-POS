import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/app_state.dart';
import '../core/models/payment_method.dart';
import 'package:provider/provider.dart';

class ReceiptService {
  static Future<void> printReceipt({
    required CartState cartState,
    required PaymentMethod paymentMethod,
    required BuildContext context,
    double? amountTendered,
  }) async {
    final pdf = pw.Document();
    final settingsState = Provider.of<SettingsState>(context, listen: false);

    // Get the current timestamp
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store name and timestamp
              pw.Center(
                child: pw.Text(
                  'Your Store Name',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('$dateStr $timeStr'),
              ),
              pw.Divider(),

              // Items
              ...cartState.items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.product.name),
                              pw.Text(
                                '${item.quantity} × ${settingsState.formatCurrency(item.product.price)}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        pw.Text(
                          settingsState.formatCurrency(
                            item.product.price * item.quantity,
                          ),
                        ),
                      ],
                    ),
                  )),

              pw.Divider(),

              // Subtotal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text(settingsState.formatCurrency(cartState.subtotal)),
                ],
              ),

              // Tax
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${settingsState.settings.taxName} (${settingsState.settings.taxRate}%):'),
                  pw.Text(settingsState.formatCurrency(cartState.hst)),
                ],
              ),

              // Tip if applicable
              if (cartState.tipPercentage > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tip (${cartState.tipPercentage}%):'),
                    pw.Text(settingsState.formatCurrency(cartState.tipAmount)),
                  ],
                ),
              ],

              pw.Divider(),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    settingsState.formatCurrency(cartState.total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // Payment method
              pw.Text('Payment Method: ${paymentMethod.displayName}'),

              // Amount tendered and change (for cash payments)
              if (paymentMethod == PaymentMethod.cash && amountTendered != null) ...[
                pw.Text('Amount Tendered: ${settingsState.formatCurrency(amountTendered)}'),
                pw.Text('Change: ${settingsState.formatCurrency(amountTendered - cartState.total)}'),
              ],

              pw.SizedBox(height: 16),

              // Thank you message
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
