import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schemas.dart';
import 'auth_service.dart'; // Import AuthService

class ApiService {
  // Use localhost for local development
  static const String baseUrl = 'http://199.247.1.121:8001';
  final http.Client _client = http.Client();
  final AuthService? authService; // Make AuthService available

  ApiService({this.authService});

  // Private method to get headers, including Auth token if available
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (authService?.token != null) {
      headers['Authorization'] = 'Bearer ${authService!.token}';
    }
    return headers;
  }

  // --- Authentication Methods ---

  Future<UserProfile> register(UserRegisterRequest request) async {
    final url = Uri.parse('$baseUrl/auth/register');
    print('🔵 [POST] Registering user at: $url');

    try {
      // 1. Get Token
      final response = await _client.post(
        url,
        headers: _getHeaders(), // Initial headers (no token)
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Register Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode != 201) {
        throw Exception(body['detail'] ?? 'Failed to register');
      }
      
      final tokenResponse = TokenResponse.fromJson(body);

      // 2. Set token for the session
      await authService?.setTokenForSession(tokenResponse.accessToken);

      // 3. Get user profile with the new token
      final userProfile = await getMe();
      
      // 4. Finalize login state
      authService?.finalizeLogin(userProfile);

      return userProfile;

    } catch (e) {
      print('🔴 Connection Error in register: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<UserProfile> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    print('🔵 [POST] Logging in user at: $url');

    try {
      // 1. Get Token
      final response = await _client.post(
        url,
        headers: _getHeaders(), // Initial headers (no token)
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('🟢 Login Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(body['detail'] ?? 'Failed to login');
      }

      final tokenResponse = TokenResponse.fromJson(body);
      
      // 2. Set token for the session
      await authService?.setTokenForSession(tokenResponse.accessToken);
      
      // 3. Get user profile with the new token
      final userProfile = await getMe();

      // 4. Finalize login state
      authService?.finalizeLogin(userProfile);
      
      return userProfile;

    } catch (e) {
      print('🔴 Connection Error in login: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<UserProfile> getMe() async {
    final url = Uri.parse('$baseUrl/auth/me');
    print('🔵 [GET] Fetching user profile at: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders()); // This will now have the token

      print('🟢 getMe Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to get profile');
      }
    } catch (e) {
      print('🔴 Connection Error in getMe: $e');
      throw Exception('Connection error: $e');
    }
  }


  // --- Course and Conversation Methods ---

  Future<List<Course>> getCourses({CefrLevel? level}) async {
    var url = Uri.parse('$baseUrl/courses');
    if (level != null) {
      url = url.replace(queryParameters: {'level': level.name});
    }
    print('🔵 [GET] Fetching courses from: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final courses = (body['courses'] as List)
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();
        return courses;
      } else {
        throw Exception(body['detail'] ?? 'Failed to fetch courses');
      }
    } catch (e) {
      print('🔴 Connection Error in getCourses: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<ConversationDetail> startCourseSession(CourseSessionStartRequest request) async {
    final url = Uri.parse('$baseUrl/session/start');
    print('🔵 [POST] Starting course session at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ConversationDetail.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to start session');
      }
    } catch (e) {
      print('🔴 Connection Error in startCourseSession: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<ConversationDetail> getConversation(String sessionId) async {
    final url = Uri.parse('$baseUrl/session/$sessionId');
    print('🔵 [GET] Fetching conversation at: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ConversationDetail.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to get conversation');
      }
    } catch (e) {
      print('🔴 Connection Error in getConversation: $e');
      throw Exception('Connection error: $e');
    }
  }


  // 2. Stream Chat Message
  Stream<Map<String, dynamic>> sendMessage(String sessionId, String message) async* {
    final url = Uri.parse('$baseUrl/session/$sessionId/chat');
    
    final request = http.Request('POST', url);
    request.headers.addAll(_getHeaders()); // Use authenticated headers
    request.body = jsonEncode({'message': message});
    
    try {
      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception('Chat error: ${streamedResponse.statusCode}, $body');
      }

      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        
        if (line.trim().isEmpty) continue;
        
        try {
          final data = jsonDecode(line);
          if (data.containsKey('error')) {
            yield {'type': 'error', 'content': data['error']};
            break;
          } else if (data.containsKey('status')) {
            yield {'type': 'status', 'content': data['status']};
          } else if (data.containsKey('chunk')) {
            yield {'type': 'chunk', 'content': data['chunk']};
          } else if (data.containsKey('tool_calls')) {
            // Navigation tool calls from adaptive chat
            yield {'type': 'tool_calls', 'content': data['tool_calls']};
          }
        } catch (parseError) {
          print('⚠️ JSON Parse Error on line: "$line" - Error: $parseError');
          continue;
        }
      }
      
      print('✅ Stream completed for session: $sessionId');
      
    } catch (e) {
      print('🔴 Stream Error: $e');
      yield {'type': 'error', 'content': 'Connection error: ${e.toString()}'};
      rethrow;
    }
  }

  // 3. Get Daily Words
  Future<WordResponse> getDailyWords(CefrLevel level, {int count = 3}) async {
    final url = Uri.parse('$baseUrl/words/daily?level=${level.name}&count=$count');
    print('🔵 [GET] Fetching daily words at: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders()); // Auth needed

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return WordResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to get daily words');
      }
    } catch (e) {
      print('🔴 Connection Error in getDailyWords: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 4. Get Random Words
  Future<WordResponse> getRandomWords(WordRequest request) async {
    final url = Uri.parse('$baseUrl/words/random');
    print('🔵 [POST] Fetching random words at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(), // Auth needed
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return WordResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to get random words');
      }
    } catch (e) {
      print('🔴 Connection Error in getRandomWords: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 5. Start Word Learning Session
  Future<WordLearningSession> startWordSession(WordSessionStartRequest request) async {
    final url = Uri.parse('$baseUrl/word-session/start');
    print('🔵 [POST] Starting word session at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(), // Auth needed
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return WordLearningSession(
            sessionId: body['id'],
            settings: WordLearningSettings(
              words: (body['settings']['words'] as List).cast<String>(),
              level: CefrLevel.values.firstWhere((e) => e.name == body['settings']['level']),
              mode: body['settings']['mode'],
            ),
            history: (body['messages'] as List?)
                  ?.map((e) => ChatMessage.fromJson(e))
                  .toList() ?? []
        );
      } else {
        throw Exception(body['detail'] ?? 'Failed to start word session');
      }
    } catch (e) {
      print('🔴 Connection Error in startWordSession: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 6. Stream Word Chat Message
  Stream<Map<String, dynamic>> sendWordMessage(String sessionId, String message) async* {
    final url = Uri.parse('$baseUrl/word-session/$sessionId/chat');
    
    final request = http.Request('POST', url);
    request.headers.addAll(_getHeaders()); // Auth needed
    request.body = jsonEncode({'message': message});
    
    try {
      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception('Word chat error: ${streamedResponse.statusCode}, $body');
      }

      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        
        if (line.trim().isEmpty) continue;
        
        try {
          final data = jsonDecode(line);
          if (data.containsKey('error')) {
            yield {'type': 'error', 'content': data['error']};
            break;
          } else if (data.containsKey('status')) {
            yield {'type': 'status', 'content': data['status']};
          } else if (data.containsKey('chunk')) {
            yield {'type': 'chunk', 'content': data['chunk']};
          }
        } catch (parseError) {
          print('⚠️ JSON Parse Error on line: "$line" - Error: $parseError');
          continue;
        }
      }
      
      print('✅ Word stream completed for session: $sessionId');
      
    } catch (e) {
      print('🔴 Word Stream Error: $e');
      yield {'type': 'error', 'content': 'Connection error: ${e.toString()}'};
      rethrow;
    }
  }
  // --- Error Correction Methods ---

  Future<ErrorCheckResponse> checkErrors(ErrorCheckRequest request) async {
    final url = Uri.parse('$baseUrl/errors/check');
    print('🔵 [POST] Checking errors at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ErrorCheckResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to check errors');
      }
    } catch (e) {
      print('🔴 Connection Error in checkErrors: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<ErrorHistoryResponse> getErrorHistory({int limit = 20, int offset = 0}) async {
    final url = Uri.parse('$baseUrl/errors/history?limit=$limit&offset=$offset');
    print('🔵 [GET] Fetching error history from: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ErrorHistoryResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to fetch error history');
      }
    } catch (e) {
      print('🔴 Connection Error in getErrorHistory: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 9. Start Error Practice Session
  Future<ErrorPracticeResponse> startErrorPractice({String? focusType}) async {
    final url = Uri.parse('$baseUrl/errors/practice/start');
    print('🔵 [POST] Starting error practice session at: $url');

    try {
      final request = ErrorPracticeStartRequest(focusType: focusType);
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ErrorPracticeResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to start error practice');
      }
    } catch (e) {
      print('🔴 Connection Error in startErrorPractice: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 9a. Start Adaptive Session
  Future<ConversationDetail> startAdaptiveSession() async {
    final url = Uri.parse('$baseUrl/adaptive/start');
    print('🔵 [POST] Starting adaptive session at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        // No body needed as context is inferred from user ID
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ConversationDetail.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to start adaptive session');
      }
    } catch (e) {
      print('🔴 Connection Error in startAdaptiveSession: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 10. Get All Conversations (Session Listing)
  Future<ConversationListResponse> getConversations({
    String? conversationType,
    int limit = 20,
    int offset = 0,
  }) async {
    var queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (conversationType != null) {
      queryParams['conversation_type'] = conversationType;
    }

    final url = Uri.parse('$baseUrl/conversations').replace(queryParameters: queryParams);
    print('🔵 [GET] Fetching conversations from: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ConversationListResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      print('🔴 Connection Error in getConversations: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 11. Delete Session
  Future<void> deleteSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/session/$sessionId');
    print('🔵 [DELETE] Deleting session at: $url');

    try {
      final response = await _client.delete(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Failed to delete session');
      }
    } catch (e) {
      print('🔴 Connection Error in deleteSession: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 12. Get Error Stats
  Future<ErrorStatsResponse> getErrorStats() async {
    final url = Uri.parse('$baseUrl/errors/stats');
    print('🔵 [GET] Fetching error stats from: $url');

    try {
      final response = await _client.get(url, headers: _getHeaders());
      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ErrorStatsResponse.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to fetch error stats');
      }
    } catch (e) {
      print('🔴 Connection Error in getErrorStats: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 13. Update User Profile
  Future<UserProfile> updateUserProfile({
    String? fullName,
    CefrLevel? cefrLevel,
  }) async {
    final url = Uri.parse('$baseUrl/auth/me');
    print('🔵 [PATCH] Updating user profile at: $url');

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (cefrLevel != null) updateData['cefr_level'] = cefrLevel.name;

    try {
      final response = await _client.patch(
        url,
        headers: _getHeaders(),
        body: jsonEncode(updateData),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('🔴 Connection Error in updateUserProfile: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 14. Update Level from Error Assessment
  Future<UserProfile> updateLevel(String newLevel) async {
    final url = Uri.parse('$baseUrl/errors/update-level');
    print('🔵 [POST] Updating level to $newLevel at: $url');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'new_level': newLevel}),
      );

      print('🟢 Response Status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(body);
      } else {
        throw Exception(body['detail'] ?? 'Failed to update level');
      }
    } catch (e) {
      print('🔴 Connection Error in updateLevel: $e');
      throw Exception('Connection error: $e');
    }
  }

  // 15. Mark Error as Resolved
  Future<void> markErrorAsResolved(String errorId) async {
    final url = Uri.parse('$baseUrl/errors/$errorId/resolve');
    print('🔵 [PATCH] Marking error $errorId as resolved at: $url');

    try {
      final response = await _client.patch(
        url,
        headers: _getHeaders(),
      );

      print('🟢 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Failed to resolve error');
      }
    } catch (e) {
      print('🔴 Connection Error in markErrorAsResolved: $e');
      throw Exception('Connection error: $e');
    }
  }


  void dispose() {
    _client.close();
  }
}