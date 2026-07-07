import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/place.dart';
import '../../domain/usecases/search_address.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';

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
    final searchAddressUseCase = di.sl<SearchAddressUseCase>();

    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.selectedFilter != current.selectedFilter,
      builder: (context, state) {
        return BaseCard(
          semanticLabel: "Formulário de busca de rotas com preenchimento automático",
          child: Column(
            children: [
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 48.0),
                    child: Column(
                      children: [
                        // Origem Autocomplete
                        Semantics(
                          label: 'Campo de texto da Origem. Digite o endereço de partida.',
                          child: TypeAheadField<Place>(
                            controller: originController,
                            suggestionsCallback: (pattern) async {
                              if (pattern.trim().length < 3) return const [];
                              final planningState = context.read<RoutePlanningBloc>().state;
                              return await searchAddressUseCase(
                                pattern,
                                userLat: planningState.originLat,
                                userLon: planningState.originLng,
                              );
                            },
                            itemBuilder: (context, place) {
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: AppTheme.spaceBlue),
                                title: Text(place.name, style: const TextStyle(fontSize: 14)),
                              );
                            },
                            onSelected: (place) {
                              originController.text = place.name;
                              context.read<RoutePlanningBloc>().add(UpdateOriginEvent(
                                originText: place.name,
                                originLat: place.latitude,
                                originLng: place.longitude,
                              ));
                            },
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Origem',
                                  hintText: 'Sua localização atual',
                                  prefixIcon: const Icon(Icons.my_location, color: AppTheme.spaceBlue),
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
                                                icon: const Icon(Icons.clear, size: 20),
                                                onPressed: () {
                                                  controller.clear();
                                                  context.read<RoutePlanningBloc>().add(ClearOriginEvent());
                                                },
                                              ),
                                            ),
                                          Semantics(
                                            button: true,
                                            label: 'Botão Minha Localização. Obter localização atual via GPS.',
                                            child: IconButton(
                                              icon: const Icon(Icons.my_location, color: AppTheme.spaceBlue),
                                              onPressed: () {
                                                context.read<RoutePlanningBloc>().add(
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
                        const SizedBox(height: 12),
                        // Destino Autocomplete
                        Semantics(
                          label: 'Campo de texto do Destino. Digite o endereço de destino.',
                          child: TypeAheadField<Place>(
                            controller: destinationController,
                            suggestionsCallback: (pattern) async {
                              if (pattern.trim().length < 3) return const [];
                              final planningState = context.read<RoutePlanningBloc>().state;
                              return await searchAddressUseCase(
                                pattern,
                                userLat: planningState.originLat,
                                userLon: planningState.originLng,
                              );
                            },
                            itemBuilder: (context, place) {
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: AppTheme.mintGreen),
                                title: Text(place.name, style: const TextStyle(fontSize: 14)),
                              );
                            },
                            onSelected: (place) {
                              destinationController.text = place.name;
                              context.read<RoutePlanningBloc>().add(UpdateDestinationEvent(
                                destinationText: place.name,
                                destLat: place.latitude,
                                destLng: place.longitude,
                              ));
                            },
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Destino',
                                  hintText: 'Para onde quer ir?',
                                  prefixIcon: const Icon(Icons.location_on, color: AppTheme.mintGreen),
                                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: controller,
                                    builder: (context, value, _) {
                                      if (value.text.isEmpty) return const SizedBox.shrink();
                                      return Semantics(
                                        button: true,
                                        label: 'Limpar texto do destino',
                                        child: IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            controller.clear();
                                            context.read<RoutePlanningBloc>().add(ClearDestinationEvent());
                                          },
                                        ),
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
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
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
              BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
                builder: (context, planningState) {
                  final activeNavState = context.watch<ActiveNavigationBloc>().state;

                  if (activeNavState.isActive) {
                    return BaseButton(
                      label: 'Parar Navegação',
                      semanticLabel: 'Botão. Parar navegação guiada ativa.',
                      icon: const Icon(Icons.stop, color: Colors.white),
                      gradient: const LinearGradient(colors: [AppTheme.emergencyRed, Colors.redAccent]),
                      onPressed: () {
                        context.read<ActiveNavigationBloc>().add(StopNavigationEvent());
                      },
                    );
                  }

                  if (planningState.routes.isNotEmpty) {
                    final selectedRoute = planningState.routes[planningState.selectedRouteIndex];
                    return BaseButton(
                      label: 'Iniciar Navegação',
                      semanticLabel: 'Botão. Iniciar navegação guiada por voz para a rota selecionada.',
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      onPressed: () {
                        context.read<ActiveNavigationBloc>().add(StartNavigationEvent(selectedRoute));
                      },
                    );
                  }

                  final canSearch = planningState.originLat != null && 
                                    planningState.destLat != null &&
                                    !planningState.isLoading;

                  return BaseButton(
                    label: planningState.isLoading ? 'Buscando...' : 'Buscar Rotas',
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
                    onPressed: canSearch 
                      ? () {
                          context.read<RoutePlanningBloc>().add(CalculateRouteEvent());
                          FocusScope.of(context).unfocus();
                        }
                      : null,
                  );
                },
              ),
            ],
          ),
        );
      },
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
