import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://10.91.53.110:8080';
  static const Duration timeout = Duration(seconds: 30);
  late http.Client _client;

  ApiService() {
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Get all messages
  Future<List<Message>> getMessages() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decodedData = json.decode(response.body);

        // Handle different response formats
        if (decodedData is List) {
          // Direct list of messages
          return decodedData
              .map((item) => Message.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (decodedData is Map<String, dynamic>) {
          // Wrapped in ApiResponse
          final apiResponse = ApiResponse<List<Message>>.fromJson(
            decodedData,
            (data) => (data as List)
                .map((item) => Message.fromJson(item as Map<String, dynamic>))
                .toList(),
          );
          return apiResponse.data ?? [];
        }
        return [];
      } else {
        throw ApiException('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Create a new message
  Future<Message> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic>) {
          // Check if it's wrapped in ApiResponse
          if (decodedData.containsKey('success') &&
              decodedData.containsKey('data')) {
            final apiResponse = ApiResponse<Message>.fromJson(
              decodedData,
              (data) => Message.fromJson(data as Map<String, dynamic>),
            );
            if (apiResponse.data == null) {
              throw ApiException('No message data received');
            }
            return apiResponse.data!;
          } else {
            // Direct message object
            return Message.fromJson(decodedData);
          }
        }
        throw ApiException('Invalid response format');
      } else {
        throw ApiException('Failed to create message: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Update an existing message
  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic>) {
          // Check if it's wrapped in ApiResponse
          if (decodedData.containsKey('success') &&
              decodedData.containsKey('data')) {
            final apiResponse = ApiResponse<Message>.fromJson(
              decodedData,
              (data) => Message.fromJson(data as Map<String, dynamic>),
            );
            if (apiResponse.data == null) {
              throw ApiException('No message data received');
            }
            return apiResponse.data!;
          } else {
            // Direct message object
            return Message.fromJson(decodedData);
          }
        }
        throw ApiException('Invalid response format');
      } else {
        throw ApiException('Failed to update message: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode != 204) {
        throw ApiException('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Get HTTP status information
  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/status/$statusCode'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic>) {
          // Check if it's wrapped in ApiResponse
          if (decodedData.containsKey('success') &&
              decodedData.containsKey('data')) {
            final apiResponse = ApiResponse<HTTPStatusResponse>.fromJson(
              decodedData,
              (data) =>
                  HTTPStatusResponse.fromJson(data as Map<String, dynamic>),
            );
            if (apiResponse.data == null) {
              throw ApiException('No status data received');
            }
            return apiResponse.data!;
          } else {
            // Direct status object
            return HTTPStatusResponse.fromJson(decodedData);
          }
        }
        throw ApiException('Invalid response format');
      } else {
        throw ApiException('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/health'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.message}');
      }
      rethrow;
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class ValidationException extends ApiException {
  ValidationException(super.message);
}
