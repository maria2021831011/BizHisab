import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BizHisab AI'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

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

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get navSuppliers;

  /// No description provided for @navPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get navPeople;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get navAi;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'BizHisab AI'**
  String get landingTitle;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Business Finance'**
  String get landingTagline;

  /// No description provided for @landingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get landingGetStarted;

  /// No description provided for @authMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get authMobileTitle;

  /// No description provided for @authMobileHeadline.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get authMobileHeadline;

  /// No description provided for @authMobileSub.
  ///
  /// In en, this message translates to:
  /// **'We will send you a verification code'**
  String get authMobileSub;

  /// No description provided for @authMobileFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: 01XXXXXXXXX (11 digits, any BD operator)'**
  String get authMobileFormat;

  /// No description provided for @authMobileSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authMobileSendOtp;

  /// No description provided for @authMobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get authMobileInvalid;

  /// No description provided for @authMobileChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Use Different Number'**
  String get authMobileChangeNumber;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get authOtpTitle;

  /// No description provided for @authOtpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get authOtpHeadline;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to +88 {number}'**
  String authOtpSentTo(String number);

  /// No description provided for @authOtpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authOtpResendIn(int seconds);

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get authOtpResend;

  /// No description provided for @authOtpSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get authOtpSending;

  /// No description provided for @authOtpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get authOtpResentSuccess;

  /// No description provided for @authOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

  /// No description provided for @authOtpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP'**
  String get authOtpIncomplete;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get authOtpInvalid;

  /// No description provided for @authOtpRequestFirst.
  ///
  /// In en, this message translates to:
  /// **'Please request OTP first'**
  String get authOtpRequestFirst;

  /// No description provided for @authOtpVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get authOtpVerifyFailed;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionBrand.
  ///
  /// In en, this message translates to:
  /// **'Business Premium'**
  String get subscriptionBrand;

  /// No description provided for @subscriptionBlurb.
  ///
  /// In en, this message translates to:
  /// **'Subscription is required to use BizHisab AI. Subscribe via your mobile operator.'**
  String get subscriptionBlurb;

  /// No description provided for @subscriptionFeatureTracking.
  ///
  /// In en, this message translates to:
  /// **'Complete Transaction Tracking'**
  String get subscriptionFeatureTracking;

  /// No description provided for @subscriptionFeatureCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customer & Supplier Management'**
  String get subscriptionFeatureCustomers;

  /// No description provided for @subscriptionFeatureInsights.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Financial Insights'**
  String get subscriptionFeatureInsights;

  /// No description provided for @subscriptionFeatureReports.
  ///
  /// In en, this message translates to:
  /// **'Detailed Reports & Analytics'**
  String get subscriptionFeatureReports;

  /// No description provided for @subscriptionFeatureChatbot.
  ///
  /// In en, this message translates to:
  /// **'AI Business Chatbot (Bangla/English)'**
  String get subscriptionFeatureChatbot;

  /// No description provided for @subscriptionFeatureCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud-Synced Data'**
  String get subscriptionFeatureCloud;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscriptionSubscribe;

  /// No description provided for @subscriptionSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get subscriptionSendingOtp;

  /// No description provided for @subscriptionEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent by BdApps to confirm your subscription.'**
  String get subscriptionEnterOtp;

  /// No description provided for @subscriptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Subscription'**
  String get subscriptionConfirm;

  /// No description provided for @subscriptionAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid? Verify now'**
  String get subscriptionAlreadyPaid;

  /// No description provided for @subscriptionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking subscription...'**
  String get subscriptionChecking;

  /// No description provided for @subscriptionNotYetActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription not yet active. Wait 30 seconds, then tap \"Resend OTP\" — your payment may take a moment to confirm.'**
  String get subscriptionNotYetActive;

  /// No description provided for @subscriptionResent.
  ///
  /// In en, this message translates to:
  /// **'Subscription OTP resent successfully'**
  String get subscriptionResent;

  /// No description provided for @subscriptionResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String subscriptionResendIn(int seconds);

  /// No description provided for @subscriptionResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get subscriptionResendOtp;

  /// No description provided for @subscriptionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start subscription'**
  String get subscriptionStartFailed;

  /// No description provided for @subscriptionPhoneMissing.
  ///
  /// In en, this message translates to:
  /// **'Phone number missing. Please log in again.'**
  String get subscriptionPhoneMissing;

  /// No description provided for @subscriptionAuthMissing.
  ///
  /// In en, this message translates to:
  /// **'Phone number missing.'**
  String get subscriptionAuthMissing;

  /// No description provided for @subscriptionRequestOtpFirst.
  ///
  /// In en, this message translates to:
  /// **'Please request subscription OTP first'**
  String get subscriptionRequestOtpFirst;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Setup'**
  String get setupTitle;

  /// No description provided for @setupBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get setupBusinessName;

  /// No description provided for @setupBusinessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Rahman Traders'**
  String get setupBusinessNameHint;

  /// No description provided for @setupBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get setupBusinessType;

  /// No description provided for @setupBusinessTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Business type is required'**
  String get setupBusinessTypeRequired;

  /// No description provided for @setupOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get setupOwnerName;

  /// No description provided for @setupPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get setupPhone;

  /// No description provided for @setupPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get setupPhoneOptional;

  /// No description provided for @setupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get setupPhoneHint;

  /// No description provided for @setupAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get setupAddress;

  /// No description provided for @setupAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get setupAddressOptional;

  /// No description provided for @setupAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get setupAddressHint;

  /// No description provided for @setupCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get setupCurrency;

  /// No description provided for @setupSave.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get setupSave;

  /// No description provided for @setupHeadline.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get setupHeadline;

  /// No description provided for @setupSub.
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about your business so we can personalise your dashboard.'**
  String get setupSub;

  /// No description provided for @setupPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data is private and tied to your account.'**
  String get setupPrivacyNote;

  /// No description provided for @setupSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get setupSessionExpired;

  /// No description provided for @setupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create business.'**
  String get setupSaveFailed;

  /// No description provided for @currencyBdt.
  ///
  /// In en, this message translates to:
  /// **'BDT (৳) — Bangladeshi Taka'**
  String get currencyBdt;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD (\$) — US Dollar'**
  String get currencyUsd;

  /// No description provided for @currencyInr.
  ///
  /// In en, this message translates to:
  /// **'INR (₹) — Indian Rupee'**
  String get currencyInr;

  /// No description provided for @currencyEur.
  ///
  /// In en, this message translates to:
  /// **'EUR (€) — Euro'**
  String get currencyEur;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dashboardRefresh;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard'**
  String get dashboardLoadFailed;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardMonth;

  /// No description provided for @dashboardTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get dashboardTodaySales;

  /// No description provided for @dashboardTodayExpense.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expense'**
  String get dashboardTodayExpense;

  /// No description provided for @dashboardTodayProfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Profit'**
  String get dashboardTodayProfit;

  /// No description provided for @dashboardIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncome;

  /// No description provided for @dashboardExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboardExpense;

  /// No description provided for @dashboardProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get dashboardProfit;

  /// No description provided for @dashboardCustomerDue.
  ///
  /// In en, this message translates to:
  /// **'Customer Due'**
  String get dashboardCustomerDue;

  /// No description provided for @dashboardSupplierDue.
  ///
  /// In en, this message translates to:
  /// **'Supplier Due'**
  String get dashboardSupplierDue;

  /// No description provided for @dashboardAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get dashboardAddIncome;

  /// No description provided for @dashboardAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get dashboardAddExpense;

  /// No description provided for @dashboardDue.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Dues'**
  String get dashboardDue;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get dashboardGreeting;

  /// No description provided for @dashboardBusinessFallback.
  ///
  /// In en, this message translates to:
  /// **'Your Business'**
  String get dashboardBusinessFallback;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardAiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get dashboardAiInsight;

  /// No description provided for @dashboardAiInsightSub.
  ///
  /// In en, this message translates to:
  /// **'Personalized financial insights coming soon'**
  String get dashboardAiInsightSub;

  /// No description provided for @dashboardBeta.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get dashboardBeta;

  /// No description provided for @dashboardTodayLoss.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Loss'**
  String get dashboardTodayLoss;

  /// No description provided for @dashboardProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboardProfile;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get dashboardGreetingNight;

  /// No description provided for @dashboardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense to get started.'**
  String get dashboardEmptySubtitle;

  /// No description provided for @dashboardIncomeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncomeGeneric;

  /// No description provided for @dashboardExpenseGeneric.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboardExpenseGeneric;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business Owner'**
  String get profileBusinessOwner;

  /// No description provided for @profileUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileUnknownUser;

  /// No description provided for @profileNoBusiness.
  ///
  /// In en, this message translates to:
  /// **'No business profile set up'**
  String get profileNoBusiness;

  /// No description provided for @profileBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get profileBusinessInfo;

  /// No description provided for @profileFieldBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get profileFieldBusinessName;

  /// No description provided for @profileFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get profileFieldType;

  /// No description provided for @profileFieldOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get profileFieldOwner;

  /// No description provided for @profileFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileFieldPhone;

  /// No description provided for @profileFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileFieldAddress;

  /// No description provided for @profileFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profileFieldCurrency;

  /// No description provided for @profileSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'BizHisab AI Premium'**
  String get profileSubscriptionTitle;

  /// No description provided for @profileSubscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileSubscriptionActive;

  /// No description provided for @profileSubscriptionInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileSubscriptionInactive;

  /// No description provided for @profileSubscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get profileSubscriptionMonthly;

  /// No description provided for @profileUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get profileUnsubscribe;

  /// No description provided for @profileUnsubscribeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your monthly BizHisab AI Premium subscription'**
  String get profileUnsubscribeSubtitle;

  /// No description provided for @profileUnsubscribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe?'**
  String get profileUnsubscribeTitle;

  /// No description provided for @profileUnsubscribeBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your BizHisab AI Premium subscription? You will lose access to premium features on your next login.'**
  String get profileUnsubscribeBody;

  /// No description provided for @profileKeepSubscription.
  ///
  /// In en, this message translates to:
  /// **'Keep Subscription'**
  String get profileKeepSubscription;

  /// No description provided for @profileUnsubscribeSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have been unsubscribed successfully.'**
  String get profileUnsubscribeSuccess;

  /// No description provided for @profileUnsubscribeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe failed. Please try again.'**
  String get profileUnsubscribeFailed;

  /// No description provided for @profileEditBusiness.
  ///
  /// In en, this message translates to:
  /// **'Edit Business'**
  String get profileEditBusiness;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutBody;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiTitle;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @aiAskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your business...'**
  String get aiAskPlaceholder;

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiOffline.
  ///
  /// In en, this message translates to:
  /// **'AI service offline'**
  String get aiOffline;

  /// No description provided for @aiTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiTryAgain;

  /// No description provided for @aiSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use AI features.'**
  String get aiSignInRequired;

  /// No description provided for @aiInsightsSub.
  ///
  /// In en, this message translates to:
  /// **'Get a structured summary of your business performance.'**
  String get aiInsightsSub;

  /// No description provided for @aiChatSub.
  ///
  /// In en, this message translates to:
  /// **'Ask free-form questions in Bangla, Banglish or English.'**
  String get aiChatSub;

  /// No description provided for @aiFreeTierNotice.
  ///
  /// In en, this message translates to:
  /// **'AI runs on a free-tier model. If the service is unavailable, your other features keep working — try again later.'**
  String get aiFreeTierNotice;

  /// No description provided for @aiKeyFindings.
  ///
  /// In en, this message translates to:
  /// **'Key findings'**
  String get aiKeyFindings;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get aiRecommendations;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'{level} confidence'**
  String aiConfidence(String level);

  /// No description provided for @aiChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your business. Answers can be in Bangla, Banglish or English.'**
  String get aiChatEmpty;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get aiThinking;

  /// No description provided for @aiChatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask about your business...'**
  String get aiChatPlaceholder;

  /// No description provided for @aiClearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get aiClearChat;

  /// No description provided for @aiInsightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No insights yet. Pick a report type above.'**
  String get aiInsightsEmpty;

  /// No description provided for @aiOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'AI server not reachable. Start the backend and run `adb reverse tcp:8000 tcp:8000`.'**
  String get aiOfflineBanner;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionsAdd;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmpty;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customersAdd;

  /// No description provided for @customersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmpty;

  /// No description provided for @customersTotalPurchase.
  ///
  /// In en, this message translates to:
  /// **'Total Purchase'**
  String get customersTotalPurchase;

  /// No description provided for @customersTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get customersTotalPaid;

  /// No description provided for @customersTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get customersTotalDue;

  /// No description provided for @customersRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get customersRecordPayment;

  /// No description provided for @customersEditCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customersEditCustomer;

  /// No description provided for @customersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customersName;

  /// No description provided for @customersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customersPhone;

  /// No description provided for @customersAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customersAddress;

  /// No description provided for @customersSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get customersSort;

  /// No description provided for @customersSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get customersSortNameAsc;

  /// No description provided for @customersSortDueDesc.
  ///
  /// In en, this message translates to:
  /// **'Due (high to low)'**
  String get customersSortDueDesc;

  /// No description provided for @customersSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get customersSortRecent;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get customersSearchHint;

  /// No description provided for @customersTotalDueCard.
  ///
  /// In en, this message translates to:
  /// **'Total Customer Due'**
  String get customersTotalDueCard;

  /// No description provided for @customersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get customersLoadFailed;

  /// No description provided for @customersSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers match your search'**
  String get customersSearchEmpty;

  /// No description provided for @customersSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or phone.'**
  String get customersSearchEmptySubtitle;

  /// No description provided for @customersAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a customer to start tracking dues.'**
  String get customersAddSubtitle;

  /// No description provided for @customersChipDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get customersChipDue;

  /// No description provided for @customersChipSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get customersChipSettled;

  /// No description provided for @customersDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customersDetailTitle;

  /// No description provided for @customersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get customersNotFound;

  /// No description provided for @customersDueBalance.
  ///
  /// In en, this message translates to:
  /// **'Due Balance'**
  String get customersDueBalance;

  /// No description provided for @customersAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customersAddressLabel;

  /// No description provided for @customersCreditSales.
  ///
  /// In en, this message translates to:
  /// **'Credit Sales'**
  String get customersCreditSales;

  /// No description provided for @customersLoadingCreditSales.
  ///
  /// In en, this message translates to:
  /// **'Loading credit sales...'**
  String get customersLoadingCreditSales;

  /// No description provided for @customersCreditSalesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit sales yet'**
  String get customersCreditSalesEmpty;

  /// No description provided for @customersCreditSalesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales tagged as Due for this customer will show up here.'**
  String get customersCreditSalesEmptySubtitle;

  /// No description provided for @customersPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get customersPaymentHistory;

  /// No description provided for @customersLoadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Loading payments...'**
  String get customersLoadingPayments;

  /// No description provided for @customersPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get customersPaymentsEmpty;

  /// No description provided for @customersPaymentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recorded payments will show up here.'**
  String get customersPaymentsEmptySubtitle;

  /// No description provided for @customersPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get customersPaymentRecorded;

  /// No description provided for @customersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get customersDeleteTitle;

  /// No description provided for @customersDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this customer? Related transactions will keep their reference.'**
  String get customersDeleteBody;

  /// No description provided for @customersFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customersFormNameLabel;

  /// No description provided for @customersFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Rahim Enterprise'**
  String get customersFormNameHint;

  /// No description provided for @customersFormPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get customersFormPhoneLabel;

  /// No description provided for @customersFormAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get customersFormAddressLabel;

  /// No description provided for @customersFormAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 12 Mirpur Road, Dhaka'**
  String get customersFormAddressHint;

  /// No description provided for @customersUpdateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Update Customer'**
  String get customersUpdateCustomer;

  /// No description provided for @customersDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get customersDiscardTitle;

  /// No description provided for @customersDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost if you leave now.'**
  String get customersDiscardBody;

  /// No description provided for @customersKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get customersKeepEditing;

  /// No description provided for @customersDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get customersDiscard;

  /// No description provided for @customersPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get customersPaymentAmountLabel;

  /// No description provided for @customersPaymentAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get customersPaymentAmountHint;

  /// No description provided for @customersPaymentEnterValid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get customersPaymentEnterValid;

  /// No description provided for @customersPaymentNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get customersPaymentNoteLabel;

  /// No description provided for @customersPaymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., partial payment for invoice #12'**
  String get customersPaymentNoteHint;

  /// No description provided for @customersPaymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get customersPaymentSave;

  /// No description provided for @customersPaymentCurrentDue.
  ///
  /// In en, this message translates to:
  /// **'Current Due'**
  String get customersPaymentCurrentDue;

  /// No description provided for @customersPaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get customersPaymentDateLabel;

  /// No description provided for @customersPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get customersPaymentMethodLabel;

  /// No description provided for @customersPaymentAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'After this payment'**
  String get customersPaymentAfterTitle;

  /// No description provided for @customersPaymentNewDue.
  ///
  /// In en, this message translates to:
  /// **'New Due'**
  String get customersPaymentNewDue;

  /// No description provided for @customersPaymentExceedsDue.
  ///
  /// In en, this message translates to:
  /// **'Exceeds Due'**
  String get customersPaymentExceedsDue;

  /// No description provided for @customersPaymentNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get customersPaymentNotSignedIn;

  /// No description provided for @customersPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get customersPaymentFailed;

  /// No description provided for @customersPaymentExceedsBody.
  ///
  /// In en, this message translates to:
  /// **'Payment ({amount}) exceeds the due balance ({balance}).'**
  String customersPaymentExceedsBody(Object amount, Object balance);

  /// No description provided for @customersPaymentExceedsHint.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds the current due — only up to {amount} can be settled'**
  String customersPaymentExceedsHint(Object amount);

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @suppliersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get suppliersAdd;

  /// No description provided for @suppliersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet'**
  String get suppliersEmpty;

  /// No description provided for @suppliersRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get suppliersRecordPayment;

  /// No description provided for @suppliersEditSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get suppliersEditSupplier;

  /// No description provided for @suppliersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get suppliersName;

  /// No description provided for @suppliersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get suppliersPhone;

  /// No description provided for @suppliersAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get suppliersAddress;

  /// No description provided for @suppliersSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get suppliersSort;

  /// No description provided for @suppliersSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get suppliersSortNameAsc;

  /// No description provided for @suppliersSortDueDesc.
  ///
  /// In en, this message translates to:
  /// **'Due (high to low)'**
  String get suppliersSortDueDesc;

  /// No description provided for @suppliersSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get suppliersSortRecent;

  /// No description provided for @suppliersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or address...'**
  String get suppliersSearchHint;

  /// No description provided for @suppliersTotalDueCard.
  ///
  /// In en, this message translates to:
  /// **'Total Supplier Due'**
  String get suppliersTotalDueCard;

  /// No description provided for @suppliersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load suppliers'**
  String get suppliersLoadFailed;

  /// No description provided for @suppliersSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suppliers match your search'**
  String get suppliersSearchEmpty;

  /// No description provided for @suppliersSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, phone, or address.'**
  String get suppliersSearchEmptySubtitle;

  /// No description provided for @suppliersAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a supplier to start tracking dues.'**
  String get suppliersAddSubtitle;

  /// No description provided for @suppliersDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Details'**
  String get suppliersDetailTitle;

  /// No description provided for @suppliersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Supplier not found'**
  String get suppliersNotFound;

  /// No description provided for @suppliersTotalPurchase.
  ///
  /// In en, this message translates to:
  /// **'Total Purchase'**
  String get suppliersTotalPurchase;

  /// No description provided for @suppliersTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get suppliersTotalPaid;

  /// No description provided for @suppliersDueBalance.
  ///
  /// In en, this message translates to:
  /// **'Due Balance'**
  String get suppliersDueBalance;

  /// No description provided for @suppliersCreditPurchases.
  ///
  /// In en, this message translates to:
  /// **'Credit Purchases'**
  String get suppliersCreditPurchases;

  /// No description provided for @suppliersLoadingCreditPurchases.
  ///
  /// In en, this message translates to:
  /// **'Loading credit purchases...'**
  String get suppliersLoadingCreditPurchases;

  /// No description provided for @suppliersCreditPurchasesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit purchases yet'**
  String get suppliersCreditPurchasesEmpty;

  /// No description provided for @suppliersCreditPurchasesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases tagged as Due for this supplier will show up here.'**
  String get suppliersCreditPurchasesEmptySubtitle;

  /// No description provided for @suppliersPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get suppliersPaymentHistory;

  /// No description provided for @suppliersLoadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Loading payments...'**
  String get suppliersLoadingPayments;

  /// No description provided for @suppliersPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get suppliersPaymentsEmpty;

  /// No description provided for @suppliersPaymentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recorded payments will show up here.'**
  String get suppliersPaymentsEmptySubtitle;

  /// No description provided for @suppliersPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get suppliersPaymentRecorded;

  /// No description provided for @suppliersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Supplier'**
  String get suppliersDeleteTitle;

  /// No description provided for @suppliersDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this supplier? Related expenses will keep their reference.'**
  String get suppliersDeleteBody;

  /// No description provided for @suppliersFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get suppliersFormNameLabel;

  /// No description provided for @suppliersFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Dhaka Traders'**
  String get suppliersFormNameHint;

  /// No description provided for @suppliersFormPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get suppliersFormPhoneLabel;

  /// No description provided for @suppliersFormPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get suppliersFormPhoneHint;

  /// No description provided for @suppliersUpdateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Update Supplier'**
  String get suppliersUpdateSupplier;

  /// No description provided for @suppliersDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get suppliersDiscardTitle;

  /// No description provided for @suppliersDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost if you leave now.'**
  String get suppliersDiscardBody;

  /// No description provided for @suppliersDiscardPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard payment?'**
  String get suppliersDiscardPaymentTitle;

  /// No description provided for @suppliersDiscardPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment details will be lost if you leave now.'**
  String get suppliersDiscardPaymentBody;

  /// No description provided for @suppliersKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get suppliersKeepEditing;

  /// No description provided for @suppliersDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get suppliersDiscard;

  /// No description provided for @suppliersPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get suppliersPaymentAmountLabel;

  /// No description provided for @suppliersPaymentAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get suppliersPaymentAmountHint;

  /// No description provided for @suppliersPaymentEnterValid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get suppliersPaymentEnterValid;

  /// No description provided for @suppliersPaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get suppliersPaymentDateLabel;

  /// No description provided for @suppliersPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get suppliersPaymentMethodLabel;

  /// No description provided for @suppliersPaymentNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get suppliersPaymentNoteLabel;

  /// No description provided for @suppliersPaymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., partial payment against invoice #12'**
  String get suppliersPaymentNoteHint;

  /// No description provided for @suppliersPaymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get suppliersPaymentSave;

  /// No description provided for @suppliersPaymentCurrentDue.
  ///
  /// In en, this message translates to:
  /// **'Current Due'**
  String get suppliersPaymentCurrentDue;

  /// No description provided for @suppliersPaymentCurrentDueSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get suppliersPaymentCurrentDueSettled;

  /// No description provided for @suppliersPaymentAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'After this payment'**
  String get suppliersPaymentAfterTitle;

  /// No description provided for @suppliersPaymentNewDue.
  ///
  /// In en, this message translates to:
  /// **'New due: {amount}'**
  String suppliersPaymentNewDue(String amount);

  /// No description provided for @suppliersPaymentTotalPaidAfter.
  ///
  /// In en, this message translates to:
  /// **'Total paid after this: {amount}'**
  String suppliersPaymentTotalPaidAfter(String amount);

  /// No description provided for @suppliersPaymentExceedsDue.
  ///
  /// In en, this message translates to:
  /// **'Exceeds Due'**
  String get suppliersPaymentExceedsDue;

  /// No description provided for @suppliersPaymentExceedsHint.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds the current due — only up to {amount} can be settled in one payment'**
  String suppliersPaymentExceedsHint(String amount);

  /// No description provided for @suppliersPaymentNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get suppliersPaymentNotSignedIn;

  /// No description provided for @suppliersPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get suppliersPaymentFailed;

  /// No description provided for @suppliersPaymentExceedsBody.
  ///
  /// In en, this message translates to:
  /// **'Payment ({amount}) exceeds the due balance ({balance}).'**
  String suppliersPaymentExceedsBody(String amount, String balance);

  /// No description provided for @incomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeTitle;

  /// No description provided for @incomeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get incomeAdd;

  /// No description provided for @incomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No income recorded yet'**
  String get incomeEmpty;

  /// No description provided for @incomeEditIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get incomeEditIncome;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseTitle;

  /// No description provided for @expenseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseAdd;

  /// No description provided for @expenseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expense recorded yet'**
  String get expenseEmpty;

  /// No description provided for @expenseEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseEditExpense;

  /// No description provided for @transactionsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionsHistoryTitle;

  /// No description provided for @transactionsNewBtn.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get transactionsNewBtn;

  /// No description provided for @transactionsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get transactionsRefresh;

  /// No description provided for @transactionsSummaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsSummaryIncome;

  /// No description provided for @transactionsSummaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionsSummaryExpense;

  /// No description provided for @transactionsSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get transactionsSummaryNet;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by category or note...'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsDateAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get transactionsDateAll;

  /// No description provided for @transactionsDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get transactionsDateToday;

  /// No description provided for @transactionsDateWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get transactionsDateWeek;

  /// No description provided for @transactionsDateMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get transactionsDateMonth;

  /// No description provided for @transactionsDateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get transactionsDateCustom;

  /// No description provided for @transactionsTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsTypeAll;

  /// No description provided for @transactionsTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsTypeIncome;

  /// No description provided for @transactionsTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionsTypeExpense;

  /// No description provided for @transactionsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get transactionsAllCategories;

  /// No description provided for @transactionsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions...'**
  String get transactionsLoading;

  /// No description provided for @transactionsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get transactionsLoadFailedTitle;

  /// No description provided for @transactionsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get transactionsRetry;

  /// No description provided for @transactionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get transactionsEmptyTitle;

  /// No description provided for @transactionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try widening the date range or clearing the search.'**
  String get transactionsEmptySubtitle;

  /// No description provided for @transactionsResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get transactionsResetFilters;

  /// No description provided for @transactionsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get transactionsLoadMore;

  /// No description provided for @transactionsEndOfList.
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get transactionsEndOfList;

  /// No description provided for @transactionsBadgeIncome.
  ///
  /// In en, this message translates to:
  /// **'INCOME'**
  String get transactionsBadgeIncome;

  /// No description provided for @transactionsBadgeExpense.
  ///
  /// In en, this message translates to:
  /// **'EXPENSE'**
  String get transactionsBadgeExpense;

  /// No description provided for @transactionsSearchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get transactionsSearchTransactions;

  /// No description provided for @transactionsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsSearchEmpty;

  /// No description provided for @transactionsSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense to start tracking.'**
  String get transactionsSearchEmptySubtitle;

  /// No description provided for @transactionsLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get transactionsLoadFailedSubtitle;

  /// No description provided for @transactionsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get transactionsFilterTitle;

  /// No description provided for @transactionsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionsFilterType;

  /// No description provided for @transactionsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get transactionsFilterClear;

  /// No description provided for @transactionsTileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get transactionsTileEdit;

  /// No description provided for @transactionsTileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionsTileDelete;

  /// No description provided for @transactionsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get transactionsDeleteConfirmTitle;

  /// No description provided for @transactionsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get transactionsDeleteConfirmBody;

  /// No description provided for @transactionsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionsDetailTitle;

  /// No description provided for @transactionsDetailEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get transactionsDetailEditTooltip;

  /// No description provided for @transactionsDetailDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionsDetailDeleteTooltip;

  /// No description provided for @transactionsDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading transaction...'**
  String get transactionsDetailLoading;

  /// No description provided for @transactionsDetailLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transaction'**
  String get transactionsDetailLoadFailedTitle;

  /// No description provided for @transactionsDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get transactionsDetailNotFoundTitle;

  /// No description provided for @transactionsDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted or your access changed.'**
  String get transactionsDetailNotFoundSubtitle;

  /// No description provided for @transactionsDetailBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get transactionsDetailBack;

  /// No description provided for @transactionsDetailInfoDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionsDetailInfoDate;

  /// No description provided for @transactionsDetailInfoPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get transactionsDetailInfoPaymentMethod;

  /// No description provided for @transactionsDetailInfoSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier linked'**
  String get transactionsDetailInfoSupplier;

  /// No description provided for @transactionsDetailInfoCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer linked'**
  String get transactionsDetailInfoCustomer;

  /// No description provided for @transactionsDetailInfoYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get transactionsDetailInfoYes;

  /// No description provided for @transactionsDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionsDetailNote;

  /// No description provided for @transactionsDetailTypeIndicator.
  ///
  /// In en, this message translates to:
  /// **'Type indicator'**
  String get transactionsDetailTypeIndicator;

  /// No description provided for @transactionsDetailCountsIncome.
  ///
  /// In en, this message translates to:
  /// **'Counts toward income totals'**
  String get transactionsDetailCountsIncome;

  /// No description provided for @transactionsDetailCountsExpense.
  ///
  /// In en, this message translates to:
  /// **'Counts toward expense totals'**
  String get transactionsDetailCountsExpense;

  /// No description provided for @transactionsDetailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{type} of {amount} on {date} will be removed.'**
  String transactionsDetailDeleteBody(String type, String amount, String date);

  /// No description provided for @transactionsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionsDeleteSuccess;

  /// No description provided for @transactionsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get transactionsDeleteFailed;

  /// No description provided for @transactionsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transactionsEditTitle;

  /// No description provided for @transactionsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionsAddTitle;

  /// No description provided for @transactionsEditButton.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get transactionsEditButton;

  /// No description provided for @transactionsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionsAddButton;

  /// No description provided for @transactionsSuccessAdd.
  ///
  /// In en, this message translates to:
  /// **'Transaction added'**
  String get transactionsSuccessAdd;

  /// No description provided for @transactionsSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionsSuccessUpdate;

  /// No description provided for @transactionsAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionsAmountLabel;

  /// No description provided for @transactionsAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get transactionsAmountHint;

  /// No description provided for @transactionsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionsCategoryLabel;

  /// No description provided for @transactionsPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get transactionsPaymentMethodLabel;

  /// No description provided for @transactionsDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionsDateLabel;

  /// No description provided for @transactionsNoteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get transactionsNoteOptionalLabel;

  /// No description provided for @transactionsNoteOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get transactionsNoteOptionalHint;

  /// No description provided for @transactionsCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get transactionsCategoryRequired;

  /// No description provided for @transactionsPaymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get transactionsPaymentMethodRequired;

  /// No description provided for @incomeListTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeListTitle;

  /// No description provided for @incomeListAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get incomeListAdd;

  /// No description provided for @incomeListEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get incomeListEdit;

  /// No description provided for @incomeListTooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get incomeListTooltipRefresh;

  /// No description provided for @incomeListLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading income...'**
  String get incomeListLoading;

  /// No description provided for @incomeListLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load income'**
  String get incomeListLoadFailedTitle;

  /// No description provided for @incomeListLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your income right now.'**
  String get incomeListLoadFailedSubtitle;

  /// No description provided for @incomeListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete income?'**
  String get incomeListDeleteTitle;

  /// No description provided for @incomeListDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{category} • {amount} on {date}'**
  String incomeListDeleteBody(String category, String amount, String date);

  /// No description provided for @incomeListDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Income deleted'**
  String get incomeListDeleteSuccess;

  /// No description provided for @incomeListDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete income'**
  String get incomeListDeleteFailed;

  /// No description provided for @incomeListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get incomeListEmptyTitle;

  /// No description provided for @incomeListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Income\" to record your first sale, service or payment.'**
  String get incomeListEmptySubtitle;

  /// No description provided for @incomeListSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get incomeListSummaryTitle;

  /// No description provided for @incomeListFilterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get incomeListFilterAllTime;

  /// No description provided for @incomeListFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get incomeListFilterToday;

  /// No description provided for @incomeListFilterMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get incomeListFilterMonth;

  /// No description provided for @incomeListSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String incomeListSummaryCount(int count);

  /// No description provided for @incomeListTileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get incomeListTileMore;

  /// No description provided for @incomeListEmptyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'No income matches the filter'**
  String get incomeListEmptyFilterTitle;

  /// No description provided for @incomeListEmptyFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different date or category to see more.'**
  String get incomeListEmptyFilterSubtitle;

  /// No description provided for @incomeListClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get incomeListClearFilters;

  /// No description provided for @incomeListTooltipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get incomeListTooltipAdd;

  /// No description provided for @incomeFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get incomeFormTitle;

  /// No description provided for @incomeFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get incomeFormEditTitle;

  /// No description provided for @incomeFormHeaderNew.
  ///
  /// In en, this message translates to:
  /// **'Record a new income'**
  String get incomeFormHeaderNew;

  /// No description provided for @incomeFormHeaderEdit.
  ///
  /// In en, this message translates to:
  /// **'Update this income record'**
  String get incomeFormHeaderEdit;

  /// No description provided for @incomeFormHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every transaction is tagged to your business and account.'**
  String get incomeFormHeaderSubtitle;

  /// No description provided for @incomeFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get incomeFormNoteLabel;

  /// No description provided for @incomeFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Order #42, project description'**
  String get incomeFormNoteHint;

  /// No description provided for @incomeFormNoteValidator.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get incomeFormNoteValidator;

  /// No description provided for @incomeFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Income'**
  String get incomeFormSaveButton;

  /// No description provided for @incomeFormUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Income'**
  String get incomeFormUpdateButton;

  /// No description provided for @incomeFormCreditSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded as a credit sale — customer due will update.'**
  String get incomeFormCreditSaleHint;

  /// No description provided for @incomeFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get incomeFormAmountLabel;

  /// No description provided for @incomeFormAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get incomeFormAmountHint;

  /// No description provided for @incomeFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get incomeFormCategoryLabel;

  /// No description provided for @incomeFormPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get incomeFormPaymentMethodLabel;

  /// No description provided for @incomeFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get incomeFormDateLabel;

  /// No description provided for @incomeFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get incomeFormCategoryRequired;

  /// No description provided for @incomeFormPaymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get incomeFormPaymentMethodRequired;

  /// No description provided for @incomeFormCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get incomeFormCustomerLabel;

  /// No description provided for @incomeFormCustomerNone.
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get incomeFormCustomerNone;

  /// No description provided for @incomeFormCustomerUnnamed.
  ///
  /// In en, this message translates to:
  /// **'(unnamed)'**
  String get incomeFormCustomerUnnamed;

  /// No description provided for @incomeFormAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add new customer'**
  String get incomeFormAddCustomer;

  /// No description provided for @incomeFormSuccessAdd.
  ///
  /// In en, this message translates to:
  /// **'Income added'**
  String get incomeFormSuccessAdd;

  /// No description provided for @incomeFormSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Income updated'**
  String get incomeFormSuccessUpdate;

  /// No description provided for @incomeFormFailedAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add income'**
  String get incomeFormFailedAdd;

  /// No description provided for @incomeFormFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update income'**
  String get incomeFormFailedUpdate;

  /// No description provided for @incomeFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get incomeFormDiscardTitle;

  /// No description provided for @incomeFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost if you leave now.'**
  String get incomeFormDiscardBody;

  /// No description provided for @incomeFormKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get incomeFormKeepEditing;

  /// No description provided for @incomeFormDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get incomeFormDiscard;

  /// No description provided for @incomeFormCustomerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added'**
  String get incomeFormCustomerAdded;

  /// No description provided for @expenseListTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseListTitle;

  /// No description provided for @expenseListAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseListAdd;

  /// No description provided for @expenseListEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseListEdit;

  /// No description provided for @expenseListTooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get expenseListTooltipRefresh;

  /// No description provided for @expenseListLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading expense...'**
  String get expenseListLoading;

  /// No description provided for @expenseListLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load expense'**
  String get expenseListLoadFailedTitle;

  /// No description provided for @expenseListLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your expense right now.'**
  String get expenseListLoadFailedSubtitle;

  /// No description provided for @expenseListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get expenseListDeleteTitle;

  /// No description provided for @expenseListDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{category} • {amount} on {date}'**
  String expenseListDeleteBody(String category, String amount, String date);

  /// No description provided for @expenseListDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseListDeleteSuccess;

  /// No description provided for @expenseListDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete expense'**
  String get expenseListDeleteFailed;

  /// No description provided for @expenseListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expense yet'**
  String get expenseListEmptyTitle;

  /// No description provided for @expenseListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Expense\" to record your first cost, rent or salary payment.'**
  String get expenseListEmptySubtitle;

  /// No description provided for @expenseListEmptyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'No expense matches the filter'**
  String get expenseListEmptyFilterTitle;

  /// No description provided for @expenseListEmptyFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different date or category to see more.'**
  String get expenseListEmptyFilterSubtitle;

  /// No description provided for @expenseListClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get expenseListClearFilters;

  /// No description provided for @expenseListSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get expenseListSummaryTitle;

  /// No description provided for @expenseListSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String expenseListSummaryCount(int count);

  /// No description provided for @expenseListFilterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get expenseListFilterAllTime;

  /// No description provided for @expenseListFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get expenseListFilterToday;

  /// No description provided for @expenseListFilterMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get expenseListFilterMonth;

  /// No description provided for @expenseListTileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get expenseListTileMore;

  /// No description provided for @expenseFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get expenseFormTitle;

  /// No description provided for @expenseFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseFormEditTitle;

  /// No description provided for @expenseFormHeaderNew.
  ///
  /// In en, this message translates to:
  /// **'Record a new expense'**
  String get expenseFormHeaderNew;

  /// No description provided for @expenseFormHeaderEdit.
  ///
  /// In en, this message translates to:
  /// **'Update this expense record'**
  String get expenseFormHeaderEdit;

  /// No description provided for @expenseFormHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every transaction is tagged to your business and account.'**
  String get expenseFormHeaderSubtitle;

  /// No description provided for @expenseFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get expenseFormNoteLabel;

  /// No description provided for @expenseFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Office rent for August, fuel refill'**
  String get expenseFormNoteHint;

  /// No description provided for @expenseFormNoteValidator.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expenseFormNoteValidator;

  /// No description provided for @expenseFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get expenseFormSaveButton;

  /// No description provided for @expenseFormUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get expenseFormUpdateButton;

  /// No description provided for @expenseFormCreditPurchaseHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded as a credit purchase — supplier due will update.'**
  String get expenseFormCreditPurchaseHint;

  /// No description provided for @expenseFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseFormAmountLabel;

  /// No description provided for @expenseFormAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get expenseFormAmountHint;

  /// No description provided for @expenseFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseFormCategoryLabel;

  /// No description provided for @expenseFormPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get expenseFormPaymentMethodLabel;

  /// No description provided for @expenseFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseFormDateLabel;

  /// No description provided for @expenseFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get expenseFormCategoryRequired;

  /// No description provided for @expenseFormPaymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get expenseFormPaymentMethodRequired;

  /// No description provided for @expenseFormSupplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get expenseFormSupplierLabel;

  /// No description provided for @expenseFormSupplierNone.
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get expenseFormSupplierNone;

  /// No description provided for @expenseFormSupplierUnnamed.
  ///
  /// In en, this message translates to:
  /// **'(unnamed)'**
  String get expenseFormSupplierUnnamed;

  /// No description provided for @expenseFormAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add new supplier'**
  String get expenseFormAddSupplier;

  /// No description provided for @expenseFormSuccessAdd.
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get expenseFormSuccessAdd;

  /// No description provided for @expenseFormSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Expense updated'**
  String get expenseFormSuccessUpdate;

  /// No description provided for @expenseFormFailedAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add expense'**
  String get expenseFormFailedAdd;

  /// No description provided for @expenseFormFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update expense'**
  String get expenseFormFailedUpdate;

  /// No description provided for @expenseFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get expenseFormDiscardTitle;

  /// No description provided for @expenseFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost if you leave now.'**
  String get expenseFormDiscardBody;

  /// No description provided for @expenseFormKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get expenseFormKeepEditing;

  /// No description provided for @expenseFormDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get expenseFormDiscard;

  /// No description provided for @expenseFormSupplierAdded.
  ///
  /// In en, this message translates to:
  /// **'Supplier added'**
  String get expenseFormSupplierAdded;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAppBarTitle;

  /// No description provided for @reportsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reports'**
  String get reportsErrorTitle;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add income or expense to see your reports.'**
  String get reportsEmptySubtitle;

  /// No description provided for @reportsActionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get reportsActionRefresh;

  /// No description provided for @reportsPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsPeriodToday;

  /// No description provided for @reportsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get reportsPeriodWeek;

  /// No description provided for @reportsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get reportsPeriodMonth;

  /// No description provided for @reportsPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsPeriodCustom;

  /// No description provided for @reportsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsFilterAll;

  /// No description provided for @reportsSummaryTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get reportsSummaryTotalIncome;

  /// No description provided for @reportsSummaryTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get reportsSummaryTotalExpense;

  /// No description provided for @reportsSummaryNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get reportsSummaryNetProfit;

  /// No description provided for @reportsSummaryMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get reportsSummaryMargin;

  /// No description provided for @reportsSummaryCustomerDue.
  ///
  /// In en, this message translates to:
  /// **'Customer Due'**
  String get reportsSummaryCustomerDue;

  /// No description provided for @reportsSummarySupplierDue.
  ///
  /// In en, this message translates to:
  /// **'Supplier Due'**
  String get reportsSummarySupplierDue;

  /// No description provided for @reportsBreakdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {title} recorded in this period.'**
  String reportsBreakdownEmpty(String title);

  /// No description provided for @reportsBreakdownCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String reportsBreakdownCount(num count);

  /// No description provided for @reportsIncomeExpenseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No income or expense in this period yet.'**
  String get reportsIncomeExpenseEmpty;

  /// No description provided for @reportsChartLabelIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsChartLabelIncome;

  /// No description provided for @reportsChartLabelExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get reportsChartLabelExpense;

  /// No description provided for @reportsTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trend needs at least 2 days of data.'**
  String get reportsTrendEmpty;

  /// No description provided for @reportsChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data to chart yet.'**
  String get reportsChartEmpty;

  /// No description provided for @reportsCategoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get reportsCategoryUncategorized;

  /// No description provided for @reportsChartIncomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get reportsChartIncomeVsExpense;

  /// No description provided for @reportsChartProfitTrend.
  ///
  /// In en, this message translates to:
  /// **'Profit Trend'**
  String get reportsChartProfitTrend;

  /// No description provided for @reportsChartIncomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Income Categories'**
  String get reportsChartIncomeCategories;

  /// No description provided for @reportsChartExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get reportsChartExpenseCategories;

  /// No description provided for @reportsBreakdownIncome.
  ///
  /// In en, this message translates to:
  /// **'Income breakdown'**
  String get reportsBreakdownIncome;

  /// No description provided for @reportsBreakdownExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense breakdown'**
  String get reportsBreakdownExpense;

  /// No description provided for @reportsTransactionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Transactions in this period'**
  String get reportsTransactionsHeading;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No report data yet'**
  String get reportsEmpty;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get errorAuthFailed;

  /// No description provided for @errorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {message}'**
  String errorSignInFailed(String message);

  /// No description provided for @errorInit.
  ///
  /// In en, this message translates to:
  /// **'Initialization error: {message}'**
  String errorInit(String message);

  /// No description provided for @errorManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to manage your subscription.'**
  String get errorManageSubscription;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
