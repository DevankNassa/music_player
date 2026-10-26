import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/queue_player.dart';
import '../widgets/now_playing_bar.dart';
import 'filter_switches_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'quick_tag_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    LibraryScreen(),
    _TabScaffold(title: 'Player', child: PlayerScreen()),
    _TabScaffold(title: 'Quick Tag', child: QuickTagScreen()),
    _TabScaffold(title: 'Filters', child: FilterSwitchesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final queuePlayer = context.watch<QueuePlayer>();
    // Player and Quick Tag have their own full player UI built in; showing
    // the mini-bar there too would just duplicate it.
    final showMiniPlayer = _index != 1 && _index != 2;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMiniPlayer) NowPlayingBar(queuePlayer: queuePlayer),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.library_music), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.play_circle), label: 'Player'),
              NavigationDestination(icon: Icon(Icons.label), label: 'Quick Tag'),
              NavigationDestination(icon: Icon(Icons.tune), label: 'Filters'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Library has its own AppBar/FAB; the other tabs just need a title bar.
class _TabScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _TabScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
