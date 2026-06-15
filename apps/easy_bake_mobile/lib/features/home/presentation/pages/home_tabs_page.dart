import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/pages/ai_chef_chat_popup_page.dart';
import '../../../community-chat/presentation/pages/community_chat_room_page.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../recipes/presentation/pages/recipe_create_page.dart';
import '../../../recipes/presentation/pages/recipe_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../shopping-list/presentation/pages/shopping_list_page.dart';
import 'home_dashboard_page.dart';
import '../widgets/home_bottom_tab_bar.dart';

class HomeTabsPage extends ConsumerStatefulWidget {
  const HomeTabsPage({super.key});

  @override
  ConsumerState<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends ConsumerState<HomeTabsPage> {
  int _currentIndex = 2;

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAiChefChat() {
    return showAiChefChatPopup(
      context,
      pageContext: 'home',
      chatService: ref.read(chatServiceProvider),
      onOpenRecipeCreated: (recipePayload) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final savedRecipe = await Navigator.of(context).push<RecipeModel>(
            MaterialPageRoute(
              builder: (_) => RecipeCreatePage(initialRecipeJson: recipePayload),
            ),
          );

          if (savedRecipe != null && context.mounted) {
            notifyRecipeSaved(savedRecipe.title);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ProfilePage(),
      const CommunityChatRoomPage(),
      HomeDashboardPage(
        onSeeAllRecipes: () => _onTabSelected(3),
        onSeeAllShoppingList: () => _onTabSelected(4),
        onOpenAiChefChat: _openAiChefChat,
      ),
      const RecipeListPage(showBottomActions: true),
      const ShoppingListPage(),
    ];

    return Scaffold(
      extendBody: false,
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: HomeBottomTabBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}