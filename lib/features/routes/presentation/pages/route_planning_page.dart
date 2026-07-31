import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/route_planning_bloc.dart';
import '../bloc/active_navigation_bloc.dart';
import '../widgets/active_navigation_panel.dart';
import '../widgets/route_search_card.dart';
import '../widgets/route_list_view.dart';
import '../widgets/route_map_view.dart';

class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({super.key});

  @override
  State<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  bool _isSearchExpanded = false;

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
              const Positioned.fill(
                child: RouteMapSection(),
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

                    if (!_isSearchExpanded) {
                      return Semantics(
                        button: true,
                        label: 'Abrir busca de rotas e endereços',
                        child: Material(
                          color: Colors.transparent,
                          elevation: 6,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppTheme.mintGreen.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.mintGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _destinationController.text.isNotEmpty
                                          ? _destinationController.text
                                          : 'Para onde vamos? (Buscar rota)',
                                      style: TextStyle(
                                        color: _destinationController.text.isNotEmpty
                                            ? AppTheme.spaceBlue
                                            : AppTheme.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.spaceBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.tune,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        'Passo Certo — Busca',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Recolher painel de busca',
                                  child: IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.softGreyBg,
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_up,
                                      color: AppTheme.spaceBlue,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSearchExpanded = false;
                                      });
                                    },
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
                ),
              ),

              // --------------------------------------------------------------
              // Camada 3: Painel Flutuante de Rotas Disponíveis (Grid 2 Colunas)
              // --------------------------------------------------------------
              Positioned(
                bottom: 16,
                left: 16,
                right: 80,
                child: BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
                  builder: (context, planningState) {
                    final activeState =
                        context.watch<ActiveNavigationBloc>().state;
                    if (planningState.routes.isEmpty || activeState.isActive) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RoutesHeader(),
                            SizedBox(height: 8),
                            RouteListView(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --------------------------------------------------------------
              // Camada 4: Painel de Navegação Ativa
              // --------------------------------------------------------------
              const ActiveNavigationPanel(),
            ],
          ),
        ),
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
          const Icon(Icons.route, color: AppTheme.spaceBlue, size: 18),
          const SizedBox(width: 6),
          Text(
            'Rotas Disponíveis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
