import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

Future<void> generatePartyReportPdf(
    List<Map<String, dynamic>> summaryList, String financeName) async {
  final pdf = pw.Document();
  final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      ),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                financeName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          // Account Statement on Date
          pw.Center(
            child: pw.Text(
              'Account Statement on Date ($today)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(height: 18), // Report Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'ACTIVE PARTIES REPORT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(height: 1, thickness: 1, color: PdfColors.blue200),
          pw.SizedBox(height: 15),

          // Parties List
          ...summaryList.map((summary) {
            final collections =
                summary['Collections'] as List<Map<String, dynamic>>;
            final partyName =
                summary['PartyName']?.toString() ?? 'Unnamed Party';
            final totalGiven = summary['TotalGiven']?.toString() ?? '0.00';
            final lentDateRaw = summary['LentDate'];
            final lentDate = (lentDateRaw != null &&
                    lentDateRaw.toString().isNotEmpty)
                ? DateFormat('dd-MM-yyyy').format(DateTime.parse(lentDateRaw))
                : 'N/A';
            final dueDays = summary['DueDays']?.toString() ?? '0';
            final amtCollected = summary['AmtCollected']?.toString() ?? '0.00';
            final dueDate = summary['DueDate']?.toString() ?? 'N/A';

            final totalGivenVal = double.tryParse(totalGiven) ?? 0;
            final amtCollectedVal = double.tryParse(amtCollected) ?? 0;
            final balance =
                (totalGivenVal - amtCollectedVal).toStringAsFixed(2);
            final isOverdue =
                DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) ?? false;

            // Party Information Card
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: isOverdue ? PdfColors.red200 : PdfColors.grey300,
                  width: 0.8,
                ),
                boxShadow: const [
                  pw.BoxShadow(
                    color: PdfColors.grey300,
                    blurRadius: 2,
                    offset: PdfPoint(0, 1),
                  )
                ],
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Party Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: isOverdue ? PdfColors.red50 : PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(6),
                        topRight: pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            partyName,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: isOverdue
                                  ? PdfColors.red800
                                  : PdfColors.blue800,
                            ),
                          ),
                        ),
                        if (isOverdue)
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red500,
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              'OVERDUE',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Party Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.5),
                        1: const pw.FlexColumnWidth(1.5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(1.5),
                        4: const pw.FlexColumnWidth(1.5),
                        5: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: PdfColors.grey200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          children: [
                            _buildDetailCell('Amount Given', '₹$totalGiven'),
                            _buildDetailCell(
                                'Amount Collected', '₹$amtCollected'),
                            _buildDetailCell('Balance', '₹$balance'),
                            _buildDetailCell('Lent Date', lentDate),
                            _buildDetailCell('Due Days', '$dueDays days'),
                            _buildDetailCell('Due Date', dueDate),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Collections Table Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    color: PdfColors.blue700,
                    child: pw.Row(
                      children: List.generate(6, (pairIndex) {
                        return pw.Expanded(
                          flex: 2,
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  'Date ${pairIndex + 1}',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  'DrAmt ${pairIndex + 1}',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  // Collections Table
                  if (collections.isNotEmpty)
                    ..._buildCollectionRows(collections, rows: 15)
                  else
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 15),
                      child: pw.Center(
                        child: pw.Text(
                          'No collection records available',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey500,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  // Summary
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(6),
                        bottomRight: pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Collections: ${collections.length}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Report Generated: ${DateFormat('dd-MMM-yy HH:mm').format(DateTime.now())}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

// Helper function to create detail cells
pw.Widget _buildDetailCell(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// Build collection rows with alternating colors
List<pw.Widget> _buildCollectionRows(
  List<Map<String, dynamic>> collections, {
  int rows = 15,
  int pairsPerRow = 6,
}) {
  final widgets = <pw.Widget>[];
  final totalCells = rows * pairsPerRow;

  for (int i = 0; i < rows; i++) {
    final rowWidgets = <pw.Widget>[];
    bool hasData = false;

    for (int j = 0; j < pairsPerRow; j++) {
      final index = i * pairsPerRow + j;
      if (index < collections.length && index < totalCells) {
        hasData = true;
        final entry = collections[index];
        final date =
            entry['Date'] != null && entry['Date'].toString().isNotEmpty
                ? DateFormat('dd-MM-yy').format(DateTime.parse(entry['Date']))
                : '-';
        final drAmt = entry['DrAmt']?.toString() ?? '-';

        rowWidgets.add(
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 0.3),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      color: PdfColors.grey50,
                      child: pw.Text(
                        date,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(
                        drAmt,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        rowWidgets.add(
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 0.3),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      color: PdfColors.grey50,
                      child: pw.Text(
                        '-',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(
                        '-',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (hasData) {
      widgets.add(
        pw.Container(
          color: i.isEven ? PdfColors.white : PdfColors.grey50,
          child: pw.Row(children: rowWidgets),
        ),
      );
    }
  }

  return widgets;
}
