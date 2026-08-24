import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/landing/landing_screen.dart';
import '../features/auth/mobile_number_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/subscription_screen.dart';
import '../features/setup/business_setup_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/add_edit_transaction_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/transactions/transaction_detail_screen.dart';
import '../features/income/income_list_screen.dart';
import '../features/income/add_edit_income_screen.dart';
import '../features/expense/expense_list_screen.dart';
import '../features/expense/add_edit_expense_screen.dart';
import '../features/customers/customer_list_screen.dart';
import '../features/customers/add_edit_customer_screen.dart';
import '../features/customers/customer_detail_screen.dart';
import '../features/customers/record_payment_screen.dart';
import '../features/suppliers/supplier_list_screen.dart';
import '../features/suppliers/supplier_detail_screen.dart';
import '../features/suppliers/record_supplier_payment_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/ai/ai_screen.dart';
import '../features/ai/ai_insights_screen.dart';
import '../features/ai/ai_chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/business_profile_edit_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/landing',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final authState = authProvider.state;
      final location = state.uri.toString();

      final isLanding = location == '/landing';
      final isAuthRoute = location.startsWith('/auth');
      final isSetup = location == '/setup';

      switch (authState) {
        case AuthState.initial:
        case AuthState.loading:
          return null;

        case AuthState.unauthenticated:
          if (isLanding || isAuthRoute) return null;
          return '/landing';

        case AuthState.otpSent:
        case AuthState.otpVerifying:
          if (location == '/auth/otp') return null;
          return '/auth/otp';

        case AuthState.subscriptionChecking:
          return null;

        case AuthState.subscriptionInactive:
          if (location == '/auth/subscription') return null;
          return '/auth/subscription';

        case AuthState.settingUpBusiness:
          if (isSetup) return null;
          return '/setup';

        case AuthState.authenticated:
          if (authProvider.hasBusiness) {
            if (isSetup) return '/app/dashboard';
            if (isLanding || isAuthRoute) return '/app/dashboard';
            return null;
          } else {
            if (isSetup) return null;
            return '/setup';
          }
      }
    },
    routes: [
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/auth/mobile',
        builder: (context, state) => const MobileNumberScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/auth/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/app/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app/transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              // Literal routes MUST come before `:id` so GoRouter doesn't
              // match e.g. "add-income" or "income" as a transaction id.
              GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const AddEditTransactionScreen(),
              ),
              // Income flow (separate from the legacy dual-purpose
              // add/edit transaction screen above). Reached from the
              // dashboard's "Add Income" quick action and from the
              // income list screen.
              GoRoute(
                path: 'income',
                builder: (context, state) => const IncomeListScreen(),
                routes: [
                  // Nested under 'income' so the path becomes
                  // /app/transactions/income/:id/edit — no conflict
                  // with the parent :id catch-all.
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => AddEditIncomeScreen(
                      incomeId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'add-income',
                builder: (context, state) => const AddEditIncomeScreen(),
              ),
              // Expense flow (mirrors income). Same rule as above: literal
              // paths ('expense', 'add-expense') must come before `:id`.
              GoRoute(
                path: 'expense',
                builder: (context, state) => const ExpenseListScreen(),
                routes: [
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => AddEditExpenseScreen(
                      expenseId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'add-expense',
                builder: (context, state) => const AddEditExpenseScreen(),
              ),
              // Transaction History — paginated list + detail screen with
              // filters and search. Literal path 'history' must come BEFORE
              // the `:id` catch-all below so it doesn't get treated as a
              // transaction id (matches the lesson learned in the income
              // and expense flows above).
              GoRoute(
                path: 'history',
                builder: (context, state) => const TransactionsScreen(),
              ),
              GoRoute(
                path: 'history/:id',
                builder: (context, state) => TransactionDetailScreen(
                  transactionId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => AddEditTransactionScreen(
                  transactionId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/app/customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const AddEditCustomerScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    CustomerDetailScreen(customerId: state.pathParameters['id']!),
                routes: [
                  // Literal sub-routes must come BEFORE any path that starts
                  // with a colon under the same parent (matches the lesson
                  // already applied in the transactions flow above).
                  GoRoute(
                    path: 'payment',
                    builder: (context, state) => RecordPaymentScreen(
                      customerId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => AddEditCustomerScreen(
                      customerId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/app/suppliers',
            builder: (context, state) => const SupplierListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) =>
                    const AddEditSupplierScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    SupplierDetailScreen(supplierId: state.pathParameters['id']!
),                                                                                              routes: [
                  // Literal sub-route must come before any future path that   
                  // starts with a colon under the same parent. Mirrors the    
                  // customer flow (`payment` before `edit`).
                  GoRoute(
                    path: 'payment',
                    builder: (context, state) => RecordSupplierPaymentScreen(
                      supplierId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => AddEditSupplierScreen(
                      supplierId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/app/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/app/ai',
            builder: (context, state) => const AiScreen(),
            routes: [
              GoRoute(
                path: 'insights',
                builder: (context, state) {
                  final businessId =
                      authProvider.user?.businessId ?? '';
                  return AiInsightsScreen(businessId: businessId);
                },
              ),
              GoRoute(
                path: 'chat',
                builder: (context, state) {
                  final businessId =
                      authProvider.user?.businessId ?? '';
                  return AiChatScreen(businessId: businessId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/app/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    const BusinessProfileEditScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
