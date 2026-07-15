// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'EasyBake';

  @override
  String get communityChatTooltip => 'Community Chat';

  @override
  String get communityChatLabel => 'Chat';

  @override
  String get communityChatHeaderTitle => 'Community Chat';

  @override
  String get communityChatHeaderSubtitle => 'Bakers Community';

  @override
  String get composerConnectingHint => 'Connecting to community chat...';

  @override
  String get composerShareHint => 'Share the community...';

  @override
  String get composerOfflineHint => 'Chat is offline right now';

  @override
  String get shareRecipeWithCommunityLabel =>
      'Share a recipe with the community';

  @override
  String get connectToShareRecipesLabel => 'Connect to share recipes';

  @override
  String get connectionPillConnectingLabel => 'Connecting...';

  @override
  String get connectionPillOnlineLabel => 'Online';

  @override
  String get connectionPillOfflineLabel => 'Offline';

  @override
  String get homeTooltip => 'Home';

  @override
  String get homeLabel => 'Home';

  @override
  String get recipesLabel => 'Recipes';

  @override
  String get shoppingListLabel => 'Shopping List';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get profileLabel => 'Profile';

  @override
  String get signInLabel => 'Sign In';

  @override
  String get registerLabel => 'Register';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get emailHint => 'Email';

  @override
  String get emailAddressHint => 'Email Address';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get nextButtonLabel => 'Next';

  @override
  String get signInErrorInvalidEmail => 'Enter a valid email';

  @override
  String get signInErrorMinPasswordLength => 'Min 8 characters';

  @override
  String get registerErrorNameRequired => 'Please enter your name';

  @override
  String get registerErrorNameTooShort => 'Name must be at least 2 characters';

  @override
  String get registerErrorEmailRequired => 'Please enter your email';

  @override
  String get registerErrorEmailInvalid => 'Please enter a valid email';

  @override
  String get registerErrorPasswordRequired => 'Please enter a password';

  @override
  String get registerErrorPasswordMinLength => 'Min 8 characters';

  @override
  String get registerErrorConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get registerErrorPasswordMismatch => 'Passwords do not match';

  @override
  String registerStepIndicatorLabel(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get gotItButtonLabel => 'Got it';

  @override
  String get authWrongCredentialsTitle => 'Wrong credentials';

  @override
  String get authWrongCredentialsMessage =>
      'The email or password is incorrect. Please try again.';

  @override
  String get authGenericErrorTitle => 'Oops! Something went wrong';

  @override
  String get authRetrySoonMessage => 'Please try again in a moment.';

  @override
  String get authUnexpectedErrorMessage =>
      'An unexpected error occurred. Please try again.';

  @override
  String get emailAlreadyExistsTitle => 'Email already exists';

  @override
  String get emailAlreadyExistsMessage =>
      'A user with this email is already registered.';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutMessage => 'Are you sure you want to log out of EasyBake?';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get logoutButtonLabel => 'Logout';

  @override
  String get profilePageTitle => 'Profile';

  @override
  String get easyBakeUserFallback => 'EasyBake User';

  @override
  String get askAiChefHint => 'Ask the AI Chef';

  @override
  String get viewRecipeButtonLabel => 'View recipe';

  @override
  String get couldNotCreateRecipeTitle => 'Could not create recipe';

  @override
  String get couldNotCreateRecipeMessage =>
      'We could not create a recipe from this image. Please try again or use another image.';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get uploadFromGalleryLabel => 'Upload from Gallery';

  @override
  String get takeAPictureLabel => 'Take a Picture';

  @override
  String get recipeTitleHint => 'Recipe Title';

  @override
  String get uploadRecipeImageTitle => 'Upload Recipe Image';

  @override
  String get uploadRecipeImageSubtitle => 'Gallery or camera';

  @override
  String recipeIngredientHint(Object index) {
    return 'Ingredient #$index';
  }

  @override
  String get recipeIngredientAmountHint => 'Amount';

  @override
  String get recipeIngredientAmountExampleHint =>
      'Amount (e.g. 200 g, 120 ml, 2)';

  @override
  String recipeInstructionHint(Object index) {
    return 'Instruction Step #$index';
  }

  @override
  String recipeItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get creatingYourRecipeMessage => 'Creating your recipe...';

  @override
  String get recipeCannotBeDeletedYetMessage =>
      'This recipe cannot be deleted yet.';

  @override
  String get deleteRecipeTitle => 'Delete Recipe?';

  @override
  String get deleteRecipeMessage =>
      'This action cannot be undone. Do you want to delete this recipe?';

  @override
  String get deleteButtonLabel => 'Delete';

  @override
  String get recipeNotFoundMessage =>
      'Recipe not found. It may have already been deleted.';

  @override
  String get couldNotDeleteRecipeMessage =>
      'Could not delete recipe. Please try again.';

  @override
  String get requestTimedOutMessage => 'Request timed out. Please try again.';

  @override
  String get couldNotSaveRecipeMessage =>
      'Could not save recipe. Please try again.';

  @override
  String get communityChatFailureHint =>
      'You can try again later or refresh the chat.';

  @override
  String get communityChatUnavailableTitle => 'Community chat is unavailable';

  @override
  String get communityChatUnavailableMessage =>
      'Community chat is temporarily unavailable. Please refresh or try again later.';

  @override
  String get communityChatRefreshFailedMessage =>
      'We could not refresh community chat right now. Please try again later.';

  @override
  String get communityChatIdentityMessage =>
      'We could not identify your account for chat.';

  @override
  String get communityChatSendFailedMessage =>
      'Could not send your message right now. Please try again later.';

  @override
  String get communityChatEmptyTitle => 'No messages yet';

  @override
  String get communityChatEmptySubtitle =>
      'Start the conversation in this room.';

  @override
  String get communityChatOfflineTitle => 'Community chat is offline';

  @override
  String get communityChatOfflineSubtitle =>
      'Pull down to refresh to try reconnecting and see messages again.';

  @override
  String get recipePreviewUnavailableTitle => 'Recipe preview unavailable';

  @override
  String get recipePreviewNoLongerAvailableMessage =>
      'This shared recipe is no longer available.';

  @override
  String get recipePreviewRefreshHint =>
      'Pull down to refresh the chat to try loading the shared recipe again.';

  @override
  String get laterButtonLabel => 'Later';

  @override
  String get refreshButtonLabel => 'Refresh';

  @override
  String get tryAgainButtonLabel => 'Try again';

  @override
  String get searchRecipesHint => 'Search recipes...';

  @override
  String get chooseShareMethodSubtitle =>
      'Choose how you\'d like to share your culinary creation';

  @override
  String get createRecipeManuallyTitle => 'Create Recipe Manually';

  @override
  String get createRecipeManuallySubtitle => 'Add your recipe step by step';

  @override
  String get aiMagicPhotoToRecipeTitle => 'AI Magic: Photo to Recipe';

  @override
  String get aiMagicPhotoToRecipeSubtitle =>
      'AI scans your photo and builds the recipe';

  @override
  String get createRecipeHeaderCreateTitle => 'Create New Recipe';

  @override
  String get createRecipeHeaderEditTitle => 'Edit Recipe';

  @override
  String get createRecipeHeaderCreateSubtitle => 'Share your culinary creation';

  @override
  String get createRecipeHeaderEditSubtitle => 'Update your culinary creation';

  @override
  String get replaceButtonLabel => 'Replace';

  @override
  String get shareRecipeTitle => 'Share a recipe';

  @override
  String get shareRecipeSubtitle =>
      'Choose one of your recipes to send to the community.';

  @override
  String get closeTooltip => 'Close';

  @override
  String get couldNotLoadRecipesRightNowMessage =>
      'Could not load your recipes right now.';

  @override
  String get noRecipesYetMessage => 'You do not have any recipes to share yet.';

  @override
  String get noRecipesFoundTitle => 'No recipes found';

  @override
  String get noRecipesFoundSubtitle =>
      'Use AI Chef chat to semantically search your recipes.';

  @override
  String get noRecipesYetTitle => 'Your recipe collection is empty';

  @override
  String get noRecipesYetSubtitle =>
      'Tap the + button to add your first recipe, or use AI to create one for you.';

  @override
  String get viewButtonLabel => 'View';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get ingredientsTabLabel => 'Ingredients';

  @override
  String get instructionsTabLabel => 'Instructions';

  @override
  String get recipeActionsTooltip => 'Recipe actions';

  @override
  String get editActionLabel => 'Edit';

  @override
  String get updateRecipeSubtitle => 'Update title, image, or steps';

  @override
  String get deleteActionLabel => 'Delete';

  @override
  String get removeRecipePermanentlySubtitle =>
      'Remove this recipe permanently';

  @override
  String get customScaleTitle => 'Custom Scale';

  @override
  String get enterDesiredScaleHint => 'Enter your desired scale';

  @override
  String get applyButtonLabel => 'Apply';

  @override
  String get noIngredientsAvailableMessage => 'No ingredients available.';

  @override
  String get backButtonLabel => 'Back';

  @override
  String get chatDisplayNameLabel => 'Chat Display Name';

  @override
  String get enterChatDisplayNameHint => 'Enter your chat display name';

  @override
  String get chatDisplayNameDescription =>
      'This is the name displayed in the community chat';

  @override
  String get usingFullProfileNameByDefaultMessage =>
      'Using your full profile name by default';

  @override
  String get editTooltip => 'Edit';

  @override
  String get cancelTooltip => 'Cancel';

  @override
  String get saveTooltip => 'Save';

  @override
  String get savingYourRecipeMessage => 'Saving your recipe...';

  @override
  String get recipeSavedMessage => 'Recipe saved';

  @override
  String get deletingYourRecipeMessage => 'Deleting your recipe...';

  @override
  String get recipeDeletedMessage => 'Recipe deleted';

  @override
  String get shoppingListPageTitle => 'Shopping List';

  @override
  String get shoppingListPageSubtitle =>
      'Future feature: shopping list management will live here.';

  @override
  String get shoppingListFutureDetails =>
      'This area is reserved for future shopping list tools, saved grocery lists, and ingredient tracking.';

  @override
  String get shoppingListAddItemTitle => 'Add Item';

  @override
  String get shoppingListIngredientNameHint => 'Ingredient name';

  @override
  String get shoppingListIngredientAmountHint => 'Amount (e.g. 2, 200g, 1 cup)';

  @override
  String get addButtonLabel => 'Add';

  @override
  String get shoppingListItemAddedMessage => 'Item added to shopping list';

  @override
  String get shoppingListItemAddFailedMessage =>
      'Failed to add item to shopping list';

  @override
  String get shoppingListLoadFailedMessage => 'Failed to load shopping list';

  @override
  String get shoppingListEditItemTitle => 'Edit Item';

  @override
  String get shoppingListItemUpdatedMessage => 'Item updated';

  @override
  String get shoppingListItemUpdateFailedMessage => 'Failed to update item';

  @override
  String get shoppingListItemDeletedMessage => 'Item deleted';

  @override
  String get shoppingListItemDeleteFailedMessage => 'Failed to delete item';

  @override
  String get confirmDeleteShoppingListItemMessage =>
      'Are you sure you want to delete this item?';

  @override
  String get deletingShoppingListItemMessage => 'Deleting item...';

  @override
  String get shoppingListEmptyTitle => 'Your shopping list is empty';

  @override
  String get shoppingListEmptySubtitle =>
      'Tap the + button to add items to your list.';

  @override
  String get shoppingListEmptyBackLabel => 'Go Back';

  @override
  String get cookingStepsTitle => 'Cooking Steps';

  @override
  String get doneLabel => 'Done';

  @override
  String get recipeScalesTitle => 'Recipe scales';

  @override
  String get customScaleButtonLabel => 'Custom';

  @override
  String get timerKitchenTitle => 'Kitchen Timer';

  @override
  String get timerKitchenSubtitle =>
      'Perfect for proofing, resting, and baking';

  @override
  String get timerCustomButtonLabel => 'Custom';

  @override
  String get timerSetCustomTitle => 'Set custom timer';

  @override
  String get timerCompleteTitle => 'Timer Complete!';

  @override
  String get timerCompleteMessage => 'Your step is ready for the next action.';

  @override
  String get timerCompleteButtonLabel => 'Great';

  @override
  String get timerNotificationTitle => 'EasyBake Timer Done';

  @override
  String get timerNotificationBody =>
      'Your timer has finished. Check your recipe step.';

  @override
  String get timerOpenTooltip => 'Open timer';

  @override
  String get timerCloseTooltip => 'Close timer';

  @override
  String get timerStartButtonLabel => 'Start';

  @override
  String get timerPauseButtonLabel => 'Pause';

  @override
  String get timerResetButtonLabel => 'Reset';

  @override
  String get timerHourUnitShort => 'h';

  @override
  String get timerMinuteUnitShort => 'm';

  @override
  String get timerSecondUnitShort => 's';

  @override
  String get confirmDeleteRecipeMessage =>
      'Are you sure you want to delete this recipe?';

  @override
  String get saveRecipeConfirmationMessage =>
      'Do you want to save this recipe?';

  @override
  String get deleteRecipeMissingIdMessage =>
      'Cannot delete: recipe ID is missing';

  @override
  String get deleteRecipeUnauthorizedMessage =>
      'Unauthorized. Please check your app configuration.';

  @override
  String get deleteRecipeNotFoundMessage => 'Recipe not found.';

  @override
  String get profileHeaderGreetingSubtitle => 'Welcome back to EasyBake';

  @override
  String summaryCardSavedRecipes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved recipes',
      one: '1 saved recipe',
      zero: 'No saved recipes',
    );
    return '$_temp0';
  }

  @override
  String get summaryCardSubtitle => 'Your personal recipe collection';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get dashboardSubtitle => 'Your recipes and health trends at a glance.';

  @override
  String get myRecipesLabel => 'My Recipes';

  @override
  String get seeAllLabel => 'See all';

  @override
  String get dashboardNoRecipesSubtitle =>
      'Create your first recipe or jump into the Recipes tab.';

  @override
  String get healthStatisticsLabel => 'Health Statistics';

  @override
  String get dashboardNoHealthStatsTitle => 'No data yet';

  @override
  String get dashboardNoHealthStatsSubtitle =>
      'Add recipes and the health breakdown will appear here.';

  @override
  String recipeCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String ingredientCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get summaryCardLoadingMessage => 'Loading your recipe summary...';

  @override
  String get summaryCardUnavailableMessage =>
      'Recipe summary unavailable right now';

  @override
  String get logoutButtonShortLabel => 'Logout';

  @override
  String get createRecipeModalTitle => 'Create Your Recipe';

  @override
  String get aiChefPopupTitle => 'EasyBake AI Chef';

  @override
  String get aiChefPopupSubtitle => 'Chat assistant';

  @override
  String get aiChefPopupCheckingLabel => 'Checking...';

  @override
  String get aiChefPopupRefreshLabel => 'Refresh';

  @override
  String get aiChefGreetingWithoutName => 'How can I help you?';

  @override
  String aiChefGreetingWithName(Object displayName) {
    return 'Hello $displayName!\nHow can I help you?';
  }

  @override
  String get aiChefServiceUnavailableMessage =>
      'Recipe service is currently unavailable. Please tap Refresh and try again.';

  @override
  String get aiChefCreatingRecipeMessage =>
      'Sure! I am creating the recipe for you';

  @override
  String get aiChefGenericErrorMessage =>
      'I\'m sorry, it seems like something went wrong 😞, try to ask me again please!';

  @override
  String get aiChefErrorPleaseTypeMessageFirst =>
      'Please type a message first.';

  @override
  String get aiChefErrorCouldNotSendMessage =>
      'Could not send your message. Please try again.';

  @override
  String get aiChefErrorEmptyResponse => 'Empty response from server.';

  @override
  String get aiChefErrorStreamInterrupted =>
      'Stream interrupted. Please try again.';

  @override
  String get aiChefErrorAssistantCouldNotComplete =>
      'The assistant could not complete this response.';

  @override
  String get aiChefErrorCouldNotReadServerResponse =>
      'Could not read server response. Please try again.';

  @override
  String get aiChefErrorResponseUnsupportedFormat =>
      'Response received in an unsupported format.';

  @override
  String get aiChefErrorUnexpectedResponseFormat =>
      'Unexpected response format from server.';

  @override
  String get aiChefErrorFailedToParseServerResponse =>
      'Failed to parse server response.';

  @override
  String get aiChefErrorRequestFailed => 'Request failed. Please try again.';

  @override
  String get aiChefErrorServerSlow =>
      'The server is taking too long to respond. Please try again in a moment.';

  @override
  String get aiChefErrorCannotReachServer =>
      'Cannot reach the server right now. Please check your connection and try again.';

  @override
  String get aiChefErrorRequestCancelled =>
      'Request was cancelled. Please try again.';

  @override
  String get aiChefErrorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get aiChefErrorServerIssue =>
      'The server hit an issue while handling your request. Please try again shortly.';

  @override
  String get aiChefErrorNotFound =>
      'I could not find what you requested. Please try again.';

  @override
  String get aiChefErrorRateLimited =>
      'I am a bit busy right now. Please try again in a few seconds.';

  @override
  String get aiChefErrorValidation =>
      'I could not process that message. Please rephrase and try again.';

  @override
  String get aiChefErrorGeneric =>
      'Something went wrong on our side. Please try again.';

  @override
  String get aiChefSuggestedSubstitutionsTitle => 'Suggested substitutions';

  @override
  String get aiChefYourRecipeFallback => 'your recipe';

  @override
  String get aiChefConnectionRestoredMessage =>
      'Connection restored. You can continue chatting.';

  @override
  String aiChefRecipeSavedConfirmation(Object recipeName) {
    return 'Great! I\'ve saved your recipe: $recipeName';
  }

  @override
  String get aiChefAddingToShoppingListMessage =>
      'Sure! I am adding the items to your shopping list';

  @override
  String get aiChefShoppingListAddedTitle =>
      'I added these items to your shopping list:';

  @override
  String get aiChefNavigateToShoppingListButton => 'View Shopping List';

  @override
  String shareRecipeIngredientsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
      zero: 'No ingredients',
    );
    return '$_temp0';
  }

  @override
  String get preferencesSectionTitle => 'Preferences';

  @override
  String get customizeYourExperienceSubtitle => 'Customize your experience';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystemDefaultLabel => 'System default';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageHebrewLabel => 'עברית';

  @override
  String get healthyModeTitle => 'Healthy Mode';

  @override
  String get healthyModeSubtitle => 'Show health badges on recipe cards';

  @override
  String get healthyBadgeLabel => 'Healthy';

  @override
  String get averageBadgeLabel => 'Average';

  @override
  String get unhealthyBadgeLabel => 'Unhealthy';

  @override
  String welcomeUser(Object username) {
    return 'Welcome, $username!';
  }

  @override
  String get createFolderButtonLabel => 'Create Folder';

  @override
  String get newFolderDialogTitle => 'New Folder';

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get deleteFolderTitle => 'Delete Folder?';

  @override
  String get deleteFolderOptionAllTitle => 'Delete folder and all contents';

  @override
  String get deleteFolderOptionAllMessage =>
      'This will delete the folder, all its sub-folders, and all the recipes inside them.';

  @override
  String get deleteFolderOptionPopTitle => 'Delete folder only (keep contents)';

  @override
  String get deleteFolderOptionPopMessage =>
      'This will delete only the folder. Recipes and sub-folders will move one level up.';

  @override
  String get moveRecipeDialogTitle => 'Move Recipe';

  @override
  String get moveFolderDialogTitle => 'Move Folder';

  @override
  String get moveToRootOption => 'Root (No folder)';

  @override
  String get folderLabel => 'Folder';

  @override
  String get emptyFolderTitle => 'This folder is empty';

  @override
  String get emptyFolderSubtitle =>
      'Tap the + button to add a recipe or create a sub-folder.';

  @override
  String get moveButtonLabel => 'Move';

  @override
  String get savingFolderMessage => 'Saving folder...';

  @override
  String get folderSavedMessage => 'Folder saved';

  @override
  String get deletingFolderMessage => 'Deleting folder...';

  @override
  String get folderDeletedMessage => 'Folder deleted';

  @override
  String movingRecipeMessage(Object folderName) {
    return 'Moving recipe to $folderName...';
  }

  @override
  String get recipeMovedMessage => 'Recipe moved';

  @override
  String movingFolderMessage(Object folderName) {
    return 'Moving folder to $folderName...';
  }

  @override
  String get folderMovedMessage => 'Folder moved';

  @override
  String get deleteFolderConfirmationMessage =>
      'Are you sure you want to delete this folder?';

  @override
  String get foldersHeaderLabel => 'Folders';

  @override
  String get recipesHeaderLabel => 'Recipes';

  @override
  String get recipeAuthorHint => 'Recipe By';

  @override
  String get recipeAuthorLabel => 'By';

  @override
  String get aiChefName => 'AI Chef';
}
