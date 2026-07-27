import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
import 'location_service.dart';

class GeolocatorLocationServiceImpl implements LocationService {
  // --- Métodos exigidos pela interface LocationService ---

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  // --- Lógica principal da Navegação ---

  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica se o GPS do aparelho está ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado no aparelho.');
    }

    // 2. Verifica e pede as permissões
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão negada permanentemente. Vá nas configurações do Android.',
      );
    }

    try {
      // 3. Tenta buscar do Cache do Android primeiro (Instantâneo - Ótimo para ambientes fechados)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        developer.log(
          'Usando localização do cache (rápido).',
          name: 'LocationService',
        );
        return lastKnown;
      }

      // 4. Se não tiver cache, força a busca nos satélites, mas com TIMEOUT DE SEGURANÇA!
      developer.log(
        'Buscando localização via satélite...',
        name: 'LocationService',
      );
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(
            seconds: 8,
          ), // Proteção contra o loop/espera infinita
        ),
      );
    } catch (e) {
      developer.log(
        'Falha ao buscar GPS: $e',
        error: e,
        name: 'LocationService',
      );
      throw Exception(
        'Não foi possível obter o sinal de GPS. Tente chegar perto de uma janela.',
      );
    }
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Mínimo de 2 metros de variação para atualizar
      ),
    );
  }
}
