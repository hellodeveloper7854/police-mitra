import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class CertificateGenerator {
  static Future<void> generateAndDownloadCertificate({
    required String userName,
    required String serviceName,
    required String participationArea,
    required String date,
    required String location,
    required String duration,
  }) async {
    // Load Hindi font for Devanagari text support
    Font hindiFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      hindiFont = Font.ttf(fontData);
    } catch (e) {
      debugPrint('Error loading Hindi font: $e');
      // Fallback to default font
      rethrow;
    }

    Font hindiBoldFont;
    try {
      final boldFontData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      hindiBoldFont = Font.ttf(boldFontData);
    } catch (e) {
      debugPrint('Error loading Hindi bold font: $e');
      // Fallback to regular font
      hindiBoldFont = hindiFont;
    }

    final pdf = Document();

    // Load the Police Mitra logo image from assets
    MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading Police Mitra logo: $e');
      // Logo will be null, and we'll use fallback
    }

    // Load the Thane Police logo image from assets
    MemoryImage? thanePoliceLogoImage;
    try {
      final thaneLogoData = await rootBundle.load('assets/images/thanepolicelogo.jpg');
      thanePoliceLogoImage = MemoryImage(thaneLogoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading Thane Police logo: $e');
      // Logo will be null, and we'll use fallback
    }

    pdf.addPage(
      Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const EdgeInsets.all(0),
        build: (Context context) {
          return Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PdfColor(1.0, 1.0, 0.98), // Light cream
                        PdfColor(1.0, 0.98, 0.95), // Light amber
                      ],
                    ),
                  ),
                ),
              ),

              // Background border - outer
              Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PdfColor(0.8, 0.5, 0.0), // Amber color
                    width: 15,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: PdfColor(0.6, 0.4, 0.0), // Darker amber
                      width: 3,
                    ),
                  ),
                ),
              ),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),

                    // Logos Row - Police Mitra and Thane Police logos side by side
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Police Mitra Logo
                        if (logoImage != null)
                          Image(
                            logoImage,
                            width: 100,
                            height: 100,
                          )
                        else
                          // Fallback if Police Mitra logo fails to load
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: PdfColor(0.4, 0.2, 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PdfColor(0.8, 0.5, 0.0),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ठाणे',
                                    style: TextStyle(
                                      font: hindiBoldFont,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                  Text(
                                    'पोलीस',
                                    style: TextStyle(
                                      font: hindiBoldFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(width: 20),

                        // Thane Police Logo
                        if (thanePoliceLogoImage != null)
                          Image(
                            thanePoliceLogoImage,
                            width: 100,
                            height: 100,
                          )
                        else
                          // Fallback if Thane Police logo fails to load
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: PdfColor(0.4, 0.2, 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PdfColor(0.8, 0.5, 0.0),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ठाणे',
                                    style: TextStyle(
                                      font: hindiBoldFont,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                  Text(
                                    'पोलीस',
                                    style: TextStyle(
                                      font: hindiBoldFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // App Name
                    Text(
                      'पोलीस मित्र ठाणे पोलीस',
                      style: TextStyle(
                        font: hindiBoldFont,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: PdfColor(0.4, 0.2, 0.6), // Purple
                        letterSpacing: 1,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'POLICE MITRA - THANE POLICE',
                      style: TextStyle(
                        fontSize: 18,
                        // `package:pdf` only supports a limited set of weights.
                        // Map semi-bold (~w600) to bold.
                        fontWeight: FontWeight.bold,
                        color: PdfColor(0.4, 0.2, 0.6),
                        letterSpacing: 1,
                      ),
                    ),

                    SizedBox(height: 30),

                    // Header
                    Text(
                      'CERTIFICATE OF APPRECIATION',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: PdfColor(0.8, 0.5, 0.0), // Amber/gold
                        letterSpacing: 3,
                      ),
                    ),

                    SizedBox(height: 15),

                    // Decorative line
                    Container(
                      width: 350,
                      height: 3,
                      color: PdfColor(0.8, 0.5, 0.0),
                    ),

                    SizedBox(height: 35),

                    // Presented to
                    Text(
                      'This certificate is proudly presented to',
                      style: TextStyle(
                        fontSize: 18,
                        color: PdfColor(0.3, 0.3, 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 20),

                    // User Name
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      decoration: BoxDecoration(
                        color: PdfColor(1.0, 0.95, 0.8), // Light amber
                        border: Border.all(
                          color: PdfColor(0.8, 0.5, 0.0),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userName.toUpperCase(),
                        style: TextStyle(
                          font: hindiBoldFont,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: PdfColor(0.3, 0.15, 0.5), // Dark purple
                          letterSpacing: 4,
                        ),
                      ),
                    ),

                    SizedBox(height: 35),

                    // For service description
                    Text(
                      'For valuable contribution and dedicated service as a',
                      style: TextStyle(
                        fontSize: 16,
                        color: PdfColor(0.3, 0.3, 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'POLICE MITRA VOLUNTEER',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: PdfColor(0.4, 0.2, 0.6),
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Service details - Enhanced
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 50),
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: PdfColor(0.98, 0.98, 0.98),
                        border: Border.all(
                          color: PdfColor(0.7, 0.7, 0.7),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Event Name - Prominent
                          Container(
                            width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                              // `PdfColor` doesn't have `withOpacity`; provide alpha in constructor.
                              color: PdfColor(0.4, 0.2, 0.6, 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'EVENT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PdfColor(0.4, 0.2, 0.6),
                                    letterSpacing: 2,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  serviceName,
                                  style: TextStyle(
                                    font: hindiBoldFont,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: PdfColor(0.2, 0.2, 0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 15),

                          // Service Type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SERVICE PROVIDED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.5, 0.5, 0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      participationArea,
                                      style: TextStyle(
                                        font: hindiFont,
                                        fontSize: 16,
                                        // Map semi-bold (~w600) to bold for `package:pdf`.
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.2, 0.2, 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'LOCATION',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.5, 0.5, 0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      location,
                                      style: TextStyle(
                                        font: hindiFont,
                                        fontSize: 16,
                                        // Map semi-bold (~w600) to bold for `package:pdf`.
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.2, 0.2, 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 15),

                          // Date and Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE OF SERVICE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.5, 0.5, 0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        font: hindiFont,
                                        fontSize: 16,
                                        // Map semi-bold (~w600) to bold for `package:pdf`.
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.2, 0.2, 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'DURATION',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.5, 0.5, 0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      duration,
                                      style: TextStyle(
                                        font: hindiFont,
                                        fontSize: 16,
                                        // Map semi-bold (~w600) to bold for `package:pdf`.
                                        fontWeight: FontWeight.bold,
                                        color: PdfColor(0.2, 0.2, 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 35),

                    // Thank you message
                    Text(
                      'Thank you for your dedicated service to the community',
                      style: TextStyle(
                        fontSize: 15,
                        color: PdfColor(0.3, 0.3, 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 25),

                    // Signature section
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 180,
                                height: 1,
                                color: PdfColors.black,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Police Commissioner',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              Text(
                                'Thane City Police',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PdfColor(0.4, 0.4, 0.4),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                DateFormat('dd MMMM, yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Date of Issue',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PdfColor(0.4, 0.4, 0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Footer text
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      decoration: BoxDecoration(
                        color: PdfColor(0.4, 0.2, 0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'ठाणे पोलीस - सेवा नागरिक सुरक्षेची | Thane Police - Citizens\' Security',
                        style: TextStyle(
                          font: hindiFont,
                          fontSize: 11,
                          color: PdfColors.white,
                          // Medium (~w500) isn't available in `package:pdf`; use normal.
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'PoliceMitra_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Open PDF
    await OpenFilex.open(file.path);
  }
}
