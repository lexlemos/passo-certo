import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../community/domain/entities/obstacle.dart';
import '../../../community/presentation/bloc/obstacle_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';

class RouteMapSection extends StatefulWidget {
  const RouteMapSection({super.key});

  @override
  State<RouteMapSection> createState() => _RouteMapSectionState();
}

enum _LocationPermissionStatus { checking, granted, denied }

class _RouteMapSectionState extends State<RouteMapSection> {
  _LocationPermissionStatus _permissionStatus = _LocationPermissionStatus.checking;
  final MapController _mapController = MapController();

  /// Marcadores estáticos declarados como const — inicializados uma única vez na compilação.
  static const List<Marker> _staticMarkers = [
    Marker(
      point: LatLng(-10.9472, -37.0731),
      width: 40,
      height: 40,
      child: Icon(
        Icons.my_location,
        color: AppTheme.spaceBlue,
        size: 30,
        semanticLabel: 'Origem: CCET UFS',
      ),
    ),
    Marker(
      point: LatLng(-10.9350, -37.0650),
      width: 40,
      height: 40,
      child: Icon(
        Icons.location_on,
        color: AppTheme.mintGreen,
        size: 30,
        semanticLabel: 'Destino: Terminal D.I.A.',
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  /// Verifica e, se necessário, solicita permissão de localização.
  /// Atualiza [_permissionStatus] para controlar qual UI exibir.
  Future<void> _checkAndRequestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      if (mounted) setState(() => _permissionStatus = _LocationPermissionStatus.granted);
      return;
    }

    // Solicita ao usuário (exibe o diálogo do SO apenas na primeira vez)
    status = await Permission.locationWhenInUse.request();

    if (!mounted) return;
    setState(() {
      _permissionStatus = status.isGranted
          ? _LocationPermissionStatus.granted
          : _LocationPermissionStatus.denied;
    });
  }

  @override
  Widget build(BuildContext context) {
    // CRI-01: Escuta exclusivamente alterações na lista de obstáculos via context.select no build principal
    final obstacles = context.select<ObstacleBloc, List<Obstacle>>((bloc) => bloc.state.obstacles);

    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.routes != current.routes ||
          previous.selectedRouteIndex != current.selectedRouteIndex,
      builder: (context, state) {
        return Semantics(
          label: "Mapa interativo exibindo o trajeto selecionado. Nível de acessibilidade codificado por cores no mapa.",
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMapContent(state, obstacles),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapContent(RoutePlanningState state, List<Obstacle> obstacles) {
    switch (_permissionStatus) {
      case _LocationPermissionStatus.checking:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando permissão de localização...'),
            ],
          ),
        );

      case _LocationPermissionStatus.denied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Permissão de localização necessária',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para exibir sua posição no mapa, permita o acesso à localização nas configurações.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Abre as configurações do app se a permissão foi negada permanentemente
                    final opened = await openAppSettings();
                    if (!opened && mounted) {
                      _checkAndRequestLocationPermission();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Abrir Configurações'),
                ),
              ],
            ),
          ),
        );

      case _LocationPermissionStatus.granted:
        final polylines = state.routes.asMap().entries.map((entry) {
          final index = entry.key;
          final route = entry.value;
          final isSelected = index == state.selectedRouteIndex;
          final isRec = route.accessibilityScore >= 0.8;
          // MED-01: Utiliza a lista de waypoints já pré-calculada no construtor da rota
          final latLngWaypoints = route.latLngWaypoints;
          return Polyline(
            points: latLngWaypoints,
            color: isSelected
                ? (isRec ? AppTheme.mintGreen : Colors.orange)
                : (isRec
                    ? AppTheme.mintGreen.withValues(alpha: 0.4)
                    : Colors.orange.withValues(alpha: 0.4)),
            strokeWidth: isSelected ? 8 : 4,
          );
        }).toList();

        final obstacleMarkers = _buildObstacleMarkers(obstacles);
        final activeState = context.watch<ActiveNavigationBloc>().state;

        // Bônus de UX: Auto-centra a câmera na última posição geográfica da navegação ativa
        if (activeState.isActive && activeState.lastPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
              _mapController.camera.zoom,
            );
          });
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(-10.9472, -37.0731),
                initialZoom: 15.0,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.passo_certo',
                ),
                PolylineLayer(
                  polylines: polylines,
                ),
                MarkerLayer(
                  markers: [
                    ..._staticMarkers,
                    ...obstacleMarkers,
                    if (activeState.isActive && activeState.lastPosition != null)
                      Marker(
                        point: LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.navigation,
                          color: AppTheme.mintGreen,
                          size: 32,
                          semanticLabel: 'Sua posição atual na navegação',
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: MapLegend(),
            ),
          ],
        );
    }
  }

  /// Converte a lista de entidades de obstáculos para Marcadores acessíveis do flutter_map
  List<Marker> _buildObstacleMarkers(List<Obstacle> obstacles) {
    return obstacles.map((obstacle) {
      final IconData iconData;
      final Color color;
      final String semanticLabel;

      switch (obstacle.type) {
        case ObstacleType.pothole:
          iconData = Icons.warning_amber_rounded;
          color = Colors.orange;
          semanticLabel = 'Alerta: Buraco. ${obstacle.description}';
          break;
        case ObstacleType.noTactilePaving:
          iconData = Icons.do_not_disturb_on_total_silence;
          color = Colors.blue;
          semanticLabel = 'Alerta: Ausência de piso podotátil. ${obstacle.description}';
          break;
        case ObstacleType.stairs:
          iconData = Icons.stairs_rounded;
          color = AppTheme.emergencyRed;
          semanticLabel = 'Alerta: Escada sem rampa. ${obstacle.description}';
          break;
        case ObstacleType.blockedSidewalk:
          iconData = Icons.block_flipped;
          color = Colors.redAccent;
          semanticLabel = 'Alerta: Calçada bloqueada. ${obstacle.description}';
          break;
        case ObstacleType.other:
          iconData = Icons.help_outline_rounded;
          color = Colors.grey;
          semanticLabel = 'Alerta: Obstáculo geral. ${obstacle.description}';
          break;
      }

      return Marker(
        point: LatLng(obstacle.latitude, obstacle.longitude),
        width: 36,
        height: 36,
        child: Semantics(
          label: semanticLabel,
          button: false,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              iconData,
              color: color,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseCard(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: AppTheme.mintGreen, label: 'Boa'),
          _LegendItem(color: Colors.orange, label: 'Regular'),
          _LegendItem(color: AppTheme.emergencyRed, label: 'Atenção'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 6),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
