class DiagnosisShareCardData {
  const DiagnosisShareCardData({
    required this.slug,
    required this.assetPath,
    required this.displayName,
    required this.tagline,
    required this.shareUrl,
    this.oddballScore,
  });

  final String slug;
  final String assetPath;
  final String displayName;
  final String tagline;
  final String shareUrl;
  final int? oddballScore;
}
