import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pomodoro/config/env_config.dart';

class AuthService {
  final String baseUrl = EnvConfig.apiBaseUrl;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Token token="${EnvConfig.apiToken}"',
  };

  // 用戶註冊方法
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    var request = http.Request('POST', Uri.parse('$baseUrl/users'));

    request.body = json.encode({
      "user": {"login": username, "email": email, "password": password},
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(responseBody)};
    } else {
      return {
        'success': false,
        'message':
            json.decode(responseBody)['message'] ?? response.reasonPhrase,
      };
    }
  }

  // 用戶登入方法
  Future<Map<String, dynamic>> login(String username, String password) async {
    var request = http.Request('POST', Uri.parse('$baseUrl/session'));

    request.body = json.encode({
      "user": {"login": username, "password": password},
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final responseData = json.decode(responseBody);

    if (response.statusCode == 200) {
      // 檢查是否包含錯誤信息
      if (responseData.containsKey('error_code') ||
          (responseData.containsKey('message') &&
              !responseData.containsKey('User-Token'))) {
        return {'success': false, 'message': responseData['message'] ?? '登入失敗'};
      }
      // 檢查是否有成功登入的必要信息
      else if (responseData.containsKey('User-Token')) {
        return {
          'success': true,
          'data': responseData,
          'userToken': responseData['User-Token'],
          'username': responseData['login'],
          'email': responseData['email'],
        };
      } else {
        // 處理未預期的回應格式
        return {'success': false, 'message': '未預期的回應格式'};
      }
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? response.reasonPhrase,
      };
    }
  }
}
