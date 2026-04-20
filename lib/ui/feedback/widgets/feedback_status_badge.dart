import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';

class FeedbackStatusBadge extends StatefulWidget {
  final AppStatus status;
  final String label;
  final Color color;
  final double progress;

  const FeedbackStatusBadge({
    super.key,
    required this.status,
    required this.label,
    required this.color,
    required this.progress,
  });

  @override
  State<FeedbackStatusBadge> createState() => _FeedbackStatusBadgeState();
}

class _FeedbackStatusBadgeState extends State<FeedbackStatusBadge> {
  Timer? _completedTimer;
  bool _showCompletedCheck = false;

  @override
  void initState() {
    super.initState();
    _syncCompletedState();
  }

  @override
  void didUpdateWidget(covariant FeedbackStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncCompletedState();
    }
  }

  @override
  void dispose() {
    _completedTimer?.cancel();
    super.dispose();
  }

  void _syncCompletedState() {
    _completedTimer?.cancel();
    if (widget.status == AppStatus.completed) {
      _showCompletedCheck = true;
      _completedTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showCompletedCheck = false);
        }
      });
    } else {
      _showCompletedCheck = false;
    }
  }

  Widget _buildDot() {
    final dot = SizedBox(
      width: 6,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
    if (widget.status != AppStatus.recording) return dot;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() {});
      },
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: dot,
    );
  }

  Widget _buildLeadingIcon() {
    if (widget.status == AppStatus.error) {
      return Icon(
        CupertinoIcons.exclamationmark_triangle,
        size: 12,
        color: widget.color,
      );
    }
    if (_showCompletedCheck && widget.status == AppStatus.completed) {
      return Icon(CupertinoIcons.checkmark, size: 12, color: widget.color);
    }
    return _buildDot();
  }

  String? get _progressText {
    if (widget.status != AppStatus.transcribing &&
        widget.status != AppStatus.summarizing) {
      return null;
    }
    if (widget.progress > 0) {
      return '${(widget.progress * 100).toStringAsFixed(0)}%';
    }
    return 'Procesando...';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: FeedbackStyles.statusBadgeDecoration(widget.color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLeadingIcon(),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            if (_progressText != null) ...[
              const SizedBox(width: 8),
              Text(
                _progressText!,
                style: FeedbackStyles.monoStyle(
                  fontSize: 11,
                  color: widget.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
