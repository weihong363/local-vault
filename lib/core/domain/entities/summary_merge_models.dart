import 'package:local_vault/core/domain/entities/summary_entity.dart';

enum SummaryMergeFieldChoice {
  existing,
  incoming,
  combined,
}

class SummaryMergeResolution {
  const SummaryMergeResolution({
    this.title = SummaryMergeFieldChoice.existing,
    this.content = SummaryMergeFieldChoice.combined,
    this.tags = SummaryMergeFieldChoice.combined,
  });

  final SummaryMergeFieldChoice title;
  final SummaryMergeFieldChoice content;
  final SummaryMergeFieldChoice tags;
}

class SummaryMergeCandidate {
  const SummaryMergeCandidate({
    required this.summary,
    required this.similarity,
  });

  final SummaryEntity summary;
  final double similarity;
}

class FactSummarySaveResult {
  const FactSummarySaveResult({
    required this.savedSummary,
    this.wasExactDuplicate = false,
    this.mergeCandidates = const <SummaryMergeCandidate>[],
  });

  final SummaryEntity savedSummary;
  final bool wasExactDuplicate;
  final List<SummaryMergeCandidate> mergeCandidates;

  bool get hasMergeSuggestions => mergeCandidates.isNotEmpty;
}
