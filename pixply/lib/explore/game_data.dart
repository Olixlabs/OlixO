class GameData {
  // 1) Info
  String name;
  String about;
  String overview;
  int? playersFrom;
  int? playersTo;
  int? ageMin;
  int? ageMax;
  String? region;

  // 2) Design
  int? gridSize;                // e.g., 56
  List<int>? pixelsArgb;        // 56*56  ARGB

  // 3) Instructions
  String gameplayDescription;
  String instructionVideoUrl;   // address (mp4/…)
  String? localMediaPath;       // video 

  GameData({
    this.name = '',
    this.about = '',
    this.overview = '',
    this.playersFrom,
    this.playersTo,
    this.ageMin,
    this.ageMax,
    this.region,
    this.gridSize,
    this.pixelsArgb,
    this.gameplayDescription = '',
    this.instructionVideoUrl = '',
    this.localMediaPath,
  });

  bool get hasVideoUrl => instructionVideoUrl.trim().isNotEmpty;
  bool get hasLocalMedia => (localMediaPath ?? '').isNotEmpty;
  int  get pixelCount => pixelsArgb?.length ?? 0;
   bool get isReadyForRelease {
    final infoOk = name.trim().isNotEmpty && overview.trim().isNotEmpty;
    final designOk = (gridSize ?? 0) > 0 && (pixelsArgb?.length ?? 0) == (gridSize! * gridSize!);
    final instrOk = gameplayDescription.trim().isNotEmpty || hasVideoUrl || hasLocalMedia;
    return infoOk && designOk && instrOk;
  }

  GameData copy() => GameData(
        name: name,
        about: about,
        overview: overview,
        playersFrom: playersFrom,
        playersTo: playersTo,
        ageMin: ageMin,
        ageMax: ageMax,
        region: region,
        gridSize: gridSize,
        pixelsArgb: pixelsArgb == null ? null : List<int>.from(pixelsArgb!),
        gameplayDescription: gameplayDescription,
        instructionVideoUrl: instructionVideoUrl,
        localMediaPath: localMediaPath,
      );
  Map<String, dynamic> toJson() => {
    "name": name,
    "about": about,
    "overview": overview,
    "playersFrom": playersFrom,
    "playersTo": playersTo,
    "ageMin": ageMin,
    "ageMax": ageMax,
    "region": region,
    "gridSize": gridSize,
    "pixelsArgb": pixelsArgb,
    "gameplayDescription": gameplayDescription,
    "instructionVideoUrl": instructionVideoUrl,
    "localMediaPath": localMediaPath,
  };

    static GameData fromJson(Map m) => GameData()
    ..name = m["name"]
    ..about = m["about"]
    ..overview = m["overview"]
    ..playersFrom = m["playersFrom"]
    ..playersTo = m["playersTo"]
    ..ageMin = m["ageMin"]
    ..ageMax = m["ageMax"]
    ..region = m["region"]
    ..gridSize = m["gridSize"]
    ..pixelsArgb = (m["pixelsArgb"] as List?)?.cast<int>()
    ..gameplayDescription = m["gameplayDescription"]
    ..instructionVideoUrl = m["instructionVideoUrl"]
    ..localMediaPath = m["localMediaPath"];
  
}
