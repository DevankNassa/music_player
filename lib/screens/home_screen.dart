import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/queue_player.dart';
import '../theme/organic.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Runs each time the tab changes: the new tab fades and settles in.
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> _arriveCurve = CurvedAnimation(
    parent: _arrive,
    curve: Curves.easeOutCubic,
  );

  static const _playerTab = 1;
  static const _tabs = ['Library', 'Player', 'Tag', 'Mix'];

  static const _screens = [
    LibraryScreen(),
    PlayerScreen(),
    QuickTagScreen(),
    FilterSwitchesScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    _arrive.forward(from: 0);
  }

  @override
  void dispose() {
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queuePlayer = context.watch<QueuePlayer>();
    // Player and Tag have their own full player UI built in; showing the
    // dock there too would just duplicate it.
    final showMiniPlayer = _index != 1 && _index != 2;

    return Scaffold(
      body: Stack(
        children: [
          // Phones get the mocks' layout edge to edge; on a desktop window
          // the column stays phone-width rather than stretching.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FadeTransition(
                opacity: _arriveCurve,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.012),
                    end: Offset.zero,
                  ).animate(_arriveCurve),
                  child: IndexedStack(index: _index, children: _screens),
                ),
              ),
            ),
          ),
          if (showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: NowPlayingBar(
                      queuePlayer: queuePlayer,
                      onOpen: () => _select(_playerTab),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _TabBar(tabs: _tabs, selected: _index, onSelected: _select),
    );
  }
}

/// Text-only tab bar: heading-font labels, the active one in accent with an
/// underline that grows in under it.
class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  const _TabBar({required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    // Each tab takes a full quarter of the bar, so the whole
                    // strip is a tap target, not just the word.
                    Expanded(
                      child: Semantics(
                        selected: i == selected,
                        button: true,
                        child: InkWell(
                          onTap: () => onSelected(i),
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: Organic.headingStyle(
                                    16,
                                    height: 1.2,
                                    color: i == selected ? c.accent700 : c.neutral600,
                                  ),
                                  child: Text(tabs[i]),
                                ),
                                const SizedBox(height: 3),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  height: 3,
                                  width: i == selected ? 26 : 0,
                                  decoration: BoxDecoration(
                                    color: c.accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
