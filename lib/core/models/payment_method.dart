import 'package:flutter/material.dart';

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  cashless,
  points,
  onAccount;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.cashless:
        return 'Cashless';
      case PaymentMethod.points:
        return 'Points';
      case PaymentMethod.onAccount:
        return 'On Account';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.cashless:
        return Icons.contactless;
      case PaymentMethod.points:
        return Icons.stars;
      case PaymentMethod.onAccount:
        return Icons.account_balance;
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay with cash';
      case PaymentMethod.creditCard:
        return 'Pay with credit card';
      case PaymentMethod.debitCard:
        return 'Pay with debit card';
      case PaymentMethod.cashless:
        return 'Pay with tap or mobile payment';
      case PaymentMethod.points:
        return 'Pay with reward points';
      case PaymentMethod.onAccount:
        return 'Charge to account';
    }
  }
}
