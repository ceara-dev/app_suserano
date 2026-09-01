import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/routine_visuals.dart';
import '../../data/models/models.dart';
import 'bloc/checkin_bloc.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckinBloc>().state;
    final rawTitle =
        DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(parseDayKey(state.dateKey));
    final title = rawTitle[0].toUpperCase() + rawTitle.substring(1);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: state.routines.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma rotina ativa.\nCrie rotinas na aba "Rotinas" para começar.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _ProgressHeader(state: state),
                for (final routine in state.routines)
                  _RoutineCheckinCard(
                    routine: routine,
                    checkin: state.checkins[routine.id],
                  ),
              ],
            ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final CheckinState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${state.completedRoutines} de ${state.totalRoutines} rotinas concluídas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.overallProgress,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCheckinCard extends StatelessWidget {
  const _RoutineCheckinCard({required this.routine, this.checkin});

  final Routine routine;
  final Checkin? checkin;

  @override
  Widget build(BuildContext context) {
    final color = Color(routine.colorValue);
    final completed = checkin?.isCompleted ?? false;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(iconAt(routine.iconIndex), color: color),
            ),
            title: Text(routine.name),
            subtitle: routine.stepCount > 0 && checkin != null
                ? Text(
                    '${checkin!.completedSteps} de ${routine.stepCount} passos',
                  )
                : null,
            trailing: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? color : Colors.grey,
            ),
          ),
          if (routine.stepCount > 0) ...[
            for (final step in routine.steps)
              CheckboxListTile(
                value: checkin?.completedStepIds.contains(step.id) ?? false,
                onChanged: (_) => context
                    .read<CheckinBloc>()
                    .add(CheckinToggleStep(routine.id, step.id)),
                title: Text(step.title),
                subtitle: step.note.isEmpty ? null : Text(step.note),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: completed
                        ? null
                        : () => context
                            .read<CheckinBloc>()
                            .add(CheckinCompleteRoutine(routine.id)),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Concluir tudo'),
                  ),
                ],
              ),
            ),
          ] else
            CheckboxListTile(
              value: checkin?.wholeRoutineDone ?? false,
              onChanged: (_) => context
                  .read<CheckinBloc>()
                  .add(CheckinToggleWholeRoutine(routine.id)),
              title: Text(
                completed ? 'Concluída' : 'Marcar como concluída',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }
}
