import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 用戶註冊方法
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // 使用 Firebase 創建用戶
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 設置用戶顯示名稱
      await credential.user?.updateDisplayName(username);

      return {
        'success': true,
        'data': {
          'uid': credential.user?.uid,
          'email': credential.user?.email,
          'displayName': username,
        },
      };
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = '密碼強度太弱';
      } else if (e.code == 'email-already-in-use') {
        message = '此電子郵件已被使用';
      } else if (e.code == 'invalid-email') {
        message = '無效的電子郵件格式';
      } else {
        message = e.message ?? '註冊時發生錯誤';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 用戶登入方法
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'data': {
          'uid': credential.user?.uid,
          'email': credential.user?.email,
          'displayName': credential.user?.displayName,
        },
      };
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = '找不到使用此電子郵件的用戶';
      } else if (e.code == 'wrong-password') {
        message = '密碼錯誤';
      } else if (e.code == 'user-disabled') {
        message = '此用戶帳號已被停用';
      } else if (e.code == 'invalid-email') {
        message = '無效的電子郵件格式';
      } else {
        message = e.message ?? '登入時發生錯誤';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 忘記密碼方法
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': '密碼重設電子郵件已發送'};
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = '找不到使用此電子郵件的用戶';
      } else if (e.code == 'invalid-email') {
        message = '無效的電子郵件格式';
      } else {
        message = e.message ?? '發送重設密碼郵件時發生錯誤';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
      final userCredential = await _auth.signInWithCredential(credential);
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
