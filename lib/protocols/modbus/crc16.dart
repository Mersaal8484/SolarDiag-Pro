abstract final class ModbusCrc16 {
  static int calculate(List<int> bytes) {
    var crc = 0xffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xa001 : crc >> 1;
      }
    }
    return crc & 0xffff;
  }

  static bool valid(List<int> frame) {
    if (frame.length < 4) return false;
    final expected = calculate(frame.sublist(0, frame.length - 2));
    return frame[frame.length - 2] == expected & 0xff &&
        frame.last == expected >> 8;
  }
}
