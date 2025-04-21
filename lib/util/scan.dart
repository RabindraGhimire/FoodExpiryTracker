import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String?> scanDateFromCamera() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null) {
    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = TextRecognizer();

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    // Extract date from recognized text (basic pattern for YYYY-MM-DD, DD/MM/YYYY etc.)
    final RegExp dateRegEx = RegExp(
      r'\b(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b',
    );

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        final match = dateRegEx.firstMatch(line.text);
        if (match != null) {
          return match.group(0);
        }
      }
    }
  }

  return null;
}
