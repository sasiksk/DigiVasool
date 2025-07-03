import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:open_file/open_file.dart';

Future<void> generatePartyReportPdf(
    List<Map<String, dynamic>> summaryList, String financeName) async {
  final pdf = pw.Document();
  final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  financeName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Account Statement on $today',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),
          ),
          ...summaryList.expand((summary) {
            final partyName = summary['PartyName']?.toString() ?? '';
            final totalGiven = summary['TotalGiven']?.toString() ?? '0.00';
            final amtCollected = summary['AmtCollected']?.toString() ?? '0.00';
            final lentDateRaw = summary['LentDate']?.toString() ?? '';
            final dueDays = summary['DueDays']?.toString() ?? '0';
            final dueDate = summary['DueDate']?.toString() ?? 'N/A';
            final balance = (double.tryParse(totalGiven) ?? 0) -
                (double.tryParse(amtCollected) ?? 0);

            String lentDateStr = 'N/A';
            if (lentDateRaw.isNotEmpty) {
              try {
                lentDateStr = DateFormat('dd-MM-yyyy')
                    .format(DateFormat('yyyy-MM-dd').parse(lentDateRaw));
              } catch (_) {}
            }

            final collections =
                summary['Collections'] as List<Map<String, dynamic>>? ?? [];

            return [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Party: $partyName',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Given: Rs. $totalGiven'),
                        pw.Text('Collected: Rs. $amtCollected'),
                        pw.Text(
                          'Balance: Rs. ${balance.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Lent Date: $lentDateStr'),
                        pw.Text('Due Days: $dueDays'),
                        pw.Text('Due Date: $dueDate'),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    if (collections.isNotEmpty)
                      pw.Table.fromTextArray(
                        headers: List.generate(5, (i) => ['Date', 'DrAmt'])
                            .expand((x) => x)
                            .toList(),
                        data: () {
                          List<List<String>> rows = [];
                          for (int i = 0; i < collections.length; i += 5) {
                            final chunk = collections.skip(i).take(5).toList();
                            List<String> row = [];
                            for (var entry in chunk) {
                              final dateStr = entry['Date']?.toString() ?? '';
                              String formattedDate = '-';
                              if (dateStr.isNotEmpty) {
                                try {
                                  formattedDate = DateFormat('dd-MM-yy').format(
                                    DateFormat('yyyy-MM-dd').parse(dateStr),
                                  );
                                } catch (_) {}
                              }
                              final drAmt = entry['DrAmt']?.toString() ?? '-';
                              row.add(formattedDate);
                              row.add(drAmt);
                            }
                            while (row.length < 10) {
                              row.add('');
                            }
                            rows.add(row);
                          }
                          return rows;
                        }(),
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                        cellStyle: pw.TextStyle(fontSize: 9),
                        cellAlignment: pw.Alignment.center,
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.teal),
                        border: pw.TableBorder.all(
                            color: PdfColors.grey, width: 0.4),
                        columnWidths: {
                          for (int i = 0; i < 10; i++)
                            i: const pw.FlexColumnWidth(1),
                        },
                      )
                    else
                      pw.Text(
                        'No collections.',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ];
          }),
        ];
      },
    ),
  );

  final formattedDate = DateFormat('ddMMyy_HHmmss').format(DateTime.now());
  final output = await path_provider.getTemporaryDirectory();
  final file = File("${output.path}/AccSta_$formattedDate.pdf");
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}
