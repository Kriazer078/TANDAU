class FinTechResult {
  final double score;
  final String paybackLabel;
  final int netProfit;
  final double roi;
  final int monthlyFreeCash;
  final List<double> yearlyBalance;

  FinTechResult({
    required this.score,
    required this.paybackLabel,
    required this.netProfit,
    required this.roi,
    required this.monthlyFreeCash,
    required this.yearlyBalance,
  });
}
