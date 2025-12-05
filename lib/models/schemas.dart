// --- Authentication Models ---

class UserRegisterRequest {
  final String email;
  final String username;
  final String password;
  final String? fullName;
  final CefrLevel cefrLevel;

  UserRegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    this.fullName,
    this.cefrLevel = CefrLevel.A1,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'password': password,
    'full_name': fullName,
    'cefr_level': cefrLevel.name,
  };
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final String userId;
  final String email;
  final String username;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.email,
    required this.username,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      userId: json['user_id'],
      email: json['email'],
      username: json['username'],
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final CefrLevel cefrLevel;
  final DateTime createdAt;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.cefrLevel,
    required this.createdAt,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      cefrLevel: CefrLevel.values.firstWhere((e) => e.name == json['cefr_level']),
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'],
    );
  }
}


// --- Course & Conversation Models ---

class Course {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final CefrLevel recommendedLevel;
  final Map<String, dynamic>? content;
  final bool isActive;
  final int orderIndex;

  Course({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.recommendedLevel,
    this.content,
    required this.isActive,
    required this.orderIndex,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      recommendedLevel: CefrLevel.values.firstWhere((e) => e.name == json['recommended_level']),
      content: json['content'],
      isActive: json['is_active'],
      orderIndex: json['order_index'],
    );
  }
}

class CourseSessionStartRequest {
  final String courseId;
  final CefrLevel level;

  CourseSessionStartRequest({required this.courseId, required this.level});

  Map<String, dynamic> toJson() => {
    'course_id': courseId,
    'level': level.name,
  };
}

class Conversation {
  final String id;
  final String? title;
  final String conversationType;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  Conversation({
    required this.id,
    this.title,
    required this.conversationType,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      conversationType: json['conversation_type'],
      settings: json['settings'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'],
    );
  }
}

class ConversationDetail extends Conversation {
  final List<ChatMessage> messages;

  ConversationDetail({
    required super.id,
    super.title,
    required super.conversationType,
    required super.settings,
    required super.createdAt,
    required super.updatedAt,
    required super.messageCount,
    required this.messages,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'],
      title: json['title'],
      conversationType: json['conversation_type'],
      settings: json['settings'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'],
      messages: (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList(),
    );
  }
}



// --- General ---

enum CefrLevel {
  A1, A2, B1, B2, C1, C2;
  
  String get label => name;
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
    );
  }
}


// --- Word Learning Models ---
class WordRequest {
  final CefrLevel level;
  final int count;
  final String mode; // exact, upto, above, any

  WordRequest({
    required this.level,
    this.count = 3,
    this.mode = 'exact',
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'count': count,
    'mode': mode,
  };
}

class WordResponse {
  final List<String> words;

  WordResponse({required this.words});

  factory WordResponse.fromJson(Map<String, dynamic> json) {
    return WordResponse(
      words: (json['words'] as List).map((e) => e.toString()).toList(),
    );
  }
}

class WordSessionStartRequest {
  final String mode; // daily or random
  final CefrLevel level;
  final int count;

  WordSessionStartRequest({
    required this.mode,
    required this.level,
    this.count = 3,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'level': level.name,
    'count': count,
  };
}

class WordLearningSettings {
  final List<String> words;
  final CefrLevel level;
  final String mode;

  WordLearningSettings({
    required this.words,
    required this.level,
    required this.mode,
  });

  factory WordLearningSettings.fromJson(Map<String, dynamic> json) {
    return WordLearningSettings(
      words: (json['words'] as List).map((e) => e.toString()).toList(),
      level: CefrLevel.values.firstWhere((e) => e.name == json['level']),
      mode: json['mode'],
    );
  }
}

class WordLearningSession {
  final String sessionId;
  final WordLearningSettings settings;
  final List<ChatMessage> history;

  WordLearningSession({
    required this.sessionId,
    required this.settings,
    required this.history,
  });

  factory WordLearningSession.fromJson(Map<String, dynamic> json) {
    return WordLearningSession(
      sessionId: json['session_id'],
      settings: WordLearningSettings.fromJson(json['settings']),
      history: (json['history'] as List?)
          ?.map((e) => ChatMessage.fromJson(e))
          .toList() ?? [],
    );
  }
}

// --- Error Correction Models ---

class ErrorCheckRequest {
  final String text;

  ErrorCheckRequest({required this.text});

  Map<String, dynamic> toJson() => {'text': text};
}

class ErrorDetail {
  final String original;
  final String corrected;
  final String explanation;
  final String errorType;

  ErrorDetail({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.errorType,
  });

  factory ErrorDetail.fromJson(Map<String, dynamic> json) {
    return ErrorDetail(
      original: json['original'],
      corrected: json['corrected'],
      explanation: json['explanation'],
      errorType: json['error_type'],
    );
  }
}

class LevelAssessment {
  final String level;
  final String confidence;
  final String reasoning;

  LevelAssessment({
    required this.level,
    required this.confidence,
    required this.reasoning,
  });

