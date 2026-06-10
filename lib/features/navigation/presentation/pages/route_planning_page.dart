import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/route_planning_bloc.dart';

class RoutePlanningPage extends StatelessWidget {
  const RoutePlanningPage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<RoutePlanningBloc>(
      create: (context) => RoutePlanningBloc(),
      child: const RoutePlanningPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Passo Certo', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, semanticLabel: 'Voltar para a página inicial'),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoutePlanningHeader(),
            const SizedBox(height: 24),
            const RouteSearchCard(),
            const SizedBox(height: 32),
            const RoutesHeader(),
            const SizedBox(height: 16),
            
            // Lista de Rotas Otimizada
            RouteOptionCard(
              title: 'Via CCET Park',
              time: '15 min',
              distance: '1.2 km',
              isRecommended: true,
              accessibilityLevel: 'Alto (95%)',
              tags: const ['PLANO', 'CALÇADAS BOAS'],
              onTap: () => context.read<RoutePlanningBloc>().add(SelectRouteEvent(routeIndex: 0)),
            ),
            
            RouteOptionCard(
              title: 'Via Terminal UFS',
              time: '12 min',
              distance: '0.9 km',
              isRecommended: false,
              accessibilityLevel: 'Médio (60%)',
              tags: const ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
              onTap: () => context.read<RoutePlanningBloc>().add(SelectRouteEvent(routeIndex: 1)),
            ),
            
            const SizedBox(height: 24),
            const RouteMapSection(),
            const SizedBox(height: 24),
          ],
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
  const RouteSearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.selectedFilter != current.selectedFilter ||
          previous.originController != current.originController ||
          previous.destinationController != current.destinationController,
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
                        controller: state.originController,
                      ),
                      const SizedBox(height: 12),
                      RouteTextField(
                        hint: 'Para onde quer ir?',
                        label: 'Destino',
                        icon: Icons.location_on,
                        iconColor: AppTheme.mintGreen,
                        controller: state.destinationController,
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    child: Semantics(
                      button: true,
                      label: "Inverter origem e destino",
                      child: FloatingActionButton.small(
                        onPressed: () => context.read<RoutePlanningBloc>().add(SwapLocationsEvent()),
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
                onPressed: () => context.read<RoutePlanningBloc>().add(SearchRoutesEvent()),
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
      selectedColor: AppTheme.mintGreen.withOpacity(0.1),
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

  const RouteOptionCard({
    super.key,
    required this.title,
    required this.time,
    required this.distance,
    required this.isRecommended,
    required this.accessibilityLevel,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighAccessibility = accessibilityLevel.contains('Alto');

    return BaseCard(
      margin: const EdgeInsets.only(bottom: 16),
      semanticLabel:
          "Rota $title. Tempo estimado $time. Distância $distance. Nível de acessibilidade $accessibilityLevel. Toque duas vezes para selecionar.",
      onTap: onTap,
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
    );
  }
}

class RouteMapSection extends StatelessWidget {
  const RouteMapSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.markers != current.markers || previous.polylines != current.polylines,
      builder: (context, state) {
        return Semantics(
          label: "Mapa interativo exibindo o trajeto selecionado. Nível de acessibilidade codificado por cores no mapa.",
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.mintGreen.withOpacity(0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-10.9472, -37.0731), // Coordenadas de Aracaju/UFS mantidas!
                      zoom: 15,
                    ),
                    onMapCreated: (controller) =>
                        context.read<RoutePlanningBloc>().add(MapCreatedEvent(controller: controller)),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: state.markers,
                    polylines: state.polylines,
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