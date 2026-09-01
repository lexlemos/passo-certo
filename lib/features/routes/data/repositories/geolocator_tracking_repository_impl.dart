import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../domain/repositories/location_tracking_repository.dart';

class GeolocatorTrackingRepositoryImpl implements LocationTrackingRepository {
  @override
  Stream<Position> getNavigationPositionStream() {
    // REGRA DE PERFORMANCE CRÍTICA: precisão de navegação e filtro de 3 metros
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Previne "GPS drift" e otimiza a CPU/bateria
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  @override
  Future<void> enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Evita travamentos silenciosos em ambientes de teste sem plataforma nativa
    }
  }

  @override
  Future<void> disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Evita travamentos silenciosos em ambientes de teste sem plataforma nativa
    }
  }
}
