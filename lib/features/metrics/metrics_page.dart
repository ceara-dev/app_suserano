import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/routine_visuals.dart';
import 'bloc/metrics_bloc.dart';

class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: BlocBuilder<MetricsBloc, MetricsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _StatGrid(state: state),
            const SizedBox(height: 8),
            _Last7DaysCard(counts: state.last7DaysCounts),
            if (state.perRoutine.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Crie rotinas para acompanhar métricas por rotina.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Por rotina',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final metrics in state.perRoutine)
              _RoutineMetricsCard(metrics: metrics),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});

  final MetricsState state;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.local_fire_department, '${state.currentStreak}',
          'Sequência atual (dias)'),
      (Icons.emoji_events, '${state.bestStreak}', 'Melhor sequência'),
      (Icons.check_circle_outline, '${state.totalCompleted}',
          'Rotinas concluídas'),
      (Icons.percent, '${(state.overallRate * 100).round()}%',
          'Taxa de conclusão'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final (icon, value, label) in items)
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Last7DaysCard extends StatelessWidget {
  const _Last7DaysCard({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimos 7 dias', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text('${counts[i]}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: counts[i] > 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineMetricsCard extends StatelessWidget {
  const _RoutineMetricsCard({required this.metrics});

  final RoutineMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final routine = metrics.routine;
    final color = Color(routine.colorValue);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(iconAt(routine.iconIndex), color: color),
        ),
        title: Text(routine.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              for (final done in metrics.last7Days) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: done
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${metrics.completions}',
                style: Theme.of(context).textTheme.titleMedium),
            Text('${(metrics.completionRate * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
