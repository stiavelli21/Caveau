import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/icons/caveau_desktop_icon.png').readAsBytesSync();
  final src = img.decodePng(bytes)!;

  final dibSizes = [16, 24, 32, 48, 64];
  const pngSize = 256;

  final dibImages = dibSizes.map((s) => img.copyResize(src, width: s, height: s, interpolation: img.Interpolation.cubic)).toList();
  final pngImage = img.copyResize(src, width: pngSize, height: pngSize, interpolation: img.Interpolation.cubic);
  final pngBytes = img.encodePng(pngImage);

  final totalEntries = dibSizes.length + 1;
  final headerSize = 6 + totalEntries * 16;

  final entryDataList = <Uint8List>[];

  // Generate DIB data for each size
  for (int i = 0; i < dibSizes.length; i++) {
    final s = dibSizes[i];
    final image = dibImages[i];

    // DIB header (40 bytes)
    // Pixel data: s * s * 4 bytes (BGRA, bottom-up)
    // AND mask: ((s + 31) ~/ 32 * 4) * s bytes
    final andRowBytes = ((s + 31) ~/ 32) * 4;
    final andMaskSize = andRowBytes * s;
    final pixelDataSize = s * s * 4;
    final totalSize = 40 + pixelDataSize + andMaskSize;

    final dib = Uint8List(totalSize);
    final bd = ByteData.sublistView(dib);

    // BITMAPINFOHEADER
    bd.setUint32(0, 40, Endian.little);
    bd.setInt32(4, s, Endian.little);
    bd.setInt32(8, s * 2, Endian.little); // Height is doubled for XOR + AND masks
    bd.setUint16(12, 1, Endian.little); // Planes
    bd.setUint16(14, 32, Endian.little); // Bit count (32-bit BGRA)
    bd.setUint32(16, 0, Endian.little); // BI_RGB
    bd.setUint32(20, pixelDataSize, Endian.little);
    bd.setInt32(24, 0, Endian.little);
    bd.setInt32(28, 0, Endian.little);
    bd.setUint32(32, 0, Endian.little);
    bd.setUint32(36, 0, Endian.little);

    int pixelOffset = 40;
    // DIB pixels are stored bottom-to-top
    for (int y = s - 1; y >= 0; y--) {
      for (int x = 0; x < s; x++) {
        final p = image.getPixel(x, y);
        dib[pixelOffset++] = p.b.toInt(); // Blue
        dib[pixelOffset++] = p.g.toInt(); // Green
        dib[pixelOffset++] = p.r.toInt(); // Red
        dib[pixelOffset++] = p.a.toInt(); // Alpha
      }
    }

    // AND mask (bottom-to-top)
    int maskOffset = 40 + pixelDataSize;
    for (int y = s - 1; y >= 0; y--) {
      for (int x = 0; x < s; x++) {
        final p = image.getPixel(x, y);
        // If alpha < 128, bit is 1 (transparent), else 0 (opaque)
        if (p.a < 128) {
          final byteIdx = maskOffset + (x ~/ 8);
          final bitIdx = 7 - (x % 8);
          dib[byteIdx] |= (1 << bitIdx);
        }
      }
      maskOffset += andRowBytes;
    }

    entryDataList.add(dib);
  }

  // Add 256x256 PNG
  entryDataList.add(Uint8List.fromList(pngBytes));

  // Now assemble full ICO file
  final icoBuffer = BytesBuilder();

  // ICO header: 0-1 (0), 2-3 (1 = icon), 4-5 (count)
  final hdr = Uint8List(6);
  final hdrBd = ByteData.sublistView(hdr);
  hdrBd.setUint16(0, 0, Endian.little);
  hdrBd.setUint16(2, 1, Endian.little);
  hdrBd.setUint16(4, totalEntries, Endian.little);
  icoBuffer.add(hdr);

  // Directory entries
  int currentDataOffset = headerSize;
  for (int i = 0; i < totalEntries; i++) {
    final entry = Uint8List(16);
    final eBd = ByteData.sublistView(entry);
    final isPng = i == dibSizes.length;
    final size = isPng ? pngSize : dibSizes[i];
    final dataSize = entryDataList[i].length;

    entry[0] = size == 256 ? 0 : size; // Width
    entry[1] = size == 256 ? 0 : size; // Height
    entry[2] = 0; // Color count (0 for >= 8bpp)
    entry[3] = 0; // Reserved
    eBd.setUint16(4, 1, Endian.little); // Color planes
    eBd.setUint16(6, 32, Endian.little); // Bit count
    eBd.setUint32(8, dataSize, Endian.little); // Bytes in res
    eBd.setUint32(12, currentDataOffset, Endian.little); // Image offset

    icoBuffer.add(entry);
    currentDataOffset += dataSize;
  }

  // Add all image data
  for (final data in entryDataList) {
    icoBuffer.add(data);
  }

  final finalIcoBytes = icoBuffer.toBytes();
  final target = File('windows/runner/resources/app_icon.ico');
  target.writeAsBytesSync(finalIcoBytes);
  print('Successfully generated standard Windows ICO: ${finalIcoBytes.length} bytes with ${totalEntries} resolutions');
}
