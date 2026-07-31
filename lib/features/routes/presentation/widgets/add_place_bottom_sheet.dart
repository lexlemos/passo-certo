import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/base_button.dart';
import '../bloc/add_place_bloc.dart';

class AddPlaceBottomSheet extends StatefulWidget {
  final LatLng selectedLocation;

  const AddPlaceBottomSheet({super.key, required this.selectedLocation});

  static void show(BuildContext context, LatLng selectedLocation) {
    final bloc = context.read<AddPlaceBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddPlaceBottomSheet(selectedLocation: selectedLocation),
      ),
    );
  }

  @override
  State<AddPlaceBottomSheet> createState() => _AddPlaceBottomSheetState();
}

class _AddPlaceBottomSheetState extends State<AddPlaceBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchTermsController = TextEditingController();
  String _selectedCategory = 'Prédio';

  final List<String> _categories = [
    'Prédio',
    'Banheiro',
    'Auditório',
    'Biblioteca',
    'Restaurante',
    'Outro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _searchTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<AddPlaceBloc, AddPlaceState>(
      listenWhen: (prev, curr) =>
          (!prev.isSuccess && curr.isSuccess) ||
          (prev.errorMessage != curr.errorMessage && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local adicionado com sucesso!'),
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
                  'ADICIONAR NOVO LOCAL',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              Semantics(
                label: 'Nome do Local',
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'NOME DO LOCAL',
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
              const SizedBox(height: 16),

              Semantics(
                label: 'Categoria',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'CATEGORIA',
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
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              Semantics(
                label: 'Termos de Busca',
                child: TextField(
                  controller: _searchTermsController,
                  decoration: const InputDecoration(
                    labelText: 'TERMOS DE BUSCA (separados por vírgula)',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Ex: reitoria, dces, secretaria',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              BlocBuilder<AddPlaceBloc, AddPlaceState>(
                builder: (context, state) {
                  return BaseButton(
                    label: 'SALVAR LOCAL',
                    semanticLabel: 'Botão. Enviar formulário de novo local.',
                    borderRadius: 4,
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (_nameController.text.trim().isEmpty) return;
                            FocusScope.of(context).unfocus();
                            context.read<AddPlaceBloc>().add(
                              SubmitPlaceEvent(
                                name: _nameController.text.trim(),
                                category: _selectedCategory,
                                searchTerms: _searchTermsController.text.trim(),
                                location: widget.selectedLocation,
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
