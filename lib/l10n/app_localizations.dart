import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TANDAU'**
  String get appTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the right path to your future'**
  String get homeSubtitle;

  /// No description provided for @ctaStart.
  ///
  /// In en, this message translates to:
  /// **'Start Choosing'**
  String get ctaStart;

  /// No description provided for @statsUniversity.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get statsUniversity;

  /// No description provided for @statsStudent.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get statsStudent;

  /// No description provided for @statsGraduates.
  ///
  /// In en, this message translates to:
  /// **'Graduates'**
  String get statsGraduates;

  /// No description provided for @statsSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get statsSpecialty;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settingsAbout;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @dialogLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get dialogLanguageTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get navAgent;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TANDAU!'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join TANDAU and start your educational journey'**
  String get authSubtitle;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get authWelcomeBack;

  /// No description provided for @authLoginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get authLoginToAccount;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhone;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccount;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authDontHaveAccount;

  /// No description provided for @authRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterNow;

  /// No description provided for @authLoginNow.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginNow;

  /// No description provided for @authGuestLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authGuestLogin;

  /// No description provided for @authGoogleLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get authGoogleLogin;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authErrorRegister.
  ///
  /// In en, this message translates to:
  /// **'Registration error. Try again.'**
  String get authErrorRegister;

  /// No description provided for @authErrorLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorLogin;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout from account'**
  String get authLogout;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search University...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Universities not found'**
  String get searchNoResults;

  /// No description provided for @searchTryOthers.
  ///
  /// In en, this message translates to:
  /// **'Try other filters'**
  String get searchTryOthers;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get filterNext;

  /// No description provided for @filterShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get filterShowResults;

  /// No description provided for @filterCity.
  ///
  /// In en, this message translates to:
  /// **'Which City?'**
  String get filterCity;

  /// No description provided for @filterCitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the city where you want to study'**
  String get filterCitySubtitle;

  /// No description provided for @filterMajor.
  ///
  /// In en, this message translates to:
  /// **'Which Major?'**
  String get filterMajor;

  /// No description provided for @filterMajorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a major you are interested in'**
  String get filterMajorSubtitle;

  /// No description provided for @filterBudget.
  ///
  /// In en, this message translates to:
  /// **'What is your budget?'**
  String get filterBudget;

  /// No description provided for @filterBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select annual tuition fee range'**
  String get filterBudgetSubtitle;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterEducationType.
  ///
  /// In en, this message translates to:
  /// **'Education Type'**
  String get filterEducationType;

  /// No description provided for @filterGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get filterGrant;

  /// No description provided for @filterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get filterPaid;

  /// No description provided for @filterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price (per year)'**
  String get filterMaxPrice;

  /// No description provided for @filterPricePerYear.
  ///
  /// In en, this message translates to:
  /// **'Price per year'**
  String get filterPricePerYear;

  /// No description provided for @aiAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAgentTitle;

  /// No description provided for @aiAgentWelcome.
  ///
  /// In en, this message translates to:
  /// **'Need help choosing a university?\nAsk me a question!'**
  String get aiAgentWelcome;

  /// No description provided for @aiAgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I analyze thousands of universities to find your perfect match.'**
  String get aiAgentSubtitle;

  /// No description provided for @aiAgentInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a question...'**
  String get aiAgentInputHint;

  /// No description provided for @aiAgentSample1.
  ///
  /// In en, this message translates to:
  /// **'Which university is better?'**
  String get aiAgentSample1;

  /// No description provided for @aiAgentSample2.
  ///
  /// In en, this message translates to:
  /// **'Where are IT majors?'**
  String get aiAgentSample2;

  /// No description provided for @aiAgentSample3.
  ///
  /// In en, this message translates to:
  /// **'What is needed for a grant?'**
  String get aiAgentSample3;

  /// No description provided for @aiClearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get aiClearChat;

  /// No description provided for @aiAbout.
  ///
  /// In en, this message translates to:
  /// **'About TANDAU AI'**
  String get aiAbout;

  /// No description provided for @aiClearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History?'**
  String get aiClearDialogTitle;

  /// No description provided for @aiClearDialogContent.
  ///
  /// In en, this message translates to:
  /// **'All messages will be permanently deleted.'**
  String get aiClearDialogContent;

  /// No description provided for @aiClearDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get aiClearDialogConfirm;

  /// No description provided for @aiAboutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'I use advanced algorithms to analyze university data. My goal is to help you find the perfect place to study and assess your chances of admission.'**
  String get aiAboutDialogContent;

  /// No description provided for @aiAboutDialogButton.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get aiAboutDialogButton;

  /// No description provided for @aiTyping.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get aiTyping;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, an error occurred. Please try again later.'**
  String get aiError;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @majorIT.
  ///
  /// In en, this message translates to:
  /// **'IT'**
  String get majorIT;

  /// No description provided for @majorMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get majorMedicine;

  /// No description provided for @majorPedagogy.
  ///
  /// In en, this message translates to:
  /// **'Pedagogy'**
  String get majorPedagogy;

  /// No description provided for @majorEconomics.
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get majorEconomics;

  /// No description provided for @majorEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get majorEngineering;

  /// No description provided for @majorArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get majorArt;

  /// No description provided for @budgetOnlyGrants.
  ///
  /// In en, this message translates to:
  /// **'Only grants'**
  String get budgetOnlyGrants;

  /// No description provided for @budgetUpTo500k.
  ///
  /// In en, this message translates to:
  /// **'Up to 500k T'**
  String get budgetUpTo500k;

  /// No description provided for @budget1To2m.
  ///
  /// In en, this message translates to:
  /// **'1-2m T'**
  String get budget1To2m;

  /// No description provided for @budgetAny.
  ///
  /// In en, this message translates to:
  /// **'Not important'**
  String get budgetAny;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPassword;

  /// No description provided for @validationName.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationName;

  /// No description provided for @validationPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get validationPhone;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationNameLength.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be 3-20 characters'**
  String get validationNameLength;

  /// No description provided for @validationNameChars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers and _ allowed'**
  String get validationNameChars;

  /// No description provided for @validationEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get validationEmailFormat;

  /// No description provided for @validationTerms.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms and Conditions'**
  String get validationTerms;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure notifications'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information about TANDAU'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ and support'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsInProgress.
  ///
  /// In en, this message translates to:
  /// **'This feature is in development'**
  String get settingsInProgress;

  /// No description provided for @aboutContent.
  ///
  /// In en, this message translates to:
  /// **'TANDAU - is an application to help students choose a university.\n\nVersion: 1.0.0\n\n© 2026 TANDAU Team'**
  String get aboutContent;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// No description provided for @searchPopularCities.
  ///
  /// In en, this message translates to:
  /// **'Popular Cities'**
  String get searchPopularCities;

  /// No description provided for @searchDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get searchDepartments;

  /// No description provided for @navComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get navComparison;

  /// No description provided for @comparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'University Comparison'**
  String get comparisonTitle;

  /// No description provided for @comparisonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Comparison list is empty'**
  String get comparisonEmpty;

  /// No description provided for @comparisonEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add universities to compare their features'**
  String get comparisonEmptySubtitle;

  /// No description provided for @comparisonBrowseUniversities.
  ///
  /// In en, this message translates to:
  /// **'Browse Universities'**
  String get comparisonBrowseUniversities;

  /// No description provided for @comparisonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get comparisonClear;

  /// No description provided for @comparisonClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear comparison?'**
  String get comparisonClearTitle;

  /// No description provided for @comparisonClearMessage.
  ///
  /// In en, this message translates to:
  /// **'All universities will be removed from comparison'**
  String get comparisonClearMessage;

  /// No description provided for @comparisonClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all universities from comparison?'**
  String get comparisonClearConfirm;

  /// No description provided for @comparisonEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add universities from the list to start comparing'**
  String get comparisonEmptyHint;

  /// No description provided for @comparisonRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from comparison'**
  String get comparisonRemoved;

  /// No description provided for @comparisonAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to comparison'**
  String get comparisonAdded;

  /// No description provided for @comparisonFull.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} universities for comparison'**
  String comparisonFull(int max);

  /// No description provided for @comparisonInfo.
  ///
  /// In en, this message translates to:
  /// **'Comparing {count} of {max} universities'**
  String comparisonInfo(int count, int max);

  /// No description provided for @comparisonParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get comparisonParameters;

  /// No description provided for @comparisonParamName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get comparisonParamName;

  /// No description provided for @comparisonParamCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get comparisonParamCity;

  /// No description provided for @comparisonParamTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition Cost'**
  String get comparisonParamTuition;

  /// No description provided for @comparisonParamGrants.
  ///
  /// In en, this message translates to:
  /// **'Grants/Budget'**
  String get comparisonParamGrants;

  /// No description provided for @comparisonParamRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get comparisonParamRating;

  /// No description provided for @comparisonParamSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get comparisonParamSpecialties;

  /// No description provided for @comparisonParamDormitory.
  ///
  /// In en, this message translates to:
  /// **'Dormitory'**
  String get comparisonParamDormitory;

  /// No description provided for @comparisonParamStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get comparisonParamStudents;

  /// No description provided for @comparisonParamPassingScore.
  ///
  /// In en, this message translates to:
  /// **'Passing Score'**
  String get comparisonParamPassingScore;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @comparisonAddToCompare.
  ///
  /// In en, this message translates to:
  /// **'Add to Compare'**
  String get comparisonAddToCompare;

  /// No description provided for @comparisonComparing.
  ///
  /// In en, this message translates to:
  /// **'Comparing 2 Universities'**
  String get comparisonComparing;

  /// No description provided for @comparisonAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add one more university to compare'**
  String get comparisonAddMore;

  /// No description provided for @comparisonAddUniversity.
  ///
  /// In en, this message translates to:
  /// **'Add University'**
  String get comparisonAddUniversity;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to List'**
  String get backToList;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @tuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition'**
  String get tuition;

  /// No description provided for @grants.
  ///
  /// In en, this message translates to:
  /// **'Grants'**
  String get grants;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @specialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get specialties;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get delete;

  /// No description provided for @inDevelopment.
  ///
  /// In en, this message translates to:
  /// **'In Development'**
  String get inDevelopment;

  /// No description provided for @inDevelopmentMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development and will be available soon!'**
  String get inDevelopmentMessage;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabMajors.
  ///
  /// In en, this message translates to:
  /// **'Majors'**
  String get tabMajors;

  /// No description provided for @tabAdmissions.
  ///
  /// In en, this message translates to:
  /// **'Admissions'**
  String get tabAdmissions;

  /// No description provided for @tabContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get tabContact;

  /// No description provided for @tabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tabReviews;

  /// No description provided for @detailAbout.
  ///
  /// In en, this message translates to:
  /// **'About University'**
  String get detailAbout;

  /// No description provided for @detailTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition Fees'**
  String get detailTuition;

  /// No description provided for @detailPassingScore.
  ///
  /// In en, this message translates to:
  /// **'Passing Score'**
  String get detailPassingScore;

  /// No description provided for @detailDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get detailDocuments;

  /// No description provided for @detailDeadline.
  ///
  /// In en, this message translates to:
  /// **'Application Deadline'**
  String get detailDeadline;

  /// No description provided for @detailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get detailAddress;

  /// No description provided for @detailWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get detailWebsite;

  /// No description provided for @detailLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get detailLeaveReview;

  /// No description provided for @detailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get detailNoReviews;

  /// No description provided for @universityDormitory.
  ///
  /// In en, this message translates to:
  /// **'Dormitory'**
  String get universityDormitory;

  /// No description provided for @universityGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get universityGrant;

  /// No description provided for @universityMilitary.
  ///
  /// In en, this message translates to:
  /// **'Military Department'**
  String get universityMilitary;

  /// No description provided for @universityStudentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String universityStudentCount(int count);

  /// No description provided for @authGuestMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account to access all features'**
  String get authGuestMessage;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAge;

  /// No description provided for @profileEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileEducation;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileUntScore.
  ///
  /// In en, this message translates to:
  /// **'UNT Score'**
  String get profileUntScore;

  /// No description provided for @profileIeltsScore.
  ///
  /// In en, this message translates to:
  /// **'IELTS (optional)'**
  String get profileIeltsScore;

  /// No description provided for @profileErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Profile update failed'**
  String get profileErrorUpdate;

  /// No description provided for @profileErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile. Please retry.'**
  String get profileErrorLoad;

  /// No description provided for @authPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get authPleaseLogin;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @detailChances.
  ///
  /// In en, this message translates to:
  /// **'Estimate Chances'**
  String get detailChances;

  /// No description provided for @detailRequirementsHeader.
  ///
  /// In en, this message translates to:
  /// **'Admission Requirements'**
  String get detailRequirementsHeader;

  /// No description provided for @detailScorePoints.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get detailScorePoints;

  /// No description provided for @detailScoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on last year\'s data'**
  String get detailScoreSubtitle;

  /// No description provided for @detailPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get detailPhoneLabel;

  /// No description provided for @moderationSpam.
  ///
  /// In en, this message translates to:
  /// **'Too many messages. Please wait a moment.'**
  String get moderationSpam;

  /// No description provided for @moderationProfanity.
  ///
  /// In en, this message translates to:
  /// **'Please use respectful language. Profanity is not allowed.'**
  String get moderationProfanity;

  /// No description provided for @homeTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get homeTools;

  /// No description provided for @homeMarketInsights.
  ///
  /// In en, this message translates to:
  /// **'Market Insights'**
  String get homeMarketInsights;

  /// No description provided for @homeAIPowered.
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get homeAIPowered;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeChanceEstimation.
  ///
  /// In en, this message translates to:
  /// **'Chance Estimation'**
  String get homeChanceEstimation;

  /// No description provided for @homeChanceAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Grant Admission Analysis 2026'**
  String get homeChanceAnalysis;

  /// No description provided for @homeAdvancedFilter.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filter'**
  String get homeAdvancedFilter;

  /// No description provided for @homeUniversitySearch.
  ///
  /// In en, this message translates to:
  /// **'University Search'**
  String get homeUniversitySearch;

  /// No description provided for @homeUniversities.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get homeUniversities;

  /// No description provided for @homeNoUniversitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No universities found'**
  String get homeNoUniversitiesFound;

  /// No description provided for @homeYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your current score: {score}'**
  String homeYourScore(int score);

  /// No description provided for @homeAIAnalysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis...'**
  String get homeAIAnalysisInProgress;

  /// No description provided for @homeAIAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'TANDAU AI Analytics'**
  String get homeAIAnalyticsTitle;

  /// No description provided for @detailBeFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a review!'**
  String get detailBeFirstReview;

  /// No description provided for @reviewEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get reviewEdited;

  /// No description provided for @reviewAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to rate'**
  String get reviewAuthRequired;

  /// No description provided for @reviewHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful {count}'**
  String reviewHelpful(String count);

  /// No description provided for @reviewOfficialReply.
  ///
  /// In en, this message translates to:
  /// **'Official Reply'**
  String get reviewOfficialReply;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @aiChancesAnalytics.
  ///
  /// In en, this message translates to:
  /// **'SVD Analytics'**
  String get aiChancesAnalytics;

  /// No description provided for @aiChancesDataYear.
  ///
  /// In en, this message translates to:
  /// **'Data for {year}'**
  String aiChancesDataYear(String year);

  /// No description provided for @aiChancesGrant.
  ///
  /// In en, this message translates to:
  /// **'chance for grant'**
  String get aiChancesGrant;

  /// No description provided for @aiChancesRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk: {risk}'**
  String aiChancesRisk(String risk);

  /// No description provided for @aiChancesEntThreshold.
  ///
  /// In en, this message translates to:
  /// **'UNT Threshold for this major: {score} points'**
  String aiChancesEntThreshold(int score);

  /// No description provided for @aiChancesDetails.
  ///
  /// In en, this message translates to:
  /// **'Calculation Details'**
  String get aiChancesDetails;

  /// No description provided for @aiChancesDetailedStrategy.
  ///
  /// In en, this message translates to:
  /// **'Detailed AI Strategy'**
  String get aiChancesDetailedStrategy;

  /// No description provided for @detailErrorFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorites'**
  String get detailErrorFavorites;

  /// No description provided for @aiStrategyTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Strategy'**
  String get aiStrategyTitle;

  /// No description provided for @aiStrategyGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {university}'**
  String aiStrategyGoal(String university);

  /// No description provided for @aiStrategyAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternative Options'**
  String get aiStrategyAlternatives;

  /// No description provided for @aiStrategyUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get aiStrategyUniversity;

  /// No description provided for @aiStrategySpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get aiStrategySpecialty;

  /// No description provided for @aiStrategyLoading.
  ///
  /// In en, this message translates to:
  /// **'Collecting data and analyzing chances for {university}...\nFind out which topics to improve to guarantee a grant!'**
  String aiStrategyLoading(String university);

  /// No description provided for @aiStrategyGetPlan.
  ///
  /// In en, this message translates to:
  /// **'Get Detailed Plan'**
  String get aiStrategyGetPlan;

  /// No description provided for @aiStrategyFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Admission Strategy'**
  String get aiStrategyFallbackTitle;

  /// No description provided for @authLoginContinue.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue your journey'**
  String get authLoginContinue;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterButton;

  /// No description provided for @authTermsIHaveRead.
  ///
  /// In en, this message translates to:
  /// **'I agree with '**
  String get authTermsIHaveRead;

  /// No description provided for @authTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get authTermsLink;

  /// No description provided for @authTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authTermsAnd;

  /// No description provided for @authPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyLink;

  /// No description provided for @authGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Login as Guest'**
  String get authGuestTitle;

  /// No description provided for @authGuestWarning.
  ///
  /// In en, this message translates to:
  /// **'In guest mode, access is limited. For full access to the AI consultant and other functions, registration is required.'**
  String get authGuestWarning;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authTermsRegister.
  ///
  /// In en, this message translates to:
  /// **'By registering, you agree to the '**
  String get authTermsRegister;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authRequired;

  /// No description provided for @validationMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String validationMinLength(int count);

  /// No description provided for @validationDigitRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one digit'**
  String get validationDigitRequired;

  /// No description provided for @detailEstimateChances.
  ///
  /// In en, this message translates to:
  /// **'Estimate Chances'**
  String get detailEstimateChances;

  /// No description provided for @detailRecommendations.
  ///
  /// In en, this message translates to:
  /// **'💡 Recommendations'**
  String get detailRecommendations;

  /// No description provided for @detailAiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is generating strategy...'**
  String get detailAiThinking;

  /// No description provided for @detailAiStrategySubtitle.
  ///
  /// In en, this message translates to:
  /// **'TANDAU AI Strategy'**
  String get detailAiStrategySubtitle;

  /// No description provided for @profileSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved universities'**
  String get profileSavedSubtitle;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelTitle;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage push and data'**
  String get adminPanelSubtitle;

  /// No description provided for @authTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get authTermsSuffix;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get homeGreetingNight;

  /// No description provided for @homeEntScore.
  ///
  /// In en, this message translates to:
  /// **'Your UNT Score:'**
  String get homeEntScore;

  /// No description provided for @promoCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Promo Code'**
  String get promoCodeTitle;

  /// No description provided for @promoCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Activate PRO or Premium subscription'**
  String get promoCodeSubtitle;

  /// No description provided for @promoCodeActivation.
  ///
  /// In en, this message translates to:
  /// **'Promo Code Activation'**
  String get promoCodeActivation;

  /// No description provided for @promoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code to activate subscription:'**
  String get promoCodeHint;

  /// No description provided for @promoCodeActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get promoCodeActivate;

  /// No description provided for @promoCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo code successfully activated!'**
  String get promoCodeSuccess;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support TANDAU Team ❤️'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct transfer via Kaspi'**
  String get supportSubtitle;

  /// No description provided for @supportProject.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportProject;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'We appreciate any support! All funds go to AI server costs and TANDAU development.'**
  String get supportDescription;

  /// No description provided for @supportOpenKaspi.
  ///
  /// In en, this message translates to:
  /// **'Open Kaspi app'**
  String get supportOpenKaspi;

  /// No description provided for @supportNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied to clipboard'**
  String get supportNumberCopied;

  /// No description provided for @aiTokensRemaining.
  ///
  /// In en, this message translates to:
  /// **'AI requests left: {count}'**
  String aiTokensRemaining(int count);

  /// No description provided for @detailAboutUniversity.
  ///
  /// In en, this message translates to:
  /// **'About University'**
  String get detailAboutUniversity;

  /// No description provided for @detailPassingScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Passing Score'**
  String get detailPassingScoreTitle;

  /// No description provided for @detailPoints.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get detailPoints;

  /// No description provided for @detailBasedOnLastYear.
  ///
  /// In en, this message translates to:
  /// **'Based on last year\'s data'**
  String get detailBasedOnLastYear;

  /// No description provided for @detailAdmissionRequirements.
  ///
  /// In en, this message translates to:
  /// **'Admission Requirements'**
  String get detailAdmissionRequirements;

  /// No description provided for @detailApplicationDeadline.
  ///
  /// In en, this message translates to:
  /// **'Application Deadline'**
  String get detailApplicationDeadline;

  /// No description provided for @detailPhoneNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get detailPhoneNotProvided;

  /// No description provided for @detailWebsiteNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Website not provided'**
  String get detailWebsiteNotProvided;

  /// No description provided for @detailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get detailAddressLabel;

  /// No description provided for @detailWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get detailWebsiteLabel;

  /// No description provided for @detailPhoneLabelFull.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get detailPhoneLabelFull;

  /// No description provided for @detailLeaveReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get detailLeaveReviewBtn;

  /// No description provided for @detailNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get detailNoReviewsYet;

  /// No description provided for @detailBeFirstReviewer.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a review!'**
  String get detailBeFirstReviewer;

  /// No description provided for @detailReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String detailReviewsCount(int count);

  /// No description provided for @detailJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get detailJustNow;

  /// No description provided for @reviewEditedLabel.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get reviewEditedLabel;

  /// No description provided for @reviewAuthRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to rate'**
  String get reviewAuthRequiredMsg;

  /// No description provided for @reviewHelpfulLabel.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get reviewHelpfulLabel;

  /// No description provided for @reviewOfficialReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Official Reply'**
  String get reviewOfficialReplyLabel;

  /// No description provided for @majorBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get majorBusiness;

  /// No description provided for @majorLaw.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get majorLaw;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get commonOr;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @scoreInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter UNT Score'**
  String get scoreInputTitle;

  /// No description provided for @scoreInputHint.
  ///
  /// In en, this message translates to:
  /// **'0 – 140'**
  String get scoreInputHint;

  /// No description provided for @scoreInputError.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 140'**
  String get scoreInputError;

  /// No description provided for @scoreInputTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the number for precise input'**
  String get scoreInputTapHint;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get reviewTitle;

  /// No description provided for @reviewRateQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you rate it?'**
  String get reviewRateQuestion;

  /// No description provided for @reviewSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Select a rating'**
  String get reviewSelectRating;

  /// No description provided for @reviewWriteComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get reviewWriteComment;

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your experience...'**
  String get reviewCommentHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get reviewSubmit;

  /// No description provided for @reviewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review added successfully!'**
  String get reviewSuccess;

  /// No description provided for @reviewModerationFail.
  ///
  /// In en, this message translates to:
  /// **'Could not submit. Check text for inappropriate language.'**
  String get reviewModerationFail;

  /// No description provided for @reviewAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo ({current}/3)'**
  String reviewAttachPhoto(int current);

  /// No description provided for @reviewRatingBad.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get reviewRatingBad;

  /// No description provided for @reviewRatingPoor.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get reviewRatingPoor;

  /// No description provided for @reviewRatingOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get reviewRatingOk;

  /// No description provided for @reviewRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewRatingGood;

  /// No description provided for @reviewRatingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get reviewRatingExcellent;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your\nfull potential'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that suits you and get admitted on a grant with confidence.'**
  String get paywallSubtitle;

  /// No description provided for @paywallFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallFree;

  /// No description provided for @paywallCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Your current plan'**
  String get paywallCurrentPlan;

  /// No description provided for @paywallChoosePro.
  ///
  /// In en, this message translates to:
  /// **'Choose PRO'**
  String get paywallChoosePro;

  /// No description provided for @paywallChoosePremium.
  ///
  /// In en, this message translates to:
  /// **'Choose Premium'**
  String get paywallChoosePremium;

  /// No description provided for @paywallProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect for 11th graders'**
  String get paywallProSubtitle;

  /// No description provided for @paywallFeatureAiRequests.
  ///
  /// In en, this message translates to:
  /// **'100 AI requests'**
  String get paywallFeatureAiRequests;

  /// No description provided for @paywallFeatureBasicChances.
  ///
  /// In en, this message translates to:
  /// **'Basic chance estimation'**
  String get paywallFeatureBasicChances;

  /// No description provided for @paywallFeatureUniversityDb.
  ///
  /// In en, this message translates to:
  /// **'Access to university database'**
  String get paywallFeatureUniversityDb;

  /// No description provided for @paywallFeatureAiDaily.
  ///
  /// In en, this message translates to:
  /// **'100 AI requests per day'**
  String get paywallFeatureAiDaily;

  /// No description provided for @paywallFeatureStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy generator (4-university algorithm) 🔥'**
  String get paywallFeatureStrategy;

  /// No description provided for @paywallFeatureDetailedChances.
  ///
  /// In en, this message translates to:
  /// **'Detailed chance estimation'**
  String get paywallFeatureDetailedChances;

  /// No description provided for @paywallFeaturePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority access'**
  String get paywallFeaturePriority;

  /// No description provided for @paywallFeatureUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI requests ♾️'**
  String get paywallFeatureUnlimited;

  /// No description provided for @paywallFeatureParents.
  ///
  /// In en, this message translates to:
  /// **'Analytics for parents'**
  String get paywallFeatureParents;

  /// No description provided for @paywallFeaturePersonalSupport.
  ///
  /// In en, this message translates to:
  /// **'Personal support'**
  String get paywallFeaturePersonalSupport;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} ₸ / month'**
  String paywallPerMonth(String price);

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @notificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationEmpty;

  /// No description provided for @deadlineTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Admission Deadlines 2026'**
  String get deadlineTitle;

  /// No description provided for @deadlineDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get deadlineDays;

  /// No description provided for @deadlineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get deadlineCompleted;

  /// No description provided for @deadlineToday.
  ///
  /// In en, this message translates to:
  /// **'Today!'**
  String get deadlineToday;

  /// No description provided for @deadlineTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow!'**
  String get deadlineTomorrow;

  /// No description provided for @deadlineWeeks.
  ///
  /// In en, this message translates to:
  /// **'wk'**
  String get deadlineWeeks;

  /// No description provided for @deadlineMonths.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get deadlineMonths;

  /// No description provided for @wizardStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wizardStepOf(int current, int total);

  /// No description provided for @wizardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get wizardSkip;

  /// No description provided for @wizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get wizardNext;

  /// No description provided for @wizardFinish.
  ///
  /// In en, this message translates to:
  /// **'✨ Finish'**
  String get wizardFinish;

  /// No description provided for @wizardEntTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your UNT score?'**
  String get wizardEntTitle;

  /// No description provided for @wizardEntSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trial or actual — enter an approximate score'**
  String get wizardEntSubtitle;

  /// No description provided for @wizardMajorTitle.
  ///
  /// In en, this message translates to:
  /// **'What major?'**
  String get wizardMajorTitle;

  /// No description provided for @wizardMajorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select one or more'**
  String get wizardMajorSubtitle;

  /// No description provided for @wizardCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Which city?'**
  String get wizardCityTitle;

  /// No description provided for @wizardCitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to study'**
  String get wizardCitySubtitle;

  /// No description provided for @wizardFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial situation?'**
  String get wizardFinanceTitle;

  /// No description provided for @wizardFinanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will help find suitable universities'**
  String get wizardFinanceSubtitle;

  /// No description provided for @wizardQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Have any quotas?'**
  String get wizardQuotaTitle;

  /// No description provided for @wizardQuotaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quotas give an advantage in admission'**
  String get wizardQuotaSubtitle;

  /// No description provided for @wizardAchievementTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements?'**
  String get wizardAchievementTitle;

  /// No description provided for @wizardAchievementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Altyn Belgi, olympiads, sports'**
  String get wizardAchievementSubtitle;

  /// No description provided for @wizardFinanceOnlyGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant only'**
  String get wizardFinanceOnlyGrant;

  /// No description provided for @wizardFinanceOnlyGrantDesc.
  ///
  /// In en, this message translates to:
  /// **'Cannot afford tuition'**
  String get wizardFinanceOnlyGrantDesc;

  /// No description provided for @wizardFinanceUpTo1m.
  ///
  /// In en, this message translates to:
  /// **'Up to 1,000,000 ₸'**
  String get wizardFinanceUpTo1m;

  /// No description provided for @wizardFinanceUpTo1mDesc.
  ///
  /// In en, this message translates to:
  /// **'Can partially pay'**
  String get wizardFinanceUpTo1mDesc;

  /// No description provided for @wizardFinanceAny.
  ///
  /// In en, this message translates to:
  /// **'Any budget'**
  String get wizardFinanceAny;

  /// No description provided for @wizardFinanceAnyDesc.
  ///
  /// In en, this message translates to:
  /// **'Finances don\'t limit my choice'**
  String get wizardFinanceAnyDesc;

  /// No description provided for @wizardQuotaRural.
  ///
  /// In en, this message translates to:
  /// **'🏡 Rural quota'**
  String get wizardQuotaRural;

  /// No description provided for @wizardQuotaRuralDesc.
  ///
  /// In en, this message translates to:
  /// **'Registered in a village'**
  String get wizardQuotaRuralDesc;

  /// No description provided for @wizardQuotaOrphan.
  ///
  /// In en, this message translates to:
  /// **'👶 Orphan quota'**
  String get wizardQuotaOrphan;

  /// No description provided for @wizardQuotaOrphanDesc.
  ///
  /// In en, this message translates to:
  /// **'Orphan child status'**
  String get wizardQuotaOrphanDesc;

  /// No description provided for @wizardQuotaDisability.
  ///
  /// In en, this message translates to:
  /// **'♿ Disability quota'**
  String get wizardQuotaDisability;

  /// No description provided for @wizardQuotaDisabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Disability group I, II or III'**
  String get wizardQuotaDisabilityDesc;

  /// No description provided for @wizardQuotaHint.
  ///
  /// In en, this message translates to:
  /// **'No quota? No problem! AI will consider this and find the best options.'**
  String get wizardQuotaHint;

  /// No description provided for @wizardProfileButton.
  ///
  /// In en, this message translates to:
  /// **'🚀 Complete profile in 2 min'**
  String get wizardProfileButton;

  /// No description provided for @wizardProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'My profile is updated! Show me suitable universities.'**
  String get wizardProfileUpdated;

  /// No description provided for @wizardSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save error'**
  String get wizardSaveError;

  /// No description provided for @wizardScoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! 🔥'**
  String get wizardScoreExcellent;

  /// No description provided for @wizardScoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good! 💪'**
  String get wizardScoreGood;

  /// No description provided for @wizardScoreOk.
  ///
  /// In en, this message translates to:
  /// **'Not bad 👍'**
  String get wizardScoreOk;

  /// No description provided for @wizardScoreGrow.
  ///
  /// In en, this message translates to:
  /// **'Room to grow 📈'**
  String get wizardScoreGrow;

  /// No description provided for @wizardScorePrep.
  ///
  /// In en, this message translates to:
  /// **'Prep needed 📚'**
  String get wizardScorePrep;

  /// No description provided for @successStoriesChip.
  ///
  /// In en, this message translates to:
  /// **'📖 Success Stories'**
  String get successStoriesChip;

  /// No description provided for @wizardMajorIT.
  ///
  /// In en, this message translates to:
  /// **'IT / Programming'**
  String get wizardMajorIT;

  /// No description provided for @wizardMajorMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get wizardMajorMedicine;

  /// No description provided for @wizardMajorEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get wizardMajorEngineering;

  /// No description provided for @wizardMajorBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business / Economics'**
  String get wizardMajorBusiness;

  /// No description provided for @wizardMajorPedagogy.
  ///
  /// In en, this message translates to:
  /// **'Pedagogy'**
  String get wizardMajorPedagogy;

  /// No description provided for @wizardMajorLaw.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get wizardMajorLaw;

  /// No description provided for @wizardMajorArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get wizardMajorArchitecture;

  /// No description provided for @wizardMajorOilGas.
  ///
  /// In en, this message translates to:
  /// **'Oil & Gas'**
  String get wizardMajorOilGas;

  /// No description provided for @wizardMajorArt.
  ///
  /// In en, this message translates to:
  /// **'Art / Design'**
  String get wizardMajorArt;

  /// No description provided for @wizardMajorUndecided.
  ///
  /// In en, this message translates to:
  /// **'Undecided'**
  String get wizardMajorUndecided;

  /// No description provided for @wizardAchAltynBelgi.
  ///
  /// In en, this message translates to:
  /// **'Altyn Belgi'**
  String get wizardAchAltynBelgi;

  /// No description provided for @wizardAchOlympiadRepublic.
  ///
  /// In en, this message translates to:
  /// **'Olympiad (national)'**
  String get wizardAchOlympiadRepublic;

  /// No description provided for @wizardAchOlympiadRegion.
  ///
  /// In en, this message translates to:
  /// **'Olympiad (regional)'**
  String get wizardAchOlympiadRegion;

  /// No description provided for @wizardAchSport.
  ///
  /// In en, this message translates to:
  /// **'Sports achievements'**
  String get wizardAchSport;

  /// No description provided for @wizardAchVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get wizardAchVolunteer;

  /// No description provided for @wizardAchScience.
  ///
  /// In en, this message translates to:
  /// **'Research project'**
  String get wizardAchScience;

  /// No description provided for @wizardAchNone.
  ///
  /// In en, this message translates to:
  /// **'No achievements'**
  String get wizardAchNone;

  /// No description provided for @wizardCityAny.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get wizardCityAny;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
