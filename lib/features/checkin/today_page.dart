import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/routine_visuals.dart';
import '../../core/theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/bloc/auth_bloc.dart';
import '../routines/pages/routine_editor_page.dart';
import 'bloc/checkin_bloc.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckinBloc>().state;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _HomeHeader(),
            const SizedBox(height: 20),
            _ProgressHero(state: state),
            const SizedBox(height: 24),
            if (state.routines.isNotEmpty) ...[
              Text('Rotinas de hoje',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
            ],
            if (state.routines.isEmpty)
              const _EmptyRoutinesHint()
            else
              for (final routine in state.routines)
                _RoutineCheckinCard(
                  routine: routine,
                  checkin: state.checkins[routine.id],
                ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final greeting = greetingFor(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                  children: [
                    const TextSpan(text: 'Cuide da sua '),
                    TextSpan(
                      text: 'rotina.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ProfileAvatar(user: user),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => _showProfileSheet(context, user),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: primary.withValues(alpha: 0.12),
        backgroundImage:
            user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
        child: user?.photoUrl == null
            ? Icon(Icons.person, color: primary)
            : null,
      ),
    );
  }
}

void _showProfileSheet(BuildContext context, AppUser? user) {
  final authBloc = context.read<AuthBloc>();
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(user?.displayName ?? 'Usuário'),
            subtitle: user?.email != null ? Text(user!.email!) : null,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              authBloc.add(AuthSignOutRequested());
            },
          ),
        ],
      ),
    ),
  );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.state});

  final CheckinState state;

  @override
  Widget build(BuildContext context) {
    final hasRoutines = state.totalRoutines > 0;
    final rawDate = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR')
        .format(parseDayKey(state.dateKey));
    final dateLabel = rawDate[0].toUpperCase() + rawDate.substring(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appPrimaryDarkColor, appPrimaryColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Icon(Icons.task_alt,
                size: 100, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasRoutines
                    ? '${state.completedRoutines} de ${state.totalRoutines} rotinas concluídas'
                    : 'Nenhuma rotina ainda',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasRoutines ? dateLabel : 'Crie sua primeira rotina para começar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              if (hasRoutines)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.overallProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: appPrimaryColor,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RoutineEditorPage(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova rotina'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutinesHint extends StatelessWidget {
  const _EmptyRoutinesHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Nenhuma rotina ativa.\nCrie rotinas na aba "Rotinas" para começar.',
        textAlign: TextAlign.center,
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
            trailing: _StatusPill(completed: completed),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = completed ? primary.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.15);
    final fg = completed ? primary : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'Concluída' : 'Pendente',
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
