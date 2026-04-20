import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/domain/history_item.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';

class FeedbackHistoryRail extends StatefulWidget {
  final List<HistoryItem> history;
  final HistoryItem? viewingItem;
  final ValueChanged<HistoryItem> onSelectItem;

  const FeedbackHistoryRail({
    super.key,
    required this.history,
    required this.viewingItem,
    required this.onSelectItem,
  });

  @override
  State<FeedbackHistoryRail> createState() => _FeedbackHistoryRailState();
}

class _FeedbackHistoryRailState extends State<FeedbackHistoryRail> {
  int? _hoveredIndex;

  String _timeFromDate(String raw) {
    final parts = raw.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    return raw.length > 8 ? raw.substring(raw.length - 8) : raw;
  }

  String _previewLine(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    return normalized.isEmpty ? 'Sin resumen' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: FeedbackStyles.historyRailColorBgDecoration(context),
      child: SizedBox(
        height: FeedbackStyles.historyRailHeight,
        child: Row(
          children: [
            const SizedBox(width: 2),
            SizedBox(
              width: 4,
              height: 20,
              child: ColoredBox(
                color: MacosColors.systemGrayColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'HISTORIAL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: MacosColors.systemGrayColor.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: widget.history.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = widget.history[index];
                  final isSelected = widget.viewingItem == item;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      onTap: () => widget.onSelectItem(item),
                      child: SizedBox(
                        width: FeedbackStyles.historyItemWidth,
                        height: FeedbackStyles.historyItemHeight,
                        child: DecoratedBox(
                          decoration: FeedbackStyles.historyItemDecoration(
                            context,
                            isSelected: isSelected,
                            isHovering: _hoveredIndex == index,
                          ),
                          child: Padding(
                            padding: FeedbackStyles.historyItemPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 2,
                                      height: 10,
                                      child: ColoredBox(
                                        color: isSelected
                                            ? MacosColors.systemBlueColor
                                            : MacosColors.systemGrayColor
                                                  .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _timeFromDate(item.date),
                                        style: FeedbackStyles.monoStyle(
                                          fontSize: 10,
                                          color: MacosColors.systemGrayColor,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 1,
                                  child: ColoredBox(
                                    color: MacosTheme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Expanded(
                                  child: Text(
                                    _previewLine(item.summary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}
