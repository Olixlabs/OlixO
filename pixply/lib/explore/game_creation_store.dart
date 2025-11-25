import 'package:flutter/foundation.dart';
import 'game_data.dart';

class GameCreationStore extends ChangeNotifier {
  GameData _data = GameData();
  GameData get data => _data;

  // --- Info ---
  void setInfo({
    required String name,
    required String about,
    required String overview,
    required int? playersFrom,
    required int? playersTo,
    required int? ageMin,
    required int? ageMax,
    required String? region,
  }) {
    _data
      ..name = name.trim()
      ..about = about.trim()
      ..overview = overview.trim()
      ..playersFrom = playersFrom
      ..playersTo = playersTo
      ..ageMin = ageMin
      ..ageMax = ageMax
      ..region = region?.trim().isEmpty == true ? null : region?.trim();
    notifyListeners();
  }

  // --- Design ---
  void setDesign({required int gridSize, required List<int> pixelsArgb}) {
    final expected = gridSize * gridSize;
    List<int> copy = List<int>.from(pixelsArgb);
    if (copy.length > expected) {
      copy = copy.sublist(0, expected);
    } else if (copy.length < expected) {
      copy.addAll(List<int>.filled(expected - copy.length, 0xFF000000));
    }

    _data
      ..gridSize = gridSize
      ..pixelsArgb = copy;
    notifyListeners();
  }
  // --- Instructions ---
  void setInstruction({
    required String gameplayDescription,
    required String videoUrl,
    String? localMediaPath,
  }) {
    _data
      ..gameplayDescription = gameplayDescription.trim()
      ..instructionVideoUrl = videoUrl.trim()
      ..localMediaPath = (localMediaPath?.trim().isEmpty ?? true) ? null : localMediaPath!.trim();
    notifyListeners();
  }

  GameData current() => _data;
 GameData snapshot() => _data.copy();

  void reset() {
    _data = GameData();
    notifyListeners();
  }
}
