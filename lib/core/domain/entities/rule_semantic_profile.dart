enum RuleSemanticLanguage {
  cjk,
  latin,
}

class RuleSemanticProfile {
  const RuleSemanticProfile({
    required this.language,
    required this.domainKey,
    required this.domainLabel,
    required this.facetKey,
    required this.facetLabel,
    required this.displayTopic,
    required this.displayTitle,
    this.tags = const <String>[],
    this.keywords = const <String>[],
    this.confidence = 0.0,
  });

  const RuleSemanticProfile.empty({
    this.language = RuleSemanticLanguage.latin,
  })  : domainKey = '',
        domainLabel = '',
        facetKey = '',
        facetLabel = '',
        displayTopic = '',
        displayTitle = '',
        tags = const <String>[],
        keywords = const <String>[],
        confidence = 0.0;

  final RuleSemanticLanguage language;
  final String domainKey;
  final String domainLabel;
  final String facetKey;
  final String facetLabel;
  final String displayTopic;
  final String displayTitle;
  final List<String> tags;
  final List<String> keywords;
  final double confidence;

  bool get hasDomain => domainKey.isNotEmpty;

  bool get hasFacet => facetKey.isNotEmpty;

  bool get hasSpecificFacet => hasFacet && facetKey != domainKey;

  String get semanticKey {
    if (hasDomain && hasFacet) {
      return '$domainKey::$facetKey';
    }
    if (hasDomain) {
      return domainKey;
    }
    return facetKey;
  }
}
