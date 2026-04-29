import 'package:flutter/material.dart';

class QuickCapture extends StatefulWidget {
  final Function(String) onCapture;

  const QuickCapture({super.key, required this.onCapture});

  @override
  State<QuickCapture> createState() => _QuickCaptureState();
}

class _QuickCaptureState extends State<QuickCapture> {
  final _controller = TextEditingController();
  bool _expanded = false;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onCapture(text);
    _controller.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_expanded ? 16 : 28),
        border: Border.all(
          color: _expanded
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).dividerColor,
          width: _expanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _expanded ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              AnimatedRotation(
                turns: _expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.add_circle_outline,
                  color: _expanded
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _expanded ? "What's on your mind?" : "Quick capture...",
                    hintStyle: TextStyle(
                      fontSize: _expanded ? 16 : 14,
                      color: Theme.of(context).hintColor,
                    ),
                    border: InputBorder.none,
                    isDense: !_expanded,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: _expanded ? 16 : 14,
                    height: 1.5,
                  ),
                  maxLines: _expanded ? 5 : 1,
                  minLines: 1,
                  onTap: _expanded ? null : _toggleExpand,
                  onSubmitted: (_) => _expanded ? _submit() : _toggleExpand(),
                ),
              ),
              if (!_expanded)
                IconButton(
                  icon: const Icon(Icons.expand_more, size: 20),
                  onPressed: _toggleExpand,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    _toggleExpand();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).hintColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Capture'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (!_expanded) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
