import 'package:geolocator/geolocator.dart';
import '../entities/place.dart';
import '../repositories/geocoding_repository.dart';

class GetCurrentLocationPlaceUseCase {
  final GeocodingRepository _repository;

  GetCurrentLocationPlaceUseCase(this._repository);

  Future<Place> call() async {
    // 1. Verifica se os serviços de GPS estão ativados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Os serviços de localização (GPS) estão desativados.');
    }

    // 2. Trata a verificação e solicitação de permissões em tempo de execução
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('A permissão de localização foi negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('A permissão de localização foi permanentemente negada.');
    }

    // 3. Obtém a posição geográfica atual do sensor de alta precisão
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
      timeLimit: const Duration(seconds: 10),
    );

    // 4. Converte latitude/longitude para um endereço real amigável
    return await _repository.getPlaceFromCoordinates(
      position.latitude,
      position.longitude,
    );
  }
}
