/// Command code constants class
class CommandCode {
  /// Command to send program data
  static const int sendProgramData = 0x00;

  /// Command to send completion notification
  static const int sendCompletionNotification = 0x01;

  /// Command to delete all programs
  static const int deleteAllPrograms = 0x02;

  /// Command to add program to playlist
  static const int addProgramToPlaylist = 0x03;

  /// Command to send music and microphone rhythm
  static const int sendMusicRhythm = 0x04;

  /// Command to send real-time doodle data
  static const int sendDoodleData = 0x05;

  /// Command to send temporary program
  static const int sendTemporaryProgram = 0x06;

  /// Command to select program
  static const int selectProgram = 0x07;

  /// Command to complete program playlist update
  static const int updatePlaylistComplete = 0x08;

  /// Command to set LED screen brightness
  static const int setBrightness = 0x09;

  /// Command to switch LED screen
  static const int switchLedScreen = 0x0A;

  /// Command to set LED screen rotation angle
  static const int setRotation = 0x0B;
  
  static const int rotate = 0x0B;
  /// Command to correct LED screen time
  static const int correctTime = 0x0C;

  /// Command to get total number of built-in GIFs
  static const int getBuiltInGifCount = 0x0D;

  /// Command to set password
  static const int setPassword = 0x0E;

  /// Command to verify password
  static const int verifyPassword = 0x0F;

  /// Query if firmware supports new features
  static const int queryFeatureSupport = 0x10;
}