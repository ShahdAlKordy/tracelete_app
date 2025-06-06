import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';

class BraceletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _realtimeDb = FirebaseDatabase.instance.ref();

  // إضافة بريسليت جديد
  Future<bool> addBracelet({
    required String braceletId,
    required String ownerNumber,
    String? customName,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // التحقق من وجود البريسليت في Realtime Database
      final snapshot = await _realtimeDb.child("bracelets/$braceletId").get();
      if (!snapshot.exists) {
        throw Exception('البريسليت غير موجود');
      }

      // التحقق من أن البريسليت غير مربوط بمستخدم آخر
      final braceletData = snapshot.value as Map<dynamic, dynamic>?;
      if (braceletData != null && 
          braceletData['user_info'] != null && 
          braceletData['user_info']['connected'] == true &&
          braceletData['user_info']['user_id'] != currentUser.uid) {
        throw Exception('البريسليت مربوط بمستخدم آخر');
      }

      // ربط البريسليت في Realtime Database
      await _realtimeDb.child("bracelets/$braceletId/user_info").set({
        "connected": true,
        "owner_number": ownerNumber,
        "user_id": currentUser.uid,
        "connected_at": ServerValue.timestamp,
      });

      // حفظ البريسليت في Firestore
      await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .set({
        "bracelet_id": braceletId,
        "name": customName ?? 'Bracelet $braceletId',
        "owner_number": ownerNumber,
        "connected_at": FieldValue.serverTimestamp(),
        "is_active": true,
      });

      return true;
    } catch (e) {
      print("Error adding bracelet: $e");
      return false;
    }
  }

  // جلب جميع البريسليتات الخاصة بالمستخدم
  Future<List<BraceletModel>> getUserBracelets() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .where("is_active", isEqualTo: true)
          .orderBy("connected_at", descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BraceletModel(
          id: data['bracelet_id'] ?? doc.id,
          name: data['name'] ?? 'Bracelet ${doc.id}',
        );
      }).toList();
    } catch (e) {
      print("Error getting user bracelets: $e");
      return [];
    }
  }

  // تحديث اسم البريسليت
  Future<bool> updateBraceletName(String braceletId, String newName) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .update({
        "name": newName,
        "updated_at": FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error updating bracelet name: $e");
      return false;
    }
  }

  // إلغاء ربط البريسليت
  Future<bool> disconnectBracelet(String braceletId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // إلغاء الربط من Realtime Database
      await _realtimeDb.child("bracelets/$braceletId/user_info").update({
        "connected": false,
        "disconnected_at": ServerValue.timestamp,
      });

      // تعليم البريسليت كغير نشط في Firestore
      await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .update({
        "is_active": false,
        "disconnected_at": FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error disconnecting bracelet: $e");
      return false;
    }
  }

  // التحقق من ملكية البريسليت للمستخدم الحالي
  Future<bool> isUserBracelet(String braceletId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final DocumentSnapshot doc = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      return data?['is_active'] == true;
    } catch (e) {
      print("Error checking bracelet ownership: $e");
      return false;
    }
  }

  // الحصول على تفاصيل بريسليت محدد
  Future<BraceletModel?> getBraceletDetails(String braceletId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      if (data['is_active'] != true) return null;

      return BraceletModel(
        id: data['bracelet_id'] ?? doc.id,
        name: data['name'] ?? 'Bracelet ${doc.id}',
      );
    } catch (e) {
      print("Error getting bracelet details: $e");
      return null;
    }
  }

  // الاستماع لتغييرات البريسليتات في الوقت الفعلي
  Stream<List<BraceletModel>> watchUserBracelets() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection("users")
        .doc(currentUser.uid)
        .collection("bracelets")
        .where("is_active", isEqualTo: true)
        .orderBy("connected_at", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BraceletModel(
          id: data['bracelet_id'] ?? doc.id,
          name: data['name'] ?? 'Bracelet ${doc.id}',
        );
      }).toList();
    });
  }
}