import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  CollectionReference<Map<String, dynamic>> _remindersRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders');

  Future<List<Reminder>> fetchReminders(String uid) async {
    final snap = await _remindersRef(uid).get();
    return snap.docs.map((d) => Reminder.fromJson(d.data())).toList();
  }

  Future<void> upsertReminder(String uid, Reminder reminder) {
    return _remindersRef(uid)
        .doc(reminder.id)
        .set({...reminder.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteReminder(String uid, String reminderId) {
    return _remindersRef(uid).doc(reminderId).delete();
  }

  /// Upload a batch of reminders (used on first sign-in to push local data).
  Future<void> upsertAll(String uid, List<Reminder> reminders) async {
    if (reminders.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final r in reminders) {
      batch.set(
        _remindersRef(uid).doc(r.id),
        {...r.toJson(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: false),
      );
    }
    await batch.commit();
  }
}
