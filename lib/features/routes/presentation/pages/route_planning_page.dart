import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';
import '../widgets/active_navigation_panel.dart';
import '../widgets/route_search_card.dart';
import '../widgets/route_map_view.dart';

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
    _destinationController = TextEditingController(
      text: bloc.state.destinationText,
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: BlocListener<RoutePlanningBloc, RoutePlanningState>(
          listenWhen: (prev, curr) =>
              prev.originText != curr.originText ||
              prev.destinationText != curr.destinationText ||
              prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            if (_originController.text != state.originText) {
              _originController.text = state.originText;
            }
            if (_destinationController.text != state.destinationText) {
              _destinationController.text = state.destinationText;
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppTheme.emergencyRed,
                ),
              );
            }
          },
          child: Stack(
            children: [
              // --------------------------------------------------------------
              // Camada 1: Mapa Interativo Edge-to-Edge (100% da Tela)
              // --------------------------------------------------------------
              Positioned.fill(
                child: RouteMapSection(
                  onMapTap: () {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),

              // --------------------------------------------------------------
              // Camada 2: HUD Flutuante no Topo (Busca de Origem e Destino)
              // --------------------------------------------------------------
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: BlocBuilder<ActiveNavigationBloc, ActiveNavigationState>(
                  builder: (context, activeState) {
                    if (activeState.isActive) {
                      return const SizedBox.shrink();
                    }

                    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
                      builder: (context, planningState) {
                        final hasRoutes = planningState.routes.isNotEmpty;

                        // --------------------------------------------------------
                        // MODO RESULTADO (Rotas Calculadas)
                        // --------------------------------------------------------
                        if (hasRoutes) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Barra Resumo Pílula Moderna do Destino
                                Semantics(
                                  button: true,
                                  label: 'Editar endereço de origem e destino',
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softGreyBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppTheme.mintGreen.withValues(
                                          alpha: 0.40,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () {
                                          context
                                              .read<RoutePlanningBloc>()
                                              .add(ClearRouteSearchEvent());
                                        },
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.place_rounded,
                                                color: AppTheme.mintGreen,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Destino: ${_destinationController.text.isNotEmpty ? _destinationController.text : "Local Selecionado"}',
                                                  style: const TextStyle(
                                                    color: AppTheme.spaceBlue,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.spaceBlue
                                                      .withValues(
                                                        alpha: 0.08,
                                                      ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 14,
                                                  color: AppTheme.spaceBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Conteúdo Interno do Card (Opções de Rota + Botão Iniciar)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    4,
                                    10,
                                    10,
                                  ),
                                  child: RouteSearchCard(
                                    originController: _originController,
                                    destinationController:
                                        _destinationController,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // --------------------------------------------------------
                        // MODO EDIÇÃO (Formulário Completo de Busca)
                        // --------------------------------------------------------
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.spaceBlue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.map,
                                            color: AppTheme.mintGreen,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Busca de Rotas',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              BlocProvider.value(
                                value: context.read<RoutePlanningBloc>(),
                                child: RouteSearchCard(
                                  originController: _originController,
                                  destinationController: _destinationController,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // --------------------------------------------------------------
              // Camada 3: Painel de Navegação Ativa
              // --------------------------------------------------------------
              const ActiveNavigationPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

