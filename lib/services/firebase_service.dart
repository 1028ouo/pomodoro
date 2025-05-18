import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 確保有使用者ID，若無則進行匿名登入
  Future<String> _ensureUserId() async {
    if (_auth.currentUser == null) {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user!.uid;
    }
    return _auth.currentUser!.uid;
  }

  // 保存獲得的食譜
  Future<void> saveRecipe(int recipeId, String title, String imageUrl) async {
    final userId = await _ensureUserId();

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .doc(recipeId.toString())
        .set({
          'id': recipeId,
          'title': title,
          'imageUrl': imageUrl,
          'obtainedAt': FieldValue.serverTimestamp(),
        });
  }

  // 獲取使用者所有食譜
  Future<List<Map<String, dynamic>>> getUserRecipes() async {
    try {
      final userId = await _ensureUserId();

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('recipes')
              .orderBy('obtainedAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('獲取使用者食譜失敗: $e');
      return [];
    }
  }

  // 檢查使用者是否已獲得特定食譜
  Future<bool> hasRecipe(int recipeId) async {
    try {
      final userId = await _ensureUserId();

      final docSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('recipes')
              .doc(recipeId.toString())
              .get();

      return docSnapshot.exists;
    } catch (e) {
      print('檢查食譜失敗: $e');
      return false;
    }
  }

  // 獲取使用者所有食譜ID
  Future<List<int>> getUserRecipeIds() async {
    try {
      final recipes = await getUserRecipes();
      return recipes.map((recipe) => recipe['id'] as int).toList();
    } catch (e) {
      print('獲取食譜ID失敗: $e');
      return [];
    }
  }
}
