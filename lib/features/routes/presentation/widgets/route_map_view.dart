import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ---------------------------------------------------------------------------
// RouteMapSection — widget público usado pela página
// ---------------------------------------------------------------------------
class RouteMapSection extends StatefulWidget {
  const RouteMapSection({super.key});

  @override
  State<RouteMapSection> createState() => _RouteMapSectionState();
}

enum _LocationPermissionStatus { checking, granted, denied }

class _RouteMapSectionState extends State<RouteMapSection> {
  _LocationPermissionStatus _permissionStatus = _LocationPermissionStatus.checking;
  final MapController _mapController = MapController();
  bool _autoCenter = true;

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

  // ---------------------------------------------------------------------------
  // Abre o mapa em tela cheia via overlay animado
  // ---------------------------------------------------------------------------
  void _openFullScreen(BuildContext context) {
    // Captura os BLoCs antes de abrir o diálogo (novo contexto não herda os providers)
    final routeBloc = context.read<RoutePlanningBloc>();
    final obstacleBloc = context.read<ObstacleBloc>();
    final activeNavBloc = context.read<ActiveNavigationBloc>();

    // Permite rotação ao entrar em tela cheia
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            // Injeta os BLoCs no novo contexto do diálogo
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: routeBloc),
                BlocProvider.value(value: obstacleBloc),
                BlocProvider.value(value: activeNavBloc),
              ],
              child: _FullScreenMapDialog(
                permissionStatus: _permissionStatus,
                onClose: () {
                  Navigator.of(ctx).pop();
                  // Restaura apenas orientação retrato ao sair
                  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // CRI-01: Escuta exclusivamente alterações na lista de obstáculos via context.select no build principal
    final obstacles = context.select<ObstacleBloc, List<Obstacle>>((bloc) => bloc.state.obstacles);

    return BlocListener<ActiveNavigationBloc, ActiveNavigationState>(
      listenWhen: (prev, curr) =>
          prev.isActive != curr.isActive ||
          prev.lastPosition != curr.lastPosition,
      listener: (context, activeState) {
        if (activeState.isActive && activeState.lastPosition != null && _autoCenter) {
          _mapController.move(
            LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
            _mapController.camera.zoom,
          );
        }
      },
      child: BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
        buildWhen: (previous, current) =>
            previous.routes != current.routes ||
            previous.selectedRouteIndex != current.selectedRouteIndex,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------------------
              // Mapa compacto (preview)
              // ----------------------------------------------------------------
              Semantics(
                label:
                    'Mapa interativo exibindo o trajeto selecionado. Nível de acessibilidade codificado por cores no mapa.',
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildMapContent(state, obstacles, _mapController),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------------
              // Botão "Iniciar Rota"
              // ----------------------------------------------------------------
              Semantics(
                button: true,
                label: 'Iniciar rota — expande o mapa para tela cheia',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openFullScreen(context),
                    icon: const Icon(Icons.navigation_rounded, size: 22),
                    label: const Text(
                      'Iniciar Rota',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mintGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.mintGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapContent(
    RoutePlanningState state,
    List<Obstacle> obstacles,
    MapController mapController,
  ) {
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

        final List<Marker> dynamicMarkers = [];
        if (state.originLat != null && state.originLng != null) {
          dynamicMarkers.add(
            Marker(
              point: LatLng(state.originLat!, state.originLng!),
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: -0.785398, // Rotaciona 45 graus para parecer uma seta de navegação ativa inclinada (ou use sem rotação)
                child: const Icon(
                  Icons.navigation,
                  color: AppTheme.spaceBlue,
                  size: 30,
                  semanticLabel: 'Origem (Sua Localização)',
                ),
              ),
            ),
          );
        }
        if (state.destLat != null && state.destLng != null) {
          dynamicMarkers.add(
            Marker(
              point: LatLng(state.destLat!, state.destLng!),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: AppTheme.mintGreen,
                size: 30,
                semanticLabel: 'Destino',
              ),
            ),
          );
        }

        return Builder(builder: (builderCtx) {
          final activeState = builderCtx.watch<ActiveNavigationBloc>().state;

          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: state.originLat != null && state.originLng != null
                      ? LatLng(state.originLat!, state.originLng!)
                      : const LatLng(-10.9472, -37.0731),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() {
                        _autoCenter = false;
                      });
                    }
                  },
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
                      ...obstacleMarkers,
                      ...dynamicMarkers,
                      if (activeState.isActive && activeState.lastPosition != null)
                        Marker(
                          point: LatLng(activeState.lastPosition!.latitude,
                              activeState.lastPosition!.longitude),
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
              if (!_autoCenter && activeState.isActive)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        _autoCenter = true;
                      });
                      if (activeState.lastPosition != null) {
                        mapController.move(
                          LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
                          mapController.camera.zoom,
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.gps_not_fixed, color: AppTheme.spaceBlue),
                  ),
                ),
              const Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: MapLegend(),
              ),
            ],
          );
        });
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

// ---------------------------------------------------------------------------
// _FullScreenMapDialog — diálogo que ocupa toda a tela
// ---------------------------------------------------------------------------
class _FullScreenMapDialog extends StatefulWidget {
  final _LocationPermissionStatus permissionStatus;
  final VoidCallback onClose;

