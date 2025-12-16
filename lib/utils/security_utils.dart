class SecurityUtils {
  static String sanitizeMessage(String input) {
    if (input.isEmpty) return input;

    // First trim the input
    String sanitized = input.trim();

    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Then limit length safely - check the actual length first
    const int maxLength = 1000;
    if (sanitized.length > maxLength) {
      return sanitized.substring(0, maxLength);
    }
    return sanitized;
  }

  static bool isValidUserId(String userId) {
    return userId.isNotEmpty && userId.length <= 128;
  }

  static bool isValidChatParticipants(List<String> participants) {
    return participants.length == 2 &&
        participants.every((id) => isValidUserId(id));
  }

  static String generateSecureChatId(String user1Id, String user2Id) {
    if (!isValidUserId(user1Id) || !isValidUserId(user2Id)) {
      throw Exception('Invalid user IDs for chat');
    }

    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }
}
