import 'package:flutter/material.dart';

class AnimatedExpansionTile extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final IconData icon;
  final Color lightModeColor;
  final Color darkModeColor;

  const AnimatedExpansionTile({
    super.key,
    required this.title,
    required this.children,
    required this.icon,
    required this.lightModeColor,
    required this.darkModeColor,
  });

  @override
  State<AnimatedExpansionTile> createState() => _AnimatedExpansionTileState();
}

class _AnimatedExpansionTileState extends State<AnimatedExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeIn)));
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? widget.darkModeColor : widget.lightModeColor;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(widget.icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller.view,
              builder: (BuildContext context, Widget? child) {
                return SizeTransition(
                  sizeFactor: _heightFactor,
                  child: child,
                );
              },
              child: Column(children: widget.children),
            ),
          ),
        ],
      ),
    );
  }
}
