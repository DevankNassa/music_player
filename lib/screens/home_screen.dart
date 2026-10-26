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

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = ['Library', 'Player', 'Tag', 'Mix'];

  static const _screens = [
    LibraryScreen(),
    PlayerScreen(),
    QuickTagScreen(),
    FilterSwitchesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final queuePlayer = context.watch<QueuePlayer>();
    // Player and Tag have their own full player UI built in; showing the
    // dock there too would just duplicate it.
    final showMiniPlayer = _index != 1 && _index != 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Stack(
          children: [
            // Phones get the mocks' layout edge to edge; on a desktop window
            // the column stays phone-width rather than stretching.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: IndexedStack(index: _index, children: _screens),
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
                      child: NowPlayingBar(queuePlayer: queuePlayer),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _TabBar(
          tabs: _tabs,
          selected: _index,
          onSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// Text-only tab bar: heading-font labels, the active one in accent with an
/// underline.
class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  const _TabBar({required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Organic.bg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < tabs.length; i++)
                Semantics(
                  selected: i == selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelected(i),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == selected ? Organic.accent : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[i],
                          style: Organic.headingStyle(
                            16,
                            height: 1.2,
                            color: i == selected ? Organic.accent700 : Organic.neutral600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
