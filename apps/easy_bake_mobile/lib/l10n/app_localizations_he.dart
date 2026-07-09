// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'EasyBake';

  @override
  String get communityChatTooltip => 'צ\'אט קהילתי';

  @override
  String get communityChatLabel => 'צ\'אט';

  @override
  String get communityChatHeaderTitle => 'צ\'אט קהילתי';

  @override
  String get communityChatHeaderSubtitle => 'קהילת האופים';

  @override
  String get composerConnectingHint => 'מתחבר לצ\'אט הקהילתי...';

  @override
  String get composerShareHint => 'שתף את הקהילה...';

  @override
  String get composerOfflineHint => 'הצ\'אט לא מקוון כרגע';

  @override
  String get shareRecipeWithCommunityLabel => 'שתף מתכון עם הקהילה';

  @override
  String get connectToShareRecipesLabel => 'התחבר כדי לשתף מתכונים';

  @override
  String get connectionPillConnectingLabel => 'מתחבר...';

  @override
  String get connectionPillOnlineLabel => 'מקוון';

  @override
  String get connectionPillOfflineLabel => 'לא מקוון';

  @override
  String get homeTooltip => 'בית';

  @override
  String get homeLabel => 'בית';

  @override
  String get recipesLabel => 'מתכונים';

  @override
  String get shoppingListLabel => 'רשימת קניות';

  @override
  String get profileTooltip => 'פרופיל';

  @override
  String get profileLabel => 'פרופיל';

  @override
  String get signInLabel => 'כניסה';

  @override
  String get registerLabel => 'הרשמה';

  @override
  String get fullNameHint => 'שם מלא';

  @override
  String get emailHint => 'אימייל';

  @override
  String get emailAddressHint => 'כתובת אימייל';

  @override
  String get passwordHint => 'סיסמה';

  @override
  String get confirmPasswordHint => 'אישור סיסמה';

  @override
  String get nextButtonLabel => 'הבא';

  @override
  String get signInErrorInvalidEmail => 'הכנס כתובת אימייל תקינה';

  @override
  String get signInErrorMinPasswordLength => 'לפחות 8 תווים';

  @override
  String get registerErrorNameRequired => 'אנא הזן את שמך';

  @override
  String get registerErrorNameTooShort => 'השם חייב להכיל לפחות 2 תווים';

  @override
  String get registerErrorEmailRequired => 'אנא הזן את כתובת האימייל שלך';

  @override
  String get registerErrorEmailInvalid => 'אנא הזן כתובת אימייל תקינה';

  @override
  String get registerErrorPasswordRequired => 'אנא הזן סיסמה';

  @override
  String get registerErrorPasswordMinLength => 'לפחות 8 תווים';

  @override
  String get registerErrorConfirmPasswordRequired => 'אנא אשר את הסיסמה שלך';

  @override
  String get registerErrorPasswordMismatch => 'הסיסמאות אינן תואמות';

  @override
  String registerStepIndicatorLabel(Object current, Object total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get gotItButtonLabel => 'הבנתי';

  @override
  String get authWrongCredentialsTitle => 'פרטי הכניסה שגויים';

  @override
  String get authWrongCredentialsMessage =>
      'כתובת האימייל או הסיסמה שגויים. נסה שוב.';

  @override
  String get authGenericErrorTitle => 'אופס! משהו השתבש';

  @override
  String get authRetrySoonMessage => 'נסה שוב בעוד רגע.';

  @override
  String get authUnexpectedErrorMessage => 'אירעה שגיאה לא צפויה. נסה שוב.';

  @override
  String get emailAlreadyExistsTitle => 'האימייל כבר קיים';

  @override
  String get emailAlreadyExistsMessage =>
      'משתמש עם כתובת האימייל הזו כבר רשום.';

  @override
  String get logoutTitle => 'לצאת מהחשבון?';

  @override
  String get logoutMessage => 'האם אתה בטוח שברצונך לצאת מ-EasyBake?';

  @override
  String get cancelButtonLabel => 'ביטול';

  @override
  String get logoutButtonLabel => 'יציאה';

  @override
  String get profilePageTitle => 'פרופיל';

  @override
  String get easyBakeUserFallback => 'משתמש EasyBake';

  @override
  String get askAiChefHint => 'שאל את שף ה-AI';

  @override
  String get viewRecipeButtonLabel => 'הצג מתכון';

  @override
  String get couldNotCreateRecipeTitle => 'לא ניתן ליצור מתכון';

  @override
  String get couldNotCreateRecipeMessage =>
      'לא הצלחנו ליצור מתכון מהתמונה הזו. נסה שוב או השתמש בתמונה אחרת.';

  @override
  String get okButtonLabel => 'אישור';

  @override
  String get uploadFromGalleryLabel => 'העלאה מהגלריה';

  @override
  String get takeAPictureLabel => 'צלם תמונה';

  @override
  String get recipeTitleHint => 'כותרת המתכון';

  @override
  String get uploadRecipeImageTitle => 'העלאת תמונת מתכון';

  @override
  String get uploadRecipeImageSubtitle => 'גלריה או מצלמה';

  @override
  String recipeIngredientHint(Object index) {
    return 'רכיב #$index';
  }

  @override
  String get recipeIngredientAmountHint => 'כמות';

  @override
  String get recipeIngredientAmountExampleHint =>
      'כמות (למשל 200 גרם, 120 ml, 2)';

  @override
  String recipeInstructionHint(Object index) {
    return 'שלב הוראות #$index';
  }

  @override
  String recipeItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פריטים',
      one: 'פריט אחד',
      zero: 'אין פריטים',
    );
    return '$_temp0';
  }

  @override
  String get creatingYourRecipeMessage => 'יוצר את המתכון שלך...';

  @override
  String get recipeCannotBeDeletedYetMessage =>
      'אי אפשר למחוק את המתכון הזה עדיין.';

  @override
  String get deleteRecipeTitle => 'למחוק את המתכון?';

  @override
  String get deleteRecipeMessage =>
      'הפעולה הזו אינה ניתנת לביטול. האם למחוק את המתכון הזה?';

  @override
  String get deleteButtonLabel => 'מחיקה';

  @override
  String get recipeNotFoundMessage => 'המתכון לא נמצא. ייתכן שכבר נמחק.';

  @override
  String get couldNotDeleteRecipeMessage =>
      'לא ניתן היה למחוק את המתכון. נסה שוב.';

  @override
  String get requestTimedOutMessage => 'תם הזמן הקצוב לבקשה. נסה שוב.';

  @override
  String get couldNotSaveRecipeMessage =>
      'לא ניתן היה לשמור את המתכון. נסה שוב.';

  @override
  String get communityChatFailureHint =>
      'אפשר לנסות שוב מאוחר יותר או לרענן את הצ\'אט.';

  @override
  String get communityChatUnavailableTitle => 'הצ\'אט הקהילתי אינו זמין';

  @override
  String get communityChatUnavailableMessage =>
      'הצ\'אט הקהילתי אינו זמין כרגע. רענן או נסה שוב מאוחר יותר.';

  @override
  String get communityChatRefreshFailedMessage =>
      'לא ניתן לרענן את הצ\'אט הקהילתי כרגע. נסה שוב מאוחר יותר.';

  @override
  String get communityChatIdentityMessage =>
      'לא ניתן לזהות את החשבון שלך לצ\'אט.';

  @override
  String get communityChatSendFailedMessage =>
      'לא ניתן לשלוח את ההודעה כרגע. נסה שוב מאוחר יותר.';

  @override
  String get communityChatEmptyTitle => 'אין עדיין הודעות';

  @override
  String get communityChatEmptySubtitle => 'התחל את השיחה בחדר הזה.';

  @override
  String get communityChatOfflineTitle => 'הצ\'אט הקהילתי לא מקוון';

  @override
  String get communityChatOfflineSubtitle =>
      'משוך מטה לרענון כדי לנסות להתחבר שוב ולראות הודעות שוב.';

  @override
  String get recipePreviewUnavailableTitle => 'תצוגת המתכון אינה זמינה';

  @override
  String get recipePreviewNoLongerAvailableMessage =>
      'המתכון המשותף הזה כבר אינו זמין.';

  @override
  String get recipePreviewRefreshHint =>
      'משוך מטה לרענון הצ\'אט כדי לנסות לטעון שוב את המתכון המשותף.';

  @override
  String get laterButtonLabel => 'מאוחר יותר';

  @override
  String get refreshButtonLabel => 'רענון';

  @override
  String get tryAgainButtonLabel => 'נסה שוב';

  @override
  String get searchRecipesHint => 'חיפוש מתכונים...';

  @override
  String get chooseShareMethodSubtitle =>
      'בחר איך תרצה לשתף את היצירה הקולינרית שלך';

  @override
  String get createRecipeManuallyTitle => 'יצירת מתכון ידנית';

  @override
  String get createRecipeManuallySubtitle => 'הוסף את המתכון שלך שלב אחר שלב';

  @override
  String get aiMagicPhotoToRecipeTitle => 'קסם בינה מלאכותית: תמונה למתכון';

  @override
  String get aiMagicPhotoToRecipeSubtitle =>
      'הבינה המלאכותית סורקת את התמונה שלך ובונה את המתכון';

  @override
  String get createRecipeHeaderCreateTitle => 'יצירת מתכון חדש';

  @override
  String get createRecipeHeaderEditTitle => 'עריכת מתכון';

  @override
  String get createRecipeHeaderCreateSubtitle => 'שתף את היצירה הקולינרית שלך';

  @override
  String get createRecipeHeaderEditSubtitle => 'עדכן את היצירה הקולינרית שלך';

  @override
  String get replaceButtonLabel => 'החלפה';

  @override
  String get shareRecipeTitle => 'שתף מתכון';

  @override
  String get shareRecipeSubtitle => 'בחר אחד מהמתכונים שלך כדי לשלוח לקהילה.';

  @override
  String get closeTooltip => 'סגירה';

  @override
  String get couldNotLoadRecipesRightNowMessage =>
      'לא ניתן לטעון את המתכונים שלך כרגע.';

  @override
  String get noRecipesYetMessage => 'אין לך עדיין מתכונים לשתף כאן.';

  @override
  String get noRecipesFoundTitle => 'לא נמצאו מתכונים';

  @override
  String get noRecipesFoundSubtitle =>
      'אפשר להשתמש בצ\'אט של שף ה-AI כדי לחפש מתכונים סמנטית.';

  @override
  String get noRecipesYetTitle => 'אוסף המתכונים שלך ריק';

  @override
  String get noRecipesYetSubtitle =>
      'לחץ על כפתור + כדי להוסיף את המתכון הראשון שלך, או השתמש ב-AI כדי ליצור אחד עבורך.';

  @override
  String get viewButtonLabel => 'צפייה';

  @override
  String get saveButtonLabel => 'שמירה';

  @override
  String get ingredientsTabLabel => 'רכיבים';

  @override
  String get instructionsTabLabel => 'הוראות';

  @override
  String get recipeActionsTooltip => 'פעולות מתכון';

  @override
  String get editActionLabel => 'עריכה';

  @override
  String get updateRecipeSubtitle => 'עדכן כותרת, תמונה או שלבים';

  @override
  String get deleteActionLabel => 'מחיקה';

  @override
  String get removeRecipePermanentlySubtitle => 'הסר את המתכון הזה לצמיתות';

  @override
  String get customScaleTitle => 'קנה מידה מותאם';

  @override
  String get enterDesiredScaleHint => 'הזן את הקנה מידה הרצוי';

  @override
  String get applyButtonLabel => 'החלה';

  @override
  String get noIngredientsAvailableMessage => 'אין רכיבים זמינים.';

  @override
  String get backButtonLabel => 'חזרה';

  @override
  String get chatDisplayNameLabel => 'שם תצוגה בצ\'אט';

  @override
  String get enterChatDisplayNameHint => 'הזן את שם התצוגה שלך בצ\'אט';

  @override
  String get chatDisplayNameDescription => 'זה השם שמוצג בצ\'אט הקהילתי';

  @override
  String get usingFullProfileNameByDefaultMessage =>
      'משתמש בשם הפרופיל המלא שלך כברירת מחדל';

  @override
  String get editTooltip => 'עריכה';

  @override
  String get cancelTooltip => 'ביטול';

  @override
  String get saveTooltip => 'שמירה';

  @override
  String get savingYourRecipeMessage => 'שומר את המתכון שלך...';

  @override
  String get recipeSavedMessage => 'המתכון נשמר';

  @override
  String get deletingYourRecipeMessage => 'מוחק את המתכון שלך...';

  @override
  String get recipeDeletedMessage => 'המתכון נמחק';

  @override
  String get shoppingListPageTitle => 'רשימת קניות';

  @override
  String get shoppingListPageSubtitle =>
      'תכונה עתידית: ניהול רשימות קניות יופיע כאן.';

  @override
  String get shoppingListFutureDetails =>
      'אזור זה שמור לכלים עתידיים של רשימות קניות, רשימות מכולת שמורות ומעקב אחר רכיבים.';

  @override
  String get shoppingListAddItemTitle => 'הוספת פריט';

  @override
  String get shoppingListIngredientNameHint => 'שם הרכיב';

  @override
  String get shoppingListIngredientAmountHint =>
      'כמות (למשל 2, 200 גרם, כוס אחת)';

  @override
  String get addButtonLabel => 'הוספה';

  @override
  String get shoppingListItemAddedMessage => 'הפריט נוסף לרשימת הקניות';

  @override
  String get shoppingListItemAddFailedMessage =>
      'הוספת הפריט לרשימת הקניות נכשלה';

  @override
  String get shoppingListLoadFailedMessage => 'טעינת רשימת הקניות נכשלה';

  @override
  String get shoppingListEditItemTitle => 'עריכת פריט';

  @override
  String get shoppingListItemUpdatedMessage => 'הפריט עודכן בהצלחה';

  @override
  String get shoppingListItemUpdateFailedMessage => 'עדכון הפריט נכשל';

  @override
  String get shoppingListItemDeletedMessage => 'הפריט נמחק';

  @override
  String get shoppingListItemDeleteFailedMessage => 'מחיקת הפריט נכשלה';

  @override
  String get confirmDeleteShoppingListItemMessage =>
      'האם אתה בטוח שברצונך למחוק את הפריט הזה?';

  @override
  String get deletingShoppingListItemMessage => 'מוחק פריט...';

  @override
  String get shoppingListEmptyTitle => 'רשימת הקניות שלך ריקה';

  @override
  String get shoppingListEmptySubtitle =>
      'הקישו על כפתור ה-+ למטה כדי להוסיף פריטים לרשימה.';

  @override
  String get shoppingListEmptyBackLabel => 'חזרה';

  @override
  String get cookingStepsTitle => 'שלבי הבישול';

  @override
  String get doneLabel => 'סיום';

  @override
  String get recipeScalesTitle => 'כמויות';

  @override
  String get customScaleButtonLabel => 'מותאם אישית';

  @override
  String get timerKitchenTitle => 'טיימר למטבח';

  @override
  String get timerKitchenSubtitle => 'מושלם להתפחה, למנוחה ולאפייה';

  @override
  String get timerCustomButtonLabel => 'מותאם אישית';

  @override
  String get timerSetCustomTitle => 'הגדרת טיימר מותאם';

  @override
  String get timerCompleteTitle => 'הטיימר הסתיים!';

  @override
  String get timerCompleteMessage => 'השלב שלך מוכן לפעולה הבאה.';

  @override
  String get timerCompleteButtonLabel => 'מעולה';

  @override
  String get timerNotificationTitle => 'הטיימר של EasyBake הסתיים';

  @override
  String get timerNotificationBody => 'הטיימר הסתיים. בדוק את שלב המתכון שלך.';

  @override
  String get timerOpenTooltip => 'פתיחת טיימר';

  @override
  String get timerCloseTooltip => 'סגירת טיימר';

  @override
  String get timerStartButtonLabel => 'התחלה';

  @override
  String get timerPauseButtonLabel => 'השהיה';

  @override
  String get timerResetButtonLabel => 'איפוס';

  @override
  String get timerHourUnitShort => 'ש׳';

  @override
  String get timerMinuteUnitShort => 'דק׳';

  @override
  String get timerSecondUnitShort => 'שנ׳';

  @override
  String get confirmDeleteRecipeMessage =>
      'האם אתה בטוח שברצונך למחוק את המתכון הזה?';

  @override
  String get saveRecipeConfirmationMessage => 'האם לשמור את המתכון הזה?';

  @override
  String get deleteRecipeMissingIdMessage => 'לא ניתן למחוק: מזהה המתכון חסר';

  @override
  String get deleteRecipeUnauthorizedMessage =>
      'אין הרשאה. בדוק את הגדרות האפליקציה.';

  @override
  String get deleteRecipeNotFoundMessage => 'המתכון לא נמצא.';

  @override
  String get profileHeaderGreetingSubtitle => 'ברוך שובך ל-EasyBake';

  @override
  String summaryCardSavedRecipes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מתכונים שמורים',
      one: 'מתכון שמור אחד',
      zero: 'אין מתכונים שמורים',
    );
    return '$_temp0';
  }

  @override
  String get summaryCardSubtitle => 'אוסף המתכונים האישי שלך';

  @override
  String get dashboardLabel => 'לוח בקרה';

  @override
  String get dashboardSubtitle => 'המתכונים והבריאות שלך במבט אחד.';

  @override
  String get myRecipesLabel => 'המתכונים שלי';

  @override
  String get seeAllLabel => 'הצג הכול';

  @override
  String get dashboardNoRecipesSubtitle =>
      'צרו את המתכון הראשון או עברו ללשונית המתכונים.';

  @override
  String get healthStatisticsLabel => 'סטטיסטיקות בריאות';

  @override
  String get dashboardNoHealthStatsTitle => 'אין עדיין נתונים';

  @override
  String get dashboardNoHealthStatsSubtitle =>
      'הוסיפו מתכונים ואז תופיע כאן התפלגות הבריאות.';

  @override
  String recipeCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מתכונים',
      one: 'מתכון אחד',
    );
    return '$_temp0';
  }

  @override
  String ingredientCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count רכיבים',
      one: 'רכיב אחד',
    );
    return '$_temp0';
  }

  @override
  String get summaryCardLoadingMessage => 'טוען את סיכום המתכונים שלך...';

  @override
  String get summaryCardUnavailableMessage => 'סיכום המתכונים אינו זמין כרגע';

  @override
  String get logoutButtonShortLabel => 'יציאה';

  @override
  String get createRecipeModalTitle => 'יצירת המתכון שלך';

  @override
  String get aiChefPopupTitle => 'שף ה-AI של EasyBake';

  @override
  String get aiChefPopupSubtitle => 'עוזר הצ\'אט';

  @override
  String get aiChefPopupCheckingLabel => 'בודק...';

  @override
  String get aiChefPopupRefreshLabel => 'רענון';

  @override
  String get aiChefGreetingWithoutName => 'איך אני יכול לעזור לך?';

  @override
  String aiChefGreetingWithName(Object displayName) {
    return 'שלום $displayName!\nאיך אני יכול לעזור לך?';
  }

  @override
  String get aiChefServiceUnavailableMessage =>
      'שירות המתכונים אינו זמין כרגע. לחץ על רענון ונסה שוב.';

  @override
  String get aiChefCreatingRecipeMessage => 'בטח! אני יוצר את המתכון עבורך';

  @override
  String get aiChefGenericErrorMessage =>
      'מצטער, נראה שמשהו השתבש 😞. אנא נסה לשאול אותי שוב בבקשה!';

  @override
  String get aiChefErrorPleaseTypeMessageFirst => 'אנא הקלד הודעה קודם.';

  @override
  String get aiChefErrorCouldNotSendMessage =>
      'לא ניתן היה לשלוח את ההודעה שלך. נסה שוב.';

  @override
  String get aiChefErrorEmptyResponse => 'התקבלה תשובה ריקה מהשרת.';

  @override
  String get aiChefErrorStreamInterrupted => 'הזרם הופסק. נסה שוב.';

  @override
  String get aiChefErrorAssistantCouldNotComplete =>
      'העוזר לא הצליח להשלים את התשובה הזו.';

  @override
  String get aiChefErrorCouldNotReadServerResponse =>
      'לא ניתן היה לקרוא את תגובת השרת. נסה שוב.';

  @override
  String get aiChefErrorResponseUnsupportedFormat =>
      'התגובה התקבלה בפורמט שאינו נתמך.';

  @override
  String get aiChefErrorUnexpectedResponseFormat =>
      'פורמט תגובת השרת אינו צפוי.';

  @override
  String get aiChefErrorFailedToParseServerResponse =>
      'לא ניתן היה לנתח את תגובת השרת.';

  @override
  String get aiChefErrorRequestFailed => 'הבקשה נכשלה. נסה שוב.';

  @override
  String get aiChefErrorServerSlow =>
      'לשרת לוקח זמן רב מדי להגיב. נסה שוב בעוד רגע.';

  @override
  String get aiChefErrorCannotReachServer =>
      'לא ניתן להגיע לשרת כרגע. בדוק את החיבור ונסה שוב.';

  @override
  String get aiChefErrorRequestCancelled => 'הבקשה בוטלה. נסה שוב.';

  @override
  String get aiChefErrorUnauthorized => 'פג תוקף ההתחברות שלך. היכנס שוב.';

  @override
  String get aiChefErrorServerIssue =>
      'אירעה בעיה בשרת בעת טיפול בבקשה שלך. נסה שוב בקרוב.';

  @override
  String get aiChefErrorNotFound => 'לא הצלחתי למצוא את מה שביקשת. נסה שוב.';

  @override
  String get aiChefErrorRateLimited =>
      'אני קצת עסוק כרגע. נסה שוב בעוד כמה שניות.';

  @override
  String get aiChefErrorValidation =>
      'לא הצלחתי לעבד את ההודעה הזו. נסח מחדש ונסה שוב.';

  @override
  String get aiChefErrorGeneric => 'משהו השתבש אצלנו. נסה שוב.';

  @override
  String get aiChefSuggestedSubstitutionsTitle => 'החלפות מוצעות';

  @override
  String get aiChefYourRecipeFallback => 'המתכון שלך';

  @override
  String get aiChefConnectionRestoredMessage =>
      'החיבור שוחזר. אפשר להמשיך לשוחח.';

  @override
  String aiChefRecipeSavedConfirmation(Object recipeName) {
    return 'מעולה! שמרתי את המתכון שלך: $recipeName';
  }

  @override
  String get aiChefAddingToShoppingListMessage =>
      'בטח! אוסיף את הפריטים לרשימת הקניות שלך';

  @override
  String get aiChefShoppingListAddedTitle =>
      'הוספתי את הפריטים הבאים לרשימת הקניות שלך:';

  @override
  String get aiChefNavigateToShoppingListButton => 'לצפייה ברשימת הקניות';

  @override
  String shareRecipeIngredientsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count רכיבים',
      one: 'רכיב אחד',
      zero: 'אין רכיבים',
    );
    return '$_temp0';
  }

  @override
  String get preferencesSectionTitle => 'העדפות';

  @override
  String get customizeYourExperienceSubtitle => 'התאם את החוויה שלך';

  @override
  String get languageSectionTitle => 'שפה';

  @override
  String get languageSystemDefaultLabel => 'ברירת מערכת';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageHebrewLabel => 'עברית';

  @override
  String get healthyModeTitle => 'מצב בריא';

  @override
  String get healthyModeSubtitle => 'הצג תגי בריאות בכרטיסי מתכונים';

  @override
  String get healthyBadgeLabel => 'בריא';

  @override
  String get averageBadgeLabel => 'בינוני';

  @override
  String get unhealthyBadgeLabel => 'לא בריא';

  @override
  String welcomeUser(Object username) {
    return 'ברוך הבא, $username!';
  }

  @override
  String get createFolderButtonLabel => 'צור תיקייה';

  @override
  String get newFolderDialogTitle => 'תיקייה חדשה';

  @override
  String get folderNameHint => 'שם התיקייה';

  @override
  String get deleteFolderTitle => 'למחוק את התיקייה?';

  @override
  String get deleteFolderOptionAllTitle => 'מחק את התיקייה ואת כל התוכן שלה';

  @override
  String get deleteFolderOptionAllMessage =>
      'פעולה זו תמחק את התיקייה, את כל תתי-התיקיות שלה ואת כל המתכונים שבתוכן.';

  @override
  String get deleteFolderOptionPopTitle =>
      'מחק את התיקייה בלבד (שמור על התוכן)';

  @override
  String get deleteFolderOptionPopMessage =>
      'פעולה זו תמחק רק את התיקייה. המתכונים ותתי-התיקיות יעברו רמה אחת למעלה.';

  @override
  String get moveRecipeDialogTitle => 'העברת מתכון';

  @override
  String get moveFolderDialogTitle => 'העברת תיקייה';

  @override
  String get moveToRootOption => 'ראשי (ללא תיקייה)';

  @override
  String get folderLabel => 'תיקייה';

  @override
  String get emptyFolderTitle => 'תיקייה זו ריקה';

  @override
  String get emptyFolderSubtitle =>
      'לחץ על כפתור ה-+ כדי להוסיף מתכון או ליצור תת-תיקייה.';

  @override
  String get moveButtonLabel => 'העבר';

  @override
  String get savingFolderMessage => 'שומר תיקייה...';

  @override
  String get folderSavedMessage => 'התיקייה נשמרה';

  @override
  String get deletingFolderMessage => 'מוחק תיקייה...';

  @override
  String get folderDeletedMessage => 'התיקייה נמחקה';

  @override
  String movingRecipeMessage(Object folderName) {
    return 'מעביר מתכון ל-$folderName...';
  }

  @override
  String get recipeMovedMessage => 'המתכון הועבר';

  @override
  String movingFolderMessage(Object folderName) {
    return 'מעביר תיקייה ל-$folderName...';
  }

  @override
  String get folderMovedMessage => 'התיקייה הועברה';

  @override
  String get deleteFolderConfirmationMessage =>
      'האם אתה בטוח שברצונך למחוק תיקייה זו?';

  @override
  String get foldersHeaderLabel => 'תיקיות';

  @override
  String get recipesHeaderLabel => 'מתכונים';
}
