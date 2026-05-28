class OddballDistributionBin {
  const OddballDistributionBin({
    required this.start,
    required this.end,
    required this.count,
  });

  final int start;
  final int end;
  final int count;

  String get label => end == 100 ? '$start+' : '$start-$end';
}

class OddballScoreDistribution {
  const OddballScoreDistribution({
    required this.score,
    required this.totalUsers,
    required this.percentile,
    required this.bins,
  });

  final int score;
  final int totalUsers;
  final int percentile;
  final List<OddballDistributionBin> bins;

  int get highlightedBinIndex {
    if (bins.isEmpty) return 0;
    final index = bins.indexWhere((bin) => score >= bin.start && score <= bin.end);
    return index < 0 ? bins.length - 1 : index;
  }
}
