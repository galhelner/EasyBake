import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_popup_dialog.dart';
import '../../../community-chat/presentation/pages/community_chat_room_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../recipes/presentation/pages/recipe_create_page.dart';
import '../../../recipes/presentation/pages/recipe_list_page.dart';
import '../../../recipes/presentation/widgets/bottom_actions.dart';
import '../../../recipes/presentation/widgets/recipe_creation_modal.dart';

class HomeTabsPage extends ConsumerStatefulWidget {
  const HomeTabsPage({super.key});

  @override
  ConsumerState<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends ConsumerState<HomeTabsPage> {
  int _currentIndex = 1;

  static const _tabs = [
    CommunityChatRoomPage(),
    RecipeListPage(showBottomActions: false),
    ProfilePage(),
  ];

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showHomeActions = _currentIndex == 1;

    return Scaffold(
      extendBody: false,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: IgnorePointer(
        ignoring: !showHomeActions,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: showHomeActions ? 1 : 0,
          child: BottomActions(
            onCreate: () {
              showRecipeCreationModal(
                context,
                onCreateManually: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecipeCreatePage()),
                  );
                },
                onCreateFromImage: null,
              );
            },
            onAiCreate: () {
              unawaited(
                showAiChefChatPopup(
                  context,
                  pageContext: 'home',
                  chatService: ref.read(chatServiceProvider),
                  onOpenRecipeCreated: (recipePayload) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeCreatePage(initialRecipeJson: recipePayload),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _HomeBottomTabBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _HomeBottomTabBar extends StatelessWidget {
  const _HomeBottomTabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;

  IconData _iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.forum_rounded;
      case 2:
        return Icons.person_rounded;
      case 1:
      default:
        return Icons.home_rounded;
    }
  }

  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 58.0;
    const pillHeight = 46.0;

    return SizedBox(
      height: barHeight + bottomInset + 12,
      child: ColoredBox(
        color: const Color(0xFFEDF1F6),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF95BDDC), Color(0xFF7EACD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2B1E3850),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 5.0;
                final segmentWidth =
                    (constraints.maxWidth - (horizontalPadding * 2)) / 3;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: horizontalPadding + (segmentWidth * currentIndex),
                      top: (barHeight - pillHeight) / 2,
                      width: segmentWidth,
                      height: pillHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF2E4E69),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D122738),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForIndex(currentIndex),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Community Chat Room',
                            selected: currentIndex == 0,
                            icon: Icons.forum_rounded,
                            onTap: () => onTabSelected(0),
                          ),
                        ),
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Home',
                            selected: currentIndex == 1,
                            icon: Icons.home_rounded,
                            onTap: () => onTabSelected(1),
                          ),
                        ),
                        Expanded(
                          child: _TabIconButton(
                            tooltip: 'Profile',
                            selected: currentIndex == 2,
                            icon: Icons.person_rounded,
                            onTap: () => onTabSelected(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        splashRadius: 22,
        icon: Icon(
          icon,
          size: 22,
          color: selected
              ? Colors.transparent
              : const Color(0xFFEEF6FC).withValues(alpha: 0.94),
        ),
      ),
    );
  }
}
