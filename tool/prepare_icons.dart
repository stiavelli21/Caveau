// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final sourcePath = r'C:\Users\stiav\.gemini\antigravity-ide\brain\8afad5c3-84a5-48c7-bea6-a6c8379e2046\caveau_minimal_vault_clean_1786957946458.jpg';
  final targetDir = Directory('assets/icons');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    print('Errore: File sorgente non trovato in $sourcePath');
    exit(1);
  }

  final bytes = sourceFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Errore nella decodifica dell\'immagine.');
    exit(1);
  }

  final centerX = 511;
  final centerY = 526;

  // 1. caveau_icon.png: Main Icon for iOS, Web, Windows & In-App UI.
  // We crop tightly around the vault safe emblem (crop ~590px) so it fills the icon frame
  // with perfect balance, making it prominent, sharp, and easy to see even at small sizes.
  const cropMainSize = 590;
  final cropMain = img.copyCrop(
    image,
    x: (centerX - cropMainSize / 2).round().clamp(0, image.width - cropMainSize),
    y: (centerY - cropMainSize / 2).round().clamp(0, image.height - cropMainSize),
    width: cropMainSize,
    height: cropMainSize,
  );
  final resizedMain = img.copyResize(cropMain, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);
  final mainFile = File('assets/icons/caveau_icon.png');
  mainFile.writeAsBytesSync(img.encodePng(resizedMain));
  print('Main icon created: ${mainFile.path} (${mainFile.lengthSync()} bytes)');

  // 2. caveau_adaptive_foreground.png: Android Adaptive Icon Foreground.
  // Android Adaptive Icons require a ~66%-72% safe zone so circular / squircle masks do not clip the design.
  // Crop size 770px fits the safe emblem right into the Android launcher safe zone.
  const cropAdaptiveSize = 770;
  final cropAdaptive = img.copyCrop(
    image,
    x: (centerX - cropAdaptiveSize / 2).round().clamp(0, image.width - cropAdaptiveSize),
    y: (centerY - cropAdaptiveSize / 2).round().clamp(0, image.height - cropAdaptiveSize),
    width: cropAdaptiveSize,
    height: cropAdaptiveSize,
  );
  final resizedAdaptive = img.copyResize(cropAdaptive, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);
  final adaptiveFile = File('assets/icons/caveau_adaptive_foreground.png');
  adaptiveFile.writeAsBytesSync(img.encodePng(resizedAdaptive));
  print('Adaptive foreground created: ${adaptiveFile.path} (${adaptiveFile.lengthSync()} bytes)');
}
