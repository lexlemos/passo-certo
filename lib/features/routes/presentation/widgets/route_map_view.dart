import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../community/domain/entities/obstacle.dart';
import '../../../community/presentation/bloc/obstacle_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_constants.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';
import '../bloc/add_place_bloc.dart';
import '../../domain/entities/place.dart';
import '../../../community/presentation/widgets/report_obstacle_bottom_sheet.dart';
import 'add_place_bottom_sheet.dart';
import 'map_layers/place_markers_layer.dart';
import 'map_layers/obstacle_markers_layer.dart';
import 'map_layers/map_action_buttons_hud.dart';
import 'map_layers/map_selection_mode_banner.dart';

enum MapSelectionMode { none, obstacle, place }
enum _LocationPermissionStatus { checking, granted, denied }

void _safeMoveMap(MapController controller, LatLng target, [double? zoom]) {
  if (!target.latitude.isFinite || !target.longitude.isFinite) return;
  if (target.latitude < -90.0 ||
      target.latitude > 90.0 ||
      target.longitude < -180.0 ||
      target.longitude > 180.0) {
    return;
  }
  try {
    double validZoom = 15.0;
    try {
      final z = controller.camera.zoom;
      if (z.isFinite && z >= 3.0 && z <= 18.0) {
        validZoom = z;
      }
    } catch (_) {}
    if (zoom != null && zoom.isFinite && zoom >= 3.0 && zoom <= 18.0) {
      validZoom = zoom;
    }
    controller.move(target, validZoom);
  } catch (_) {}
}

/// Widget principal do Mapa de Rotas do Passo Certo.
class RouteMapSection extends StatefulWidget {
  const RouteMapSection({super.key});

  @override
  State<RouteMapSection> createState() => _RouteMapSectionState();
}

