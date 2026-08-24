// Unit tests for DueCalculationService.
//
// We use a hand-rolled `FakeDueDataSource` instead of mocking so the test
// reads naturally and there's no Mocktail/Firebase mock dependency.

import 'package:flutter_test/flutter_test.dart';

import 'package:bizhisab_ai/features/transactions/due_classifier.dart';
import 'package:bizhisab_ai/models/transaction.dart';
import 'package:bizhisab_ai/services/due_calculation_service.dart';

void main() {
  group('CustomerDueTotals.fromTransactions', () {
    TransactionModel creditSale({
      required String customerId,
      required double amount,
    }) {
      return TransactionModel(
        id: 't-${amount.toInt()}',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: amount,
        category: kSalesCategory,
        paymentMethod: kDuePaymentMethod,
        customerId: customerId,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    TransactionModel customerPayment({
      required String customerId,
      required double amount,
    }) {
      return TransactionModel(
        id: 'p-${amount.toInt()}',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: amount,
        category: kCustomerPaymentCategory,
        paymentMethod: 'Cash',
        customerId: customerId,
        date: DateTime(2024, 1, 2),
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      );
    }

    test('empty list gives zero totals', () {
      final totals = CustomerDueTotals.fromTransactions(const []);
      expect(totals.totalPurchase, 0);
      expect(totals.totalPaid, 0);
      expect(totals.totalDue, 0);
    });

    test('only credit sales sum into totalPurchase', () {
      final totals = CustomerDueTotals.fromTransactions([
        creditSale(customerId: 'c1', amount: 100),
        creditSale(customerId: 'c1', amount: 50.5),
      ]);
      expect(totals.totalPurchase, 150.5);
      expect(totals.totalPaid, 0);
      expect(totals.totalDue, 150.5);
    });

    test('only payments sum into totalPaid', () {
      final totals = CustomerDueTotals.fromTransactions([
        customerPayment(customerId: 'c1', amount: 30),
        customerPayment(customerId: 'c1', amount: 20),
      ]);
      expect(totals.totalPurchase, 0);
      expect(totals.totalPaid, 50);
      expect(totals.totalDue, -50);
    });

    test('sales minus payments gives net due', () {
      final totals = CustomerDueTotals.fromTransactions([
        creditSale(customerId: 'c1', amount: 200),
        creditSale(customerId: 'c1', amount: 100),
        customerPayment(customerId: 'c1', amount: 75),
      ]);
      expect(totals.totalPurchase, 300);
      expect(totals.totalPaid, 75);
      expect(totals.totalDue, 225);
    });

    test('cash sales (Sales+Cash) are NOT counted as due', () {
      // A Sales row with paymentMethod=Cash is fully settled at sale time --
      // it does NOT contribute to totalPurchase (it isn't really a credit
      // sale any more).
      final cashSale = TransactionModel(
        id: 'cs',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: 999,
        category: kSalesCategory,
        paymentMethod: 'Cash',
        customerId: 'c1',
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final totals = CustomerDueTotals.fromTransactions([cashSale]);
      expect(totals.totalPurchase, 0);
      expect(totals.totalPaid, 0);
      expect(totals.totalDue, 0);
    });

    test('expense rows are ignored (wrong type)', () {
      // An expense row that happens to have a customerId is meaningless for
      // the customer's due.
      final stray = TransactionModel(
        id: 'e',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: 100,
        category: kCustomerPaymentCategory,
        paymentMethod: 'Cash',
        customerId: 'c1',
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final totals = CustomerDueTotals.fromTransactions([stray]);
      expect(totals.totalPurchase, 0);
      expect(totals.totalPaid, 0);
      expect(totals.totalDue, 0);
    });

    test('rows with no customerId are ignored', () {
      final cashSale = TransactionModel(
        id: 'cs',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: 999,
        category: kSalesCategory,
        paymentMethod: 'Cash',
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final totals = CustomerDueTotals.fromTransactions([cashSale]);
      expect(totals.totalPurchase, 0);
    });

    test('handles floating-point sums without throwing', () {
      final totals = CustomerDueTotals.fromTransactions([
        creditSale(customerId: 'c1', amount: 0.1),
        creditSale(customerId: 'c1', amount: 0.2),
      ]);
      // 0.1 + 0.2 == 0.30000000000000004 in IEEE-754 -- just make sure we
      // don't blow up and the result is close to 0.3.
      expect(totals.totalPurchase, closeTo(0.3, 1e-9));
    });
  });

  group('SupplierDueTotals.fromTransactions', () {
    TransactionModel creditPurchase({
      required String supplierId,
      required double amount,
    }) {
      return TransactionModel(
        id: 't-${amount.toInt()}',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: amount,
        category: kPurchaseCategory,
        paymentMethod: kDuePaymentMethod,
        supplierId: supplierId,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    TransactionModel supplierPayment({
      required String supplierId,
      required double amount,
    }) {
      return TransactionModel(
        id: 'p-${amount.toInt()}',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: amount,
        category: kSupplierPaymentCategory,
        paymentMethod: 'Cash',
        supplierId: supplierId,
        date: DateTime(2024, 1, 2),
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      );
    }

    test('empty list gives zero totals', () {
      final totals = SupplierDueTotals.fromTransactions(const []);
      expect(totals.totalPurchase, 0);
      expect(totals.totalPaid, 0);
      expect(totals.totalDue, 0);
    });

    test('purchases minus payments gives net due', () {
      final totals = SupplierDueTotals.fromTransactions([
        creditPurchase(supplierId: 's1', amount: 500),
        supplierPayment(supplierId: 's1', amount: 200),
      ]);
      expect(totals.totalPurchase, 500);
      expect(totals.totalPaid, 200);
      expect(totals.totalDue, 300);
    });

    test('cash purchases (Purchase+Cash) are NOT counted', () {
      final cashPurchase = TransactionModel(
        id: 'cp',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: 999,
        category: kPurchaseCategory,
        paymentMethod: 'Cash',
        supplierId: 's1',
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final totals = SupplierDueTotals.fromTransactions([cashPurchase]);
      expect(totals.totalPurchase, 0);
      expect(totals.totalDue, 0);
    });

    test('rows with no supplierId are ignored', () {
      final cash = TransactionModel(
        id: 'cp',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: 999,
        category: kPurchaseCategory,
        paymentMethod: kDuePaymentMethod,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final totals = SupplierDueTotals.fromTransactions([cash]);
      expect(totals.totalPurchase, 0);
    });
  });

  group('DueCalculationService (with FakeDueDataSource)', () {
    late _FakeDueDataSource ds;
    late DueCalculationService service;

    setUp(() {
      ds = _FakeDueDataSource();
      service = DueCalculationService(dataSource: ds);
    });

    TransactionModel saleRow(String customerId, double amount) => TransactionModel(
          id: 't',
          userId: 'u1',
          businessId: 'b1',
          type: TransactionType.income,
          amount: amount,
          category: kSalesCategory,
          paymentMethod: kDuePaymentMethod,
          customerId: customerId,
          date: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

    TransactionModel paymentRow(String customerId, double amount) =>
        TransactionModel(
          id: 'p',
          userId: 'u1',
          businessId: 'b1',
          type: TransactionType.income,
          amount: amount,
          category: kCustomerPaymentCategory,
          paymentMethod: 'Cash',
          customerId: customerId,
          date: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

    test('recalculateCustomerDue reads from data source and writes totals',
        () async {
      ds.transactionsByCustomer['c1'] = [
        saleRow('c1', 100),
        saleRow('c1', 50),
        paymentRow('c1', 30),
      ];

      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');

      expect(ds.writtenCustomerTotals, isNotEmpty);
      final write = ds.writtenCustomerTotals.single;
      expect(write.businessId, 'b1');
      expect(write.customerId, 'c1');
      expect(write.totalPurchase, 150);
      expect(write.totalPaid, 30);
      expect(write.totalDue, 120);
    });

    test('recalculateCustomerDue swallows errors and does not throw', () async {
      ds.shouldThrowOnFetch = true;

      // Should not throw even though the data source blew up.
      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');

      // And the write should never have been attempted.
      expect(ds.writtenCustomerTotals, isEmpty);
    });

    test('recalculateSupplierDue reads from data source and writes totals',
        () async {
      ds.transactionsBySupplier['s1'] = [
        TransactionModel(
          id: 't',
          userId: 'u1',
          businessId: 'b1',
          type: TransactionType.expense,
          amount: 400,
          category: kPurchaseCategory,
          paymentMethod: kDuePaymentMethod,
          supplierId: 's1',
          date: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        TransactionModel(
          id: 'p',
          userId: 'u1',
          businessId: 'b1',
          type: TransactionType.expense,
          amount: 100,
          category: kSupplierPaymentCategory,
          paymentMethod: 'Cash',
          supplierId: 's1',
          date: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      await service.recalculateSupplierDue(businessId: 'b1', supplierId: 's1');

      final write = ds.writtenSupplierTotals.single;
      expect(write.totalPurchase, 400);
      expect(write.totalPaid, 100);
      expect(write.totalDue, 300);
    });

    test('recalculateSupplierDue swallows errors', () async {
      ds.shouldThrowOnFetch = true;
      await service.recalculateSupplierDue(businessId: 'b1', supplierId: 's1');
      expect(ds.writtenSupplierTotals, isEmpty);
    });

    test('empty transaction list writes all zeros', () async {
      ds.transactionsByCustomer['c1'] = const [];
      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');
      final write = ds.writtenCustomerTotals.single;
      expect(write.totalPurchase, 0);
      expect(write.totalPaid, 0);
      expect(write.totalDue, 0);
    });

    test('customer vs supplier business isolation is respected', () async {
      // A customer shouldn't ever touch a supplier write.
      ds.transactionsByCustomer['c1'] = [saleRow('c1', 100)];
      ds.transactionsBySupplier['s1'] = [];
      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');
      expect(ds.writtenCustomerTotals, hasLength(1));
      expect(ds.writtenSupplierTotals, isEmpty);
    });

    test('recalc is idempotent -- calling twice with same data writes twice '
        '(no skip-write logic at the service level)', () async {
      ds.transactionsByCustomer['c1'] = [saleRow('c1', 100)];
      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');
      await service.recalculateCustomerDue(businessId: 'b1', customerId: 'c1');
      // The service always writes -- it relies on the data source to
      // short-circuit when the totals didn't change.
      expect(ds.writtenCustomerTotals, hasLength(2));
    });
  });
}

/// Minimal in-memory [DueDataSource] for unit tests.
class _FakeDueDataSource implements DueDataSource {
  final Map<String, List<TransactionModel>> transactionsByCustomer = {};
  final Map<String, List<TransactionModel>> transactionsBySupplier = {};
  final List<_CustomerWrite> writtenCustomerTotals = [];
  final List<_SupplierWrite> writtenSupplierTotals = [];
  bool shouldThrowOnFetch = false;

  @override
  Future<List<TransactionModel>> fetchTransactionsForCustomer({
    required String businessId,
    required String customerId,
  }) async {
    if (shouldThrowOnFetch) throw StateError('boom');
    return transactionsByCustomer[customerId] ?? const [];
  }

  @override
  Future<List<TransactionModel>> fetchTransactionsForSupplier({
    required String businessId,
    required String supplierId,
  }) async {
    if (shouldThrowOnFetch) throw StateError('boom');
    return transactionsBySupplier[supplierId] ?? const [];
  }

  @override
  Future<void> writeCustomerTotals({
    required String businessId,
    required String customerId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {
    writtenCustomerTotals.add(_CustomerWrite(
      businessId: businessId,
      customerId: customerId,
      totalPurchase: totalPurchase,
      totalPaid: totalPaid,
      totalDue: totalDue,
    ));
  }

  @override
  Future<void> writeSupplierTotals({
    required String businessId,
    required String supplierId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {
    writtenSupplierTotals.add(_SupplierWrite(
      businessId: businessId,
      supplierId: supplierId,
      totalPurchase: totalPurchase,
      totalPaid: totalPaid,
      totalDue: totalDue,
    ));
  }
}

class _CustomerWrite {
  _CustomerWrite({
    required this.businessId,
    required this.customerId,
    required this.totalPurchase,
    required this.totalPaid,
    required this.totalDue,
  });
  final String businessId;
  final String customerId;
  final double totalPurchase;
  final double totalPaid;
  final double totalDue;
}

class _SupplierWrite {
  _SupplierWrite({
    required this.businessId,
    required this.supplierId,
    required this.totalPurchase,
    required this.totalPaid,
    required this.totalDue,
  });
  final String businessId;
  final String supplierId;
  final double totalPurchase;
  final double totalPaid;
  final double totalDue;
}
