// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BizHisab AI';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonSearch => 'Search';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navSuppliers => 'Suppliers';

  @override
  String get navPeople => 'People';

  @override
  String get navReports => 'Reports';

  @override
  String get navAi => 'AI';

  @override
  String get navProfile => 'Profile';

  @override
  String get landingTitle => 'BizHisab AI';

  @override
  String get landingTagline => 'Smart Business Finance';

  @override
  String get landingGetStarted => 'Get Started';

  @override
  String get authMobileTitle => 'Enter Phone Number';

  @override
  String get authMobileHeadline => 'Enter your mobile number';

  @override
  String get authMobileSub => 'We will send you a verification code';

  @override
  String get authMobileFormat =>
      'Format: 01XXXXXXXXX (11 digits, any BD operator)';

  @override
  String get authMobileSendOtp => 'Send OTP';

  @override
  String get authMobileInvalid => 'Invalid number format';

  @override
  String get authMobileChangeNumber => 'Use Different Number';

  @override
  String get authOtpTitle => 'Verify OTP';

  @override
  String get authOtpHeadline => 'Enter Verification Code';

  @override
  String authOtpSentTo(String number) {
    return 'Code sent to +88 $number';
  }

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpResend => 'Resend';

  @override
  String get authOtpSending => 'Sending...';

  @override
  String get authOtpResentSuccess => 'OTP resent successfully';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpIncomplete => 'Please enter complete OTP';

  @override
  String get authOtpInvalid => 'Invalid OTP';

  @override
  String get authOtpRequestFirst => 'Please request OTP first';

  @override
  String get authOtpVerifyFailed => 'Verification failed. Please try again.';

  @override
  String get subscriptionTitle => 'Premium Subscription';

  @override
  String get subscriptionBrand => 'Business Premium';

  @override
  String get subscriptionBlurb =>
      'Subscription is required to use BizHisab AI. Subscribe via your mobile operator.';

  @override
  String get subscriptionFeatureTracking => 'Complete Transaction Tracking';

  @override
  String get subscriptionFeatureCustomers => 'Customer & Supplier Management';

  @override
  String get subscriptionFeatureInsights => 'AI-Powered Financial Insights';

  @override
  String get subscriptionFeatureReports => 'Detailed Reports & Analytics';

  @override
  String get subscriptionFeatureChatbot =>
      'AI Business Chatbot (Bangla/English)';

  @override
  String get subscriptionFeatureCloud => 'Cloud-Synced Data';

  @override
  String get subscriptionSubscribe => 'Subscribe Now';

  @override
  String get subscriptionSendingOtp => 'Sending OTP...';

  @override
  String get subscriptionEnterOtp =>
      'Enter the OTP sent by BdApps to confirm your subscription.';

  @override
  String get subscriptionConfirm => 'Confirm Subscription';

  @override
  String get subscriptionAlreadyPaid => 'Already paid? Verify now';

  @override
  String get subscriptionChecking => 'Checking subscription...';

  @override
  String get subscriptionNotYetActive =>
      'Subscription not yet active. Wait 30 seconds, then tap \"Resend OTP\" — your payment may take a moment to confirm.';

  @override
  String get subscriptionResent => 'Subscription OTP resent successfully';

  @override
  String subscriptionResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get subscriptionResendOtp => 'Resend OTP';

  @override
  String get subscriptionStartFailed => 'Failed to start subscription';

  @override
  String get subscriptionPhoneMissing =>
      'Phone number missing. Please log in again.';

  @override
  String get subscriptionAuthMissing => 'Phone number missing.';

  @override
  String get subscriptionRequestOtpFirst =>
      'Please request subscription OTP first';

  @override
  String get setupTitle => 'Business Setup';

  @override
  String get setupBusinessName => 'Business Name';

  @override
  String get setupBusinessNameHint => 'e.g., Rahman Traders';

  @override
  String get setupBusinessType => 'Business Type';

  @override
  String get setupBusinessTypeRequired => 'Business type is required';

  @override
  String get setupOwnerName => 'Owner Name';

  @override
  String get setupPhone => 'Phone';

  @override
  String get setupPhoneOptional => 'Phone (Optional)';

  @override
  String get setupPhoneHint => '01XXXXXXXXX';

  @override
  String get setupAddress => 'Address';

  @override
  String get setupAddressOptional => 'Address (Optional)';

  @override
  String get setupAddressHint => 'Business address';

  @override
  String get setupCurrency => 'Currency';

  @override
  String get setupSave => 'Save & Continue';

  @override
  String get setupHeadline => 'Set up your business';

  @override
  String get setupSub =>
      'Tell us a little about your business so we can personalise your dashboard.';

  @override
  String get setupPrivacyNote =>
      'Your data is private and tied to your account.';

  @override
  String get setupSessionExpired => 'Session expired. Please log in again.';

  @override
  String get setupSaveFailed => 'Failed to create business.';

  @override
  String get currencyBdt => 'BDT (৳) — Bangladeshi Taka';

  @override
  String get currencyUsd => 'USD (\$) — US Dollar';

  @override
  String get currencyInr => 'INR (₹) — Indian Rupee';

  @override
  String get currencyEur => 'EUR (€) — Euro';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRefresh => 'Refresh';

  @override
  String get dashboardLoadFailed => 'Unable to load dashboard';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardMonth => 'This Month';

  @override
  String get dashboardTodaySales => 'Today\'s Sales';

  @override
  String get dashboardTodayExpense => 'Today\'s Expense';

  @override
  String get dashboardTodayProfit => 'Today\'s Profit';

  @override
  String get dashboardIncome => 'Income';

  @override
  String get dashboardExpense => 'Expense';

  @override
  String get dashboardProfit => 'Profit';

  @override
  String get dashboardCustomerDue => 'Customer Due';

  @override
  String get dashboardSupplierDue => 'Supplier Due';

  @override
  String get dashboardAddIncome => 'Add Income';

  @override
  String get dashboardAddExpense => 'Add Expense';

  @override
  String get dashboardDue => 'Outstanding Dues';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardGreeting => 'Welcome back';

  @override
  String get dashboardBusinessFallback => 'Your Business';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardRecentTransactions => 'Recent Transactions';

  @override
  String get dashboardAiInsight => 'AI Insight';

  @override
  String get dashboardAiInsightSub =>
      'Personalized financial insights coming soon';

  @override
  String get dashboardBeta => 'BETA';

  @override
  String get dashboardTodayLoss => 'Today\'s Loss';

  @override
  String get dashboardProfile => 'Profile';

  @override
  String get dashboardGreetingMorning => 'Good Morning';

  @override
  String get dashboardGreetingAfternoon => 'Good Afternoon';

  @override
  String get dashboardGreetingEvening => 'Good Evening';

  @override
  String get dashboardGreetingNight => 'Good Night';

  @override
  String get dashboardEmptySubtitle =>
      'Add your first income or expense to get started.';

  @override
  String get dashboardIncomeGeneric => 'Income';

  @override
  String get dashboardExpenseGeneric => 'Expense';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileBusinessOwner => 'Business Owner';

  @override
  String get profileUnknownUser => 'Unknown';

  @override
  String get profileNoBusiness => 'No business profile set up';

  @override
  String get profileBusinessInfo => 'Business Information';

  @override
  String get profileFieldBusinessName => 'Business Name';

  @override
  String get profileFieldType => 'Type';

  @override
  String get profileFieldOwner => 'Owner';

  @override
  String get profileFieldPhone => 'Phone';

  @override
  String get profileFieldAddress => 'Address';

  @override
  String get profileFieldCurrency => 'Currency';

  @override
  String get profileSubscriptionTitle => 'BizHisab AI Premium';

  @override
  String get profileSubscriptionActive => 'Active';

  @override
  String get profileSubscriptionInactive => 'Inactive';

  @override
  String get profileSubscriptionMonthly => 'Monthly';

  @override
  String get profileUnsubscribe => 'Unsubscribe';

  @override
  String get profileUnsubscribeSubtitle =>
      'Cancel your monthly BizHisab AI Premium subscription';

  @override
  String get profileUnsubscribeTitle => 'Unsubscribe?';

  @override
  String get profileUnsubscribeBody =>
      'Are you sure you want to cancel your BizHisab AI Premium subscription? You will lose access to premium features on your next login.';

  @override
  String get profileKeepSubscription => 'Keep Subscription';

  @override
  String get profileUnsubscribeSuccess =>
      'You have been unsubscribed successfully.';

  @override
  String get profileUnsubscribeFailed =>
      'Unsubscribe failed. Please try again.';

  @override
  String get profileEditBusiness => 'Edit Business';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutTitle => 'Logout';

  @override
  String get profileLogoutBody => 'Are you sure you want to logout?';

  @override
  String get aiTitle => 'AI Assistant';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get aiAskPlaceholder => 'Ask anything about your business...';

  @override
  String get aiSend => 'Send';

  @override
  String get aiOffline => 'AI service offline';

  @override
  String get aiTryAgain => 'Try again';

  @override
  String get aiSignInRequired => 'Sign in to use AI features.';

  @override
  String get aiInsightsSub =>
      'Get a structured summary of your business performance.';

  @override
  String get aiChatSub =>
      'Ask free-form questions in Bangla, Banglish or English.';

  @override
  String get aiFreeTierNotice =>
      'AI runs on a free-tier model. If the service is unavailable, your other features keep working — try again later.';

  @override
  String get aiKeyFindings => 'Key findings';

  @override
  String get aiRecommendations => 'Recommendations';

  @override
  String aiConfidence(String level) {
    return '$level confidence';
  }

  @override
  String get aiChatEmpty =>
      'Ask anything about your business. Answers can be in Bangla, Banglish or English.';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get aiChatPlaceholder => 'Ask about your business...';

  @override
  String get aiClearChat => 'Clear chat';

  @override
  String get aiInsightsEmpty => 'No insights yet. Pick a report type above.';

  @override
  String get aiOfflineBanner =>
      'AI server not reachable. Start the backend and run `adb reverse tcp:8000 tcp:8000`.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsAdd => 'Add Transaction';

  @override
  String get transactionsEmpty => 'No transactions yet';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersAdd => 'Add Customer';

  @override
  String get customersEmpty => 'No customers yet';

  @override
  String get customersTotalPurchase => 'Total Purchase';

  @override
  String get customersTotalPaid => 'Total Paid';

  @override
  String get customersTotalDue => 'Total Due';

  @override
  String get customersRecordPayment => 'Record Payment';

  @override
  String get customersEditCustomer => 'Edit Customer';

  @override
  String get customersName => 'Name';

  @override
  String get customersPhone => 'Phone';

  @override
  String get customersAddress => 'Address';

  @override
  String get customersSort => 'Sort';

  @override
  String get customersSortNameAsc => 'Name (A-Z)';

  @override
  String get customersSortDueDesc => 'Due (high to low)';

  @override
  String get customersSortRecent => 'Recent';

  @override
  String get customersSearchHint => 'Search by name or phone...';

  @override
  String get customersTotalDueCard => 'Total Customer Due';

  @override
  String get customersLoadFailed => 'Failed to load customers';

  @override
  String get customersSearchEmpty => 'No customers match your search';

  @override
  String get customersSearchEmptySubtitle => 'Try a different name or phone.';

  @override
  String get customersAddSubtitle => 'Add a customer to start tracking dues.';

  @override
  String get customersChipDue => 'Due';

  @override
  String get customersChipSettled => 'Settled';

  @override
  String get customersDetailTitle => 'Customer Details';

  @override
  String get customersNotFound => 'Customer not found';

  @override
  String get customersDueBalance => 'Due Balance';

  @override
  String get customersAddressLabel => 'Address';

  @override
  String get customersCreditSales => 'Credit Sales';

  @override
  String get customersLoadingCreditSales => 'Loading credit sales...';

  @override
  String get customersCreditSalesEmpty => 'No credit sales yet';

  @override
  String get customersCreditSalesEmptySubtitle =>
      'Sales tagged as Due for this customer will show up here.';

  @override
  String get customersPaymentHistory => 'Payment History';

  @override
  String get customersLoadingPayments => 'Loading payments...';

  @override
  String get customersPaymentsEmpty => 'No payments yet';

  @override
  String get customersPaymentsEmptySubtitle =>
      'Recorded payments will show up here.';

  @override
  String get customersPaymentRecorded => 'Payment recorded';

  @override
  String get customersDeleteTitle => 'Delete Customer';

  @override
  String get customersDeleteBody =>
      'Are you sure you want to delete this customer? Related transactions will keep their reference.';

  @override
  String get customersFormNameLabel => 'Customer Name';

  @override
  String get customersFormNameHint => 'e.g., Rahim Enterprise';

  @override
  String get customersFormPhoneLabel => 'Phone Number';

  @override
  String get customersFormAddressLabel => 'Address (optional)';

  @override
  String get customersFormAddressHint => 'e.g., 12 Mirpur Road, Dhaka';

  @override
  String get customersUpdateCustomer => 'Update Customer';

  @override
  String get customersDiscardTitle => 'Discard changes?';

  @override
  String get customersDiscardBody =>
      'Your edits will be lost if you leave now.';

  @override
  String get customersKeepEditing => 'Keep editing';

  @override
  String get customersDiscard => 'Discard';

  @override
  String get customersPaymentAmountLabel => 'Amount';

  @override
  String get customersPaymentAmountHint => '0.00';

  @override
  String get customersPaymentEnterValid => 'Enter a valid amount';

  @override
  String get customersPaymentNoteLabel => 'Note (optional)';

  @override
  String get customersPaymentNoteHint =>
      'e.g., partial payment for invoice #12';

  @override
  String get customersPaymentSave => 'Save Payment';

  @override
  String get customersPaymentCurrentDue => 'Current Due';

  @override
  String get customersPaymentDateLabel => 'Payment Date';

  @override
  String get customersPaymentMethodLabel => 'Payment Method';

  @override
  String get customersPaymentAfterTitle => 'After this payment';

  @override
  String get customersPaymentNewDue => 'New Due';

  @override
  String get customersPaymentExceedsDue => 'Exceeds Due';

  @override
  String get customersPaymentNotSignedIn => 'Not signed in';

  @override
  String get customersPaymentFailed => 'Failed to record payment';

  @override
  String customersPaymentExceedsBody(Object amount, Object balance) {
    return 'Payment ($amount) exceeds the due balance ($balance).';
  }

  @override
  String customersPaymentExceedsHint(Object amount) {
    return 'Amount exceeds the current due — only up to $amount can be settled';
  }

  @override
  String get suppliersTitle => 'Suppliers';

  @override
  String get suppliersAdd => 'Add Supplier';

  @override
  String get suppliersEmpty => 'No suppliers yet';

  @override
  String get suppliersRecordPayment => 'Record Payment';

  @override
  String get suppliersEditSupplier => 'Edit Supplier';

  @override
  String get suppliersName => 'Name';

  @override
  String get suppliersPhone => 'Phone';

  @override
  String get suppliersAddress => 'Address';

  @override
  String get suppliersSort => 'Sort';

  @override
  String get suppliersSortNameAsc => 'Name (A-Z)';

  @override
  String get suppliersSortDueDesc => 'Due (high to low)';

  @override
  String get suppliersSortRecent => 'Recent';

  @override
  String get suppliersSearchHint => 'Search by name, phone or address...';

  @override
  String get suppliersTotalDueCard => 'Total Supplier Due';

  @override
  String get suppliersLoadFailed => 'Failed to load suppliers';

  @override
  String get suppliersSearchEmpty => 'No suppliers match your search';

  @override
  String get suppliersSearchEmptySubtitle =>
      'Try a different name, phone, or address.';

  @override
  String get suppliersAddSubtitle => 'Add a supplier to start tracking dues.';

  @override
  String get suppliersDetailTitle => 'Supplier Details';

  @override
  String get suppliersNotFound => 'Supplier not found';

  @override
  String get suppliersTotalPurchase => 'Total Purchase';

  @override
  String get suppliersTotalPaid => 'Total Paid';

  @override
  String get suppliersDueBalance => 'Due Balance';

  @override
  String get suppliersCreditPurchases => 'Credit Purchases';

  @override
  String get suppliersLoadingCreditPurchases => 'Loading credit purchases...';

  @override
  String get suppliersCreditPurchasesEmpty => 'No credit purchases yet';

  @override
  String get suppliersCreditPurchasesEmptySubtitle =>
      'Purchases tagged as Due for this supplier will show up here.';

  @override
  String get suppliersPaymentHistory => 'Payment History';

  @override
  String get suppliersLoadingPayments => 'Loading payments...';

  @override
  String get suppliersPaymentsEmpty => 'No payments yet';

  @override
  String get suppliersPaymentsEmptySubtitle =>
      'Recorded payments will show up here.';

  @override
  String get suppliersPaymentRecorded => 'Payment recorded';

  @override
  String get suppliersDeleteTitle => 'Delete Supplier';

  @override
  String get suppliersDeleteBody =>
      'Are you sure you want to delete this supplier? Related expenses will keep their reference.';

  @override
  String get suppliersFormNameLabel => 'Supplier Name';

  @override
  String get suppliersFormNameHint => 'e.g., Dhaka Traders';

  @override
  String get suppliersFormPhoneLabel => 'Phone Number';

  @override
  String get suppliersFormPhoneHint => '01XXXXXXXXX';

  @override
  String get suppliersUpdateSupplier => 'Update Supplier';

  @override
  String get suppliersDiscardTitle => 'Discard changes?';

  @override
  String get suppliersDiscardBody =>
      'Your edits will be lost if you leave now.';

  @override
  String get suppliersDiscardPaymentTitle => 'Discard payment?';

  @override
  String get suppliersDiscardPaymentBody =>
      'Your payment details will be lost if you leave now.';

  @override
  String get suppliersKeepEditing => 'Keep editing';

  @override
  String get suppliersDiscard => 'Discard';

  @override
  String get suppliersPaymentAmountLabel => 'Amount';

  @override
  String get suppliersPaymentAmountHint => '0.00';

  @override
  String get suppliersPaymentEnterValid => 'Enter a valid amount';

  @override
  String get suppliersPaymentDateLabel => 'Payment Date';

  @override
  String get suppliersPaymentMethodLabel => 'Payment Method';

  @override
  String get suppliersPaymentNoteLabel => 'Note (optional)';

  @override
  String get suppliersPaymentNoteHint =>
      'e.g., partial payment against invoice #12';

  @override
  String get suppliersPaymentSave => 'Save Payment';

  @override
  String get suppliersPaymentCurrentDue => 'Current Due';

  @override
  String get suppliersPaymentCurrentDueSettled => 'Settled';

  @override
  String get suppliersPaymentAfterTitle => 'After this payment';

  @override
  String suppliersPaymentNewDue(String amount) {
    return 'New due: $amount';
  }

  @override
  String suppliersPaymentTotalPaidAfter(String amount) {
    return 'Total paid after this: $amount';
  }

  @override
  String get suppliersPaymentExceedsDue => 'Exceeds Due';

  @override
  String suppliersPaymentExceedsHint(String amount) {
    return 'Amount exceeds the current due — only up to $amount can be settled in one payment';
  }

  @override
  String get suppliersPaymentNotSignedIn => 'Not signed in';

  @override
  String get suppliersPaymentFailed => 'Failed to record payment';

  @override
  String suppliersPaymentExceedsBody(String amount, String balance) {
    return 'Payment ($amount) exceeds the due balance ($balance).';
  }

  @override
  String get incomeTitle => 'Income';

  @override
  String get incomeAdd => 'Add Income';

  @override
  String get incomeEmpty => 'No income recorded yet';

  @override
  String get incomeEditIncome => 'Edit Income';

  @override
  String get expenseTitle => 'Expense';

  @override
  String get expenseAdd => 'Add Expense';

  @override
  String get expenseEmpty => 'No expense recorded yet';

  @override
  String get expenseEditExpense => 'Edit Expense';

  @override
  String get transactionsHistoryTitle => 'Transaction History';

  @override
  String get transactionsNewBtn => 'New';

  @override
  String get transactionsRefresh => 'Refresh';

  @override
  String get transactionsSummaryIncome => 'Income';

  @override
  String get transactionsSummaryExpense => 'Expense';

  @override
  String get transactionsSummaryNet => 'Net';

  @override
  String get transactionsSearchHint => 'Search by category or note...';

  @override
  String get transactionsDateAll => 'All time';

  @override
  String get transactionsDateToday => 'Today';

  @override
  String get transactionsDateWeek => 'This week';

  @override
  String get transactionsDateMonth => 'This month';

  @override
  String get transactionsDateCustom => 'Custom';

  @override
  String get transactionsTypeAll => 'All';

  @override
  String get transactionsTypeIncome => 'Income';

  @override
  String get transactionsTypeExpense => 'Expense';

  @override
  String get transactionsAllCategories => 'All categories';

  @override
  String get transactionsLoading => 'Loading transactions...';

  @override
  String get transactionsLoadFailedTitle => 'Couldn\'t load transactions';

  @override
  String get transactionsRetry => 'Retry';

  @override
  String get transactionsEmptyTitle => 'No transactions found';

  @override
  String get transactionsEmptySubtitle =>
      'Try widening the date range or clearing the search.';

  @override
  String get transactionsResetFilters => 'Reset filters';

  @override
  String get transactionsLoadMore => 'Load more';

  @override
  String get transactionsEndOfList => 'End of list';

  @override
  String get transactionsBadgeIncome => 'INCOME';

  @override
  String get transactionsBadgeExpense => 'EXPENSE';

  @override
  String get transactionsSearchTransactions => 'Search transactions...';

  @override
  String get transactionsSearchEmpty => 'No transactions yet';

  @override
  String get transactionsSearchEmptySubtitle =>
      'Add your first income or expense to start tracking.';

  @override
  String get transactionsLoadFailedSubtitle => 'Failed to load transactions';

  @override
  String get transactionsFilterTitle => 'Filter Transactions';

  @override
  String get transactionsFilterType => 'Type';

  @override
  String get transactionsFilterClear => 'Clear Filters';

  @override
  String get transactionsTileEdit => 'Edit';

  @override
  String get transactionsTileDelete => 'Delete';

  @override
  String get transactionsDeleteConfirmTitle => 'Delete Transaction';

  @override
  String get transactionsDeleteConfirmBody =>
      'Are you sure you want to delete this transaction?';

  @override
  String get transactionsDetailTitle => 'Transaction Details';

  @override
  String get transactionsDetailEditTooltip => 'Edit';

  @override
  String get transactionsDetailDeleteTooltip => 'Delete';

  @override
  String get transactionsDetailLoading => 'Loading transaction...';

  @override
  String get transactionsDetailLoadFailedTitle => 'Couldn\'t load transaction';

  @override
  String get transactionsDetailNotFoundTitle => 'Transaction not found';

  @override
  String get transactionsDetailNotFoundSubtitle =>
      'It may have been deleted or your access changed.';

  @override
  String get transactionsDetailBack => 'Back';

  @override
  String get transactionsDetailInfoDate => 'Date';

  @override
  String get transactionsDetailInfoPaymentMethod => 'Payment method';

  @override
  String get transactionsDetailInfoSupplier => 'Supplier linked';

  @override
  String get transactionsDetailInfoCustomer => 'Customer linked';

  @override
  String get transactionsDetailInfoYes => 'Yes';

  @override
  String get transactionsDetailNote => 'Note';

  @override
  String get transactionsDetailTypeIndicator => 'Type indicator';

  @override
  String get transactionsDetailCountsIncome => 'Counts toward income totals';

  @override
  String get transactionsDetailCountsExpense => 'Counts toward expense totals';

  @override
  String transactionsDetailDeleteBody(String type, String amount, String date) {
    return '$type of $amount on $date will be removed.';
  }

  @override
  String get transactionsDeleteSuccess => 'Transaction deleted';

  @override
  String get transactionsDeleteFailed => 'Delete failed';

  @override
  String get transactionsEditTitle => 'Edit Transaction';

  @override
  String get transactionsAddTitle => 'Add Transaction';

  @override
  String get transactionsEditButton => 'Update Transaction';

  @override
  String get transactionsAddButton => 'Add Transaction';

  @override
  String get transactionsSuccessAdd => 'Transaction added';

  @override
  String get transactionsSuccessUpdate => 'Transaction updated';

  @override
  String get transactionsAmountLabel => 'Amount';

  @override
  String get transactionsAmountHint => '0.00';

  @override
  String get transactionsCategoryLabel => 'Category';

  @override
  String get transactionsPaymentMethodLabel => 'Payment Method';

  @override
  String get transactionsDateLabel => 'Date';

  @override
  String get transactionsNoteOptionalLabel => 'Note (Optional)';

  @override
  String get transactionsNoteOptionalHint => 'Add a note...';

  @override
  String get transactionsCategoryRequired => 'Please select a category';

  @override
  String get transactionsPaymentMethodRequired =>
      'Please select a payment method';

  @override
  String get incomeListTitle => 'Income';

  @override
  String get incomeListAdd => 'Add Income';

  @override
  String get incomeListEdit => 'Edit Income';

  @override
  String get incomeListTooltipRefresh => 'Refresh';

  @override
  String get incomeListLoading => 'Loading income...';

  @override
  String get incomeListLoadFailedTitle => 'Unable to load income';

  @override
  String get incomeListLoadFailedSubtitle =>
      'We couldn\'t load your income right now.';

  @override
  String get incomeListDeleteTitle => 'Delete income?';

  @override
  String incomeListDeleteBody(String category, String amount, String date) {
    return '$category • $amount on $date';
  }

  @override
  String get incomeListDeleteSuccess => 'Income deleted';

  @override
  String get incomeListDeleteFailed => 'Failed to delete income';

  @override
  String get incomeListEmptyTitle => 'No income yet';

  @override
  String get incomeListEmptySubtitle =>
      'Tap \"Add Income\" to record your first sale, service or payment.';

  @override
  String get incomeListSummaryTitle => 'Total Income';

  @override
  String get incomeListFilterAllTime => 'All time';

  @override
  String get incomeListFilterToday => 'Today';

  @override
  String get incomeListFilterMonth => 'This month';

  @override
  String incomeListSummaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get incomeListTileMore => 'More';

  @override
  String get incomeListEmptyFilterTitle => 'No income matches the filter';

  @override
  String get incomeListEmptyFilterSubtitle =>
      'Try a different date or category to see more.';

  @override
  String get incomeListClearFilters => 'Clear filters';

  @override
  String get incomeListTooltipAdd => 'Add income';

  @override
  String get incomeFormTitle => 'Add Income';

  @override
  String get incomeFormEditTitle => 'Edit Income';

  @override
  String get incomeFormHeaderNew => 'Record a new income';

  @override
  String get incomeFormHeaderEdit => 'Update this income record';

  @override
  String get incomeFormHeaderSubtitle =>
      'Every transaction is tagged to your business and account.';

  @override
  String get incomeFormNoteLabel => 'Note (optional)';

  @override
  String get incomeFormNoteHint => 'e.g., Order #42, project description';

  @override
  String get incomeFormNoteValidator => 'Note';

  @override
  String get incomeFormSaveButton => 'Save Income';

  @override
  String get incomeFormUpdateButton => 'Update Income';

  @override
  String get incomeFormCreditSaleHint =>
      'Recorded as a credit sale — customer due will update.';

  @override
  String get incomeFormAmountLabel => 'Amount';

  @override
  String get incomeFormAmountHint => '0';

  @override
  String get incomeFormCategoryLabel => 'Category';

  @override
  String get incomeFormPaymentMethodLabel => 'Payment Method';

  @override
  String get incomeFormDateLabel => 'Date';

  @override
  String get incomeFormCategoryRequired => 'Please select a category';

  @override
  String get incomeFormPaymentMethodRequired =>
      'Please select a payment method';

  @override
  String get incomeFormCustomerLabel => 'Customer (optional)';

  @override
  String get incomeFormCustomerNone => '— None —';

  @override
  String get incomeFormCustomerUnnamed => '(unnamed)';

  @override
  String get incomeFormAddCustomer => 'Add new customer';

  @override
  String get incomeFormSuccessAdd => 'Income added';

  @override
  String get incomeFormSuccessUpdate => 'Income updated';

  @override
  String get incomeFormFailedAdd => 'Failed to add income';

  @override
  String get incomeFormFailedUpdate => 'Failed to update income';

  @override
  String get incomeFormDiscardTitle => 'Discard changes?';

  @override
  String get incomeFormDiscardBody =>
      'Your edits will be lost if you leave now.';

  @override
  String get incomeFormKeepEditing => 'Keep editing';

  @override
  String get incomeFormDiscard => 'Discard';

  @override
  String get incomeFormCustomerAdded => 'Customer added';

  @override
  String get expenseListTitle => 'Expense';

  @override
  String get expenseListAdd => 'Add Expense';

  @override
  String get expenseListEdit => 'Edit Expense';

  @override
  String get expenseListTooltipRefresh => 'Refresh';

  @override
  String get expenseListLoading => 'Loading expense...';

  @override
  String get expenseListLoadFailedTitle => 'Unable to load expense';

  @override
  String get expenseListLoadFailedSubtitle =>
      'We couldn\'t load your expense right now.';

  @override
  String get expenseListDeleteTitle => 'Delete expense?';

  @override
  String expenseListDeleteBody(String category, String amount, String date) {
    return '$category • $amount on $date';
  }

  @override
  String get expenseListDeleteSuccess => 'Expense deleted';

  @override
  String get expenseListDeleteFailed => 'Failed to delete expense';

  @override
  String get expenseListEmptyTitle => 'No expense yet';

  @override
  String get expenseListEmptySubtitle =>
      'Tap \"Add Expense\" to record your first cost, rent or salary payment.';

  @override
  String get expenseListEmptyFilterTitle => 'No expense matches the filter';

  @override
  String get expenseListEmptyFilterSubtitle =>
      'Try a different date or category to see more.';

  @override
  String get expenseListClearFilters => 'Clear filters';

  @override
  String get expenseListSummaryTitle => 'Total Expense';

  @override
  String expenseListSummaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get expenseListFilterAllTime => 'All time';

  @override
  String get expenseListFilterToday => 'Today';

  @override
  String get expenseListFilterMonth => 'This month';

  @override
  String get expenseListTileMore => 'More';

  @override
  String get expenseFormTitle => 'Add Expense';

  @override
  String get expenseFormEditTitle => 'Edit Expense';

  @override
  String get expenseFormHeaderNew => 'Record a new expense';

  @override
  String get expenseFormHeaderEdit => 'Update this expense record';

  @override
  String get expenseFormHeaderSubtitle =>
      'Every transaction is tagged to your business and account.';

  @override
  String get expenseFormNoteLabel => 'Note (optional)';

  @override
  String get expenseFormNoteHint => 'e.g., Office rent for August, fuel refill';

  @override
  String get expenseFormNoteValidator => 'Note';

  @override
  String get expenseFormSaveButton => 'Save Expense';

  @override
  String get expenseFormUpdateButton => 'Update Expense';

  @override
  String get expenseFormCreditPurchaseHint =>
      'Recorded as a credit purchase — supplier due will update.';

  @override
  String get expenseFormAmountLabel => 'Amount';

  @override
  String get expenseFormAmountHint => '0';

  @override
  String get expenseFormCategoryLabel => 'Category';

  @override
  String get expenseFormPaymentMethodLabel => 'Payment Method';

  @override
  String get expenseFormDateLabel => 'Date';

  @override
  String get expenseFormCategoryRequired => 'Please select a category';

  @override
  String get expenseFormPaymentMethodRequired =>
      'Please select a payment method';

  @override
  String get expenseFormSupplierLabel => 'Supplier (optional)';

  @override
  String get expenseFormSupplierNone => '— None —';

  @override
  String get expenseFormSupplierUnnamed => '(unnamed)';

  @override
  String get expenseFormAddSupplier => 'Add new supplier';

  @override
  String get expenseFormSuccessAdd => 'Expense added';

  @override
  String get expenseFormSuccessUpdate => 'Expense updated';

  @override
  String get expenseFormFailedAdd => 'Failed to add expense';

  @override
  String get expenseFormFailedUpdate => 'Failed to update expense';

  @override
  String get expenseFormDiscardTitle => 'Discard changes?';

  @override
  String get expenseFormDiscardBody =>
      'Your edits will be lost if you leave now.';

  @override
  String get expenseFormKeepEditing => 'Keep editing';

  @override
  String get expenseFormDiscard => 'Discard';

  @override
  String get expenseFormSupplierAdded => 'Supplier added';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsAppBarTitle => 'Reports & Analytics';

  @override
  String get reportsErrorTitle => 'Unable to load reports';

  @override
  String get reportsEmptyTitle => 'No transactions yet';

  @override
  String get reportsEmptySubtitle =>
      'Add income or expense to see your reports.';

  @override
  String get reportsActionRefresh => 'Refresh';

  @override
  String get reportsPeriodToday => 'Today';

  @override
  String get reportsPeriodWeek => 'Week';

  @override
  String get reportsPeriodMonth => 'Month';

  @override
  String get reportsPeriodCustom => 'Custom';

  @override
  String get reportsFilterAll => 'All';

  @override
  String get reportsSummaryTotalIncome => 'Total Income';

  @override
  String get reportsSummaryTotalExpense => 'Total Expense';

  @override
  String get reportsSummaryNetProfit => 'Net Profit';

  @override
  String get reportsSummaryMargin => 'Margin %';

  @override
  String get reportsSummaryCustomerDue => 'Customer Due';

  @override
  String get reportsSummarySupplierDue => 'Supplier Due';

  @override
  String reportsBreakdownEmpty(String title) {
    return 'No $title recorded in this period.';
  }

  @override
  String reportsBreakdownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get reportsIncomeExpenseEmpty =>
      'No income or expense in this period yet.';

  @override
  String get reportsChartLabelIncome => 'Income';

  @override
  String get reportsChartLabelExpense => 'Expense';

  @override
  String get reportsTrendEmpty => 'Trend needs at least 2 days of data.';

  @override
  String get reportsChartEmpty => 'No data to chart yet.';

  @override
  String get reportsCategoryUncategorized => 'Uncategorized';

  @override
  String get reportsChartIncomeVsExpense => 'Income vs Expense';

  @override
  String get reportsChartProfitTrend => 'Profit Trend';

  @override
  String get reportsChartIncomeCategories => 'Income Categories';

  @override
  String get reportsChartExpenseCategories => 'Expense Categories';

  @override
  String get reportsBreakdownIncome => 'Income breakdown';

  @override
  String get reportsBreakdownExpense => 'Expense breakdown';

  @override
  String get reportsTransactionsHeading => 'Transactions in this period';

  @override
  String get reportsEmpty => 'No report data yet';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorAuthFailed => 'Authentication failed';

  @override
  String errorSignInFailed(String message) {
    return 'Sign-in failed: $message';
  }

  @override
  String errorInit(String message) {
    return 'Initialization error: $message';
  }

  @override
  String get errorManageSubscription =>
      'You must be signed in to manage your subscription.';
}
