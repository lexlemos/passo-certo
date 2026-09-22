import 'package:geolocator/geolocator.dart';

abstract class LocationTrackingRepository {
  Stream<Position> getNavigationPositionStream();
  Future<void> enableWakelock();
  Future<void> disableWakelock();
}
