import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'EasyBake'**
  String get appName;

  /// No description provided for @communityChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Community Chat'**
  String get communityChatTooltip;

  /// No description provided for @communityChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get communityChatLabel;

  /// Title shown in the community chat app bar.
  ///
  /// In en, this message translates to:
  /// **'Community Chat'**
  String get communityChatHeaderTitle;

  /// Subtitle shown in the community chat app bar.
  ///
  /// In en, this message translates to:
  /// **'Bakers Community'**
  String get communityChatHeaderSubtitle;

  /// Hint shown in the chat composer while the app is connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to community chat...'**
  String get composerConnectingHint;

  /// Hint shown in the chat composer when sharing is available.
  ///
  /// In en, this message translates to:
  /// **'Share the community...'**
  String get composerShareHint;

  /// Hint shown in the chat composer when chat is offline.
  ///
  /// In en, this message translates to:
  /// **'Chat is offline right now'**
  String get composerOfflineHint;

  /// Accessibility label for the button that opens recipe sharing.
  ///
  /// In en, this message translates to:
  /// **'Share a recipe with the community'**
  String get shareRecipeWithCommunityLabel;

  /// Accessibility label for the disabled recipe sharing button.
  ///
  /// In en, this message translates to:
  /// **'Connect to share recipes'**
  String get connectToShareRecipesLabel;

  /// Text shown in the chat connection pill while connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connectionPillConnectingLabel;

  /// Text shown in the chat connection pill when online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connectionPillOnlineLabel;

  /// Text shown in the chat connection pill when offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get connectionPillOfflineLabel;

  /// No description provided for @homeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTooltip;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// Label for the Recipes tab in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesLabel;

  /// Label for the Shopping List tab in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListLabel;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @signInLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLabel;

  /// No description provided for @registerLabel.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLabel;

  /// Hint text for the full name field on the register form.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// Hint text for the email field on the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// Hint text for the email field on the register form.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressHint;

  /// Hint text for password fields on the auth forms.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Hint text for the confirm password field on the register form.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// Label for the next step button in the register form.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButtonLabel;

  /// Validation message shown when the sign-in email is invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get signInErrorInvalidEmail;

  /// Validation message shown when the sign-in password is too short.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get signInErrorMinPasswordLength;

  /// Validation message shown when the register name field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get registerErrorNameRequired;

  /// Validation message shown when the register name is too short.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get registerErrorNameTooShort;

  /// Validation message shown when the register email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get registerErrorEmailRequired;

  /// Validation message shown when the register email is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get registerErrorEmailInvalid;

  /// Validation message shown when the register password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get registerErrorPasswordRequired;

  /// Validation message shown when the register password is too short.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get registerErrorPasswordMinLength;

  /// Validation message shown when the confirm password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get registerErrorConfirmPasswordRequired;

  /// Validation message shown when the register passwords do not match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerErrorPasswordMismatch;

  /// Title shown above the register progress indicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String registerStepIndicatorLabel(Object current, Object total);

  /// Confirmation button label shown in auth dialogs.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButtonLabel;

  /// Title shown when the sign-in credentials are invalid.
  ///
  /// In en, this message translates to:
  /// **'Wrong credentials'**
  String get authWrongCredentialsTitle;

  /// Message shown when the sign-in credentials are invalid.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect. Please try again.'**
  String get authWrongCredentialsMessage;

  /// Generic title shown for auth-related errors.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get authGenericErrorTitle;

  /// Message shown when an auth request fails temporarily.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get authRetrySoonMessage;

  /// Message shown when an auth request fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get authUnexpectedErrorMessage;

  /// Title shown when the register email is already in use.
  ///
  /// In en, this message translates to:
  /// **'Email already exists'**
  String get emailAlreadyExistsTitle;

  /// Message shown when the register email is already in use.
  ///
  /// In en, this message translates to:
  /// **'A user with this email is already registered.'**
  String get emailAlreadyExistsMessage;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of EasyBake?'**
  String get logoutMessage;

  /// No description provided for @cancelButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// No description provided for @logoutButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButtonLabel;

  /// No description provided for @profilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePageTitle;

  /// No description provided for @easyBakeUserFallback.
  ///
  /// In en, this message translates to:
  /// **'EasyBake User'**
  String get easyBakeUserFallback;

  /// No description provided for @askAiChefHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI Chef'**
  String get askAiChefHint;

  /// No description provided for @viewRecipeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'View recipe'**
  String get viewRecipeButtonLabel;

  /// No description provided for @couldNotCreateRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not create recipe'**
  String get couldNotCreateRecipeTitle;

  /// No description provided for @couldNotCreateRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not create a recipe from this image. Please try again or use another image.'**
  String get couldNotCreateRecipeMessage;

  /// No description provided for @okButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButtonLabel;

  /// No description provided for @uploadFromGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get uploadFromGalleryLabel;

  /// No description provided for @takeAPictureLabel.
  ///
  /// In en, this message translates to:
  /// **'Take a Picture'**
  String get takeAPictureLabel;

  /// Placeholder shown in the recipe title field on the create recipe page.
  ///
  /// In en, this message translates to:
  /// **'Recipe Title'**
  String get recipeTitleHint;

  /// Title shown on the recipe image upload card.
  ///
  /// In en, this message translates to:
  /// **'Upload Recipe Image'**
  String get uploadRecipeImageTitle;

  /// Subtitle shown on the recipe image upload card.
  ///
  /// In en, this message translates to:
  /// **'Gallery or camera'**
  String get uploadRecipeImageSubtitle;

  /// Placeholder shown in each ingredient name field on the create recipe page.
  ///
  /// In en, this message translates to:
  /// **'Ingredient #{index}'**
  String recipeIngredientHint(Object index);

  /// Placeholder shown in each ingredient amount field on the create recipe page.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recipeIngredientAmountHint;

  /// Placeholder shown in compact ingredient amount fields on the create recipe page.
  ///
  /// In en, this message translates to:
  /// **'Amount (e.g. 200 g, 120 ml, 2)'**
  String get recipeIngredientAmountExampleHint;

  /// Placeholder shown in each instruction field on the create recipe page.
  ///
  /// In en, this message translates to:
  /// **'Instruction Step #{index}'**
  String recipeInstructionHint(Object index);

  /// Count label shown under create recipe section titles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String recipeItemsCount(num count);

  /// No description provided for @creatingYourRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating your recipe...'**
  String get creatingYourRecipeMessage;

  /// No description provided for @recipeCannotBeDeletedYetMessage.
  ///
  /// In en, this message translates to:
  /// **'This recipe cannot be deleted yet.'**
  String get recipeCannotBeDeletedYetMessage;

  /// No description provided for @deleteRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Recipe?'**
  String get deleteRecipeTitle;

  /// No description provided for @deleteRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Do you want to delete this recipe?'**
  String get deleteRecipeMessage;

  /// No description provided for @deleteButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButtonLabel;

  /// No description provided for @recipeNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found. It may have already been deleted.'**
  String get recipeNotFoundMessage;

  /// No description provided for @couldNotDeleteRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete recipe. Please try again.'**
  String get couldNotDeleteRecipeMessage;

  /// No description provided for @requestTimedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimedOutMessage;

  /// No description provided for @couldNotSaveRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save recipe. Please try again.'**
  String get couldNotSaveRecipeMessage;

  /// No description provided for @communityChatFailureHint.
  ///
  /// In en, this message translates to:
  /// **'You can try again later or refresh the chat.'**
  String get communityChatFailureHint;

  /// No description provided for @communityChatUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Community chat is unavailable'**
  String get communityChatUnavailableTitle;

  /// Message shown when the community chat is temporarily unavailable.
  ///
  /// In en, this message translates to:
  /// **'Community chat is temporarily unavailable. Please refresh or try again later.'**
  String get communityChatUnavailableMessage;

  /// Message shown when refreshing the community chat fails.
  ///
  /// In en, this message translates to:
  /// **'We could not refresh community chat right now. Please try again later.'**
  String get communityChatRefreshFailedMessage;

  /// Message shown when the app cannot identify the user for chat.
  ///
  /// In en, this message translates to:
  /// **'We could not identify your account for chat.'**
  String get communityChatIdentityMessage;

  /// Message shown when sending a community chat message fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message right now. Please try again later.'**
  String get communityChatSendFailedMessage;

  /// Title shown when the community chat has no messages yet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get communityChatEmptyTitle;

  /// Subtitle shown when the community chat has no messages yet.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation in this room.'**
  String get communityChatEmptySubtitle;

  /// Title shown when the community chat is offline.
  ///
  /// In en, this message translates to:
  /// **'Community chat is offline'**
  String get communityChatOfflineTitle;

  /// Subtitle shown when the community chat is offline.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh to try reconnecting and see messages again.'**
  String get communityChatOfflineSubtitle;

  /// Title shown when the shared recipe preview cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Recipe preview unavailable'**
  String get recipePreviewUnavailableTitle;

  /// Message shown when a shared recipe is no longer available.
  ///
  /// In en, this message translates to:
  /// **'This shared recipe is no longer available.'**
  String get recipePreviewNoLongerAvailableMessage;

  /// Hint telling the user to refresh to reload the shared recipe.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh the chat to try loading the shared recipe again.'**
  String get recipePreviewRefreshHint;

  /// No description provided for @laterButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterButtonLabel;

  /// No description provided for @refreshButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButtonLabel;

  /// No description provided for @tryAgainButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButtonLabel;

  /// No description provided for @searchRecipesHint.
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get searchRecipesHint;

  /// No description provided for @chooseShareMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to share your culinary creation'**
  String get chooseShareMethodSubtitle;

  /// No description provided for @createRecipeManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Recipe Manually'**
  String get createRecipeManuallyTitle;

  /// No description provided for @createRecipeManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your recipe step by step'**
  String get createRecipeManuallySubtitle;

  /// No description provided for @aiMagicPhotoToRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Magic: Photo to Recipe'**
  String get aiMagicPhotoToRecipeTitle;

  /// No description provided for @aiMagicPhotoToRecipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI scans your photo and builds the recipe'**
  String get aiMagicPhotoToRecipeSubtitle;

  /// Title shown on the create recipe page in create mode.
  ///
  /// In en, this message translates to:
  /// **'Create New Recipe'**
  String get createRecipeHeaderCreateTitle;

  /// Title shown on the create recipe page in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get createRecipeHeaderEditTitle;

  /// Subtitle shown on the create recipe page in create mode.
  ///
  /// In en, this message translates to:
  /// **'Share your culinary creation'**
  String get createRecipeHeaderCreateSubtitle;

  /// Subtitle shown on the create recipe page in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Update your culinary creation'**
  String get createRecipeHeaderEditSubtitle;

  /// No description provided for @replaceButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceButtonLabel;

  /// No description provided for @shareRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a recipe'**
  String get shareRecipeTitle;

  /// No description provided for @shareRecipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one of your recipes to send to the community.'**
  String get shareRecipeSubtitle;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @couldNotLoadRecipesRightNowMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load your recipes right now.'**
  String get couldNotLoadRecipesRightNowMessage;

  /// No description provided for @noRecipesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have any recipes to share yet.'**
  String get noRecipesYetMessage;

  /// Title shown when a recipe search returns no results.
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get noRecipesFoundTitle;

  /// Subtitle shown when a recipe search returns no results.
  ///
  /// In en, this message translates to:
  /// **'Use AI Chef chat to semantically search your recipes.'**
  String get noRecipesFoundSubtitle;

  /// Title shown when the recipe list is empty.
  ///
  /// In en, this message translates to:
  /// **'Your recipe collection is empty'**
  String get noRecipesYetTitle;

  /// Subtitle shown when the recipe list is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first recipe, or use AI to create one for you.'**
  String get noRecipesYetSubtitle;

  /// No description provided for @viewButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewButtonLabel;

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @ingredientsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTabLabel;

  /// No description provided for @instructionsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsTabLabel;

  /// No description provided for @recipeActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recipe actions'**
  String get recipeActionsTooltip;

  /// No description provided for @editActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editActionLabel;

  /// No description provided for @updateRecipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update title, image, or steps'**
  String get updateRecipeSubtitle;

  /// No description provided for @deleteActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteActionLabel;

  /// No description provided for @removeRecipePermanentlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this recipe permanently'**
  String get removeRecipePermanentlySubtitle;

  /// No description provided for @customScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Scale'**
  String get customScaleTitle;

  /// No description provided for @enterDesiredScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your desired scale'**
  String get enterDesiredScaleHint;

  /// No description provided for @applyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButtonLabel;

  /// No description provided for @noIngredientsAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No ingredients available.'**
  String get noIngredientsAvailableMessage;

  /// No description provided for @backButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButtonLabel;

  /// No description provided for @chatDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat Display Name'**
  String get chatDisplayNameLabel;

  /// No description provided for @enterChatDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your chat display name'**
  String get enterChatDisplayNameHint;

  /// No description provided for @chatDisplayNameDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the name displayed in the community chat'**
  String get chatDisplayNameDescription;

  /// No description provided for @usingFullProfileNameByDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Using your full profile name by default'**
  String get usingFullProfileNameByDefaultMessage;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @cancelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTooltip;

  /// No description provided for @saveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTooltip;

  /// No description provided for @savingYourRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Saving your recipe...'**
  String get savingYourRecipeMessage;

  /// No description provided for @recipeSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recipe saved'**
  String get recipeSavedMessage;

  /// No description provided for @deletingYourRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting your recipe...'**
  String get deletingYourRecipeMessage;

  /// No description provided for @recipeDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recipe deleted'**
  String get recipeDeletedMessage;

  /// Title shown at the top of the shopping list page.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListPageTitle;

  /// Subtitle shown under the shopping list page title.
  ///
  /// In en, this message translates to:
  /// **'Future feature: shopping list management will live here.'**
  String get shoppingListPageSubtitle;

  /// Supporting text describing the future shopping list feature.
  ///
  /// In en, this message translates to:
  /// **'This area is reserved for future shopping list tools, saved grocery lists, and ingredient tracking.'**
  String get shoppingListFutureDetails;

  /// Heading shown above the recipe instruction steps in recipe details.
  ///
  /// In en, this message translates to:
  /// **'Cooking Steps'**
  String get cookingStepsTitle;

  /// Section title shown above the recipe scale controls in recipe details.
  ///
  /// In en, this message translates to:
  /// **'Recipe scales'**
  String get recipeScalesTitle;

  /// Label for the button that opens the custom scale dialog in recipe details.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customScaleButtonLabel;

  /// Title shown in the recipe details timer card.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Timer'**
  String get timerKitchenTitle;

  /// Subtitle shown under the recipe details timer title.
  ///
  /// In en, this message translates to:
  /// **'Perfect for proofing, resting, and baking'**
  String get timerKitchenSubtitle;

  /// Label for the custom timer chip in recipe details.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timerCustomButtonLabel;

  /// Title shown in the custom timer bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Set custom timer'**
  String get timerSetCustomTitle;

  /// Title shown when the recipe timer finishes.
  ///
  /// In en, this message translates to:
  /// **'Timer Complete!'**
  String get timerCompleteTitle;

  /// Message shown when the recipe timer finishes.
  ///
  /// In en, this message translates to:
  /// **'Your step is ready for the next action.'**
  String get timerCompleteMessage;

  /// Confirmation button label shown when the timer completes.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get timerCompleteButtonLabel;

  /// Notification title shown when the recipe timer finishes.
  ///
  /// In en, this message translates to:
  /// **'EasyBake Timer Done'**
  String get timerNotificationTitle;

  /// Notification body shown when the recipe timer finishes.
  ///
  /// In en, this message translates to:
  /// **'Your timer has finished. Check your recipe step.'**
  String get timerNotificationBody;

  /// Tooltip shown for the collapsed timer button.
  ///
  /// In en, this message translates to:
  /// **'Open timer'**
  String get timerOpenTooltip;

  /// Tooltip shown for the timer close button.
  ///
  /// In en, this message translates to:
  /// **'Close timer'**
  String get timerCloseTooltip;

  /// Label shown on the timer start button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStartButtonLabel;

  /// Label shown on the timer pause button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPauseButtonLabel;

  /// Label shown on the timer reset button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerResetButtonLabel;

  /// Short hour unit used in timer duration chips.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timerHourUnitShort;

  /// Short minute unit used in timer duration chips.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get timerMinuteUnitShort;

  /// Short second unit used in timer duration chips.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get timerSecondUnitShort;

  /// No description provided for @confirmDeleteRecipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this recipe?'**
  String get confirmDeleteRecipeMessage;

  /// Confirmation prompt shown before saving a recipe.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save this recipe?'**
  String get saveRecipeConfirmationMessage;

  /// Message shown when a recipe cannot be deleted because it has no ID.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: recipe ID is missing'**
  String get deleteRecipeMissingIdMessage;

  /// Message shown when delete is blocked by an authorization issue.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please check your app configuration.'**
  String get deleteRecipeUnauthorizedMessage;

  /// Message shown when the recipe to delete could not be found.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found.'**
  String get deleteRecipeNotFoundMessage;

  /// Subtitle shown under the user's name in the profile header.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to EasyBake'**
  String get profileHeaderGreetingSubtitle;

  /// Summary card title showing how many recipes the user has saved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved recipes} =1{1 saved recipe} other{{count} saved recipes}}'**
  String summaryCardSavedRecipes(num count);

  /// Subtitle shown on the profile summary card.
  ///
  /// In en, this message translates to:
  /// **'Your personal recipe collection'**
  String get summaryCardSubtitle;

  /// Title shown at the top of the dashboard page.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// Subtitle shown under the dashboard title.
  ///
  /// In en, this message translates to:
  /// **'Your recipes and health trends at a glance.'**
  String get dashboardSubtitle;

  /// Title for the recent recipes section on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'My Recipes'**
  String get myRecipesLabel;

  /// Label for the action that opens the full recipes list.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllLabel;

  /// Message shown when the dashboard has no recipes to display.
  ///
  /// In en, this message translates to:
  /// **'Create your first recipe or jump into the Recipes tab.'**
  String get dashboardNoRecipesSubtitle;

  /// Title for the health statistics section on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Health Statistics'**
  String get healthStatisticsLabel;

  /// Title shown when there is no health data yet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dashboardNoHealthStatsTitle;

  /// Subtitle shown when there is no health data yet.
  ///
  /// In en, this message translates to:
  /// **'Add recipes and the health breakdown will appear here.'**
  String get dashboardNoHealthStatsSubtitle;

  /// Label showing how many recipes are in a section.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipe} other{{count} recipes}}'**
  String recipeCountLabel(num count);

  /// Label showing how many ingredients are in a section.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
  String ingredientCountLabel(num count);

  /// Loading message shown while summary card data is being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading your recipe summary...'**
  String get summaryCardLoadingMessage;

  /// Message shown when the profile summary card cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Recipe summary unavailable right now'**
  String get summaryCardUnavailableMessage;

  /// Label for the logout button on the profile page.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButtonShortLabel;

  /// Title shown at the top of the recipe creation popup.
  ///
  /// In en, this message translates to:
  /// **'Create Your Recipe'**
  String get createRecipeModalTitle;

  /// Title shown at the top of the AI chef chat popup.
  ///
  /// In en, this message translates to:
  /// **'EasyBake AI Chef'**
  String get aiChefPopupTitle;

  /// Subtitle shown under the AI chef popup title.
  ///
  /// In en, this message translates to:
  /// **'Chat assistant'**
  String get aiChefPopupSubtitle;

  /// Status pill text shown while checking connection in the AI chef popup.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get aiChefPopupCheckingLabel;

  /// Button text used to refresh the AI chef popup connection.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get aiChefPopupRefreshLabel;

  /// Greeting shown by the AI chef popup when the user has no display name.
  ///
  /// In en, this message translates to:
  /// **'How can I help you?'**
  String get aiChefGreetingWithoutName;

  /// Greeting shown by the AI chef popup when the user has a display name.
  ///
  /// In en, this message translates to:
  /// **'Hello {displayName}!\nHow can I help you?'**
  String aiChefGreetingWithName(Object displayName);

  /// Message shown when the AI chef service is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Recipe service is currently unavailable. Please tap Refresh and try again.'**
  String get aiChefServiceUnavailableMessage;

  /// Message shown when the AI chef starts creating a recipe.
  ///
  /// In en, this message translates to:
  /// **'Sure! I am creating the recipe for you'**
  String get aiChefCreatingRecipeMessage;

  /// Fallback error message shown in the AI chef chat.
  ///
  /// In en, this message translates to:
  /// **'I\'m sorry, it seems like something went wrong 😞, try to ask me again please!'**
  String get aiChefGenericErrorMessage;

  /// Error shown when the user submits an empty AI chef message.
  ///
  /// In en, this message translates to:
  /// **'Please type a message first.'**
  String get aiChefErrorPleaseTypeMessageFirst;

  /// Error shown when the app cannot send an AI chef message.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message. Please try again.'**
  String get aiChefErrorCouldNotSendMessage;

  /// Error shown when the AI chef server returns an empty response.
  ///
  /// In en, this message translates to:
  /// **'Empty response from server.'**
  String get aiChefErrorEmptyResponse;

  /// Error shown when a streamed AI chef response is interrupted.
  ///
  /// In en, this message translates to:
  /// **'Stream interrupted. Please try again.'**
  String get aiChefErrorStreamInterrupted;

  /// Error shown when the assistant could not complete a response.
  ///
  /// In en, this message translates to:
  /// **'The assistant could not complete this response.'**
  String get aiChefErrorAssistantCouldNotComplete;

  /// Error shown when the app cannot read the AI chef server response.
  ///
  /// In en, this message translates to:
  /// **'Could not read server response. Please try again.'**
  String get aiChefErrorCouldNotReadServerResponse;

  /// Error shown when the AI chef server response is in an unsupported format.
  ///
  /// In en, this message translates to:
  /// **'Response received in an unsupported format.'**
  String get aiChefErrorResponseUnsupportedFormat;

  /// Error shown when the AI chef server response format is unexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response format from server.'**
  String get aiChefErrorUnexpectedResponseFormat;

  /// Error shown when the AI chef server response cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse server response.'**
  String get aiChefErrorFailedToParseServerResponse;

  /// Fallback error shown when an AI chef request fails.
  ///
  /// In en, this message translates to:
  /// **'Request failed. Please try again.'**
  String get aiChefErrorRequestFailed;

  /// Error shown when the AI chef server is slow to respond.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long to respond. Please try again in a moment.'**
  String get aiChefErrorServerSlow;

  /// Error shown when the AI chef server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server right now. Please check your connection and try again.'**
  String get aiChefErrorCannotReachServer;

  /// Error shown when the AI chef request is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled. Please try again.'**
  String get aiChefErrorRequestCancelled;

  /// Error shown when the user's session has expired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get aiChefErrorUnauthorized;

  /// Error shown when the server has an issue handling the request.
  ///
  /// In en, this message translates to:
  /// **'The server hit an issue while handling your request. Please try again shortly.'**
  String get aiChefErrorServerIssue;

  /// Error shown when the requested item cannot be found.
  ///
  /// In en, this message translates to:
  /// **'I could not find what you requested. Please try again.'**
  String get aiChefErrorNotFound;

  /// Error shown when the AI chef service is rate limited or busy.
  ///
  /// In en, this message translates to:
  /// **'I am a bit busy right now. Please try again in a few seconds.'**
  String get aiChefErrorRateLimited;

  /// Error shown when the user's message failed validation.
  ///
  /// In en, this message translates to:
  /// **'I could not process that message. Please rephrase and try again.'**
  String get aiChefErrorValidation;

  /// Generic fallback error shown for AI chef failures.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get aiChefErrorGeneric;

  /// Title shown above suggested substitutions in the AI chef chat.
  ///
  /// In en, this message translates to:
  /// **'Suggested substitutions'**
  String get aiChefSuggestedSubstitutionsTitle;

  /// Fallback label used when the AI chef creates a recipe without a title.
  ///
  /// In en, this message translates to:
  /// **'your recipe'**
  String get aiChefYourRecipeFallback;

  /// Message shown when the AI chef chat reconnects successfully.
  ///
  /// In en, this message translates to:
  /// **'Connection restored. You can continue chatting.'**
  String get aiChefConnectionRestoredMessage;

  /// Message shown after the app saves a recipe from the AI chef chat.
  ///
  /// In en, this message translates to:
  /// **'Great! I\'ve saved your recipe: {recipeName}'**
  String aiChefRecipeSavedConfirmation(Object recipeName);

  /// Ingredient count label shown on each recipe tile in the share recipe dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No ingredients} =1{1 ingredient} other{{count} ingredients}}'**
  String shareRecipeIngredientsCount(num count);

  /// No description provided for @preferencesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSectionTitle;

  /// No description provided for @customizeYourExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get customizeYourExperienceSubtitle;

  /// Title for the language selection section in Preferences.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// Label for choosing the system default language option.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefaultLabel;

  /// Label for choosing English language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishLabel;

  /// Label for choosing Hebrew language.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageHebrewLabel;

  /// No description provided for @healthyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy Mode'**
  String get healthyModeTitle;

  /// No description provided for @healthyModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show health badges on recipe cards'**
  String get healthyModeSubtitle;

  /// Label shown on recipe cards for high health scores.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthyBadgeLabel;

  /// Label shown on recipe cards for medium health scores.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageBadgeLabel;

  /// Label shown on recipe cards for low health scores.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get unhealthyBadgeLabel;

  /// Greeting shown when welcoming the signed-in user.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}!'**
  String welcomeUser(Object username);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
