import "package:flutter/material.dart";
import "package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:go_router/go_router.dart";

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? secondaryBody;

  const AppScaffold({
    required this.body,
    this.secondaryBody,
    super.key = const ValueKey("AppScaffold"),
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      internalAnimations: false,
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.small: SlotLayout.from(
            key: const Key("Body Small"),
            builder: (context) => secondaryBody ?? body,
          ),
          Breakpoints.mediumAndUp: SlotLayout.from(
            key: const Key("Body Medium and Up"),
            builder: (context) => body,
          ),
        },
      ),
      secondaryBody: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.small: SlotLayout.from(
            key: const Key("Body Small"),
            builder: null,
          ),
          Breakpoints.mediumAndUp: SlotLayout.from(
            key: const Key("Body Medium"),
            builder: secondaryBody,
          ),
        },
      ),
    );
  }
}

class AppScaffoldShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffoldShell({
    required this.navigationShell,
    super.key = const ValueKey("AppScaffoldShell"),
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      useDrawer: false,
      internalAnimations: false,
      selectedIndex: navigationShell.currentIndex,
      onSelectedIndexChange: onNavigationEvent,
      destinations: [
        NavigationDestination(
          label: AppLocalizations.of(context).tabHome,
          icon: const Icon(Icons.home),
        ),
        NavigationDestination(
          label: AppLocalizations.of(context).tabHistory,
          icon: const Icon(Icons.change_history_rounded),
        ),
        NavigationDestination(
          label: AppLocalizations.of(context).tabProfile,
          icon: const Icon(Icons.account_circle),
        ),
      ],
      body: (_) => navigationShell,
    );
  }

  void onNavigationEvent(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
