import 'package:geolocator/geolocator.dart';

abstract class LocationTrackingRepository {
  Stream<Position> getNavigationPositionStream();
  Stream<ServiceStatus> getServiceStatusStream();
  Future<void> enableWakelock();
  Future<void> disableWakelock();
}

