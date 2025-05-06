import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class PdfEntry {
  final String partyName;
  final String date;
  final double drAmt;
  final double crAmt;

  PdfEntry({
    required this.partyName,
    required this.date,
    required this.drAmt,
    required this.crAmt,
  });
}

Future<void> generatePdf(
  List<PdfEntry> entries,
  double totalYouGave,
  double totalYouGot,
  String start,
  String end,
  WidgetRef ref,
  String finname, {
  bool isPartyWise = false, // Add a flag for Party-wise grouping
}) async {
  // Sort entries based on the grouping type
  if (isPartyWise) {
    entries.sort(
        (a, b) => a.partyName.compareTo(b.partyName)); // Sort by partyName
  } else {
    entries.sort((a, b) => b.date.compareTo(a.date)); // Sort by date
  }

  final pdf = pw.Document();

  // Load custom font from assets
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (pw.Context context) {
        return [
          // Finance Name and Account Statement
          pw.Container(
            color: PdfColors.blue,
            padding:
                const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    '$finname',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    isPartyWise
                        ? 'Party-wise Account Statement ($start - $end)'
                        : 'Date-wise Account Statement ($start - $end)',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Table Section
          if (isPartyWise)
            ..._buildPartyWiseTable(entries, ttf) // Build Party-wise table
          else
            _buildDateWiseTable(entries, ttf), // Build Date-wise table
        ];
      },
    ),
  );

  final output = await path_provider.getTemporaryDirectory();
  final file = File("${output.path}/AccSta_($start - $end).pdf");
  await file.writeAsBytes(await pdf.save());

  OpenFile.open(file.path);
}

List<pw.Widget> _buildPartyWiseTable(List<PdfEntry> entries, pw.Font ttf) {
  final groupedEntries = <String, List<PdfEntry>>{};

  // Group entries by partyName
  for (var entry in entries) {
    groupedEntries.putIfAbsent(entry.partyName, () => []).add(entry);
  }

  final List<pw.Widget> widgets = [];

  groupedEntries.forEach((partyName, partyEntries) {
    final totalDr = partyEntries.fold(0.0, (sum, entry) => sum + entry.drAmt);
    final totalCr = partyEntries.fold(0.0, (sum, entry) => sum + entry.crAmt);

    // Party Title
    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.lightBlue100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          "Party Name: $partyName",
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ),
    );

    // Table
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          // Header Row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.blue800),
            children: ['Date', 'Debit (-)', 'Credit (+)'].map((header) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              );
            }).toList(),
          ),

          // Entry Rows with alternate coloring
          ...partyEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final pdfEntry = entry.value;
            final isEvenRow = index % 2 == 0;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isEvenRow ? PdfColors.grey100 : PdfColors.white,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    _formatDate(pdfEntry.date),
                    style: pw.TextStyle(font: ttf, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    pdfEntry.drAmt != 0.0
                        ? '\u20B9${_formatAmount(pdfEntry.drAmt)}'
                        : '',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.red800,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    pdfEntry.crAmt != 0.0
                        ? '\u20B9${_formatAmount(pdfEntry.crAmt)}'
                        : '',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ],
            );
          }),

          // Total Row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\u20B9${_formatAmount(totalDr)}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\u20B9${_formatAmount(totalCr)}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Spacer
    widgets.add(pw.SizedBox(height: 20));
  });

  return widgets;
}

// Format amount with commas
String _formatAmount(double amount) {
  return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}

// Format date to a readable format (e.g., DD-MM-YYYY)
String _formatDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
  } catch (e) {
    return date; // Return the original string if parsing fails
  }
}

pw.Column _buildDateWiseTable(List<PdfEntry> entries, pw.Font ttf) {
  final groupedEntries = <String, List<PdfEntry>>{};

  // Group entries by date
  for (var entry in entries) {
    if (!groupedEntries.containsKey(entry.date)) {
      groupedEntries[entry.date] = [];
    }
    groupedEntries[entry.date]!.add(entry);
  }

  final List<pw.Widget> widgets = [];

  groupedEntries.forEach((date, dateEntries) {
    // Add "Date" header
    widgets.add(
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(
          "Date: ${_formatDate(date)}",
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown800, // Dark brown color
          ),
        ),
      ),
    );

    // Add table for the date entries
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey, width: 1),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          // Table Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Name',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Debit (-)',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Credit (+)',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )),
              ),
            ],
          ),
          // Table Rows
          ...dateEntries.map((pdfEntry) {
            return pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    pdfEntry.partyName,
                    style: pw.TextStyle(font: ttf, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    pdfEntry.drAmt != 0.0 ? '\u20B9${pdfEntry.drAmt}' : '',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    pdfEntry.crAmt != 0.0 ? '\u20B9${pdfEntry.crAmt}' : '',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.green,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
          // Total Row for the Date
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\u20B9${dateEntries.fold(0.0, (sum, entry) => sum + entry.drAmt).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\u20B9${dateEntries.fold(0.0, (sum, entry) => sum + entry.crAmt).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Add spacing between groups
    widgets.add(pw.SizedBox(height: 16));
  });

  return pw.Column(children: widgets);
}
