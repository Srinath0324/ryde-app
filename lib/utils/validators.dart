import '../constants/app_constants.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!AppConstants.emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Whitelist approach for valid email domains
    final validEmailDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'aol.com',
      'protonmail.com',
      'mail.com',
      'zoho.com',
      'yandex.com',
      'gmx.com',
      'live.com',
      'msn.com',
      'rocketmail.com',
      'rediffmail.com',
    ];

    final emailParts = value.split('@');
    if (emailParts.length == 2) {
      final domain = emailParts[1].toLowerCase();
      if (!validEmailDomains.contains(domain)) {
        return 'provide a valid email from a recognized provider';
      }
    }

    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }

    if (!AppConstants.phonePattern.hasMatch(value)) {
      return 'Please enter a valid 10 digit mobile number';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (value.length > 50) {
      return 'Name must be at most 50 characters long';
    }

    return null;
  }

  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }

    if (!AppConstants.aadhaarPattern.hasMatch(value)) {
      return 'Please enter a valid 12 digit Aadhaar number';
    }

    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty || value == 'Select') {
      return 'Please select a gender';
    }
    return null;
  }
}
