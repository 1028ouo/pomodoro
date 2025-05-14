import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pomodoro/config/env_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // 忘記密碼方法
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    var request = http.Request(
      'POST',
      Uri.parse('$baseUrl/users/forgot_password'),
    );

    request.body = json.encode({
      "user": {"email": email},
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final responseData = json.decode(responseBody);

    if (response.statusCode == 200) {
      return {'success': true, 'message': responseData['message']};
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? response.reasonPhrase,
      };
    }
  }

  // Google登入方法
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 觸發認證流程
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // 如果用戶取消登入
      if (googleUser == null) {
        return {'success': false, 'message': '已取消登入'};
      }

      // 獲取認證詳情
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 創建認證憑證
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用 Firebase 進行登入
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        return {
          'success': true,
          'data': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
          },
        };
      } else {
        return {'success': false, 'message': '登入失敗'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
