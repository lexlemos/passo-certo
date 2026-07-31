import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/base_button.dart';
import '../../domain/entities/obstacle.dart';
import '../bloc/obstacle_bloc.dart';

class ReportObstacleBottomSheet extends StatefulWidget {
  final LatLng selectedLocation;

  const ReportObstacleBottomSheet({super.key, required this.selectedLocation});

  static void show(BuildContext context, LatLng selectedLocation) {
    final bloc = context.read<ObstacleBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ReportObstacleBottomSheet(selectedLocation: selectedLocation),
      ),
    );
  }

  @override
  State<ReportObstacleBottomSheet> createState() =>
      _ReportObstacleBottomSheetState();
}

class _ReportObstacleBottomSheetState extends State<ReportObstacleBottomSheet> {
  ObstacleType _selectedType = ObstacleType.pothole;
  ObstacleSeverity _selectedSeverity = ObstacleSeverity.warning;
  final TextEditingController _descriptionController = TextEditingController();

  final Map<ObstacleType, String> _typesMap = {
    ObstacleType.pothole: 'Buraco ou desnível',
    ObstacleType.noTactilePaving: 'Falta de piso tátil',
    ObstacleType.stairs: 'Escada sem rampa',
    ObstacleType.blockedSidewalk: 'Calçada obstruída',
    ObstacleType.other: 'Outro',
  };

  final Map<ObstacleSeverity, String> _severityMap = {
    ObstacleSeverity.warning: 'Atenção (Requer cuidado)',
    ObstacleSeverity.blocking: 'Bloqueio (Impede passagem)',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<ObstacleBloc, ObstacleState>(
      listenWhen: (prev, curr) =>
          (prev.isReportedSuccess != curr.isReportedSuccess &&
              curr.isReportedSuccess) ||
          (prev.errorMessage != curr.errorMessage && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.isReportedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obstáculo reportado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 64),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'REPORTAR OBSTÁCULO',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              Semantics(
                label: 'Tipo de Obstáculo',
                child: DropdownButtonFormField<ObstacleType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'TIPO DE OBSTÁCULO',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _typesMap.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              Semantics(
                label: 'Severidade',
                child: DropdownButtonFormField<ObstacleSeverity>(
                  initialValue: _selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'SEVERIDADE',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _severityMap.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSeverity = val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              Semantics(
                label: 'Descrição',
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'DESCRIÇÃO (OPCIONAL)',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              BlocBuilder<ObstacleBloc, ObstacleState>(
                builder: (context, state) {
                  return BaseButton(
                    label: 'ENVIAR REPORTE',
                    semanticLabel: 'Botão. Enviar reporte de obstáculo.',
                    borderRadius: 4,
                    isEmergency: true, // Fica vermelho
                    onPressed: state.isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            context.read<ObstacleBloc>().add(
                              ReportNewObstacleEvent(
                                type: _selectedType,
                                severity: _selectedSeverity,
                                location: widget.selectedLocation,
                                description: _descriptionController.text.trim(),
                              ),
                            );
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
