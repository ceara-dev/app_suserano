import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
import 'data/models/models.dart';
import 'data/repositories/checkin_repository.dart';
import 'data/repositories/routine_repository.dart';
import 'features/checkin/bloc/checkin_bloc.dart';
import 'features/metrics/bloc/metrics_bloc.dart';
import 'features/routines/bloc/routine_bloc.dart';
import 'features/shell/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(RoutineStepAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(CheckinAdapter());
  final routineBox = await Hive.openBox<Routine>('routines');
  final checkinBox = await Hive.openBox<Checkin>('checkins');
  runApp(App(routineBox: routineBox, checkinBox: checkinBox));
}

class App extends StatelessWidget {
  const App({super.key, required this.routineBox, required this.checkinBox});

  final Box<Routine> routineBox;
  final Box<Checkin> checkinBox;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => RoutineRepository(routineBox),
        ),
        RepositoryProvider(
          create: (_) => CheckinRepository(checkinBox),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                RoutineBloc(context.read<RoutineRepository>()),
          ),
          BlocProvider(
            create: (context) => CheckinBloc(
              routineRepository: context.read<RoutineRepository>(),
              checkinRepository: context.read<CheckinRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => MetricsBloc(
              routineRepository: context.read<RoutineRepository>(),
              checkinRepository: context.read<CheckinRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Suserano',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      ),
    );
  }
}
