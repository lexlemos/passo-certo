import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/route_planning_bloc.dart';

class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({super.key});

  @override
  State<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<RoutePlanningBloc>();
    _originController = TextEditingController(text: bloc.state.originText);
    _destinationController = TextEditingController(text: bloc.state.destinationText);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<RoutePlanningBloc, RoutePlanningState>(
        listenWhen: (prev, curr) =>
            prev.originText != curr.originText ||
            prev.destinationText != curr.destinationText,
        listener: (context, state) {
          if (_originController.text != state.originText) {
            _originController.text = state.originText;
          }
          if (_destinationController.text != state.destinationText) {
            _destinationController.text = state.destinationText;
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RoutePlanningHeader(),
              const SizedBox(height: 24),
              RouteSearchCard(
                originController: _originController,
                destinationController: _destinationController,
              ),
              const SizedBox(height: 32),
              const RoutesHeader(),
              const SizedBox(height: 16),
              
              // Lista de Rotas Otimizada
              BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
                buildWhen: (previous, current) =>
                    previous.selectedRouteIndex != current.selectedRouteIndex,
                builder: (context, state) {
                  return Column(
                    children: [
                      RouteOptionCard(
                        title: 'Via CCET Park',
                        time: '15 min',
                        distance: '1.2 km',
                        isRecommended: true,
                        accessibilityLevel: 'Alto (95%)',
                        tags: const ['PLANO', 'CALÇADAS BOAS'],
                        isSelected: state.selectedRouteIndex == 0,
                        onTap: () => context
                            .read<RoutePlanningBloc>()
                            .add(SelectRouteEvent(routeIndex: 0)),
                      ),
                      RouteOptionCard(
                        title: 'Via Terminal UFS',
                        time: '12 min',
                        distance: '0.9 km',
                        isRecommended: false,
                        accessibilityLevel: 'Médio (60%)',
                        tags: const ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
                        isSelected: state.selectedRouteIndex == 1,
                        onTap: () => context
                            .read<RoutePlanningBloc>()
                            .add(SelectRouteEvent(routeIndex: 1)),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              const RouteMapSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutePlanningHeader extends StatelessWidget {
  const RoutePlanningHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para onde vamos?', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Planeje seu trajeto com segurança e autonomia.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class RoutesHeader extends StatelessWidget {
  const RoutesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          const Icon(Icons.route, color: AppTheme.spaceBlue),
          const SizedBox(width: 8),
          Text('Rotas Disponíveis', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class RouteSearchCard extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;

  const RouteSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.selectedFilter != current.selectedFilter,
      builder: (context, state) {
        return BaseCard(
          semanticLabel: "Formulário de busca de rotas",
          child: Column(
            children: [
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Column(
                    children: [
                      RouteTextField(
                        hint: 'Sua localização atual',
                        label: 'Origem',
                        icon: Icons.my_location,
                        iconColor: AppTheme.spaceBlue,
                        controller: originController,
                      ),
                      const SizedBox(height: 12),
                      RouteTextField(
                        hint: 'Para onde quer ir?',
                        label: 'Destino',
                        icon: Icons.location_on,
                        iconColor: AppTheme.mintGreen,
                        controller: destinationController,
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    child: Semantics(
                      button: true,
                      label: "Inverter origem e destino",
                      child: FloatingActionButton.small(
                        onPressed: () => context.read<RoutePlanningBloc>().add(
                              SwapLocationsEvent(
                                originText: originController.text,
                                destinationText: destinationController.text,
                              ),
                            ),
                        backgroundColor: theme.scaffoldBackgroundColor,
                        elevation: 2,
                        child: const Icon(Icons.swap_vert, color: AppTheme.spaceBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'Totalmente Acessível',
                    icon: Icons.accessible,
                    isSelected: state.selectedFilter == 'accessible',
                    filterValue: 'accessible',
                  ),
                  _FilterChip(
                    label: 'Mais Rápida',
                    icon: Icons.timer,
                    isSelected: state.selectedFilter == 'fastest',
                    filterValue: 'fastest',
                  ),
                  _FilterChip(
                    label: 'Mais Arborizada',
                    icon: Icons.park,
                    isSelected: state.selectedFilter == 'treed',
                    filterValue: 'treed',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BaseButton(
                label: 'Buscar Rotas',
                semanticLabel: 'Botão. Iniciar busca pelas melhores rotas.',
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => context.read<RoutePlanningBloc>().add(
                      SearchRoutesEvent(
                        originText: originController.text,
                        destinationText: destinationController.text,
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RouteTextField extends StatelessWidget {
  final String hint;
  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController? controller;

  const RouteTextField({
    super.key,
    required this.hint,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: AppTheme.softGreyBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final String filterValue;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? AppTheme.mintGreen : AppTheme.textMuted,
      ),
      selected: isSelected,
      selectedColor: AppTheme.mintGreen.withValues(alpha: 0.1),
      backgroundColor: AppTheme.softGreyBg,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.mintGreen : AppTheme.textMuted,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => context.read<RoutePlanningBloc>().add(SelectFilterEvent(filter: filterValue)),
    );
  }
}

class RouteOptionCard extends StatelessWidget {
  final String title;
  final String time;
  final String distance;
  final bool isRecommended;
  final String accessibilityLevel;
  final List<String> tags;
  final VoidCallback onTap;
  final bool isSelected;

  const RouteOptionCard({
    super.key,
    required this.title,
    required this.time,
    required this.distance,
    required this.isRecommended,
    required this.accessibilityLevel,
    required this.tags,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighAccessibility = accessibilityLevel.contains('Alto');

    return BaseCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      semanticLabel:
          "Rota $title. Tempo estimado $time. Distância $distance. Nível de acessibilidade $accessibilityLevel. Toque duas vezes para selecionar.",
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.mintGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.mintGreen,
                          ),
                        ),
                        Text(distance, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tags
                      .map((tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: AppTheme.softGreyBg,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Acessibilidade: $accessibilityLevel',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: isHighAccessibility ? 0.95 : 0.60,
                  backgroundColor: AppTheme.softGreyBg,
                  color: isHighAccessibility ? AppTheme.mintGreen : Colors.orange,
                ),
              ],
            ),
            if (isRecommended)
              Positioned(
                top: 0,
                right: 80, // Ajuste para não sobrepor o tempo
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Recomendada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RouteMapSection extends StatefulWidget {
  const RouteMapSection({super.key});

  @override
  State<RouteMapSection> createState() => _RouteMapSectionState();
}

class _RouteMapSectionState extends State<RouteMapSection> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.routes != current.routes ||
          previous.selectedRouteIndex != current.selectedRouteIndex,
      builder: (context, state) {
        final markers = {
          const Marker(
            markerId: MarkerId('origin'),
            position: LatLng(-10.9472, -37.0731),
            infoWindow: InfoWindow(title: 'Origem (CCET UFS)'),
          ),
          const Marker(
            markerId: MarkerId('destination'),
            position: LatLng(-10.9350, -37.0650),
            infoWindow: InfoWindow(title: 'Destino (Terminal D.I.A.)'),
          ),
        };

        final polylines = state.routes.asMap().entries.map((entry) {
          final index = entry.key;
          final route = entry.value;

          final isSelected = index == state.selectedRouteIndex;
          final isRec = route.accessibilityScore >= 0.8;
          final latLngWaypoints = route.waypoints
              .map((coord) => LatLng(coord.latitude, coord.longitude))
              .toList();

          return Polyline(
            polylineId: PolylineId(route.title),
            color: isSelected
                ? (isRec ? AppTheme.mintGreen : Colors.orange)
                : (isRec
                    ? AppTheme.mintGreen.withValues(alpha: 0.4)
                    : Colors.orange.withValues(alpha: 0.4)),
            width: isSelected ? 8 : 4,
            points: latLngWaypoints,
          );
        }).toSet();

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
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-10.9472, -37.0731),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                    },
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: markers,
                    polylines: polylines,
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: MapLegend(),
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