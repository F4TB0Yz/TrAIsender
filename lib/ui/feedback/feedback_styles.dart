import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

abstract final class FeedbackStyles {
  static const double lineWidth = 0.5;
  static const double cornerRadius = 4;
  static const double compactCornerRadius = 3;
  static const double controlsHeight = 56;
  static const double historyItemWidth = 140;
  static const double historyItemHeight = 72;
  static const double historyRailHeight = 94;
  static const double loadingTopOffset = 80;
  static const double summaryPreviewMaxHeight = 220;
  static const double progressBarHeight = 3;
  static const double activeUnderlineHeight = 2;

  static const EdgeInsets shellPadding = EdgeInsets.fromLTRB(16, 40, 16, 16);
  static const EdgeInsets controlsPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 10,
  );
  static const EdgeInsets panelPadding = EdgeInsets.all(14);
  static const EdgeInsets compactPanelPadding = EdgeInsets.all(10);
  static const EdgeInsets emptyStatePadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 22,
  );
  static const EdgeInsets historyRailPadding = EdgeInsets.only(top: 10);
  static const EdgeInsets historyItemPadding = EdgeInsets.fromLTRB(
    10,
    8,
    10,
    8,
  );

  static Color grayAlpha(double alpha) =>
      MacosColors.systemGrayColor.withValues(alpha: alpha);

  static TextStyle monoStyle({
    required double fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
      fontFamily: '.SF Mono',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle denseCapsStyle({
    required Color color,
    double fontSize = 11,
    double letterSpacing = 1,
  }) {
    return TextStyle(
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static BoxDecoration panelDecoration(BuildContext context) {
    return BoxDecoration(
      color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(cornerRadius),
      border: Border.all(
        color: MacosTheme.of(context).dividerColor.withValues(alpha: 0.9),
        width: lineWidth,
      ),
    );
  }

  static BoxDecoration shellSectionDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border(
        top: BorderSide(
          color: MacosTheme.of(context).dividerColor.withValues(alpha: 0.85),
          width: lineWidth,
        ),
      ),
    );
  }

  static BoxDecoration statusBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: color.withValues(alpha: 0.35),
        width: lineWidth,
      ),
    );
  }

  static BoxDecoration summaryPreviewDecoration() {
    return BoxDecoration(
      color: MacosColors.systemBlueColor.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(compactCornerRadius),
      border: Border.all(
        color: MacosColors.systemBlueColor.withValues(alpha: 0.3),
        width: lineWidth,
      ),
    );
  }

  static BoxDecoration dropZoneDecoration(
    BuildContext context, {
    required bool isDragging,
  }) {
    return BoxDecoration(
      color: isDragging
          ? MacosColors.systemBlueColor.withValues(alpha: 0.05)
          : MacosTheme.of(context).canvasColor.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(cornerRadius),
      border: Border.all(
        color: isDragging
            ? MacosColors.systemBlueColor
            : MacosTheme.of(context).dividerColor.withValues(alpha: 0.85),
        width: isDragging ? 1 : lineWidth,
      ),
    );
  }

  static BoxDecoration historyItemDecoration(
    BuildContext context, {
    required bool isSelected,
    required bool isHovering,
  }) {
    final baseColor = MacosTheme.of(context).canvasColor;
    final hoverColor = baseColor.withValues(alpha: 0.80);
    final idleColor = baseColor.withValues(alpha: 0.45);
    final selectedColor = MacosColors.systemBlueColor.withValues(alpha: 0.13);
    return BoxDecoration(
      color: isSelected
          ? selectedColor
          : (isHovering ? hoverColor : idleColor),
      borderRadius: BorderRadius.circular(cornerRadius),
      border: Border.all(
        color: Colors.transparent,
        width: 0,
      ),
    );
  }

  static BoxDecoration historyRailColorBgDecoration(BuildContext context) {
    // Fondo sutil, sin líneas, para separar el rail del resto
    return BoxDecoration(
      color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.60),
      // Puedes ajustar alpha para más/menos contraste
      borderRadius: BorderRadius.zero,
    );
  }
}
