import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/place.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/usecases/search_address.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';

class RouteSearchCard extends StatefulWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;

  const RouteSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
  });

  @override
  State<RouteSearchCard> createState() => _RouteSearchCardState();
}

class _RouteSearchCardState extends State<RouteSearchCard> {
  final FocusNode _destinationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _destinationFocusNode.addListener(_onFocusChange);
    widget.destinationController.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _destinationFocusNode.removeListener(_onFocusChange);
    widget.destinationController.removeListener(_onTextChange);
    _destinationFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onTextChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchAddressUseCase = di.sl<SearchAddressUseCase>();

    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      builder: (context, planningState) {
        final activeNavState = context.watch<ActiveNavigationBloc>().state;
        final hasRoutes = planningState.routes.isNotEmpty;

        return BaseCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          semanticLabel:
              "Formulário de busca de rotas com preenchimento automático",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasRoutes) ...[
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 48.0),
                      child: Column(
                        children: [
                          // Origem Autocomplete
                          Semantics(
                            label:
                                'Campo de texto da Origem. Digite o endereço de partida.',
                            child: TypeAheadField<Place>(
                              controller: widget.originController,
                              suggestionsCallback: (pattern) async {
                                if (pattern.trim().length < 3) return const [];
                                final state = context
                                    .read<RoutePlanningBloc>()
                                    .state;
                                return await searchAddressUseCase(
                                  pattern,
                                  userLat: state.originLat,
                                  userLon: state.originLng,
                                );
                              },
                              itemBuilder: (context, place) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: AppTheme.spaceBlue,
                                  ),
                                  title: Text(
                                    place.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                              onSelected: (place) {
                                widget.originController.text = place.name;
                                context.read<RoutePlanningBloc>().add(
                                  UpdateOriginEvent(
                                    originText: place.name,
                                    originLat: place.latitude,
                                    originLng: place.longitude,
                                  ),
                                );
                              },
                              builder: (context, controller, focusNode) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Origem',
                                    hintText: 'Sua localização atual',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.my_location,
                                      color: AppTheme.spaceBlue,
                                      size: 20,
                                    ),
                                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: controller,
                                      builder: (context, value, _) {
                                        final isNotEmpty = value.text.isNotEmpty;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isNotEmpty)
                                              Semantics(
                                                button: true,
                                                label: 'Limpar texto da origem',
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    controller.clear();
                                                    context
                                                        .read<RoutePlanningBloc>()
                                                        .add(ClearOriginEvent());
                                                  },
                                                ),
                                              ),
                                            Semantics(
                                              button: true,
                                              label:
                                                  'Botão Minha Localização. Obter localização atual via GPS.',
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.my_location,
                                                  color: AppTheme.spaceBlue,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  context
                                                      .read<RoutePlanningBloc>()
                                                      .add(
                                                        FetchCurrentLocationForOriginEvent(),
                                                      );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.softGreyBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Destino Autocomplete
                          Semantics(
                            label:
                                'Campo de texto do Destino. Digite o endereço de destino.',
                            child: TypeAheadField<Place>(
                              controller: widget.destinationController,
                              focusNode: _destinationFocusNode,
                              suggestionsCallback: (pattern) async {
                                final state = context
                                    .read<RoutePlanningBloc>()
                                    .state;
                                if (pattern.isEmpty) {
                                  return state.recentSearches;
                                }
                                if (pattern.trim().length < 3) return const [];
                                return await searchAddressUseCase(
                                  pattern,
                                  userLat: state.originLat,
                                  userLon: state.originLng,
                                );
                              },
                              emptyBuilder: (context) => const SizedBox.shrink(),
                              itemBuilder: (context, place) {
                                final state = context.read<RoutePlanningBloc>().state;
                                final isRecent = state.recentSearches.any((p) => p.name == place.name);
                                return ListTile(
                                  leading: Icon(
                                    isRecent ? Icons.history : Icons.location_on,
                                    color: AppTheme.spaceBlue,
                                  ),
                                  title: Text(
                                    place.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                              onSelected: (place) {
                                widget.destinationController.text = place.name;
                                _destinationFocusNode.unfocus();
                                context.read<RoutePlanningBloc>().add(
                                  UpdateDestinationEvent(
                                    destinationText: place.name,
                                    destLat: place.latitude,
                                    destLng: place.longitude,
                                  ),
                                );
                                final state = context.read<RoutePlanningBloc>().state;
                                if (state.originLat != null) {
                                  context.read<RoutePlanningBloc>().add(CalculateRouteEvent());
                                }
                              },
                              builder: (context, controller, focusNode) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Destino',
                                    hintText: 'Para onde você quer ir?',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_on,
                                      color: AppTheme.spaceBlue,
                                      size: 20,
                                    ),
                                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: controller,
                                      builder: (context, value, _) {
                                        final isNotEmpty = value.text.isNotEmpty;
                                        return isNotEmpty
                                            ? Semantics(
                                                button: true,
                                                label:
                                                    'Limpar texto do destino',
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    controller.clear();
                                                    context
                                                        .read<RoutePlanningBloc>()
                                                        .add(
                                                          ClearDestinationEvent(),
                                                        );
                                                  },
                                                ),
                                              )
                                            : const SizedBox.shrink();
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.softGreyBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Semantics(
                        button: true,
                        label:
                            'Botão Inverter Origem e Destino. Trocar pontos de partida e chegada.',
                        child: Material(
                          color: AppTheme.softGreyBg,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(
                              Icons.swap_vert,
                              color: AppTheme.spaceBlue,
                              size: 22,
                            ),
                            onPressed: () {
                              context.read<RoutePlanningBloc>().add(
                                SwapLocationsEvent(
                                  originText: widget.originController.text,
                                  destinationText: widget.destinationController.text,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // --------------------------------------------------------------
              // ESTADO COM ROTAS (HUD DUAL-OPTION COM WCAG AAA)
              // --------------------------------------------------------------
              if (hasRoutes) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Opções de Rota',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.spaceBlue,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Limpar busca de rotas',
                      child: InkWell(
                        onTap: () {
                          widget.destinationController.clear();
                          context
                              .read<RoutePlanningBloc>()
                              .add(ClearDestinationEvent());
                          context
                              .read<RoutePlanningBloc>()
                              .add(ClearRouteSearchEvent());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close,
                                size: 16,
                                color: AppTheme.spaceBlue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Nova busca',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.spaceBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: planningState.routes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final route = entry.value;
                    final isSelected =
                        index == planningState.selectedRouteIndex;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right: index == planningState.routes.length - 1
                              ? 0
                              : 4,
                        ),
                        child: _RouteOptionButton(
                          route: route,
                          isSelected: isSelected,
                          onTap: () {
                            context.read<RoutePlanningBloc>().add(
                              SelectRouteEvent(routeIndex: index),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // --------------------------------------------------------------
              // BOTÃO DE AÇÃO PRINCIPAL (INICIAR / PARAR / BUSCAR)
              // --------------------------------------------------------------
              if (activeNavState.isActive) ...[
                BaseButton(
                  label: 'Parar Navegação',
                  semanticLabel: 'Botão. Parar navegação guiada ativa.',
                  icon: const Icon(Icons.stop, color: Colors.white),
                  gradient: const LinearGradient(
                    colors: [AppTheme.emergencyRed, Colors.redAccent],
                  ),
                  onPressed: () {
                    context.read<ActiveNavigationBloc>().add(
                      StopNavigationEvent(),
                    );
                  },
                ),
              ] else if (hasRoutes) ...[
                BaseButton(
                  label: 'Iniciar Navegação',
                  semanticLabel:
                      'Botão. Iniciar navegação guiada por voz para a rota selecionada.',
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  onPressed: () {
                    final selectedRoute =
                        planningState.routes[planningState.selectedRouteIndex];
                    context.read<ActiveNavigationBloc>().add(
                      StartNavigationEvent(selectedRoute),
                    );
                  },
                ),
              ] else ...[
                BaseButton(
                  label: planningState.isLoading
                      ? 'Buscando...'
                      : 'Buscar Rotas',
                  semanticLabel: 'Botão. Buscar melhores rotas acessíveis.',
                  icon: planningState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                  onPressed:
                      (planningState.originLat != null &&
                              planningState.destLat != null &&
                              !planningState.isLoading)
                          ? () {
                              context.read<RoutePlanningBloc>().add(
                                CalculateRouteEvent(),
                              );
                              FocusScope.of(context).unfocus();
                            }
                          : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Botão minimalista de alto contraste (WCAG AAA) para seleção de rotas no HUD.
class _RouteOptionButton extends StatelessWidget {
  final NavigationRoute route;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteOptionButton({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAccessible =
        route.title.toLowerCase().contains('acessível') ||
        route.accessibilityScore >= 0.8;
    final icon = isAccessible ? Icons.accessible : Icons.directions_walk;

    final scorePct = (route.accessibilityScore * 100).round();
    final String scoreTag;
    if (route.accessibilityScore >= 0.85) {
      scoreTag = 'Piso ideal • $scorePct%';
    } else if (route.accessibilityScore >= 0.70) {
      scoreTag = 'Acessível • $scorePct%';
    } else {
      scoreTag = 'Caminho padrão • $scorePct%';
    }

    final accentColor =
        isAccessible ? AppTheme.mintGreen : const Color(0xFF2196F3);

    // Paleta Limpa de Alto Contraste (Fundo Neutro + Borda de Destaque Vibrante)
    final backgroundColor = isSelected
        ? (isAccessible
            ? AppTheme.mintGreen.withValues(alpha: 0.14)
            : const Color(0xFF2196F3).withValues(alpha: 0.14))
        : AppTheme.softGreyBg;
    final borderColor = isSelected ? accentColor : Colors.grey.shade300;
    final textColor = AppTheme.spaceBlue;
    final subtitleColor = isSelected ? accentColor : AppTheme.spaceBlue;
    final iconColor = accentColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          'Rota ${route.title}, Duração ${route.estimatedTime}, Distância ${route.distance}, $scoreTag. ${isSelected ? "Selecionada" : "Toque para selecionar esta rota"}.',
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.estimatedTime} (${route.distance})',
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scoreTag,
                  style: TextStyle(
                    color: isSelected ? AppTheme.spaceBlue : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

