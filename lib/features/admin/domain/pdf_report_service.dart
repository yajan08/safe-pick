import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../students/data/student_model.dart';
import '../../students/data/student_ride_log_model.dart';

/// Generates downloadable / shareable PDF reports for the admin portal.
///
/// All methods are static — no instance state is needed.
class PdfReportService {
  PdfReportService._(); // prevent instantiation

  // ── public API ───────────────────────────────────────────────────────────

  /// Builds a multi-page student tracking report and opens the native
  /// print / share dialog via the `printing` package.
  static Future<void> generateStudentReport(
    BuildContext context,
    StudentModel student,
    List<StudentRideLogModel> history,
  ) async {
    final pdf = pw.Document(
      title: 'SafePick – ${student.name} Report',
      author: 'SafePick Admin',
    );

    // Pre-compute metrics
    final totalTrips = history.length;
    final nonAbsentCount = history
        .where((log) => log.status.toLowerCase() != 'absent')
        .length;
    final attendanceRate = totalTrips > 0
        ? (nonAbsentCount / totalTrips * 100)
        : 0.0;
    final totalAbsences = totalTrips - nonAbsentCount;
    final generatedOn = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    // Date / time formatters
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context ctx) => _buildHeader(student, generatedOn),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) => [
          // ── Summary metrics ──────────────────────────────────────────
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _metricCard('Total Trips', '$totalTrips'),
              _metricCard(
                'Attendance Rate',
                '${attendanceRate.toStringAsFixed(1)}%',
              ),
              _metricCard('Total Absences', '$totalAbsences'),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Ride history table ────────────────────────────────────────
          pw.Text(
            'Ride History',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildDataTable(history, dateFmt, timeFmt),
        ],
      ),
    );

    // Open the native share / print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'SafePick_${student.name.replaceAll(' ', '_')}_Report',
    );
  }

  // ── private helpers ──────────────────────────────────────────────────────

  /// Page header with branding + student information.
  static pw.Widget _buildHeader(StudentModel student, String generatedOn) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SafePick',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A237E),
              ),
            ),
            pw.Text(
              generatedOn,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Student Tracking Report',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _infoChip('Student', student.name),
            pw.SizedBox(width: 24),
            _infoChip('Grade', student.grade),
            pw.SizedBox(width: 24),
            _infoChip('School', student.schoolName),
          ],
        ),
        pw.Divider(thickness: 0.5),
      ],
    );
  }

  /// Simple key → value label used in the header row.
  static pw.Widget _infoChip(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Single metric card (bordered container with title + value).
  static pw.Widget _metricCard(String title, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds the ride-history data table.
  static pw.Widget _buildDataTable(
    List<StudentRideLogModel> history,
    DateFormat dateFmt,
    DateFormat timeFmt,
  ) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headers: [
        'Date',
        'Trip Name',
        'Driver',
        'Boarded At',
        'Alighted At',
        'Status',
      ],
      data: history.map((log) {
        // Parse the date string; fall back to the raw value on failure.
        String formattedDate;
        try {
          formattedDate = dateFmt.format(DateTime.parse(log.date));
        } catch (_) {
          formattedDate = log.date;
        }

        return [
          formattedDate,
          log.tripName,
          log.driverName,
          log.boardedAt != null ? timeFmt.format(log.boardedAt!) : 'N/A',
          log.alightedAt != null ? timeFmt.format(log.alightedAt!) : 'N/A',
          log.status,
        ];
      }).toList(),
    );
  }

  /// Page footer with page numbers.
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }
}
