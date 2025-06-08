import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 登入方法
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 註冊方法
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String birthday, // 新增生日參數
  ) async {
    try {
      // 創建用戶
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 設置用戶顯示名稱
      await userCredential.user!.updateDisplayName(username);

      // 隨機選擇一個頭像 ID
      String profilePicId = getRandomProfilePicId();

      // 在Firestore中創建用戶資料，包含生日和頭像 ID
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'birthday': birthday, // 儲存生日
        'joinedAt': DateTime.now().toIso8601String(),
        'totalFocusTime': 0,
        'streakDays': 0,
        'weeklyFocusTime': 0,
        'completedPomodoros': 0,
        'profilePicId': profilePicId, // 儲存頭像 ID
      });

      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Google登入方法
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 開始Google登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': '已取消Google登入'};
      }

      // 獲取驗證信息
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用Google憑證登入Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // 檢查用戶是否已存在於Firestore
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        // 如果用戶不存在，創建新的用戶資料
        if (!docSnapshot.exists) {
          // 隨機選擇一個頭像 ID
          String profilePicId = getRandomProfilePicId();

          await docRef.set({
            'username': user.displayName ?? '使用者',
            'email': user.email ?? '',
            'birthday': '', // 為Google用戶設置空生日，需要用戶稍後填寫
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'profilePicId': profilePicId, // 為Google用戶設置隨機頭像 ID
          });
        }

        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': '無法使用Google登入'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Facebook登入方法 - 更新為更安全的實現
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      developer.log('開始Facebook登入流程');

      // 生成一次性數字(nonce)來增加安全性
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // 啟動Facebook登入流程，使用nonce增加安全性
      final LoginResult loginResult = await FacebookAuth.instance.login(
        loginTracking: LoginTracking.enabled,
        nonce: nonce,
      );

      developer.log('Facebook登入結果: ${loginResult.status.name}');

      if (loginResult.status != LoginStatus.success) {
        developer.log(
          'Facebook登入失敗',
          error: '狀態: ${loginResult.status}, 消息: ${loginResult.message}',
        );
        return {
          'success': false,
          'message': 'Facebook登入失敗: ${loginResult.message}',
        };
      }

      if (loginResult.accessToken == null) {
        developer.log('Facebook token為空');
        return {'success': false, 'message': 'Facebook登入失敗: 無法獲取訪問令牌'};
      }

      developer.log('已獲取Facebook令牌，準備處理不同類型的令牌');

      // 根據令牌類型選擇適當的憑證創建方式
      OAuthCredential facebookAuthCredential;

      try {
        // 檢查令牌類型並處理
        if (loginResult.accessToken is ClassicToken) {
          final token = loginResult.accessToken as ClassicToken;
          developer.log('使用ClassicToken處理');
          facebookAuthCredential = FacebookAuthProvider.credential(
            token.authenticationToken ?? token.tokenString,
          );
        } else if (loginResult.accessToken is LimitedToken) {
          final token = loginResult.accessToken as LimitedToken;
          developer.log('使用LimitedToken處理');
          facebookAuthCredential = OAuthCredential(
            providerId: 'facebook.com',
            signInMethod: 'oauth',
            idToken: token.tokenString,
            rawNonce: rawNonce,
          );
        } else {
          // 如果無法確定具體類型，使用通用方法
          developer.log('使用通用方法處理令牌');
          facebookAuthCredential = FacebookAuthProvider.credential(
            loginResult.accessToken!.tokenString,
          );
        }
      } catch (e) {
        developer.log('處理Facebook令牌時出錯', error: e.toString());
        // 使用標準處理作為備用方案
        facebookAuthCredential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
      }

      if (facebookAuthCredential == null) {
        return {'success': false, 'message': 'Facebook登入失敗: 無法創建有效憑證'};
      }

      // 使用Facebook憑證登入Firebase
      developer.log('嘗試使用Facebook憑證登入Firebase');
      final UserCredential userCredential = await _auth.signInWithCredential(
        facebookAuthCredential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // 檢查用戶是否已存在於Firestore
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        // 如果用戶不存在，創建新的用戶資料
        if (!docSnapshot.exists) {
          String profilePicId = getRandomProfilePicId();

          await docRef.set({
            'username': user.displayName ?? '使用者',
            'email': user.email ?? '',
            'birthday': '', // 為Facebook用戶設置空生日
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'profilePicId': profilePicId,
          });
        }

        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': '無法使用Facebook登入'};
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase認證錯誤', error: '${e.code}: ${e.message}');
      return {
        'success': false,
        'message': '登入失敗: ${_getErrorMessage(e.code)}\n詳細信息: ${e.message}',
      };
    } catch (e) {
      developer.log('Facebook登入出現未知錯誤', error: e.toString());
      return {'success': false, 'message': '登入失敗: ${e.toString()}'};
    }
  }

  // 忘記密碼方法
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': '密碼重設連結已發送到您的電子郵件'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 更新生日方法
  Future<Map<String, dynamic>> updateBirthday(String birthday) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': '用戶未登入'};
      }

      // 檢查用戶當前生日資料
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final currentBirthday = userData['birthday'] as String?;

        // 如果生日已存在且不為空，則不允許更改
        if (currentBirthday != null && currentBirthday.isNotEmpty) {
          return {'success': false, 'message': '生日資料已存在，無法修改'};
        }

        // 更新生日資料
        await _firestore.collection('users').doc(currentUser.uid).update({
          'birthday': birthday,
        });

        return {'success': true, 'message': '生日更新成功'};
      } else {
        return {'success': false, 'message': '用戶資料不存在'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 隨機選擇頭像 ID
  String getRandomProfilePicId() {
    // 生成 1-10 的隨機數
    int randomNum = 1 + (DateTime.now().millisecondsSinceEpoch % 10);
    return 'pic_$randomNum';
  }

  // 錯誤訊息處理
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '找不到此電子郵件的用戶';
      case 'wrong-password':
        return '密碼錯誤';
      case 'invalid-email':
        return '無效的電子郵件格式';
      case 'user-disabled':
        return '此用戶已被停用';
      case 'email-already-in-use':
        return '此電子郵件已被使用';
      case 'operation-not-allowed':
        return '此操作不被允許';
      case 'weak-password':
        return '密碼強度不足';
      case 'too-many-requests':
        return '登入嘗試次數過多，請稍後再試';
      default:
        return '發生錯誤: $code';
    }
  }

  // 生成一次性數字方法
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA-256哈希方法
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
