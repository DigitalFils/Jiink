import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

/// Reporting a listing or a user. Write-only — see firestore.rules: this is
/// a moderation queue, not something the reporter (or the person reported)
/// can read back through the app.
class TrustSafetyRepository {
  TrustSafetyRepository({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  /// Resolved lazily rather than in the constructor so this class can be
  /// subclassed and stubbed for the design harness (lib/dev_preview.dart),
  /// which has no Firebase: constructing the repository must not be the
  /// thing that reaches for FirebaseFirestore.instance, only *using* it.
  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  Future<void> report({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) {
    final report = Report(
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      createdAt: DateTime.now(),
    );
    return _firestore.collection('reports').add(report.toCreateMap());
  }
}
