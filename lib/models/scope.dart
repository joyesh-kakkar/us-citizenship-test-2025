/// Which pool of questions Quiz and Test draw from.
///
/// Study always browses all 128 questions regardless of the scope.
enum StudyScope {
  /// All 128 questions — the standard naturalization test.
  all('all'),

  /// The 20 starred questions — the "65/20" accommodation for applicants aged
  /// 65+ who have been lawful permanent residents for 20+ years.
  starred('starred');

  const StudyScope(this.wireName);

  /// Stable string used for persistence; never shown to the user.
  final String wireName;

  static StudyScope fromWire(String? value) => StudyScope.values.firstWhere(
        (StudyScope s) => s.wireName == value,
        orElse: () => StudyScope.all,
      );
}
