import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:open_file/open_file.dart';
import 'dart:io';

Future<void> generateChartPdf(
    List<Map<String, dynamic>> chartData, String financeName) async {
  final pdf = pw.Document();
  final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

  // Prepare formatted chart data
  final formattedData = chartData.map((item) {
    return {
      'Date': DateFormat('dd-MM-yyyy')
          .format(DateTime.tryParse(item['Date'] ?? '') ?? DateTime.now()),
      'Credit': double.tryParse(item['totalCrAmt'].toString()) ?? 0,
      'Debit': double.tryParse(item['totalDrAmt'].toString()) ?? 0,
    };
  }).toList();

  // Generate total credit and debit
  final totalCredit =
      formattedData.fold<double>(0, (sum, e) => sum + (e['Credit'] as double));
  final totalDebit =
      formattedData.fold<double>(0, (sum, e) => sum + (e['Debit'] as double));

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (pw.Context context) {
        return [
          // Header Section
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    financeName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Account Statement as on $today',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 18),

          // Title
          pw.Text(
            'Party Collection Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date-wise Credit/Debit Summary',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
          pw.Divider(thickness: 1.2, color: PdfColors.teal300),
          pw.SizedBox(height: 10),

          // Table
          pw.Table.fromTextArray(
            headers: [
              'Date',
              'Credit (Rs.)',
              'Debit (Rs.)',
            ],
            data: formattedData.map((item) {
              return [
                item['Date'],
                (item['Credit'] as num).toStringAsFixed(2),
                (item['Debit'] as num).toStringAsFixed(2),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.teal600,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
            border: null,
          ),

          pw.SizedBox(height: 20),

          // Total Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.teal200, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text(
                  'Total Credit: Rs.${totalCredit.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Total Debit: Rs.${totalDebit.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    ),
  );

  // Save & open
  final formattedDate = DateFormat('dd-MM-yyyy_HHmmss').format(DateTime.now());
  final output = await path_provider.getTemporaryDirectory();
  final file = File("${output.path}/PartyChart_$formattedDate.pdf");
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}
