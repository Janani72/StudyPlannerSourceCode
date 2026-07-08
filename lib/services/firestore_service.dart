import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USER PROFILE ============
  static Future<void> saveUserProfile(
      String uid,
      String name,
      String email,
      ) async {

    print("Firestore Name : $name");
    print("Firestore Email: $email");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("Saved to Firestore");
  }

  static Future<LocalUser?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return LocalUser(
          name: data['name'] ?? 'Student',
          email: data['email'] ?? '',
          password: '',
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<void> updateUserProfile(String uid, String name) async {
    await _db.collection('users').doc(uid).update({
      'name': name.trim(),
    });
  }

  // ============ GENERIC GET COLLECTION ============
  static Future<List<T>> getCollection<T>({
    required String uid,
    required String collectionName,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .get();

      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Get collection error for $collectionName: $e');
      return [];
    }
  }

  // ============ GENERIC SYNC COLLECTION ============
  static Future<void> syncCollection<T>({
    required String uid,
    required String collectionName,
    required List<T> items,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final batch = _db.batch();
      final collectionRef = _db
          .collection('users')
          .doc(uid)
          .collection(collectionName);

      // Get existing items
      final snapshot = await collectionRef.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final newIds = items.map((item) => getId(item)).toSet();

      // Delete items that no longer exist
      for (final id in existingIds.difference(newIds)) {
        batch.delete(collectionRef.doc(id));
      }

      // Add or update items
      for (final item in items) {
        final id = getId(item);
        final data = toJson(item);
        data['uid'] = uid;
        batch.set(collectionRef.doc(id), data, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('Sync collection error for $collectionName: $e');
      rethrow;
    }
  }

  // ============ ADD ITEM ============
  static Future<void> addItem({
    required String uid,
    required String collectionName,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['uid'] = uid;
      await _db
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(id)
          .set(data);
    } catch (e) {
      print('Add item error for $collectionName: $e');
      rethrow;
    }
  }

  // ============ UPDATE ITEM ============
  static Future<void> updateItem({
    required String uid,
    required String collectionName,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['uid'] = uid;
      await _db
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(id)
          .update(data);
    } catch (e) {
      print('Update item error for $collectionName: $e');
      rethrow;
    }
  }

  // ============ DELETE ITEM ============
  static Future<void> deleteItem({
    required String uid,
    required String collectionName,
    required String id,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(id)
          .delete();
    } catch (e) {
      print('Delete item error for $collectionName: $e');
      rethrow;
    }
  }

  // ============ UPDATE XP ============
  static Future<void> updateXP(String uid, int xp) async {
    try {
      await _db.collection('users').doc(uid).update({
        'xp': xp,
      });
    } catch (e) {
      print('Update XP error: $e');
    }
  }

  // ============ UPDATE STREAK ============
  static Future<void> updateStreak(String uid, int streak) async {
    try {
      await _db.collection('users').doc(uid).update({
        'streak': streak,
      });
    } catch (e) {
      print('Update streak error: $e');
    }
  }

  // ============ GET XP ============
  static Future<int> getXP(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['xp'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Get XP error: $e');
      return 0;
    }
  }

  // ============ GET STREAK ============
  static Future<int> getStreak(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['streak'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Get streak error: $e');
      return 0;
    }
  }

  // ============ UPDATE PROFILE PICTURE ============
  static Future<void> updateProfilePicture(String uid, String url) async {
    try {
      await _db.collection('users').doc(uid).update({
        'profilePicture': url,
      });
    } catch (e) {
      print('Update profile picture error: $e');
      rethrow;
    }
  }

  // ============ DELETE USER ============
  static Future<void> deleteUser(String uid) async {
    try {
      // Delete all user collections
      final collections = [
        'subjects', 'tasks', 'assignments', 'exams',
        'notes', 'goals', 'planner_items', 'attendance', 'daily_study'
      ];

      for (final collection in collections) {
        final snapshot = await _db
            .collection('users')
            .doc(uid)
            .collection(collection)
            .get();

        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete user document
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      print('Delete user error: $e');
      rethrow;
    }
  }
}