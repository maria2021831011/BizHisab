// Unit tests for DueRecalculationCoordinator.
//
// The coordinator is a thin decision layer on top of DueCalculationService,
// so we verify which (businessId, customerId / supplierId) tuples it asks the
// service to recompute.

import 'package:flutter_test/flutter_test.dart';

import 'package:bizhisab_ai/features/transactions/due_classifier.dart';
import 'package:bizhisab_ai/models/transaction.dart';
import 'package:bizhisab_ai/services/due_calculation_service.dart';
import 'package:bizhisab_ai/services/due_recalculation_coordinator.dart';

void main() {
  group('DueRecalculationCoordinator', () {
    late _RecordingService service;
    late DueRecalculationCoordinator coordinator;

    setUp(() {
      service = _RecordingService();
      coordinator = DueRecalculationCoordinator(service: service);
    });

    TransactionModel sale({
      required String id,
      required String customerId,
      String paymentMethod = 'Due',
    }) {
      return TransactionModel(
        id: id,
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: 100,
        category: kSalesCategory,
        paymentMethod: paymentMethod,
        customerId: customerId,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    TransactionModel cPayment({
      required String id,
      required String customerId,
    }) {
      return TransactionModel(
        id: id,
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: 50,
        category: kCustomerPaymentCategory,
        paymentMethod: 'Cash',
        customerId: customerId,
        date: DateTime(2024, 1, 2),
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      );
    }

    TransactionModel purchase({
      required String id,
      required String supplierId,
      String paymentMethod = 'Due',
    }) {
      return TransactionModel(
        id: id,
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.expense,
        amount: 80,
        category: kPurchaseCategory,
        paymentMethod: paymentMethod,
        supplierId: supplierId,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    test('insert path: customer credit sale triggers customer recalc only',
        () async {
      await coordinator.recompute(newTransaction: sale(id: '1', customerId: 'c1'));
      expect(service.customerCalls, ['b1:c1']);
      expect(service.supplierCalls, isEmpty);
    });

    test('insert path: supplier credit purchase triggers supplier recalc only',
        () async {
      await coordinator.recompute(
        newTransaction: purchase(id: '1', supplierId: 's1'),
      );
      expect(service.supplierCalls, ['b1:s1']);
      expect(service.customerCalls, isEmpty);
    });

    test('insert path: customer payment triggers customer recalc', () async {
      await coordinator.recompute(
        newTransaction: cPayment(id: '1', customerId: 'c1'),
      );
      expect(service.customerCalls, ['b1:c1']);
    });

    test('non-due-affecting income (cash sale) does NOT trigger any recalc',
        () async {
      await coordinator.recompute(
        newTransaction: sale(id: '1', customerId: 'c1', paymentMethod: 'Cash'),
      );
      expect(service.customerCalls, isEmpty);
      expect(service.supplierCalls, isEmpty);
    });

    test('edit path: previous customerId == new customerId -> single recalc',
        () async {
      await coordinator.recompute(
        newTransaction: sale(id: '1', customerId: 'c1'),
        previousTransaction: sale(id: '1', customerId: 'c1'),
      );
      expect(service.customerCalls, ['b1:c1']);
    });

    test('edit path: previous customerId != new customerId -> two recalcs',
        () async {
      await coordinator.recompute(
        newTransaction: sale(id: '1', customerId: 'c1'),
        previousTransaction: sale(id: '1', customerId: 'c2'),
      );
      expect(service.customerCalls, containsAllInOrder(['b1:c1', 'b1:c2']));
    });

    test('edit path: previous supplierId != new supplierId -> two recalcs',
        () async {
      await coordinator.recompute(
        newTransaction: purchase(id: '1', supplierId: 's1'),
        previousTransaction: purchase(id: '1', supplierId: 's2'),
      );
      expect(
          service.supplierCalls, containsAllInOrder(['b1:s1', 'b1:s2']));
    });

    test('edit path: previous transaction has no customerId -> only new recalcs',
        () async {
      final prev = TransactionModel(
        id: '1',
        userId: 'u1',
        businessId: 'b1',
        type: TransactionType.income,
        amount: 100,
        category: kSalesCategory,
        paymentMethod: 'Cash',
        customerId: null,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      await coordinator.recompute(
        newTransaction: sale(id: '1', customerId: 'c1'),
        previousTransaction: prev,
      );
      expect(service.customerCalls, ['b1:c1']);
    });

    test('recomputeAfterDelete triggers the right entity', () async {
      await coordinator.recomputeAfterDelete(sale(id: 'd', customerId: 'c9'));
      expect(service.customerCalls, ['b1:c9']);
      expect(service.supplierCalls, isEmpty);
    });

    test('recomputeAfterDelete on supplier triggers supplier only', () async {
      await coordinator.recomputeAfterDelete(
        purchase(id: 'd', supplierId: 's9'),
      );
      expect(service.supplierCalls, ['b1:s9']);
    });

    test('public recomputeCustomer / recomputeSupplier passthroughs work',
        () async {
      await coordinator.recomputeCustomer(businessId: 'b1', customerId: 'c5');
      await coordinator.recomputeSupplier(businessId: 'b1', supplierId: 's5');
      expect(service.customerCalls, ['b1:c5']);
      expect(service.supplierCalls, ['b1:s5']);
    });

    test('errors from the service are swallowed (no rethrow)', () async {
      service.shouldThrow = true;
      // Should not throw.
      await coordinator.recompute(
        newTransaction: sale(id: '1', customerId: 'c1'),
      );
      await coordinator.recomputeAfterDelete(
        sale(id: '1', customerId: 'c1'),
      );
    });
  });
}

class _RecordingService extends DueCalculationService {
  _RecordingService() : super(dataSource: _NoopDataSource());

  final List<String> customerCalls = [];
  final List<String> supplierCalls = [];
  bool shouldThrow = false;

  @override
  Future<void> recalculateCustomerDue({
    required String businessId,
    required String customerId,
  }) async {
    if (shouldThrow) throw StateError('boom');
    customerCalls.add('$businessId:$customerId');
  }

  @override
  Future<void> recalculateSupplierDue({
    required String businessId,
    required String supplierId,
  }) async {
    if (shouldThrow) throw StateError('boom');
    supplierCalls.add('$businessId:$supplierId');
  }
}

class _NoopDataSource implements DueDataSource {
  @override
  Future<List<TransactionModel>> fetchTransactionsForCustomer({
    required String businessId,
    required String customerId,
  }) async =>
      const [];

  @override
  Future<List<TransactionModel>> fetchTransactionsForSupplier({
    required String businessId,
    required String supplierId,
  }) async =>
      const [];

  @override
  Future<void> writeCustomerTotals({
    required String businessId,
    required String customerId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {}

  @override
  Future<void> writeSupplierTotals({
    required String businessId,
    required String supplierId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {}
}
