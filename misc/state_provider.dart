import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";

class AppStateProvider extends StatelessWidget {
  final Widget child;

  const AppStateProvider({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ValueKey key = ValueKey(
      "${context.watch<ArcaneEnvironment>().state.name}-${IdService.I.sessionId.value}",
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          key: key,
          create: (context) => MyBloc(GetIt.I<MyApi>()),
        ),
      ],
      child: child,
    );
  }
}