class _RouteMapSectionState extends State<RouteMapSection> {
  _LocationPermissionStatus _permissionStatus =
      _LocationPermissionStatus.checking;
  final MapController _mapController = MapController();
  bool _autoCenter = true;
  bool _hasCenteredOnUser = false;
  MapSelectionMode _selectionMode = MapSelectionMode.none;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Verifica permissão de localização com tratamento seguro contra falhas assíncronas.
  Future<void> _checkAndRequestLocationPermission() async {
    try {
      var status = await Permission.locationWhenInUse.status;

      if (status.isGranted) {
        if (mounted) {
          setState(() => _permissionStatus = _LocationPermissionStatus.granted);
        }
        return;
      }

      status = await Permission.locationWhenInUse.request();

      if (!mounted) return;
      setState(() {
        _permissionStatus = status.isGranted
            ? _LocationPermissionStatus.granted
            : _LocationPermissionStatus.denied;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _permissionStatus = _LocationPermissionStatus.granted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final obstacles = context.select<ObstacleBloc, List<Obstacle>>(
      (bloc) => bloc.state.obstacles,
    );
    final addedPlaces = context.select<AddPlaceBloc, List<Place>>(
      (b) => b.state.newlyAddedPlaces,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<ActiveNavigationBloc, ActiveNavigationState>(
          listenWhen: (prev, curr) =>
              prev.isActive != curr.isActive ||
              prev.lastPosition != curr.lastPosition ||
              prev.proximityAlertObstacle != curr.proximityAlertObstacle,
          listener: (context, activeState) {
            if (activeState.proximityAlertObstacle != null) {
              _showProximityAlert(context, activeState.proximityAlertObstacle!);
            }
            if (activeState.isActive &&
                activeState.lastPosition != null &&
                _autoCenter) {
              _safeMoveMap(
                _mapController,
                LatLng(
                  activeState.lastPosition!.latitude,
                  activeState.lastPosition!.longitude,
                ),
              );
            }
          },
        ),
        BlocListener<RoutePlanningBloc, RoutePlanningState>(
          listenWhen: (prev, curr) =>
              (prev.originLat != curr.originLat ||
                  prev.originLng != curr.originLng) &&
              curr.originLat != null &&
              curr.originLng != null,
          listener: (context, planningState) {
            if (!_hasCenteredOnUser) {
              _hasCenteredOnUser = true;
              _safeMoveMap(
                _mapController,
                LatLng(planningState.originLat!, planningState.originLng!),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
        buildWhen: (previous, current) =>
            previous.routes != current.routes ||
            previous.selectedRouteIndex != current.selectedRouteIndex ||
            previous.originLat != current.originLat ||
            previous.originLng != current.originLng ||
            previous.destLat != current.destLat ||
            previous.destLng != current.destLng,
        builder: (context, state) {
          return _buildMapContent(
            state,
            obstacles,
            addedPlaces,
          );
        },
      ),
    );
  }

  Widget _buildMapContent(
    RoutePlanningState state,
    List<Obstacle> obstacles,
    List<Place> addedPlaces,
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

        final obstacleMarkers = ObstacleMarkersLayer.buildMarkers(obstacles);
        final placeMarkers = PlaceMarkersLayer.buildMarkers(addedPlaces);

        final List<Marker> dynamicMarkers = [];
        if (state.originLat != null && state.originLng != null) {
          dynamicMarkers.add(
            Marker(
              point: LatLng(state.originLat!, state.originLng!),
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: -0.785398,
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
                color: AppTheme.emergencyRed,
                size: 30,
                semanticLabel: 'Destino',
              ),
            ),
          );
        }

        return Builder(
          builder: (builderCtx) {
            final activeState = builderCtx.watch<ActiveNavigationBloc>().state;

            return Stack(
              children: [
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          state.originLat != null &&
                          state.originLng != null &&
                          state.originLat!.isFinite &&
                          state.originLng!.isFinite
                          ? LatLng(state.originLat!, state.originLng!)
                          : const LatLng(
                              AppConstants.defaultMapCenterLat,
                              AppConstants.defaultMapCenterLng,
                            ),
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && _autoCenter) {
                          setState(() {
                            _autoCenter = false;
                          });
                        }
                      },
                      onTap: (tapPosition, latLng) {
                        if (_selectionMode == MapSelectionMode.obstacle) {
                          setState(() {
                            _selectionMode = MapSelectionMode.none;
                          });
                          ReportObstacleBottomSheet.show(context, latLng);
                        } else if (_selectionMode == MapSelectionMode.place) {
                          setState(() {
                            _selectionMode = MapSelectionMode.none;
                          });
                          AddPlaceBottomSheet.show(context, latLng);
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
                          ...placeMarkers,
                          ...dynamicMarkers,
                          if (activeState.isActive &&
                              activeState.lastPosition != null)
                            Marker(
                              point: LatLng(
                                activeState.lastPosition!.latitude,
                                activeState.lastPosition!.longitude,
                              ),
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
                ),

                // HUD de Ações do Mapa (FABs Empilhados)
                MapActionButtonsHUD(
                  onAddPlacePressed: () {
                    setState(() {
                      _selectionMode = MapSelectionMode.place;
                    });
                  },
                  onAddObstaclePressed: () {
                    setState(() {
                      _selectionMode = MapSelectionMode.obstacle;
                    });
                  },
                  onRecenterPressed: () {
                    setState(() {
                      _autoCenter = true;
                    });
                    if (activeState.isActive &&
                        activeState.lastPosition != null) {
                      _safeMoveMap(
                        _mapController,
                        LatLng(
                          activeState.lastPosition!.latitude,
                          activeState.lastPosition!.longitude,
                        ),
                      );
                    } else if (state.originLat != null &&
                        state.originLng != null) {
                      _safeMoveMap(
                        _mapController,
                        LatLng(state.originLat!, state.originLng!),
                      );
                    }
                  },
                ),

                // Barra de Instrução no Topo (Modo de Seleção)
                MapSelectionModeBanner(
                  selectionMode: _selectionMode,
                  onCancel: () {
                    setState(() {
                      _selectionMode = MapSelectionMode.none;
                    });
                  },
                ),
              ],
            );
          },
        );
    }
  }
}

void _showProximityAlert(BuildContext context, Obstacle obs) {
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 300), () {
    if (context.mounted) {
      HapticFeedback.heavyImpact();
    }
  });

  final isBlocking = obs.severity == ObstacleSeverity.blocking;
  final bgColor = isBlocking
      ? const Color(0xFFD32F2F)
      : const Color(0xFFFBC02D);
  final textColor = isBlocking ? Colors.white : Colors.black;

  final banner = MaterialBanner(
    content: Text(
      isBlocking ? 'PERIGO A FRENTE: ' : 'ATENÇÃO A FRENTE: ',
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    ),
    leading: Icon(
      isBlocking ? Icons.block : Icons.priority_high,
      color: textColor,
      size: 36,
    ),
    backgroundColor: bgColor,
    elevation: 0,
    actions: [
      TextButton(
        onPressed: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          }
        },
        child: Text(
          'OK',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );

  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  ScaffoldMessenger.of(context).showMaterialBanner(banner);

  Future.delayed(const Duration(seconds: 4), () {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
  });
}
