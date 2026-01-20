import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/utils/security_utils.dart';

void main() {
  test('sanitizeMessage trims, strips tags, and caps length', () {
    final raw = '  <b>Hello</b> world  ';
    final sanitized = SecurityUtils.sanitizeMessage(raw);
    expect(sanitized, 'Hello world');

    final long = 'a' * 1100;
    final trimmed = SecurityUtils.sanitizeMessage(long);
    expect(trimmed.length, 1000);
  });

  test('isValidChatParticipants enforces two valid IDs', () {
    expect(SecurityUtils.isValidChatParticipants(['a', 'b']), isTrue);
    expect(SecurityUtils.isValidChatParticipants(['a']), isFalse);
    expect(SecurityUtils.isValidChatParticipants(['', 'b']), isFalse);
  });

  test('generateSecureChatId sorts IDs and validates', () {
    final chatId = SecurityUtils.generateSecureChatId('userB', 'userA');
    expect(chatId, 'chat_userA_userB');

    expect(
      () => SecurityUtils.generateSecureChatId('', 'user'),
      throwsA(isA<Exception>()),
    );
  });
}
