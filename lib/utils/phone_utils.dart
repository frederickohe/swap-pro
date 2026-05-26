/// Normalize phone numbers for API calls (Ghana-focused).
String normalizePhone(String phone) {
  final raw = phone.trim();
  if (raw.isEmpty) return raw;

  final digits = raw.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('233') && digits.length >= 12) {
    return '+${digits.substring(0, 12)}';
  }

  if (digits.startsWith('0') && digits.length == 10) {
    return '+233${digits.substring(1)}';
  }

  if (digits.length == 9) {
    return '+233$digits';
  }

  if (raw.startsWith('+') && digits.isNotEmpty) {
    return '+$digits';
  }

  return digits.isNotEmpty ? digits : raw;
}
