extension IntListExtension on List<int> {
  String toHex({
    bool upperCase = true,
    String prefix = '0x',
    String separator = ', ',
    int? elementsPerLine,
    bool showIndex = false,
    int? width = 2,
  }) {
    // return this.toString();
    StringBuffer buffer = StringBuffer();

    int count = 0;
    for (int i = 0; i < length; i++) {
      if (showIndex) {
        buffer.write('[${i.toString().padLeft(length.toString().length)}] ');
      }

      String hexString = this[i].toRadixString(16);
      if (width != null) {
        hexString = hexString.padLeft(width, '0');
      }

      if (upperCase) {
        hexString = hexString.toUpperCase();
      }

      buffer.write('$prefix$hexString');

      if (i < length - 1) {
        buffer.write(separator);
        count++;

        if (elementsPerLine != null && count == elementsPerLine) {
          buffer.write('\n');
          count = 0;
        }
      }
    }
    buffer.write('\n');
    buffer.write(toString());

    return buffer.toString();
  }
}
