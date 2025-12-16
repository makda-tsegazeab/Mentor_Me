// lib/models/recommendations.dart

/// Content-based recommendation: learner -> tutor
class ContentTutorRec {
  final String tutorId;
  final double score;
  final String? name;
  final String? city;
  final List<String> subjects;
  final List<String> gradeLevels;
  final num? minPricePerHour;
  final List<String> reasons;

  ContentTutorRec({
    required this.tutorId,
    required this.score,
    this.name,
    this.city,
    this.subjects = const [],
    this.gradeLevels = const [],
    this.minPricePerHour,
    this.reasons = const [],
  });

  factory ContentTutorRec.fromMap(Map<String, dynamic> map) {
    return ContentTutorRec(
      tutorId: map['tutorId'] as String,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      name: map['name'] as String?,
      city: map['city'] as String?,
      subjects: (map['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      gradeLevels: (map['gradeLevels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      minPricePerHour: map['minPricePerHour'] as num?,
      reasons: (map['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// MF-based recommendation: learner -> tutor
class MFTutorRec {
  final String tutorId;
  final double score;

  MFTutorRec({
    required this.tutorId,
    required this.score,
  });

  factory MFTutorRec.fromMap(Map<String, dynamic> map) {
    return MFTutorRec(
      tutorId: map['tutorId'] as String,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Final merged recommendation that the learner actually sees.
class HybridTutorRec {
  final String tutorId;
  final double? contentScore;
  final double? mfScore;
  final String? name;
  final String? city;
  final List<String> subjects;
  final List<String> gradeLevels;
  final num? minPricePerHour;
  final List<String> reasons;

  HybridTutorRec({
    required this.tutorId,
    this.contentScore,
    this.mfScore,
    this.name,
    this.city,
    this.subjects = const [],
    this.gradeLevels = const [],
    this.minPricePerHour,
    this.reasons = const [],
  });

  /// Simple linear hybrid:
  /// - both present  -> wMf * mf + wContent * content
  /// - only MF       -> mf
  /// - only content  -> content
  double get finalScore {
    const double wMf = 0.7;
    const double wContent = 0.3;

    if (mfScore != null && contentScore != null) {
      return wMf * mfScore! + wContent * contentScore!;
    } else if (mfScore != null) {
      return mfScore!;
    } else if (contentScore != null) {
      return contentScore!;
    } else {
      return 0.0;
    }
  }

  HybridTutorRec copyWith({
    double? contentScore,
    double? mfScore,
    String? name,
    String? city,
    List<String>? subjects,
    List<String>? gradeLevels,
    num? minPricePerHour,
    List<String>? reasons,
  }) {
    return HybridTutorRec(
      tutorId: tutorId,
      contentScore: contentScore ?? this.contentScore,
      mfScore: mfScore ?? this.mfScore,
      name: name ?? this.name,
      city: city ?? this.city,
      subjects: subjects ?? this.subjects,
      gradeLevels: gradeLevels ?? this.gradeLevels,
      minPricePerHour: minPricePerHour ?? this.minPricePerHour,
      reasons: reasons ?? this.reasons,
    );
  }
}

/// Content-based recommendation: tutor -> learner
class TutorSideLearnerRec {
  final String learnerId;
  final double score;
  final String? name;
  final String? city;
  final List<String> subjects;
  final List<String> gradeLevels;
  final num? maxPricePerHour;
  final List<String> reasons;

  TutorSideLearnerRec({
    required this.learnerId,
    required this.score,
    this.name,
    this.city,
    this.subjects = const [],
    this.gradeLevels = const [],
    this.maxPricePerHour,
    this.reasons = const [],
  });

  factory TutorSideLearnerRec.fromMap(Map<String, dynamic> map) {
    return TutorSideLearnerRec(
      learnerId: map['learnerId'] as String,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      name: map['name'] as String?,
      city: map['city'] as String?,
      subjects: (map['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      gradeLevels: (map['gradeLevels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      maxPricePerHour: map['maxPricePerHour'] as num?,
      reasons: (map['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
