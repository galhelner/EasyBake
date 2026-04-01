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
import '../widgets/home_bottom_tab_bar.dart';

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
      bottomNavigationBar: HomeBottomTabBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
