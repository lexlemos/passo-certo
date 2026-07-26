import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/base_button.dart';
import '../../domain/entities/obstacle.dart';
import '../bloc/obstacle_bloc.dart';

class ReportObstacleBottomSheet extends StatefulWidget {
  final LatLng location;

  const ReportObstacleBottomSheet({super.key, required this.location});

  /// Método estático utilitário para facilitar o disparo do modal a partir de qualquer contexto
  static void show(BuildContext context, LatLng location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportObstacleBottomSheet(location: location),
    );
  }

  @override
  State<ReportObstacleBottomSheet> createState() =>
      _ReportObstacleBottomSheetState();
}

class _ReportObstacleBottomSheetState extends State<ReportObstacleBottomSheet> {
  ObstacleType _selectedType = ObstacleType.pothole;
  final TextEditingController _descriptionController = TextEditingController();

  final Map<ObstacleType, _ObstacleTypeData> _typesMap = {
    ObstacleType.pothole: const _ObstacleTypeData(
      label: 'Buraco',
      description: 'Buraco ou desnível acentuado na calçada/via.',
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    ),
    ObstacleType.noTactilePaving: const _ObstacleTypeData(
      label: 'Sem Piso Tátil',
      description: 'Falta de piso podotátil em rampas ou faixas.',
      icon: Icons.do_not_disturb_on_total_silence,
      color: Colors.blue,
    ),
    ObstacleType.stairs: const _ObstacleTypeData(
      label: 'Escada',
      description: 'Escadaria ou degrau sem rampa alternativa.',
      icon: Icons.stairs_rounded,
      color: AppColors.emergencyRed,
    ),
    ObstacleType.blockedSidewalk: const _ObstacleTypeData(
      label: 'Calçada Obstruída',
      description: 'Calçada bloqueada por entulho, lixo ou veículo.',
      icon: Icons.block_flipped,
      color: Colors.redAccent,
    ),
    ObstacleType.other: const _ObstacleTypeData(
      label: 'Outro',
      description: 'Outro problema que impeça o tráfego acessível.',
      icon: Icons.help_outline_rounded,
      color: Colors.grey,
    ),
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
          prev.isReportedSuccess != curr.isReportedSuccess &&
          curr.isReportedSuccess,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Obstáculo reportado com sucesso! Obrigado pela colaboração.',
            ),
            backgroundColor: AppColors.mintGreen,
          ),
        );
        Navigator.pop(context); // Fecha o bottom sheet após sucesso
      },
      child: Container(
        margin: const EdgeInsets.only(top: 64),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra indicadora de arraste
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
              Semantics(
                header: true,
                child: Text(
                  'Reportar Obstáculo Urbano',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sua contribuição ajuda a construir rotas mais acessíveis para todos.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Lista Semântica de Tipos de Obstáculo
              Semantics(
                label: 'Selecione o tipo de obstáculo encontrado',
                child: Column(
                  children: _typesMap.entries.map((entry) {
                    final type = entry.key;
                    final data = entry.value;
                    final isSelected = type == _selectedType;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Semantics(
                        selected: isSelected,
                        button: true,
                        hint:
                            'Toque duas vezes para selecionar o tipo de obstáculo: ${data.label}',
                        child: InkWell(
                          onTap: () => setState(() => _selectedType = type),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? data.color.withValues(alpha: 0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? data.color
                                    : Colors.grey[200]!,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelected
                                      ? data.color
                                      : Colors.grey[300],
                                  radius: 18,
                                  child: Icon(
                                    data.icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.label,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.darkBlue
                                                  : Colors.grey[800],
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data.description,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: data.color,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de Descrição Adicional
              Semantics(
                label: 'Campo de texto para descrição adicional do obstáculo',
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Descrição adicional (opcional)',
                    hintText:
                        'Ex: Rampa de acesso quebrada ao lado do ponto...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.tealPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de Confirmar
              BlocBuilder<ObstacleBloc, ObstacleState>(
                builder: (context, state) {
                  return BaseButton(
                    label: 'Reportar Obstáculo',
                    semanticLabel:
                        'Botão. Confirmar e enviar o reporte do obstáculo.',
                    borderRadius: 12,
                    onPressed: state.isLoading
                        ? null
                        : () {
                            context.read<ObstacleBloc>().add(
                              ReportNewObstacleEvent(
                                type: _selectedType,
                                location: widget.location,
                                description: _descriptionController.text.trim(),
                              ),
                            );
                          },
                    gradient: const LinearGradient(
                      colors: [AppColors.tealPrimary, AppColors.mintGreen],
                    ),
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

class _ObstacleTypeData {
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _ObstacleTypeData({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}
