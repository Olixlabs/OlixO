import 'package:led_ble_lib/led_ble_lib.dart';

typedef RotationListener = void Function(ScreenRotation);

class RotationStore {
  static ScreenRotation selectedRotation = ScreenRotation.degree0;
    static final List<RotationListener> _listeners = [];

    static void setRotation(ScreenRotation rotation) {
    selectedRotation = rotation;
    for (final listener in _listeners) {
      listener(rotation);
    }
      }
        static void addListener(RotationListener listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  static void removeListener(RotationListener listener) {
    _listeners.remove(listener);
  }
}


