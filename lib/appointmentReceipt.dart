import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class AppointmentReceiptPage extends StatelessWidget {
  final String doctor;
  final String date;
  final double price;
  final String time;

  AppointmentReceiptPage({
    required this.doctor,
    required this.date,
    required this.price,
    required this.time,
  });

    Future<void> _generateAndSavePDF() async {
    // Create a PDF document
    final pdf = pw.Document();

    // Load the asset image as bytesQ
    final imageBytes = await rootBundle.load('assets/cliniclogo.jpg');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    // Use the image in the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(image, height: 100),
            pw.SizedBox(height: 16),
            pw.Text("Good Health", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text("email: goodhealth@gmail.com"),
            pw.Text("tel: 062531789"),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text("Date : $date", style: pw.TextStyle(fontSize: 16)),
            pw.Text("Time : $time", style: pw.TextStyle(fontSize: 16)),
            pw.Text("Doctor: $doctor", style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Price"),
                pw.Text("MYR $price", style: pw.TextStyle(fontSize: 16)),
              ],
            ),
            pw.Divider(thickness: 2),
          ],
        ),
      ),
    );

    // Get the directory to save the file (Downloads folder)
    final directory = await getExternalStorageDirectory();
    final downloadsFolder = Directory('${directory!.path}/Download');

    // Create the Downloads folder if it doesn't exist
    if (!await downloadsFolder.exists()) {
      await downloadsFolder.create(recursive: true);
    }

    final file = File("${downloadsFolder.path}/receipt.pdf");

    // Save the PDF file
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Appointment Receipt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            Image.asset('assets/cliniclogo.jpg', height: 100),
            SizedBox(height: 16),
            Text(
              "Good Health",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("email: goodhealth@gmail.com"),
            Text("tel: 062531789"),
            SizedBox(height: 10),

            Divider(thickness: 2),

            SizedBox(height: 10),

            Column(
              children: [
                Text(
                  "Date: $date",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Time  : $time",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Doctor: $doctor",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Price"),
                Text("MYR $price", style: TextStyle(fontSize: 16)),
              ],
            ),
            Divider(thickness: 2),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.save, color: Colors.white),
              label: Text("Save", style: TextStyle(color: Colors.white)),
              onPressed: () {
                _generateAndSavePDF();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
