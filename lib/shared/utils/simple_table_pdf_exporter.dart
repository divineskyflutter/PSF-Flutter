// Small, generic PDF-table builder shared by every "export/share" icon
// that just needs to turn a list of rows into a downloadable PDF — the
// Passbook screen and the Loan Instalment Details screen today. Mirrors
// the branding (colors, letterhead line) of
// `registration_pdf_builder.dart` without needing that file's
// registration-specific data model.
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SimpleTablePdfExporter {
  SimpleTablePdfExporter._();

  static const PdfColor _brandDark = PdfColor.fromInt(0xFF185A55);
  static const PdfColor _brand = PdfColor.fromInt(0xFF258077);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);

  static Future<Uint8List> build({
    required String title,
    String? subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    String organizationName = 'Parivar Suraksha Foundation',
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) {
          if (context.pageNumber > 1) return pw.SizedBox();

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                organizationName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandDark,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _brand,
                ),
              ),
              if (subtitle != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Divider(color: _border, thickness: 0.7),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _brand),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: _border, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
