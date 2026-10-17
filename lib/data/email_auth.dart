/// Checks for the email sign-in forms. They only decide whether a button is
/// enabled; Supabase has the final say.
library;

/// The shortest password the forms accept. Matches the minimum set in the
/// Supabase dashboard.
const minPasswordLength = 8;

/// Whether the sheet offers "Forgot password?". Resetting emails a code, and
/// Supabase only emails the public once a custom SMTP sender is set up, so
/// this stays off until then (`dev/decisions.md` 19).
const emailPasswordResetEnabled = false;

/// Digits in a confirmation or reset code. Matches the Email OTP length set
/// in the Supabase dashboard.
const emailCodeLength = 6;

final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _codeShape = RegExp('^\\d{$emailCodeLength}\$');

/// The address as Supabase stores it: trimmed and lower-cased.
String normaliseEmail(String input) => input.trim().toLowerCase();

/// Something, an @, a domain with a dot. Deliberately loose.
bool isValidEmail(String input) => _emailShape.hasMatch(normaliseEmail(input));

bool isValidPassword(String password) => password.length >= minPasswordLength;

bool isValidEmailCode(String input) => _codeShape.hasMatch(input.trim());
