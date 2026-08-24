import 'package:flutter_test/flutter_test.dart';
import 'package:bizhisab_ai/models/transaction.dart';
import 'package:bizhisab_ai/models/customer.dart';
import 'package:bizhisab_ai/models/supplier.dart';
import 'package:bizhisab_ai/models/subscription_result.dart';
import 'package:bizhisab_ai/core/utils/validators.dart';
import 'package:bizhisab_ai/core/utils/currency_formatter.dart';
import 'package:bizhisab_ai/core/utils/formatters.dart';

void main() {
  group('Validators', () {
    test('required field validator', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('value'), isNull);
    });

    test('mobile number validator', () {
      expect(Validators.mobileNumber(''), isNotNull);
      expect(Validators.mobileNumber('0123456789'), isNotNull);
      expect(Validators.mobileNumber('01712345678'), isNull);
      expect(Validators.mobileNumber('01812345678'), isNull);
      expect(Validators.mobileNumber('01912345678'), isNull);
      expect(Validators.mobileNumber('01612345678'), isNotNull);
    });

    test('OTP validator', () {
      expect(Validators.otp(''), isNotNull);
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
      expect(Validators.otp('abcdef'), isNotNull);
      expect(Validators.otp('123456'), isNull);
    });

    test('amount validator', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('100'), isNull);
      expect(Validators.amount('100.50'), isNull);
    });

    test('business name validator', () {
      expect(Validators.businessName(''), isNotNull);
      expect(Validators.businessName('A'), isNotNull);
      expect(Validators.businessName('AB'), isNull);
      expect(Validators.businessName('My Business'), isNull);
    });
  });

  group('CurrencyFormatter', () {
    test('format', () {
      expect(CurrencyFormatter.format(1000), '৳1,000');
      expect(CurrencyFormatter.format(0), '৳0');
      expect(CurrencyFormatter.format(100000), '৳100,000');
    });

    test('formatWithSign', () {
      expect(CurrencyFormatter.formatWithSign(1000), '+৳1,000');
      expect(CurrencyFormatter.formatWithSign(-1000), '-৳1,000');
    });

    test('formatShort', () {
      expect(CurrencyFormatter.formatShort(500), '৳500');
      expect(CurrencyFormatter.formatShort(1500), '৳1.5K');
      expect(CurrencyFormatter.formatShort(150000), '৳1.5L');
    });
  });

  group('TransactionModel', () {
    test('income categories exist', () {
      expect(TransactionModel.incomeCategories, isNotEmpty);
      expect(TransactionModel.incomeCategories, contains('Sales'));
      expect(TransactionModel.incomeCategories, contains('Service'));
    });

    test('expense categories exist', () {
      expect(TransactionModel.expenseCategories, isNotEmpty);
      expect(TransactionModel.expenseCategories, contains('Purchase'));
      expect(TransactionModel.expenseCategories, contains('Rent'));
      expect(TransactionModel.expenseCategories, contains('Salary'));
    });

    test('payment methods exist', () {
      expect(TransactionModel.paymentMethods, contains('Cash'));
      expect(TransactionModel.paymentMethods, contains('Bank'));
      expect(TransactionModel.paymentMethods, contains('Mobile Banking'));
    });
  });

  group('Customer', () {
    test('totalDue calculation', () {
      final customer = Customer(
        id: '1',
        businessId: 'b1',
        userId: 'u1',
        name: 'Test',
        totalPurchase: 15000,
        totalPaid: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(customer.totalDue, 5000);
    });

    test('totalDue when fully paid', () {
      final customer = Customer(
        id: '1',
        businessId: 'b1',
        userId: 'u1',
        name: 'Test',
        totalPurchase: 10000,
        totalPaid: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(customer.totalDue, 0);
    });
  });

  group('Supplier', () {
    test('totalDue calculation', () {
      final supplier = Supplier(
        id: '1',
        businessId: 'b1',
        userId: 'u1',
        name: 'Test Supplier',
        totalPurchase: 50000,
        totalPaid: 35000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(supplier.totalDue, 15000);
    });
  });

  group('SubscriptionResult', () {
    test('fromJson parsing', () {
      final result = SubscriptionResult.fromJson({
        'success': true,
        'is_active': true,
        'message': 'Active',
      });
      expect(result.success, true);
      expect(result.isActive, true);
      expect(result.message, 'Active');
    });

    test('failure factory', () {
      final result = SubscriptionResult.failure('Network error');
      expect(result.success, false);
      expect(result.isActive, false);
      expect(result.error, 'Network error');
    });
  });

  group('Formatters', () {
    test('date formatting', () {
      final date = DateTime(2024, 3, 15);
      final formatted = Formatters.date(date);
      expect(formatted, '15 Mar 2024');
    });

    test('phone formatting', () {
      expect(Formatters.phone('+8801712345678'), '01712345678');
      expect(Formatters.phone('8801712345678'), '01712345678');
      expect(Formatters.phone('01712345678'), '01712345678');
    });
  });
}