  const _FullScreenMapDialog({
    required this.permissionStatus,
    required this.onClose,
  });

  @override
  State<_FullScreenMapDialog> createState() => _FullScreenMapDialogState();
}

class _FullScreenMapDialogState extends State<_FullScreenMapDialog> {
  final MapController _mapController = MapController();
  bool _autoCenter = true;

  @override
  Widget build(BuildContext context) {
    final obstacles =
        context.select<ObstacleBloc, List<Obstacle>>((bloc) => bloc.state.obstacles);

    return BlocListener<ActiveNavigationBloc, ActiveNavigationState>(
      listenWhen: (prev, curr) =>
          prev.isActive != curr.isActive ||
          prev.lastPosition != curr.lastPosition,
      listener: (context, activeState) {
        if (activeState.isActive && activeState.lastPosition != null && _autoCenter) {
          _mapController.move(
            LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
            _mapController.camera.zoom,
          );
        }
      },
      child: BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
        buildWhen: (previous, current) =>
            previous.routes != current.routes ||
            previous.selectedRouteIndex != current.selectedRouteIndex,
        builder: (context, state) {
          final polylines = state.routes.asMap().entries.map((entry) {
            final index = entry.key;
            final route = entry.value;
            final isSelected = index == state.selectedRouteIndex;
            final isRec = route.accessibilityScore >= 0.8;
            return Polyline(
              points: route.latLngWaypoints,
              color: isSelected
                  ? (isRec ? AppTheme.mintGreen : Colors.orange)
                  : (isRec
                      ? AppTheme.mintGreen.withValues(alpha: 0.4)
                      : Colors.orange.withValues(alpha: 0.4)),
              strokeWidth: isSelected ? 10 : 5,
            );
          }).toList();

          final obstacleMarkers = _buildObstacleMarkers(obstacles);

          final List<Marker> dynamicMarkers = [];
          if (state.originLat != null && state.originLng != null) {
            dynamicMarkers.add(
              Marker(
                point: LatLng(state.originLat!, state.originLng!),
                width: 48,
                height: 48,
                child: Transform.rotate(
                  angle: -0.785398,
                  child: const Icon(
                    Icons.navigation,
                    color: AppTheme.spaceBlue,
                    size: 36,
                    semanticLabel: 'Origem (Sua Localização)',
                  ),
                ),
              ),
            );
          }
          if (state.destLat != null && state.destLng != null) {
            dynamicMarkers.add(
              Marker(
                point: LatLng(state.destLat!, state.destLng!),
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.mintGreen,
                  size: 36,
                  semanticLabel: 'Destino',
                ),
              ),
            );
          }

          return Material(
            color: Colors.black,
            child: Builder(builder: (builderCtx) {
              final activeState = builderCtx.watch<ActiveNavigationBloc>().state;

              return Stack(
                children: [
                  // --------------------------------------------------------
                  // Mapa ocupa 100% da tela
                  // --------------------------------------------------------
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: state.originLat != null && state.originLng != null
                          ? LatLng(state.originLat!, state.originLng!)
                          : const LatLng(-10.9472, -37.0731),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture) {
                          setState(() {
                            _autoCenter = false;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.passo_certo',
                      ),
                      PolylineLayer(polylines: polylines),
                      MarkerLayer(
                        markers: [
                          ...obstacleMarkers,
                          ...dynamicMarkers,
                          if (activeState.isActive && activeState.lastPosition != null)
                            Marker(
                              point: LatLng(activeState.lastPosition!.latitude,
                                  activeState.lastPosition!.longitude),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.navigation,
                                color: AppTheme.mintGreen,
                                size: 36,
                                semanticLabel: 'Sua posição atual na navegação',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // --------------------------------------------------------
                  // Legenda na parte inferior
                  // --------------------------------------------------------
                  const Positioned(
                    bottom: 32,
                    left: 16,
                    right: 16,
                    child: MapLegend(),
                  ),

                  if (!_autoCenter && activeState.isActive)
                    Positioned(
                      bottom: 100,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            _autoCenter = true;
                          });
                          if (activeState.lastPosition != null) {
                            _mapController.move(
                              LatLng(activeState.lastPosition!.latitude, activeState.lastPosition!.longitude),
                              _mapController.camera.zoom,
                            );
                          }
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.gps_not_fixed, color: AppTheme.spaceBlue),
                      ),
                    ),

                  // --------------------------------------------------------
                  // Botão fechar (canto superior esquerdo)
                  // --------------------------------------------------------
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    child: Semantics(
                      button: true,
                      label: 'Fechar mapa em tela cheia',
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.spaceBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --------------------------------------------------------
                  // Rótulo "Navegação em Tela Cheia" no topo
                  // --------------------------------------------------------
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.spaceBlue.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Passo Certo — Navegação',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

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
        width: 40,
        height: 40,
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
            child: Icon(iconData, color: color, size: 22),
          ),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// MapLegend — legenda reutilizável
// ---------------------------------------------------------------------------
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
