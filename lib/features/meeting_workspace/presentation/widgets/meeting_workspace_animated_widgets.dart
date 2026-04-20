import 'package:flutter/material.dart';

import 'meeting_workspace_tokens.dart';

class MeetingWorkspaceSpinIcon extends StatefulWidget {
  const MeetingWorkspaceSpinIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<MeetingWorkspaceSpinIcon> createState() => _MeetingWorkspaceSpinIconState();
}

class _MeetingWorkspaceSpinIconState extends State<MeetingWorkspaceSpinIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MeetingWorkspaceTokens.spinSlow,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}

class MeetingWorkspacePulseDot extends StatefulWidget {
  const MeetingWorkspacePulseDot({super.key, required this.color});

  final Color color;

  @override
  State<MeetingWorkspacePulseDot> createState() => _MeetingWorkspacePulseDotState();
}

class _MeetingWorkspacePulseDotState extends State<MeetingWorkspacePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MeetingWorkspaceTokens.pulse,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.45, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class MeetingWorkspaceBlinkingCaret extends StatefulWidget {
  const MeetingWorkspaceBlinkingCaret({super.key});

  @override
  State<MeetingWorkspaceBlinkingCaret> createState() =>
      _MeetingWorkspaceBlinkingCaretState();
}

class _MeetingWorkspaceBlinkingCaretState
    extends State<MeetingWorkspaceBlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MeetingWorkspaceTokens.caretBlink,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        width: 3,
        height: 20,
        color: MeetingWorkspaceTokens.primaryBlue,
      ),
    );
  }
}
