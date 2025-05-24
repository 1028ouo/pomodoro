import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

      // 在Firestore中創建用戶資料，包含生日
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'birthday': birthday, // 儲存生日
        'joinedAt': DateTime.now().toIso8601String(),
        'totalFocusTime': 0,
        'streakDays': 0,
        'weeklyFocusTime': 0,
        'completedPomodoros': 0,
        'photoURL': '',
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
          await docRef.set({
            'username': user.displayName ?? '使用者',
            'email': user.email ?? '',
            'birthday': '', // 為Google用戶設置空生日，需要用戶稍後填寫
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'photoURL': user.photoURL ?? '',
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

  // 更新用戶頭像方法
  Future<Map<String, dynamic>> updateUserPhoto(String photoURL) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': '用戶未登入'};
      }

      // 更新 Firebase Auth 用戶資料
      await currentUser.updatePhotoURL(photoURL);

      // 更新 Firestore 中的頭像資料
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoURL': photoURL,
      });

      return {'success': true, 'message': '頭像更新成功'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
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
}
