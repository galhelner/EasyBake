import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_popup_dialog.dart';
import '../../../community-chat/presentation/pages/community_chat_room_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../recipes/data/services/recipe_service.dart';
import '../../../recipes/presentation/pages/recipe_create_page.dart';
import '../../../recipes/presentation/pages/recipe_list_page.dart';
import '../../../recipes/presentation/widgets/bottom_actions.dart';
import '../../../recipes/presentation/widgets/recipe_create_loading_dialog.dart';
import '../../../recipes/presentation/widgets/recipe_creation_modal.dart';
import '../widgets/home_bottom_tab_bar.dart';

class HomeTabsPage extends ConsumerStatefulWidget {
  const HomeTabsPage({super.key});

  @override
  ConsumerState<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends ConsumerState<HomeTabsPage> {
  int _currentIndex = 1;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _showCreateFromImageErrorDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Could not create recipe'),
        content: const Text(
          'We could not create a recipe from this image. Please try again or use another image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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

  Future<ImageSource?> _selectImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Picture'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createRecipeFromImage() async {
    final source = await _selectImageSource();
    if (!mounted || source == null) {
      return;
    }

    var loadingDialogShown = false;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (!mounted || picked == null) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RecipeCreateLoadingDialog(
          message: 'Creating your recipe...',
        ),
      );
      loadingDialogShown = true;

      final recipe = await ref.read(recipeServiceProvider).createRecipeFromImage(picked.path);

      if (!mounted) {
        return;
      }

      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeCreatePage(initialRecipe: recipe),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await _showCreateFromImageErrorDialog();
    }
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
                onCreateFromImage: _createRecipeFromImage,
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
