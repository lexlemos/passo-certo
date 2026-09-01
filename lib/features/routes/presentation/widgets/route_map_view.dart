import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../community/domain/entities/obstacle.dart';
import '../../../community/presentation/bloc/obstacle_bloc.dart';
import '../../domain/entities/place.dart';
import '../bloc/add_place_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_constants.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';
import '../../../community/presentation/widgets/report_obstacle_bottom_sheet.dart';
import 'add_place_bottom_sheet.dart';
import 'map_layers/place_markers_layer.dart';
import 'map_layers/obstacle_markers_layer.dart';
import 'map_layers/map_action_buttons_hud.dart';
import 'map_layers/map_selection_mode_banner.dart';
import 'map_layers/route_polyline_layer.dart';
import 'map_layers/user_location_layer.dart';
import 'map_layers/cached_tile_provider.dart';

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
  final VoidCallback? onMapTap;

  const RouteMapSection({super.key, this.onMapTap});

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
          listenWhen: (prev, curr) {
            final originChanged =
                (prev.originLat != curr.originLat ||
                    prev.originLng != curr.originLng) &&
                curr.originLat != null &&
                curr.originLng != null;
            final isResetSearch =
                prev.routes.isNotEmpty &&
                curr.routes.isEmpty &&
                curr.destLat == null;
            final destinationSelected =
                prev.destLat == null && curr.destLat != null;
            final routesCalculated =
                prev.routes.isEmpty && curr.routes.isNotEmpty;
            return originChanged ||
                isResetSearch ||
                destinationSelected ||
                routesCalculated;
          },
          listener: (context, planningState) {
            final isResetSearch =
                planningState.routes.isEmpty && planningState.destLat == null;
            final destinationSelected =
                planningState.destLat != null && planningState.routes.isEmpty;
            final routesCalculated = planningState.routes.isNotEmpty;

            if (routesCalculated) {
              if (planningState.originLat != null &&
                  planningState.destLat != null) {
                try {
                  final bounds = LatLngBounds(
                    LatLng(planningState.originLat!, planningState.originLng!),
                    LatLng(planningState.destLat!, planningState.destLng!),
                  );
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(40.0),
                    ),
                  );
                } catch (_) {}
              }
            } else if (destinationSelected) {
              _safeMoveMap(
                _mapController,
                LatLng(planningState.destLat!, planningState.destLng!),
                16.0,
              );
            } else if (!_hasCenteredOnUser || isResetSearch) {
              _hasCenteredOnUser = true;
              if (planningState.originLat != null &&
                  planningState.originLng != null) {
                _safeMoveMap(
                  _mapController,
                  LatLng(planningState.originLat!, planningState.originLng!),
                  isResetSearch ? 16.0 : null,
                );
              }
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
          return _buildMapContent(state, obstacles, addedPlaces);
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
        final polylines = RoutePolylineLayer.buildPolylines(
          routes: state.routes,
          selectedRouteIndex: state.selectedRouteIndex,
        );

        final obstacleMarkers = ObstacleMarkersLayer.buildMarkers(
          obstacles,
          onTap: (obstacle) => _showObstacleDetailsSheet(context, obstacle),
        );
        final placeMarkers = PlaceMarkersLayer.buildMarkers(
          addedPlaces,
          onTap: (place) => _showDeletePlaceDialog(context, place),
        );

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
                  maxZoom: AppConstants.mapMaxZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapEvent: (event) {
                    if (event.source != MapEventSource.mapController &&
                        event.source != MapEventSource.custom) {
                      if (_autoCenter) {
                        setState(() {
                          _autoCenter = false;
                        });
                      }
                    }
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && _autoCenter) {
                      setState(() {
                        _autoCenter = false;
                      });
                    }
                  },
                  onTap: (tapPosition, latLng) {
                    FocusScope.of(context).unfocus();
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
                    } else {
                      widget.onMapTap?.call();
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.passo_certo',
                    // Tile Scaling: servidor CartoCDN serve até zoom 19 (maxNativeZoom).
                    // Para zooms acima, o flutter_map estica digitalmente o tile do
                    // nível 19 até mapMaxZoom da câmera — sem requisições inválidas
                    // e sem telas cinzas. Ideal para navegação interna pedestre.
                    maxNativeZoom: AppConstants.mapMaxNativeZoom,
                    maxZoom: AppConstants.mapMaxZoom,
                    tileProvider: CachedTileProvider(),
                    keepBuffer: 2,
                    panBuffer: 1,
                    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                  ),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(
                    markers: [
                      ...obstacleMarkers,
                      ...placeMarkers,
                      ...dynamicMarkers,
                    ],
                  ),
                  const UserLocationLayer(),
                ],
              ),
            ),

            // Banner de Alerta de GPS Desativado
            const _GpsDisabledBanner(),

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
                final activeState = context.read<ActiveNavigationBloc>().state;
                if (activeState.isActive && activeState.lastPosition != null) {
                  _safeMoveMap(
                    _mapController,
                    LatLng(
                      activeState.lastPosition!.latitude,
                      activeState.lastPosition!.longitude,
                    ),
                  );
                } else if (state.originLat != null && state.originLng != null) {
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
    }
  }

  /// Bottom sheet com detalhes completos do obstáculo.
  void _showObstacleDetailsSheet(BuildContext context, Obstacle obstacle) {
    final isBlocking = obstacle.severity == ObstacleSeverity.blocking;

    // Labels legíveis por tipo
    final typeLabels = {
      ObstacleType.pothole: 'Buraco no piso',
      ObstacleType.noTactilePaving: 'Sem piso tátil',
      ObstacleType.stairs: 'Escada',
      ObstacleType.blockedSidewalk: 'Calçada bloqueada',
      ObstacleType.other: 'Outro',
    };
    final typeLabel = typeLabels[obstacle.type] ?? 'Desconhecido';
    final severityColor = isBlocking
        ? const Color(0xFFD32F2F)
        : const Color(0xFFFBC02D);
    final severityLabel = isBlocking ? 'Bloqueio' : 'Aviso';
    final severityIcon = isBlocking ? Icons.block : Icons.priority_high;

    // Formata a data de reporte
    final dt = obstacle.reportedAt.toLocal();
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puxador
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo + severidade
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            severityIcon,
                            color: isBlocking ? Colors.white : Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            severityLabel,
                            style: TextStyle(
                              color: isBlocking ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Descrição
                const Text(
                  'Descrição',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF718096),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  obstacle.description.isNotEmpty
                      ? obstacle.description
                      : 'Sem descrição informada.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Data
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFFA0AEC0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reportado em $dateStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA0AEC0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Botão remover
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'Remover Obstáculo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _confirmDeleteObstacle(context, obstacle);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Diálogo de confirmação para remover um obstáculo.
  void _confirmDeleteObstacle(BuildContext context, Obstacle obstacle) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmar remoção?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Este obstáculo será marcado como resolvido e sumirá do mapa.',
          style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<ObstacleBloc>().add(
                DeleteObstacleEvent(obstacleId: obstacle.id),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  /// Diálogo de confirmação para apagar um local.
  void _showDeletePlaceDialog(BuildContext context, Place place) {
    if (place.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este local ainda não foi sincronizado com o servidor.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: Color(0xFFD32F2F),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Remover "${place.name}"?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.category.isNotEmpty)
              Text(
                'Categoria: ${place.category}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
              ),
            const SizedBox(height: 8),
            const Text(
              'Este local será apagado permanentemente do mapa.',
              style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Remover'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AddPlaceBloc>().add(
                DeletePlaceEvent(placeId: place.id!),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Banner amigável exibido quando o sinal ou serviço de GPS do aparelho é desligado durante a navegação.
class _GpsDisabledBanner extends StatelessWidget {
  const _GpsDisabledBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveNavigationBloc, ActiveNavigationState>(
      buildWhen: (prev, curr) => prev.isGpsDisabled != curr.isGpsDisabled,
      builder: (context, state) {
        if (!state.isGpsDisabled) return const SizedBox.shrink();

        return Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.emergencyRed,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sinal de GPS Perdido! Por favor, ative a localização.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
