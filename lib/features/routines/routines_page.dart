import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/routine_visuals.dart';
import '../../data/models/models.dart';
import 'bloc/routine_bloc.dart';
import 'pages/routine_editor_page.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotinas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const RoutineEditorPage(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova rotina'),
      ),
      body: BlocBuilder<RoutineBloc, RoutineState>(
        builder: (context, state) {
          switch (state) {
            case RoutineLoading():
              return const Center(child: CircularProgressIndicator());
            case RoutineFailure():
              return Center(child: Text(state.message));
            case RoutineLoaded():
              return _RoutineList(routines: state.routines);
          }
        },
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhuma rotina ainda.\nToque em "Nova rotina" para começar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        final color = Color(routine.colorValue);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                iconFromCodePoint(routine.iconCodePoint),
                color: color,
              ),
            ),
            title: Text(
              routine.name,
              style: TextStyle(
                decoration:
                    routine.active ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              routine.stepCount > 0
                  ? '${routine.stepCount} ${routine.stepCount == 1 ? 'passo' : 'passos'}'
                  : 'Sem passos',
            ),
            trailing: IconButton(
              icon: Icon(
                routine.active
                    ? Icons.toggle_on
                    : Icons.toggle_off,
                color: routine.active
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: routine.active ? 'Desativar rotina' : 'Ativar rotina',
              onPressed: () => context
                  .read<RoutineBloc>()
                  .add(RoutineToggleActiveRequested(routine.id)),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RoutineEditorPage(routineId: routine.id),
              ),
            ),
          ),
        );
      },
    );
  }
}
