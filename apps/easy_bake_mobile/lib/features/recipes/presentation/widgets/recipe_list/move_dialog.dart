import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../domain/models/folder_model.dart';
import '../../providers/recipe_providers.dart';

class MoveDialog extends ConsumerWidget {
  final String? recipeId;
  final String? folderIdToMove;
  final String? currentParentId;

  const MoveDialog({
    super.key,
    this.recipeId,
    this.folderIdToMove,
    this.currentParentId,
  }) : assert(recipeId != null || folderIdToMove != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foldersAsync = ref.watch(foldersListProvider);

    return AlertDialog(
      title: Text(recipeId != null ? l10n.moveRecipeDialogTitle : l10n.moveFolderDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      content: foldersAsync.when(
        data: (folders) {
          // Identify folders to exclude (the folder itself and all its descendants)
          final excludedIds = <String>{};
          if (folderIdToMove != null) {
            excludedIds.add(folderIdToMove!);
            _collectDescendantIds(folderIdToMove!, folders, excludedIds);
          }

          // Build a tree-ordered list of folders
          final sortedFolders = _buildSortedFolders(folders);

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Option: Root (no folder)
                if (currentParentId != null)
                  ListTile(
                    leading: const Icon(Icons.folder_open_outlined, color: Color(0xFF8BB3D6)),
                    title: Text(
                      l10n.moveToRootOption,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF20364B),
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop('__root__'), // '__root__' means root
                  ),
                const Divider(height: 1),
                ...sortedFolders.map((folder) {
                  final isExcluded = excludedIds.contains(folder.id);
                  final isCurrentParent = folder.id == currentParentId;

                  if (isExcluded) {
                    return const SizedBox.shrink(); // Hide folder and descendants
                  }

                  // Determine depth for indentation
                  final depth = _getDepth(folder, folders);

                  return ListTile(
                    contentPadding: EdgeInsets.only(
                      left: 16.0 + (depth * 16.0),
                      right: 16.0,
                    ),
                    leading: Icon(
                      isCurrentParent ? Icons.folder_shared_rounded : Icons.folder_rounded,
                      color: isCurrentParent ? const Color(0xFF2E4E69) : const Color(0xFF8BB3D6),
                    ),
                    title: Text(
                      folder.name,
                      style: TextStyle(
                        color: isCurrentParent ? const Color(0xFF2E4E69) : const Color(0xFF20364B),
                        fontWeight: isCurrentParent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isCurrentParent ? const Icon(Icons.check, size: 18, color: Color(0xFF2E4E69)) : null,
                    onTap: isCurrentParent ? null : () => Navigator.of(context).pop(folder.id),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8BB3D6)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(currentParentId), // Pop back without change
          child: Text(l10n.cancelButtonLabel),
        ),
      ],
    );
  }

  void _collectDescendantIds(String folderId, List<FolderModel> folders, Set<String> result) {
    for (final f in folders) {
      if (f.parentId == folderId) {
        if (result.add(f.id)) {
          _collectDescendantIds(f.id, folders, result);
        }
      }
    }
  }

  List<FolderModel> _buildSortedFolders(List<FolderModel> allFolders) {
    final sorted = <FolderModel>[];
    void addChildren(String? parentId) {
      final levelFolders = allFolders.where((f) => f.parentId == parentId).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (final f in levelFolders) {
        sorted.add(f);
        addChildren(f.id);
      }
    }
    addChildren(null);
    return sorted;
  }

  int _getDepth(FolderModel folder, List<FolderModel> folders) {
    int depth = 0;
    String? currentParentId = folder.parentId;
    while (currentParentId != null) {
      FolderModel? parent;
      for (final f in folders) {
        if (f.id == currentParentId) {
          parent = f;
          break;
        }
      }
      if (parent == null) break;
      depth++;
      currentParentId = parent.parentId;
    }
    return depth;
  }
}
