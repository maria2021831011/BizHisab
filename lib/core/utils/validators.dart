class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? mobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Strip spaces, dashes and a leading +88 / 880 prefix if the user pasted one
    var cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+88')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('880')) {
      cleaned = cleaned.substring(3);
    }
    // Accept any BD operator prefix 013-019 followed by 8 digits (11 total)
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(cleaned)) {
      return 'Invalid number format. Use 01XXXXXXXXX';
    }
    return null;
  }

  /// Normalize any input into the canonical **local** form `01XXXXXXXXX`.
  /// This matches BloodMate's working BdApps integration, which sends
  /// the local 11-digit number under the `user_mobile` field.
  static String toLocalBdPhone(String value) {
    var cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+88')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('880')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('88') && cleaned.length > 11) {
      cleaned = cleaned.substring(2);
    }
    return cleaned;
  }

  /// Backwards-compatible alias preserved from earlier code paths.
  /// New callers should prefer [toLocalBdPhone].
  static String normalizeBdPhone(String value) {
    return '880${toLocalBdPhone(value)}';
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid amount';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  /// Validates a phone number **only if** the user provided one.
  /// Empty / null input is accepted; non-empty input must match the
  /// Bangladeshi mobile format `01XXXXXXXXX` (operator prefixes 013-019).
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+88')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('880')) {
      cleaned = cleaned.substring(3);
    }
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(cleaned)) {
      return 'Invalid number format. Use 01XXXXXXXXX';
    }
    return null;
  }

  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Business name must be less than 100 characters';
    }
    return null;
  }

  static String? name(String? value, [String fieldName = 'Name']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Input']) {
    if (value != null && value.length > max) {
      return '$fieldName must be less than $max characters';
    }
    return null;
  }
}
