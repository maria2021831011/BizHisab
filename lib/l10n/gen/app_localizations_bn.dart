// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'বিজহিসাব এআই';

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonSave => 'সংরক্ষণ করুন';

  @override
  String get commonDelete => 'মুছে ফেলুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonClose => 'বন্ধ করুন';

  @override
  String get commonOk => 'ঠিক আছে';

  @override
  String get commonYes => 'হ্যাঁ';

  @override
  String get commonNo => 'না';

  @override
  String get commonBack => 'পেছনে';

  @override
  String get commonLoading => 'লোড হচ্ছে...';

  @override
  String get commonSearch => 'অনুসন্ধান';

  @override
  String get navDashboard => 'ড্যাশবোর্ড';

  @override
  String get navTransactions => 'লেনদেন';

  @override
  String get navCustomers => 'ক্রেতা';

  @override
  String get navSuppliers => 'সরবরাহকারী';

  @override
  String get navPeople => 'ক্রেতা ও সরবরাহকারী';

  @override
  String get navReports => 'রিপোর্ট';

  @override
  String get navAi => 'এআই';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get landingTitle => 'বিজহিসাব এআই';

  @override
  String get landingTagline => 'স্মার্ট ব্যবসায়িক হিসাব';

  @override
  String get landingGetStarted => 'শুরু করুন';

  @override
  String get authMobileTitle => 'মোবাইল নম্বর দিন';

  @override
  String get authMobileHeadline => 'আপনার মোবাইল নম্বর দিন';

  @override
  String get authMobileSub => 'আমরা আপনাকে একটি যাচাই কোড পাঠাব';

  @override
  String get authMobileFormat =>
      'ফরম্যাট: 01XXXXXXXXX (১১ ডিজিট, যেকোনো বিডি অপারেটর)';

  @override
  String get authMobileSendOtp => 'ওটিপি পাঠান';

  @override
  String get authMobileInvalid => 'ভুল নম্বর ফরম্যাট';

  @override
  String get authMobileChangeNumber => 'অন্য নম্বর ব্যবহার করুন';

  @override
  String get authOtpTitle => 'ওটিপি যাচাই করুন';

  @override
  String get authOtpHeadline => 'যাচাই কোড দিন';

  @override
  String authOtpSentTo(String number) {
    return '+৮৮ $number নম্বরে কোড পাঠানো হয়েছে';
  }

  @override
  String authOtpResendIn(int seconds) {
    return '$seconds সেকেন্ডে আবার পাঠান';
  }

  @override
  String get authOtpResend => 'আবার পাঠান';

  @override
  String get authOtpSending => 'পাঠানো হচ্ছে...';

  @override
  String get authOtpResentSuccess => 'ওটিপি সফলভাবে আবার পাঠানো হয়েছে';

  @override
  String get authOtpVerify => 'যাচাই করুন';

  @override
  String get authOtpIncomplete => 'সম্পূর্ণ ওটিপি দিন';

  @override
  String get authOtpInvalid => 'ভুল ওটিপি';

  @override
  String get authOtpRequestFirst => 'আগে ওটিপি চান';

  @override
  String get authOtpVerifyFailed => 'যাচাই ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get subscriptionTitle => 'প্রিমিয়াম সাবস্ক্রিপশন';

  @override
  String get subscriptionBrand => 'বিজহিসাব প্রিমিয়াম';

  @override
  String get subscriptionBlurb =>
      'বিজহিসাব এআই ব্যবহার করতে সাবস্ক্রিপশন প্রয়োজন। আপনার মোবাইল অপারেটরের মাধ্যমে সাবস্ক্রাইব করুন।';

  @override
  String get subscriptionFeatureTracking => 'সম্পূর্ণ লেনদেন ট্র্যাকিং';

  @override
  String get subscriptionFeatureCustomers => 'ক্রেতা ও সরবরাহকারী ব্যবস্থাপনা';

  @override
  String get subscriptionFeatureInsights => 'এআই চালিত আর্থিক পরামর্শ';

  @override
  String get subscriptionFeatureReports => 'বিস্তারিত রিপোর্ট ও বিশ্লেষণ';

  @override
  String get subscriptionFeatureChatbot =>
      'এআই ব্যবসায়িক চ্যাটবট (বাংলা/ইংরেজি)';

  @override
  String get subscriptionFeatureCloud => 'ক্লাউডে ডাটা সংরক্ষণ';

  @override
  String get subscriptionSubscribe => 'এখনই সাবস্ক্রাইব করুন';

  @override
  String get subscriptionSendingOtp => 'ওটিপি পাঠানো হচ্ছে...';

  @override
  String get subscriptionEnterOtp =>
      'সাবস্ক্রিপশন নিশ্চিত করতে BdApps থেকে পাঠানো ওটিপি দিন।';

  @override
  String get subscriptionConfirm => 'সাবস্ক্রিপশন নিশ্চিত করুন';

  @override
  String get subscriptionAlreadyPaid =>
      'ইতিমধ্যে পেমেন্ট করেছেন? এখনই যাচাই করুন';

  @override
  String get subscriptionChecking => 'সাবস্ক্রিপশন যাচাই হচ্ছে...';

  @override
  String get subscriptionNotYetActive =>
      'সাবস্ক্রিপশন এখনো সক্রিয় হয়নি। ৩০ সেকেন্ড অপেক্ষা করে \"আবার ওটিপি পাঠান\" চাপুন — আপনার পেমেন্ট নিশ্চিত হতে একটু সময় লাগতে পারে।';

  @override
  String get subscriptionResent =>
      'সাবস্ক্রিপশন ওটিপি সফলভাবে আবার পাঠানো হয়েছে';

  @override
  String subscriptionResendIn(int seconds) {
    return '$seconds সেকেন্ডে আবার পাঠান';
  }

  @override
  String get subscriptionResendOtp => 'আবার ওটিপি পাঠান';

  @override
  String get subscriptionStartFailed => 'সাবস্ক্রিপশন শুরু করা যায়নি';

  @override
  String get subscriptionPhoneMissing =>
      'ফোন নম্বর পাওয়া যায়নি। আবার লগইন করুন।';

  @override
  String get subscriptionAuthMissing => 'ফোন নম্বর পাওয়া যায়নি।';

  @override
  String get subscriptionRequestOtpFirst => 'আগে সাবস্ক্রিপশন ওটিপি চান';

  @override
  String get setupTitle => 'ব্যবসা সেটআপ';

  @override
  String get setupBusinessName => 'ব্যবসার নাম';

  @override
  String get setupBusinessNameHint => 'যেমন: রহমান ট্রেডার্স';

  @override
  String get setupBusinessType => 'ব্যবসার ধরন';

  @override
  String get setupBusinessTypeRequired => 'ব্যবসার ধরন আবশ্যক';

  @override
  String get setupOwnerName => 'মালিকের নাম';

  @override
  String get setupPhone => 'ফোন';

  @override
  String get setupPhoneOptional => 'ফোন (ঐচ্ছিক)';

  @override
  String get setupPhoneHint => '০১XXXXXXXXX';

  @override
  String get setupAddress => 'ঠিকানা';

  @override
  String get setupAddressOptional => 'ঠিকানা (ঐচ্ছিক)';

  @override
  String get setupAddressHint => 'ব্যবসার ঠিকানা';

  @override
  String get setupCurrency => 'মুদ্রা';

  @override
  String get setupSave => 'সংরক্ষণ করে এগিয়ে যান';

  @override
  String get setupHeadline => 'আপনার ব্যবসা সেটআপ করুন';

  @override
  String get setupSub =>
      'আপনার ব্যবসা সম্পর্কে কিছু তথ্য দিন যাতে আমরা আপনার ড্যাশবোর্ড নিজের মতো করে সাজাতে পারি।';

  @override
  String get setupPrivacyNote =>
      'আপনার তথ্য গোপনীয় এবং আপনার অ্যাকাউন্টের সাথে সংযুক্ত।';

  @override
  String get setupSessionExpired => 'সেশনের মেয়াদ শেষ। আবার লগইন করুন।';

  @override
  String get setupSaveFailed => 'ব্যবসা তৈরি করা যায়নি।';

  @override
  String get currencyBdt => 'বিডিটি (৳) — বাংলাদেশি টাকা';

  @override
  String get currencyUsd => 'ইউএসডি (\$) — মার্কিন ডলার';

  @override
  String get currencyInr => 'আইএনআর (₹) — ভারতীয় রুপি';

  @override
  String get currencyEur => 'ইইউআর (€) — ইউরো';

  @override
  String get dashboardTitle => 'ড্যাশবোর্ড';

  @override
  String get dashboardRefresh => 'রিফ্রেশ';

  @override
  String get dashboardLoadFailed => 'ড্যাশবোর্ড লোড করা যায়নি';

  @override
  String get dashboardToday => 'আজ';

  @override
  String get dashboardMonth => 'এই মাসে';

  @override
  String get dashboardTodaySales => 'আজকের বিক্রি';

  @override
  String get dashboardTodayExpense => 'আজকের খরচ';

  @override
  String get dashboardTodayProfit => 'আজকের লাভ';

  @override
  String get dashboardIncome => 'আয়';

  @override
  String get dashboardExpense => 'খরচ';

  @override
  String get dashboardProfit => 'লাভ';

  @override
  String get dashboardCustomerDue => 'ক্রেতার বকেয়া';

  @override
  String get dashboardSupplierDue => 'সরবরাহকারীর বকেয়া';

  @override
  String get dashboardAddIncome => 'আয় যোগ করুন';

  @override
  String get dashboardAddExpense => 'খরচ যোগ করুন';

  @override
  String get dashboardDue => 'বকেয়া পাওনা';

  @override
  String get dashboardQuickActions => 'দ্রুত অ্যাকশন';

  @override
  String get dashboardGreeting => 'স্বাগতম';

  @override
  String get dashboardBusinessFallback => 'আপনার ব্যবসা';

  @override
  String get dashboardSeeAll => 'সব দেখুন';

  @override
  String get dashboardRecentTransactions => 'সাম্প্রতিক লেনদেন';

  @override
  String get dashboardAiInsight => 'এআই পরামর্শ';

  @override
  String get dashboardAiInsightSub => 'ব্যক্তিগতকৃত আর্থিক ইনসাইট শীঘ্রই আসছে';

  @override
  String get dashboardBeta => 'বেটা';

  @override
  String get dashboardTodayLoss => 'আজকের ক্ষতি';

  @override
  String get dashboardProfile => 'প্রোফাইল';

  @override
  String get dashboardGreetingMorning => 'সুপ্রভাত';

  @override
  String get dashboardGreetingAfternoon => 'শুভ দুপুর';

  @override
  String get dashboardGreetingEvening => 'শুভ সন্ধ্যা';

  @override
  String get dashboardGreetingNight => 'শুভ রাত্রি';

  @override
  String get dashboardEmptySubtitle =>
      'শুরু করতে আপনার প্রথম আয় বা খরচ যোগ করুন।';

  @override
  String get dashboardIncomeGeneric => 'আয়';

  @override
  String get dashboardExpenseGeneric => 'খরচ';

  @override
  String get profileTitle => 'প্রোফাইল';

  @override
  String get profileBusinessOwner => 'ব্যবসার মালিক';

  @override
  String get profileUnknownUser => 'অজানা';

  @override
  String get profileNoBusiness => 'কোনো ব্যবসার প্রোফাইল সেটআপ করা হয়নি';

  @override
  String get profileBusinessInfo => 'ব্যবসার তথ্য';

  @override
  String get profileFieldBusinessName => 'ব্যবসার নাম';

  @override
  String get profileFieldType => 'ধরন';

  @override
  String get profileFieldOwner => 'মালিক';

  @override
  String get profileFieldPhone => 'ফোন';

  @override
  String get profileFieldAddress => 'ঠিকানা';

  @override
  String get profileFieldCurrency => 'মুদ্রা';

  @override
  String get profileSubscriptionTitle => 'বিজহিসাব এআই প্রিমিয়াম';

  @override
  String get profileSubscriptionActive => 'সক্রিয়';

  @override
  String get profileSubscriptionInactive => 'নিষ্ক্রিয়';

  @override
  String get profileSubscriptionMonthly => 'মাসিক';

  @override
  String get profileUnsubscribe => 'সাবস্ক্রিপশন বাতিল';

  @override
  String get profileUnsubscribeSubtitle =>
      'আপনার মাসিক বিজহিসাব এআই প্রিমিয়াম সাবস্ক্রিপশন বাতিল করুন';

  @override
  String get profileUnsubscribeTitle => 'সাবস্ক্রিপশন বাতিল করবেন?';

  @override
  String get profileUnsubscribeBody =>
      'আপনি কি নিশ্চিত যে আপনার বিজহিসাব এআই প্রিমিয়াম সাবস্ক্রিপশন বাতিল করতে চান? পরবর্তী লগইনে আপনি প্রিমিয়াম ফিচার হারাবেন।';

  @override
  String get profileKeepSubscription => 'সাবস্ক্রিপশন রাখুন';

  @override
  String get profileUnsubscribeSuccess =>
      'আপনার সাবস্ক্রিপশন সফলভাবে বাতিল হয়েছে।';

  @override
  String get profileUnsubscribeFailed =>
      'সাবস্ক্রিপশন বাতিল করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get profileEditBusiness => 'ব্যবসা সম্পাদনা';

  @override
  String get profileLogout => 'লগআউট';

  @override
  String get profileLogoutTitle => 'লগআউট';

  @override
  String get profileLogoutBody => 'আপনি কি নিশ্চিত যে লগআউট করতে চান?';

  @override
  String get aiTitle => 'এআই সহকারী';

  @override
  String get aiInsights => 'এআই পরামর্শ';

  @override
  String get aiChat => 'এআই চ্যাট';

  @override
  String get aiAskPlaceholder => 'আপনার ব্যবসা সম্পর্কে যেকোনো প্রশ্ন করুন...';

  @override
  String get aiSend => 'পাঠান';

  @override
  String get aiOffline => 'এআই সেবা অফলাইন';

  @override
  String get aiTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get aiSignInRequired => 'এআই ব্যবহার করতে সাইন ইন করুন।';

  @override
  String get aiInsightsSub =>
      'আপনার ব্যবসার কার্যক্ষমতার একটি গঠিত সারসংক্ষেপ পান।';

  @override
  String get aiChatSub => 'বাংলা, বাংলিশ বা ইংরেজিতে প্রশ্ন জিজ্ঞাসা করুন।';

  @override
  String get aiFreeTierNotice =>
      'এআই একটি ফ্রি-টিয়ার মডেলে চলে। সেবা অনুপলব্ধ থাকলে আপনার অন্যান্য ফিচার কাজ করতে থাকবে — পরে আবার চেষ্টা করুন।';

  @override
  String get aiKeyFindings => 'মূল অনুসন্ধান';

  @override
  String get aiRecommendations => 'সুপারিশ';

  @override
  String aiConfidence(String level) {
    return '$level আত্মবিশ্বাস';
  }

  @override
  String get aiChatEmpty =>
      'আপনার ব্যবসা সম্পর্কে যেকোনো কিছু জিজ্ঞাসা করুন। উত্তর বাংলা, বাংলিশ বা ইংরেজিতে হতে পারে।';

  @override
  String get aiThinking => 'এআই ভাবছে...';

  @override
  String get aiChatPlaceholder => 'আপনার ব্যবসা সম্পর্কে জিজ্ঞাসা করুন...';

  @override
  String get aiClearChat => 'চ্যাট মুছুন';

  @override
  String get aiInsightsEmpty =>
      'এখনো কোনো ইনসাইট নেই। উপরে একটি রিপোর্ট ধরন বেছে নিন।';

  @override
  String get aiOfflineBanner =>
      'এআই সার্ভারে পৌঁছানো যাচ্ছে না। ব্যাকএন্ড চালু করুন এবং `adb reverse tcp:8000 tcp:8000` রান করুন।';

  @override
  String get transactionsTitle => 'লেনদেন';

  @override
  String get transactionsAdd => 'লেনদেন যোগ করুন';

  @override
  String get transactionsEmpty => 'এখনো কোনো লেনদেন নেই';

  @override
  String get customersTitle => 'ক্রেতা';

  @override
  String get customersAdd => 'ক্রেতা যোগ করুন';

  @override
  String get customersEmpty => 'এখনো কোনো ক্রেতা নেই';

  @override
  String get customersTotalPurchase => 'মোট কেনাকাটা';

  @override
  String get customersTotalPaid => 'মোট পরিশোধ';

  @override
  String get customersTotalDue => 'মোট বকেয়া';

  @override
  String get customersRecordPayment => 'পেমেন্ট রেকর্ড করুন';

  @override
  String get customersEditCustomer => 'ক্রেতা সম্পাদনা';

  @override
  String get customersName => 'নাম';

  @override
  String get customersPhone => 'ফোন';

  @override
  String get customersAddress => 'ঠিকানা';

  @override
  String get customersSort => 'সাজান';

  @override
  String get customersSortNameAsc => 'নাম (ক-য)';

  @override
  String get customersSortDueDesc => 'বকেয়া (বেশি থেকে কম)';

  @override
  String get customersSortRecent => 'সাম্প্রতিক';

  @override
  String get customersSearchHint => 'নাম বা ফোন দিয়ে খুঁজুন...';

  @override
  String get customersTotalDueCard => 'ক্রেতার মোট বকেয়া';

  @override
  String get customersLoadFailed => 'ক্রেতাদের লোড করতে ব্যর্থ';

  @override
  String get customersSearchEmpty => 'আপনার অনুসন্ধানের সাথে কোনো ক্রেতা নেই';

  @override
  String get customersSearchEmptySubtitle => 'অন্য নাম বা ফোন চেষ্টা করুন।';

  @override
  String get customersAddSubtitle =>
      'বকেয়া ট্র্যাকিং শুরু করতে একজন ক্রেতা যোগ করুন।';

  @override
  String get customersChipDue => 'বকেয়া';

  @override
  String get customersChipSettled => 'পরিশোধিত';

  @override
  String get customersDetailTitle => 'ক্রেতার বিস্তারিত';

  @override
  String get customersNotFound => 'ক্রেতা পাওয়া যায়নি';

  @override
  String get customersDueBalance => 'বকেয়া পরিমাণ';

  @override
  String get customersAddressLabel => 'ঠিকানা';

  @override
  String get customersCreditSales => 'বাকিতে বিক্রয়';

  @override
  String get customersLoadingCreditSales => 'বাকিতে বিক্রয় লোড হচ্ছে...';

  @override
  String get customersCreditSalesEmpty => 'এখনো কোনো বাকিতে বিক্রয় নেই';

  @override
  String get customersCreditSalesEmptySubtitle =>
      'এই ক্রেতার জন্য বকেয়া হিসেবে চিহ্নিত বিক্রয় এখানে দেখা যাবে।';

  @override
  String get customersPaymentHistory => 'পেমেন্টের ইতিহাস';

  @override
  String get customersLoadingPayments => 'পেমেন্ট লোড হচ্ছে...';

  @override
  String get customersPaymentsEmpty => 'এখনো কোনো পেমেন্ট নেই';

  @override
  String get customersPaymentsEmptySubtitle =>
      'রেকর্ড করা পেমেন্টগুলো এখানে দেখা যাবে।';

  @override
  String get customersPaymentRecorded => 'পেমেন্ট রেকর্ড হয়েছে';

  @override
  String get customersDeleteTitle => 'ক্রেতা মুছুন';

  @override
  String get customersDeleteBody =>
      'আপনি কি নিশ্চিত যে এই ক্রেতাকে মুছতে চান? সম্পর্কিত লেনদেন তাদের রেফারেন্স রাখবে।';

  @override
  String get customersFormNameLabel => 'ক্রেতার নাম';

  @override
  String get customersFormNameHint => 'যেমন, রহিম এন্টারপ্রাইজ';

  @override
  String get customersFormPhoneLabel => 'ফোন নম্বর';

  @override
  String get customersFormAddressLabel => 'ঠিকানা (ঐচ্ছিক)';

  @override
  String get customersFormAddressHint => 'যেমন, ১২ মিরপুর রোড, ঢাকা';

  @override
  String get customersUpdateCustomer => 'ক্রেতা আপডেট করুন';

  @override
  String get customersDiscardTitle => 'পরিবর্তন বাতিল করবেন?';

  @override
  String get customersDiscardBody =>
      'আপনি এখন চলে গেলে আপনার সম্পাদনা হারিয়ে যাবে।';

  @override
  String get customersKeepEditing => 'সম্পাদনা চালিয়ে যান';

  @override
  String get customersDiscard => 'বাতিল';

  @override
  String get customersPaymentAmountLabel => 'পরিমাণ';

  @override
  String get customersPaymentAmountHint => '০.০০';

  @override
  String get customersPaymentEnterValid => 'একটি সঠিক পরিমাণ লিখুন';

  @override
  String get customersPaymentNoteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get customersPaymentNoteHint => 'যেমন, ইনভয়েস #১২ এর আংশিক পেমেন্ট';

  @override
  String get customersPaymentSave => 'পেমেন্ট সংরক্ষণ';

  @override
  String get customersPaymentCurrentDue => 'বর্তমান বকেয়া';

  @override
  String get customersPaymentDateLabel => 'পেমেন্টের তারিখ';

  @override
  String get customersPaymentMethodLabel => 'পেমেন্টের পদ্ধতি';

  @override
  String get customersPaymentAfterTitle => 'এই পেমেন্টের পর';

  @override
  String get customersPaymentNewDue => 'নতুন বকেয়া';

  @override
  String get customersPaymentExceedsDue => 'বকেয়ার বেশি';

  @override
  String get customersPaymentNotSignedIn => 'সাইন ইন করা হয়নি';

  @override
  String get customersPaymentFailed => 'পেমেন্ট রেকর্ড করতে ব্যর্থ';

  @override
  String customersPaymentExceedsBody(Object amount, Object balance) {
    return 'পেমেন্ট ($amount) বকেয়ার পরিমাণ ($balance) এর চেয়ে বেশি।';
  }

  @override
  String customersPaymentExceedsHint(Object amount) {
    return 'পরিমাণ বর্তমান বকেয়ার চেয়ে বেশি — সর্বোচ্চ $amount পরিশোধ করা যাবে';
  }

  @override
  String get suppliersTitle => 'সরবরাহকারী';

  @override
  String get suppliersAdd => 'সরবরাহকারী যোগ করুন';

  @override
  String get suppliersEmpty => 'এখনো কোনো সরবরাহকারী নেই';

  @override
  String get suppliersRecordPayment => 'পেমেন্ট রেকর্ড করুন';

  @override
  String get suppliersEditSupplier => 'সরবরাহকারী সম্পাদনা';

  @override
  String get suppliersName => 'নাম';

  @override
  String get suppliersPhone => 'ফোন';

  @override
  String get suppliersAddress => 'ঠিকানা';

  @override
  String get suppliersSort => 'সাজান';

  @override
  String get suppliersSortNameAsc => 'নাম (ক-য)';

  @override
  String get suppliersSortDueDesc => 'বকেয়া (বেশি থেকে কম)';

  @override
  String get suppliersSortRecent => 'সাম্প্রতিক';

  @override
  String get suppliersSearchHint => 'নাম, ফোন বা ঠিকানা দিয়ে খুঁজুন...';

  @override
  String get suppliersTotalDueCard => 'সরবরাহকারীর মোট বকেয়া';

  @override
  String get suppliersLoadFailed => 'সরবরাহকারী লোড করা যায়নি';

  @override
  String get suppliersSearchEmpty =>
      'কোনো সরবরাহকারী আপনার অনুসন্ধানের সাথে মেলে না';

  @override
  String get suppliersSearchEmptySubtitle =>
      'অন্য নাম, ফোন বা ঠিকানা দিয়ে চেষ্টা করুন।';

  @override
  String get suppliersAddSubtitle =>
      'বকেয়া হিসাব শুরু করতে একজন সরবরাহকারী যোগ করুন।';

  @override
  String get suppliersDetailTitle => 'সরবরাহকারীর বিস্তারিত';

  @override
  String get suppliersNotFound => 'সরবরাহকারী পাওয়া যায়নি';

  @override
  String get suppliersTotalPurchase => 'মোট ক্রয়';

  @override
  String get suppliersTotalPaid => 'মোট পরিশোধ';

  @override
  String get suppliersDueBalance => 'বকেয়ার পরিমাণ';

  @override
  String get suppliersCreditPurchases => 'বাকিতে ক্রয়';

  @override
  String get suppliersLoadingCreditPurchases => 'বাকিতে ক্রয় লোড হচ্ছে...';

  @override
  String get suppliersCreditPurchasesEmpty => 'এখনো কোনো বাকিতে ক্রয় নেই';

  @override
  String get suppliersCreditPurchasesEmptySubtitle =>
      'এই সরবরাহকারীর জন্য বাকি হিসাবে চিহ্নিত ক্রয় এখানে দেখা যাবে।';

  @override
  String get suppliersPaymentHistory => 'পেমেন্ট ইতিহাস';

  @override
  String get suppliersLoadingPayments => 'পেমেন্ট লোড হচ্ছে...';

  @override
  String get suppliersPaymentsEmpty => 'এখনো কোনো পেমেন্ট নেই';

  @override
  String get suppliersPaymentsEmptySubtitle =>
      'রেকর্ডকৃত পেমেন্ট এখানে দেখা যাবে।';

  @override
  String get suppliersPaymentRecorded => 'পেমেন্ট রেকর্ড হয়েছে';

  @override
  String get suppliersDeleteTitle => 'সরবরাহকারী মুছে ফেলুন';

  @override
  String get suppliersDeleteBody =>
      'আপনি কি নিশ্চিত যে এই সরবরাহকারীকে মুছে ফেলতে চান? সম্পর্কিত খরচের রেফারেন্স বজায় থাকবে।';

  @override
  String get suppliersFormNameLabel => 'সরবরাহকারীর নাম';

  @override
  String get suppliersFormNameHint => 'যেমন, ঢাকা ট্রেডার্স';

  @override
  String get suppliersFormPhoneLabel => 'ফোন নম্বর';

  @override
  String get suppliersFormPhoneHint => '০১XXXXXXXXX';

  @override
  String get suppliersUpdateSupplier => 'সরবরাহকারী আপডেট করুন';

  @override
  String get suppliersDiscardTitle => 'পরিবর্তন বাতিল করবেন?';

  @override
  String get suppliersDiscardBody =>
      'আপনি এখন চলে গেলে আপনার সম্পাদনা হারিয়ে যাবে।';

  @override
  String get suppliersDiscardPaymentTitle => 'পেমেন্ট বাতিল করবেন?';

  @override
  String get suppliersDiscardPaymentBody =>
      'আপনি এখন চলে গেলে আপনার পেমেন্টের তথ্য হারিয়ে যাবে।';

  @override
  String get suppliersKeepEditing => 'সম্পাদনা চালিয়ে যান';

  @override
  String get suppliersDiscard => 'বাতিল';

  @override
  String get suppliersPaymentAmountLabel => 'পরিমাণ';

  @override
  String get suppliersPaymentAmountHint => '০.০০';

  @override
  String get suppliersPaymentEnterValid => 'একটি সঠিক পরিমাণ লিখুন';

  @override
  String get suppliersPaymentDateLabel => 'পেমেন্টের তারিখ';

  @override
  String get suppliersPaymentMethodLabel => 'পেমেন্টের পদ্ধতি';

  @override
  String get suppliersPaymentNoteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get suppliersPaymentNoteHint =>
      'যেমন, চালান #১২ এর বিপরীতে আংশিক পেমেন্ট';

  @override
  String get suppliersPaymentSave => 'পেমেন্ট সংরক্ষণ';

  @override
  String get suppliersPaymentCurrentDue => 'বর্তমান বকেয়া';

  @override
  String get suppliersPaymentCurrentDueSettled => 'নিষ্পত্তি হয়েছে';

  @override
  String get suppliersPaymentAfterTitle => 'এই পেমেন্টের পর';

  @override
  String suppliersPaymentNewDue(String amount) {
    return 'নতুন বকেয়া: $amount';
  }

  @override
  String suppliersPaymentTotalPaidAfter(String amount) {
    return 'এই পেমেন্টের পর মোট পরিশোধ: $amount';
  }

  @override
  String get suppliersPaymentExceedsDue => 'বকেয়ার বেশি';

  @override
  String suppliersPaymentExceedsHint(String amount) {
    return 'পরিমাণ বর্তমান বকেয়ার চেয়ে বেশি — একটি পেমেন্টে সর্বোচ্চ $amount নিষ্পত্তি করা যাবে';
  }

  @override
  String get suppliersPaymentNotSignedIn => 'সাইন ইন করা হয়নি';

  @override
  String get suppliersPaymentFailed => 'পেমেন্ট রেকর্ড করা যায়নি';

  @override
  String suppliersPaymentExceedsBody(String amount, String balance) {
    return 'পেমেন্ট ($amount) বকেয়ার পরিমাণ ($balance) এর চেয়ে বেশি।';
  }

  @override
  String get incomeTitle => 'আয়';

  @override
  String get incomeAdd => 'আয় যোগ করুন';

  @override
  String get incomeEmpty => 'এখনো কোনো আয় রেকর্ড করা হয়নি';

  @override
  String get incomeEditIncome => 'আয় সম্পাদনা';

  @override
  String get expenseTitle => 'খরচ';

  @override
  String get expenseAdd => 'খরচ যোগ করুন';

  @override
  String get expenseEmpty => 'এখনো কোনো খরচ রেকর্ড করা হয়নি';

  @override
  String get expenseEditExpense => 'খরচ সম্পাদনা';

  @override
  String get transactionsHistoryTitle => 'লেনদেনের ইতিহাস';

  @override
  String get transactionsNewBtn => 'নতুন';

  @override
  String get transactionsRefresh => 'রিফ্রেশ';

  @override
  String get transactionsSummaryIncome => 'আয়';

  @override
  String get transactionsSummaryExpense => 'খরচ';

  @override
  String get transactionsSummaryNet => 'নিট';

  @override
  String get transactionsSearchHint => 'ক্যাটাগরি বা নোট দিয়ে খুঁজুন...';

  @override
  String get transactionsDateAll => 'সব সময়';

  @override
  String get transactionsDateToday => 'আজ';

  @override
  String get transactionsDateWeek => 'এই সপ্তাহ';

  @override
  String get transactionsDateMonth => 'এই মাস';

  @override
  String get transactionsDateCustom => 'কাস্টম';

  @override
  String get transactionsTypeAll => 'সব';

  @override
  String get transactionsTypeIncome => 'আয়';

  @override
  String get transactionsTypeExpense => 'খরচ';

  @override
  String get transactionsAllCategories => 'সব ক্যাটাগরি';

  @override
  String get transactionsLoading => 'লেনদেন লোড হচ্ছে...';

  @override
  String get transactionsLoadFailedTitle => 'লেনদেন লোড করা যায়নি';

  @override
  String get transactionsRetry => 'আবার চেষ্টা করুন';

  @override
  String get transactionsEmptyTitle => 'কোনো লেনদেন পাওয়া যায়নি';

  @override
  String get transactionsEmptySubtitle =>
      'তারিখের পরিসীমা বাড়ান বা অনুসন্ধান সাফ করুন।';

  @override
  String get transactionsResetFilters => 'ফিল্টার রিসেট করুন';

  @override
  String get transactionsLoadMore => 'আরও লোড করুন';

  @override
  String get transactionsEndOfList => 'তালিকার শেষ';

  @override
  String get transactionsBadgeIncome => 'আয়';

  @override
  String get transactionsBadgeExpense => 'খরচ';

  @override
  String get transactionsSearchTransactions => 'লেনদেন খুঁজুন...';

  @override
  String get transactionsSearchEmpty => 'এখনো কোনো লেনদেন নেই';

  @override
  String get transactionsSearchEmptySubtitle =>
      'ট্র্যাকিং শুরু করতে আপনার প্রথম আয় বা খরচ যোগ করুন।';

  @override
  String get transactionsLoadFailedSubtitle => 'লেনদেন লোড করা যায়নি';

  @override
  String get transactionsFilterTitle => 'লেনদেন ফিল্টার করুন';

  @override
  String get transactionsFilterType => 'ধরন';

  @override
  String get transactionsFilterClear => 'ফিল্টার সাফ করুন';

  @override
  String get transactionsTileEdit => 'সম্পাদনা';

  @override
  String get transactionsTileDelete => 'মুছুন';

  @override
  String get transactionsDeleteConfirmTitle => 'লেনদেন মুছবেন?';

  @override
  String get transactionsDeleteConfirmBody =>
      'আপনি কি নিশ্চিত যে এই লেনদেনটি মুছতে চান?';

  @override
  String get transactionsDetailTitle => 'লেনদেনের বিস্তারিত';

  @override
  String get transactionsDetailEditTooltip => 'সম্পাদনা';

  @override
  String get transactionsDetailDeleteTooltip => 'মুছুন';

  @override
  String get transactionsDetailLoading => 'লেনদেন লোড হচ্ছে...';

  @override
  String get transactionsDetailLoadFailedTitle => 'লেনদেন লোড করা যায়নি';

  @override
  String get transactionsDetailNotFoundTitle => 'লেনদেন পাওয়া যায়নি';

  @override
  String get transactionsDetailNotFoundSubtitle =>
      'হয়তো এটি মুছে ফেলা হয়েছে বা আপনার অ্যাক্সেস পরিবর্তিত হয়েছে।';

  @override
  String get transactionsDetailBack => 'ফিরে যান';

  @override
  String get transactionsDetailInfoDate => 'তারিখ';

  @override
  String get transactionsDetailInfoPaymentMethod => 'পেমেন্ট পদ্ধতি';

  @override
  String get transactionsDetailInfoSupplier => 'সরবরাহকারী সংযুক্ত';

  @override
  String get transactionsDetailInfoCustomer => 'ক্রেতা সংযুক্ত';

  @override
  String get transactionsDetailInfoYes => 'হ্যাঁ';

  @override
  String get transactionsDetailNote => 'নোট';

  @override
  String get transactionsDetailTypeIndicator => 'ধরন নির্দেশক';

  @override
  String get transactionsDetailCountsIncome => 'আয়ের মোট হিসাবে গণনা হয়';

  @override
  String get transactionsDetailCountsExpense => 'খরচের মোট হিসাবে গণনা হয়';

  @override
  String transactionsDetailDeleteBody(String type, String amount, String date) {
    return '$date তারিখে $type $amount মুছে ফেলা হবে।';
  }

  @override
  String get transactionsDeleteSuccess => 'লেনদেন মুছে ফেলা হয়েছে';

  @override
  String get transactionsDeleteFailed => 'মুছতে ব্যর্থ হয়েছে';

  @override
  String get transactionsEditTitle => 'লেনদেন সম্পাদনা';

  @override
  String get transactionsAddTitle => 'লেনদেন যোগ করুন';

  @override
  String get transactionsEditButton => 'লেনদেন আপডেট করুন';

  @override
  String get transactionsAddButton => 'লেনদেন যোগ করুন';

  @override
  String get transactionsSuccessAdd => 'লেনদেন যোগ হয়েছে';

  @override
  String get transactionsSuccessUpdate => 'লেনদেন আপডেট হয়েছে';

  @override
  String get transactionsAmountLabel => 'পরিমাণ';

  @override
  String get transactionsAmountHint => '০.০০';

  @override
  String get transactionsCategoryLabel => 'ক্যাটাগরি';

  @override
  String get transactionsPaymentMethodLabel => 'পেমেন্ট পদ্ধতি';

  @override
  String get transactionsDateLabel => 'তারিখ';

  @override
  String get transactionsNoteOptionalLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get transactionsNoteOptionalHint => 'নোট যোগ করুন...';

  @override
  String get transactionsCategoryRequired => 'একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get transactionsPaymentMethodRequired =>
      'একটি পেমেন্ট পদ্ধতি নির্বাচন করুন';

  @override
  String get incomeListTitle => 'আয়';

  @override
  String get incomeListAdd => 'আয় যোগ করুন';

  @override
  String get incomeListEdit => 'আয় সম্পাদনা';

  @override
  String get incomeListTooltipRefresh => 'রিফ্রেশ';

  @override
  String get incomeListLoading => 'আয় লোড হচ্ছে...';

  @override
  String get incomeListLoadFailedTitle => 'আয় লোড করা যাচ্ছে না';

  @override
  String get incomeListLoadFailedSubtitle => 'আপনার আয় এখন লোড করা যাচ্ছে না।';

  @override
  String get incomeListDeleteTitle => 'আয় মুছবেন?';

  @override
  String incomeListDeleteBody(String category, String amount, String date) {
    return '$date তারিখে $category • $amount';
  }

  @override
  String get incomeListDeleteSuccess => 'আয় মুছে ফেলা হয়েছে';

  @override
  String get incomeListDeleteFailed => 'আয় মুছতে ব্যর্থ';

  @override
  String get incomeListEmptyTitle => 'এখনো কোনো আয় নেই';

  @override
  String get incomeListEmptySubtitle =>
      'আপনার প্রথম বিক্রয়, সেবা বা পেমেন্ট রেকর্ড করতে \"আয় যোগ করুন\" টিপুন।';

  @override
  String get incomeListSummaryTitle => 'মোট আয়';

  @override
  String get incomeListFilterAllTime => 'সব সময়';

  @override
  String get incomeListFilterToday => 'আজ';

  @override
  String get incomeListFilterMonth => 'এই মাস';

  @override
  String incomeListSummaryCount(int count) {
    return '$countটি লেনদেন';
  }

  @override
  String get incomeListTileMore => 'আরও';

  @override
  String get incomeListEmptyFilterTitle =>
      'ফিল্টারের সাথে মিলে এমন কোনো আয় নেই';

  @override
  String get incomeListEmptyFilterSubtitle =>
      'আরও দেখতে অন্য তারিখ বা ক্যাটাগরি বেছে নিন।';

  @override
  String get incomeListClearFilters => 'ফিল্টার মুছুন';

  @override
  String get incomeListTooltipAdd => 'আয় যোগ করুন';

  @override
  String get incomeFormTitle => 'আয় যোগ করুন';

  @override
  String get incomeFormEditTitle => 'আয় সম্পাদনা';

  @override
  String get incomeFormHeaderNew => 'নতুন আয় রেকর্ড করুন';

  @override
  String get incomeFormHeaderEdit => 'এই আয়ের রেকর্ড আপডেট করুন';

  @override
  String get incomeFormHeaderSubtitle =>
      'প্রতিটি লেনদেন আপনার ব্যবসা ও অ্যাকাউন্টে ট্যাগ করা হয়।';

  @override
  String get incomeFormNoteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get incomeFormNoteHint => 'যেমন: অর্ডার #৪২, প্রজেক্টের বিবরণ';

  @override
  String get incomeFormNoteValidator => 'নোট';

  @override
  String get incomeFormSaveButton => 'আয় সংরক্ষণ করুন';

  @override
  String get incomeFormUpdateButton => 'আয় আপডেট করুন';

  @override
  String get incomeFormCreditSaleHint =>
      'বাকিতে বিক্রয় হিসেবে রেকর্ড হচ্ছে — ক্রেতার বকেয়া আপডেট হবে।';

  @override
  String get incomeFormAmountLabel => 'পরিমাণ';

  @override
  String get incomeFormAmountHint => '০';

  @override
  String get incomeFormCategoryLabel => 'ক্যাটাগরি';

  @override
  String get incomeFormPaymentMethodLabel => 'পেমেন্ট পদ্ধতি';

  @override
  String get incomeFormDateLabel => 'তারিখ';

  @override
  String get incomeFormCategoryRequired => 'একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get incomeFormPaymentMethodRequired =>
      'একটি পেমেন্ট পদ্ধতি নির্বাচন করুন';

  @override
  String get incomeFormCustomerLabel => 'ক্রেতা (ঐচ্ছিক)';

  @override
  String get incomeFormCustomerNone => '— কোনোটি নয় —';

  @override
  String get incomeFormCustomerUnnamed => '(নামবিহীন)';

  @override
  String get incomeFormAddCustomer => 'নতুন ক্রেতা যোগ করুন';

  @override
  String get incomeFormSuccessAdd => 'আয় যোগ হয়েছে';

  @override
  String get incomeFormSuccessUpdate => 'আয় আপডেট হয়েছে';

  @override
  String get incomeFormFailedAdd => 'আয় যোগ করা যায়নি';

  @override
  String get incomeFormFailedUpdate => 'আয় আপডেট করা যায়নি';

  @override
  String get incomeFormDiscardTitle => 'পরিবর্তন বাতিল করবেন?';

  @override
  String get incomeFormDiscardBody =>
      'আপনি এখন চলে গেলে এডিটগুলো হারিয়ে যাবে।';

  @override
  String get incomeFormKeepEditing => 'এডিট চালিয়ে যান';

  @override
  String get incomeFormDiscard => 'বাতিল করুন';

  @override
  String get incomeFormCustomerAdded => 'ক্রেতা যোগ হয়েছে';

  @override
  String get expenseListTitle => 'খরচ';

  @override
  String get expenseListAdd => 'খরচ যোগ করুন';

  @override
  String get expenseListEdit => 'খরচ সম্পাদনা';

  @override
  String get expenseListTooltipRefresh => 'রিফ্রেশ';

  @override
  String get expenseListLoading => 'খরচ লোড হচ্ছে...';

  @override
  String get expenseListLoadFailedTitle => 'খরচ লোড করা যাচ্ছে না';

  @override
  String get expenseListLoadFailedSubtitle =>
      'আপনার খরচ এখন লোড করা যাচ্ছে না।';

  @override
  String get expenseListDeleteTitle => 'খরচ মুছবেন?';

  @override
  String expenseListDeleteBody(String category, String amount, String date) {
    return '$date তারিখে $category • $amount';
  }

  @override
  String get expenseListDeleteSuccess => 'খরচ মুছে ফেলা হয়েছে';

  @override
  String get expenseListDeleteFailed => 'খরচ মুছতে ব্যর্থ';

  @override
  String get expenseListEmptyTitle => 'এখনো কোনো খরচ নেই';

  @override
  String get expenseListEmptySubtitle =>
      'আপনার প্রথম খরচ, ভাড়া বা বেতন রেকর্ড করতে \"খরচ যোগ করুন\" টিপুন।';

  @override
  String get expenseListEmptyFilterTitle =>
      'ফিল্টারের সাথে মেলে এমন কোনো খরচ নেই';

  @override
  String get expenseListEmptyFilterSubtitle =>
      'আরও দেখতে অন্য তারিখ বা ক্যাটাগরি বেছে নিন।';

  @override
  String get expenseListClearFilters => 'ফিল্টার সাফ করুন';

  @override
  String get expenseListSummaryTitle => 'মোট খরচ';

  @override
  String expenseListSummaryCount(int count) {
    return '$countটি লেনদেন';
  }

  @override
  String get expenseListFilterAllTime => 'সব সময়';

  @override
  String get expenseListFilterToday => 'আজ';

  @override
  String get expenseListFilterMonth => 'এই মাস';

  @override
  String get expenseListTileMore => 'আরও';

  @override
  String get expenseFormTitle => 'খরচ যোগ করুন';

  @override
  String get expenseFormEditTitle => 'খরচ সম্পাদনা';

  @override
  String get expenseFormHeaderNew => 'নতুন খরচ রেকর্ড করুন';

  @override
  String get expenseFormHeaderEdit => 'এই খরচের রেকর্ড আপডেট করুন';

  @override
  String get expenseFormHeaderSubtitle =>
      'প্রতিটি লেনদেন আপনার ব্যবসা ও অ্যাকাউন্টে ট্যাগ করা হয়।';

  @override
  String get expenseFormNoteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get expenseFormNoteHint => 'যেমন: অফিস ভাড়া আগস্টের জন্য, জ্বালানি';

  @override
  String get expenseFormNoteValidator => 'নোট';

  @override
  String get expenseFormSaveButton => 'খরচ সংরক্ষণ করুন';

  @override
  String get expenseFormUpdateButton => 'খরচ আপডেট করুন';

  @override
  String get expenseFormCreditPurchaseHint =>
      'বাকিতে ক্রয় হিসেবে রেকর্ড হচ্ছে — সরবরাহকারীর বকেয়া আপডেট হবে।';

  @override
  String get expenseFormAmountLabel => 'পরিমাণ';

  @override
  String get expenseFormAmountHint => '০';

  @override
  String get expenseFormCategoryLabel => 'ক্যাটাগরি';

  @override
  String get expenseFormPaymentMethodLabel => 'পেমেন্ট পদ্ধতি';

  @override
  String get expenseFormDateLabel => 'তারিখ';

  @override
  String get expenseFormCategoryRequired => 'একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get expenseFormPaymentMethodRequired =>
      'একটি পেমেন্ট পদ্ধতি নির্বাচন করুন';

  @override
  String get expenseFormSupplierLabel => 'সরবরাহকারী (ঐচ্ছিক)';

  @override
  String get expenseFormSupplierNone => '— কোনোটি নয় —';

  @override
  String get expenseFormSupplierUnnamed => '(নামবিহীন)';

  @override
  String get expenseFormAddSupplier => 'নতুন সরবরাহকারী যোগ করুন';

  @override
  String get expenseFormSuccessAdd => 'খরচ যোগ হয়েছে';

  @override
  String get expenseFormSuccessUpdate => 'খরচ আপডেট হয়েছে';

  @override
  String get expenseFormFailedAdd => 'খরচ যোগ করা যায়নি';

  @override
  String get expenseFormFailedUpdate => 'খরচ আপডেট করা যায়নি';

  @override
  String get expenseFormDiscardTitle => 'পরিবর্তন বাতিল করবেন?';

  @override
  String get expenseFormDiscardBody =>
      'আপনি এখন চলে গেলে এডিটগুলো হারিয়ে যাবে।';

  @override
  String get expenseFormKeepEditing => 'এডিট চালিয়ে যান';

  @override
  String get expenseFormDiscard => 'বাতিল করুন';

  @override
  String get expenseFormSupplierAdded => 'সরবরাহকারী যোগ হয়েছে';

  @override
  String get reportsTitle => 'রিপোর্ট';

  @override
  String get reportsAppBarTitle => 'রিপোর্ট ও বিশ্লেষণ';

  @override
  String get reportsErrorTitle => 'রিপোর্ট লোড করা যাচ্ছে না';

  @override
  String get reportsEmptyTitle => 'এখনো কোনো লেনদেন নেই';

  @override
  String get reportsEmptySubtitle => 'রিপোর্ট দেখতে আয় বা খরচ যোগ করুন।';

  @override
  String get reportsActionRefresh => 'রিফ্রেশ করুন';

  @override
  String get reportsPeriodToday => 'আজ';

  @override
  String get reportsPeriodWeek => 'সপ্তাহ';

  @override
  String get reportsPeriodMonth => 'মাস';

  @override
  String get reportsPeriodCustom => 'কাস্টম';

  @override
  String get reportsFilterAll => 'সব';

  @override
  String get reportsSummaryTotalIncome => 'মোট আয়';

  @override
  String get reportsSummaryTotalExpense => 'মোট খরচ';

  @override
  String get reportsSummaryNetProfit => 'নিট লাভ';

  @override
  String get reportsSummaryMargin => 'মার্জিন %';

  @override
  String get reportsSummaryCustomerDue => 'ক্রেতার বাকি';

  @override
  String get reportsSummarySupplierDue => 'সরবরাহকারীর বাকি';

  @override
  String reportsBreakdownEmpty(String title) {
    return 'এই সময়কালে কোনো $title রেকর্ড নেই।';
  }

  @override
  String reportsBreakdownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি লেনদেন',
      one: '১টি লেনদেন',
    );
    return '$_temp0';
  }

  @override
  String get reportsIncomeExpenseEmpty => 'এই সময়কালে কোনো আয় বা খরচ নেই।';

  @override
  String get reportsChartLabelIncome => 'আয়';

  @override
  String get reportsChartLabelExpense => 'খরচ';

  @override
  String get reportsTrendEmpty => 'প্রবণতা দেখতে কমপক্ষে ২ দিনের ডাটা দরকার।';

  @override
  String get reportsChartEmpty => 'এখনো চার্ট করার ডাটা নেই।';

  @override
  String get reportsCategoryUncategorized => 'অবিভক্ত';

  @override
  String get reportsChartIncomeVsExpense => 'আয় বনাম খরচ';

  @override
  String get reportsChartProfitTrend => 'লাভের প্রবণতা';

  @override
  String get reportsChartIncomeCategories => 'আয়ের ক্যাটাগরি';

  @override
  String get reportsChartExpenseCategories => 'খরচের ক্যাটাগরি';

  @override
  String get reportsBreakdownIncome => 'আয়ের বিস্তারিত';

  @override
  String get reportsBreakdownExpense => 'খরচের বিস্তারিত';

  @override
  String get reportsTransactionsHeading => 'এই সময়কালের লেনদেন';

  @override
  String get reportsEmpty => 'এখনো কোনো রিপোর্ট ডাটা নেই';

  @override
  String get errorNetwork => 'নেটওয়ার্ক ত্রুটি। আপনার সংযোগ পরীক্ষা করুন।';

  @override
  String get errorGeneric => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorAuthFailed => 'প্রমাণীকরণ ব্যর্থ হয়েছে';

  @override
  String errorSignInFailed(String message) {
    return 'সাইন ইন ব্যর্থ: $message';
  }

  @override
  String errorInit(String message) {
    return 'শুরু করতে ত্রুটি: $message';
  }

  @override
  String get errorManageSubscription =>
      'সাবস্ক্রিপশন পরিচালনা করতে আপনাকে সাইন ইন করতে হবে।';
}
