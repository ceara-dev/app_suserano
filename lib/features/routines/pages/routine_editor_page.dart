import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/routine_visuals.dart';
import '../../../data/models/models.dart';
import '../bloc/routine_bloc.dart';

class _StepEntry {
  _StepEntry(this.step)
      : titleController = TextEditingController(text: step.title),
        noteController = TextEditingController(text: step.note);

  RoutineStep step;
  final TextEditingController titleController;
  final TextEditingController noteController;
}

class RoutineEditorPage extends StatefulWidget {
  const RoutineEditorPage({super.key, this.routineId});

  final String? routineId;

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  static const _uuid = Uuid();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_StepEntry> _steps = [];
  int _colorValue = routineColors.first;
  int _iconIndex = 0;
  Routine? _original;

  bool get _isEditing => widget.routineId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final state = context.read<RoutineBloc>().state;
      if (state is RoutineLoaded) {
        for (final routine in state.routines) {
          if (routine.id == widget.routineId) {
            _original = routine;
            break;
          }
        }
      }
      if (_original != null) {
        _nameController.text = _original!.name;
        _descriptionController.text = _original!.description;
        _colorValue = _original!.colorValue;
        _iconIndex = _original!.iconIndex;
        _steps.addAll(_original!.steps.map(_StepEntry.new));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final entry in _steps) {
      entry.titleController.dispose();
      entry.noteController.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _steps.add(_StepEntry(RoutineStep(id: _uuid.v4(), title: '')));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index).titleController.dispose();
    });
  }

  void _moveStep(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _steps.length) return;
    setState(() {
      final entry = _steps.removeAt(index);
      _steps.insert(target, entry);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Dê um nome à rotina');
      return;
    }
    if (_steps.any((e) => e.titleController.text.trim().isEmpty)) {
      _showMessage('Preencha o título de todos os passos');
      return;
    }
    final steps = _steps
        .map((e) => e.step.copyWith(
              title: e.titleController.text.trim(),
              note: e.noteController.text.trim(),
            ))
        .toList();
    final routine = _original == null
        ? Routine(
            id: _uuid.v4(),
            name: name,
            description: _descriptionController.text.trim(),
            colorValue: _colorValue,
            iconIndex: _iconIndex,
            steps: steps,
            createdAt: DateTime.now(),
          )
        : _original!.copyWith(
            name: name,
            description: _descriptionController.text.trim(),
            colorValue: _colorValue,
            iconIndex: _iconIndex,
            steps: steps,
          );
    final bloc = context.read<RoutineBloc>();
    bloc.add(RoutineSaveRequested(routine, isNew: _original == null));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir rotina?'),
        content: const Text('O histórico de check-ins será mantido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<RoutineBloc>().add(RoutineDeleteRequested(widget.routineId!));
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar rotina' : 'Nova rotina'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir rotina',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome *',
              hintText: 'Ex.: Treino de manhã',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Objetivo ou detalhes da rotina',
            ),
          ),
          const SizedBox(height: 24),
          Text('Cor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final colorValue in routineColors)
                InkWell(
                  onTap: () => setState(() => _colorValue = colorValue),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: colorValue == _colorValue
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: colorValue == _colorValue
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Ícone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < routineIcons.length; i++)
                ChoiceChip(
                  selected: _iconIndex == i,
                  onSelected: (_) => setState(() => _iconIndex = i),
                  avatar: Icon(
                    routineIcons[i],
                    size: 18,
                    color: _iconIndex == i
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  label: const SizedBox.shrink(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Passos', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar passo'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sem passos: a rotina vira um item único de marcação.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          for (var i = 0; i < _steps.length; i++) _buildStepCard(i),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_isEditing ? 'Salvar alterações' : 'Criar rotina'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index) {
    final entry = _steps[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: entry.titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Passo ${index + 1} *',
                      hintText: 'Ex.: 3 séries de flexão',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: entry.noteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Mover para cima',
                  onPressed: index == 0 ? null : () => _moveStep(index, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Mover para baixo',
                  onPressed: index == _steps.length - 1
                      ? null
                      : () => _moveStep(index, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remover passo',
                  onPressed: () => _removeStep(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
