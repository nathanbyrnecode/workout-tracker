import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/email_auth.dart';

void main() {
  test('normalises an address the way Supabase stores it', () {
    expect(normaliseEmail('  Lee@Example.COM \n'), 'lee@example.com');
  });

  test('accepts loose but plausible addresses', () {
    expect(isValidEmail('lee@example.com'), isTrue);
    expect(isValidEmail(' Lee.Smith+gym@mail.example.co.uk '), isTrue);
    expect(isValidEmail(''), isFalse);
    expect(isValidEmail('lee'), isFalse);
    expect(isValidEmail('lee@example'), isFalse);
    expect(isValidEmail('lee smith@example.com'), isFalse);
    expect(isValidEmail('@example.com'), isFalse);
  });

  test('needs a password of at least eight characters', () {
    expect(isValidPassword('1234567'), isFalse);
    expect(isValidPassword('12345678'), isTrue);
    expect(isValidPassword('        '), isTrue);
  });

  test('needs a code of exactly six digits', () {
    expect(isValidEmailCode('123456'), isTrue);
    expect(isValidEmailCode(' 123456 '), isTrue);
    expect(isValidEmailCode('12345'), isFalse);
    expect(isValidEmailCode('1234567'), isFalse);
    expect(isValidEmailCode('12345a'), isFalse);
    expect(isValidEmailCode('123 456'), isFalse);
  });
}
