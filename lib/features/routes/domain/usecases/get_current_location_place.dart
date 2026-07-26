import '../entities/place.dart';
import '../repositories/geocoding_repository.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart'; // Mantido apenas para os enums

class GetCurrentLocationPlaceUseCase {
  final GeocodingRepository _repository;
  final LocationService _locationService;

  GetCurrentLocationPlaceUseCase(this._repository, this._locationService);

  Future<Place> call() async {
    // 1. Verifica se os serviços de GPS estão ativados
    bool serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Os serviços de localização (GPS) estão desativados.');
    }

    // 2. Trata a verificação e solicitação de permissões em tempo de execução
    LocationPermission permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('A permissão de localização foi negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('A permissão de localização foi permanentemente negada.');
    }

    // 3. Obtém a posição geográfica atual do sensor de alta precisão
    final position = await _locationService.getCurrentPosition();

    // 4. Converte latitude/longitude para um endereço real amigável
    return await _repository.getPlaceFromCoordinates(
      position.latitude,
      position.longitude,
    );
  }
}
