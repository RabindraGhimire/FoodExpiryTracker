import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> scanExpiryDate() async {
  try {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile == null) return null;

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer();

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String? detectedDate;

    // Use a regex to search for a date format like 12/05/2025 or 2025-05-12
    final RegExp datePattern = RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (datePattern.hasMatch(line.text)) {
          detectedDate = datePattern.firstMatch(line.text)?.group(0);
          break;
        }
      }
    }

    return detectedDate;
  } catch (e) {
    print('Error scanning expiry date: $e');
    return null;
  }
}
