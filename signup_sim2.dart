import 'dart:io';
import 'dart:convert';
import 'dart:math';

final random = Random();

String generateOtp() => (100000 + random.nextInt(900000)).toString();

void main() {
  print("=== Account Signup ===\n");

  Map<String, dynamic> user = {
    'name': '',
    'age': '',
    'profession': '',
    'email': '',
    'phone': '',
    'hospital': '',
    'emailVerified': false,
    'phoneVerified': false,
  };

  // Basic inputs
  stdout.write("Enter your full name: ");
  user['name'] = stdin.readLineSync()?.trim() ?? '';

  stdout.write("Enter your age: ");
  user['age'] = stdin.readLineSync()?.trim() ?? '';

  stdout.write("Enter your profession: ");
  user['profession'] = stdin.readLineSync()?.trim() ?? '';

  // Email input and validation
  stdout.write("Enter your email ID: ");
  String inputEmail = stdin.readLineSync()?.trim().toLowerCase() ?? ''; // convert to lowercase
  user['email'] = inputEmail;

  // Basic email validation: must contain "@" and at least one "."
  bool validEmail = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(inputEmail);

  if (inputEmail.isNotEmpty && validEmail) {
    String emailOtp = generateOtp();
    print(" OTP sent to ${user['email']} (for demo: $emailOtp)");
    stdout.write("Enter OTP for email: ");
    String enteredEmailOtp = stdin.readLineSync()?.trim() ?? '';
    if (enteredEmailOtp == emailOtp) {
      user['emailVerified'] = true;
      print("✅ Email Verified!\n");
    } else {
      print("Wrong Email OTP.\n");
    }
  } else if (inputEmail.isNotEmpty) {
    print(" Invalid email format! Please enter a valid lowercase email (example: user@mail.com)\n");
  }

  // Phone number input and validation
  stdout.write("Enter your phone number: ");
  user['phone'] = stdin.readLineSync()?.trim() ?? '';

  bool phoneLengthValid = user['phone'].length <= 10;
  bool phoneNumeric = RegExp(r'^[0-9]+$').hasMatch(user['phone']);

  if (user['phone'].isNotEmpty && phoneLengthValid && phoneNumeric) {
    String phoneOtp = generateOtp();
    print(" OTP sent to ${user['phone']} (for demo: $phoneOtp)");
    stdout.write("Enter OTP for phone: ");
    String enteredPhoneOtp = stdin.readLineSync()?.trim() ?? '';
    if (enteredPhoneOtp == phoneOtp) {
      user['phoneVerified'] = true;
      print(" Phone Verified!\n");
    } else {
      print(" Wrong Phone OTP.\n");
    }
  } else if (user['phone'].isNotEmpty && (!phoneNumeric || !phoneLengthValid)) {
    print(" Invalid phone number! It should be digits only and not exceed 10 digits.\n");
  }

  //  Optional hospital
  stdout.write("Enter hospital name (optional): ");
  user['hospital'] = stdin.readLineSync()?.trim() ?? '';

  // Final validation check
  List<String> missing = [];

  if (user['name'].isEmpty) missing.add("Name");
  if (user['age'].isEmpty) missing.add("Age");
  if (user['profession'].isEmpty) missing.add("Profession");
  if (user['email'].isEmpty || !user['emailVerified'] || !validEmail)
    missing.add("Valid Email (must contain @ and domain like .com)");
  if (user['phone'].isEmpty || !user['phoneVerified'] || !phoneLengthValid || !phoneNumeric)
    missing.add("Valid Phone Number (10 digits)");

  if (missing.isNotEmpty) {
    print("\n Please enter the following details to create your account:");
    for (var m in missing) {
      print(" - $m");
    }
    print("\n Account not created. Fill missing details and try again.");
  } else {
    String userId = DateTime.now().millisecondsSinceEpoch.toString();
    user['id'] = userId;
    print("\n Account created successfully!");
    print(jsonEncode(user));
  }
}
