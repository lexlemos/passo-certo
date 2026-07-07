abstract class VoiceNavigationService {
  Future<void> initService();
  Future<void> speak(String text);
  Future<void> stop();
}