  factory LevelAssessment.fromJson(Map<String, dynamic> json) {
    return LevelAssessment(
      level: json['level'],
      confidence: json['confidence'],
      reasoning: json['reasoning'],
    );
  }
}

class ErrorCheckResponse {
  final List<ErrorDetail> errors;
  final LevelAssessment? levelAssessment;
  final int errorCount;
  final int textLength;
  final bool? levelChanged;
  final String? currentLevel;
  final String? suggestedLevel;

  ErrorCheckResponse({
    required this.errors,
    this.levelAssessment,
    required this.errorCount,
    required this.textLength,
    this.levelChanged,
    this.currentLevel,
    this.suggestedLevel,
  });

  factory ErrorCheckResponse.fromJson(Map<String, dynamic> json) {
    return ErrorCheckResponse(
      errors: (json['errors'] as List)
          .map((e) => ErrorDetail.fromJson(e))
          .toList(),
      levelAssessment: json['level_assessment'] != null
          ? LevelAssessment.fromJson(json['level_assessment'])
          : null,
      errorCount: json['error_count'],
      textLength: json['text_length'],
      levelChanged: json['level_changed'],
      currentLevel: json['current_level'],
      suggestedLevel: json['suggested_level'],
    );
  }
}

class ErrorHistoryItem {
  final String id;
  final String originalText;
  final String correctedText;
  final String? explanation;
  final String errorType;
  final String? assessedLevel;
  final String? confidence;
  final DateTime createdAt;

  ErrorHistoryItem({
    required this.id,
    required this.originalText,
    required this.correctedText,
    this.explanation,
    required this.errorType,
    this.assessedLevel,
    this.confidence,
    required this.createdAt,
  });

  factory ErrorHistoryItem.fromJson(Map<String, dynamic> json) {
    return ErrorHistoryItem(
      id: json['id'],
      originalText: json['original_text'],
      correctedText: json['corrected_text'],
      explanation: json['explanation'],
      errorType: json['error_type'],
      assessedLevel: json['assessed_level'],
      confidence: json['confidence'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ErrorHistoryResponse {
  final List<ErrorHistoryItem> errors;
  final int total;

  ErrorHistoryResponse({required this.errors, required this.total});

  factory ErrorHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ErrorHistoryResponse(
      errors: (json['errors'] as List)
          .map((e) => ErrorHistoryItem.fromJson(e))
          .toList(),
      total: json['total'],
    );
  }
}

// --- Error Practice Models ---

class ErrorPracticeStartRequest {
  final String? focusType; // Optional: focus on specific error type

  ErrorPracticeStartRequest({this.focusType});

  Map<String, dynamic> toJson() => {
    if (focusType != null) 'focus_type': focusType,
  };
}

class ErrorPracticeResponse {
  final String sessionId;
  final int errorCount;
  final List<String> focusAreas;
  final String message;

  ErrorPracticeResponse({
    required this.sessionId,
    required this.errorCount,
    required this.focusAreas,
    required this.message,
  });

  factory ErrorPracticeResponse.fromJson(Map<String, dynamic> json) {
    return ErrorPracticeResponse(
      sessionId: json['session_id'],
      errorCount: json['error_count'],
      focusAreas: (json['focus_areas'] as List).cast<String>(),
      message: json['message'],
    );
  }
}

// --- Conversation Listing Models ---

class ConversationListItem {
  final String id;
  final String? title;
  final String conversationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ConversationListItem({
    required this.id,
    this.title,
    required this.conversationType,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationListItem.fromJson(Map<String, dynamic> json) {
    return ConversationListItem(
      id: json['id'],
      title: json['title'],
      conversationType: json['conversation_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'],
    );
  }
}

class ConversationListResponse {
  final List<ConversationListItem> conversations;
  final int total;

  ConversationListResponse({
    required this.conversations,
    required this.total,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> json) {
    return ConversationListResponse(
      conversations: (json['conversations'] as List)
          .map((e) => ConversationListItem.fromJson(e))
          .toList(),
      total: json['total'],
    );
  }
}

// --- Error Stats Models ---

class ErrorTypeCount {
  final String errorType;
  final int count;

  ErrorTypeCount({
    required this.errorType,
    required this.count,
  });

  factory ErrorTypeCount.fromJson(Map<String, dynamic> json) {
    return ErrorTypeCount(
      errorType: json['error_type'],
      count: json['count'],
    );
  }
}

class ErrorStatsResponse {
  final int totalErrors;
  final List<ErrorTypeCount> errorsByType;
  final LevelAssessment? mostRecentLevel;

  ErrorStatsResponse({
    required this.totalErrors,
    required this.errorsByType,
    this.mostRecentLevel,
  });

  factory ErrorStatsResponse.fromJson(Map<String, dynamic> json) {
    // Handle 'by_type' which is a Map<String, int> from backend
    final byTypeMap = json['by_type'] as Map<String, dynamic>? ?? {};
    final errorsList = byTypeMap.entries
        .map((e) => ErrorTypeCount(errorType: e.key, count: e.value as int))
        .toList();

    return ErrorStatsResponse(
      totalErrors: json['total_errors'],
      errorsByType: errorsList,
      mostRecentLevel: json['most_recent_assessment'] != null
          ? LevelAssessment.fromJson(json['most_recent_assessment'])
          : null,
    );
  }
}