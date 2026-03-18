import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

class SummaryCard extends StatelessWidget {
  final SummaryEntity summary;
  final VoidCallback onTap;
  final int index;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarPalette = _buildAvatarPalette(summary);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarPalette.background,
              radius: 24,
              child: Text(
                summary.title.isNotEmpty ? summary.title.substring(0, 1) : '?',
                style: TextStyle(
                  color: avatarPalette.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.title.length > 20
                        ? '${summary.title.substring(0, 20)}...'
                        : summary.title,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.content.length > 60
                        ? '${summary.content.substring(0, 60)}...'
                        : summary.content,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : null,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (summary.updatedAt != null)
              Text(
                _formatDate(summary.updatedAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : null,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  _AvatarPalette _buildAvatarPalette(SummaryEntity summary) {
    final tokenWeights = <String, double>{};

    void addWeightedTokens(String text, double weight) {
      for (final token in _tokenizeForColor(text)) {
        tokenWeights[token] = (tokenWeights[token] ?? 0) + weight;
      }
    }

    addWeightedTokens(summary.topic ?? '', 6.0);
    addWeightedTokens(summary.title, 3.2);
    for (final tag in summary.tags) {
      addWeightedTokens(tag, 2.4);
    }

    final preview = summary.content.length > 160
        ? summary.content.substring(0, 160)
        : summary.content;
    addWeightedTokens(preview, 0.6);

    if (tokenWeights.isEmpty) {
      addWeightedTokens(summary.title, 1.0);
    }

    if (tokenWeights.isEmpty) {
      addWeightedTokens(summary.id, 1.0);
    }

    final semanticKey = _buildSemanticKey(summary, tokenWeights);
    final hue = _resolveSemanticHue(semanticKey);
    final importance = summary.importance.clamp(0.0, 1.0);
    final saturation =
        (_baseSaturation(summary.type) + importance * 0.03).clamp(0.42, 0.58);
    final lightness =
        (_baseLightness(summary.type) - importance * 0.02).clamp(0.74, 0.83);
    final foregroundSaturation = (saturation + 0.18).clamp(0.56, 0.72);
    final foregroundLightness = (lightness - 0.48).clamp(0.24, 0.31);

    return _AvatarPalette(
      background: HSLColor.fromAHSL(
        1,
        hue,
        saturation.clamp(0.0, 1.0),
        lightness.clamp(0.0, 1.0),
      ).toColor(),
      foreground: HSLColor.fromAHSL(
        1,
        hue,
        foregroundSaturation,
        foregroundLightness.clamp(0.0, 1.0),
      ).toColor(),
    );
  }

  String _buildSemanticKey(
    SummaryEntity summary,
    Map<String, double> tokenWeights,
  ) {
    final normalizedTopic = _normalizeSemanticKey(summary.topic ?? '');
    if (normalizedTopic.isNotEmpty) {
      return 'topic:$normalizedTopic';
    }

    final sortedTokens = tokenWeights.entries.toList()
      ..sort((a, b) {
        final weightCompare = b.value.compareTo(a.value);
        if (weightCompare != 0) {
          return weightCompare;
        }
        return a.key.compareTo(b.key);
      });

    if (sortedTokens.isNotEmpty) {
      return sortedTokens.take(3).map((entry) => entry.key).join('|');
    }

    final normalizedTitle = _normalizeSemanticKey(summary.title);
    if (normalizedTitle.isNotEmpty) {
      return 'title:$normalizedTitle';
    }

    return 'id:${summary.id}';
  }

  double _resolveSemanticHue(String semanticKey) {
    const semanticHueBands = <double>[
      8,
      32,
      56,
      88,
      122,
      152,
      182,
      208,
      232,
      262,
      292,
      326,
    ];

    final index = _stableHash(semanticKey) % semanticHueBands.length;
    return semanticHueBands[index];
  }

  double _baseSaturation(MemoryType type) {
    switch (type) {
      case MemoryType.session:
        return 0.44;
      case MemoryType.fact:
        return 0.48;
      case MemoryType.core:
        return 0.52;
    }
  }

  double _baseLightness(MemoryType type) {
    switch (type) {
      case MemoryType.session:
        return 0.81;
      case MemoryType.fact:
        return 0.78;
      case MemoryType.core:
        return 0.76;
    }
  }

  Iterable<String> _tokenizeForColor(String text) sync* {
    final normalized = text.toLowerCase();

    for (final match in RegExp(r'[a-z0-9_]{2,}').allMatches(normalized)) {
      final token = match.group(0);
      if (token != null && token.isNotEmpty) {
        yield token;
      }
    }

    for (final match in RegExp(r'[\u4e00-\u9fff]+').allMatches(normalized)) {
      final segment = match.group(0);
      if (segment == null || segment.isEmpty) {
        continue;
      }

      if (segment.length <= 2) {
        yield segment;
        continue;
      }

      for (var i = 0; i < segment.length - 1; i++) {
        yield segment.substring(i, i + 2);
      }
    }
  }

  int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  String _normalizeSemanticKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}

class _AvatarPalette {
  const _AvatarPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
