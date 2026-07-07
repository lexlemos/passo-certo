import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/route_planning_bloc.dart';
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: BlocListener<RoutePlanningBloc, RoutePlanningState>(
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
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RoutePlanningHeader(),
                    const SizedBox(height: 24),
                    BlocProvider.value(
                      value: context.read<RoutePlanningBloc>(),
                      child: RouteSearchCard(
                        originController: _originController,
                        destinationController: _destinationController,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const RoutesHeader(),
                    const SizedBox(height: 16),
                    
                    const RouteListView(),
                    
                    const SizedBox(height: 24),
                    const RouteMapSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const ActiveNavigationPanel(),
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
