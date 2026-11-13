import 'package:flutter/material.dart';

import '../models/draw_element.dart';

class Toolbar extends StatelessWidget {
  final ToolType tool;
  final Color color;
  final double strokeWidth;
  final ValueChanged<ToolType> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;

  const Toolbar({
    super.key,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
  });

  static const _colors = <Color>[
    Color(0xFF111111),
    Color(0xFF2F6BFF),
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
  ];

  static const _widths = <double>[2, 3, 5, 8];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolsRow(),
            const SizedBox(height: 8),
            _optionsRow(),
          ],
        ),
      ),
    );
  }

  Widget _toolsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _toolButton(ToolType.pen, Icons.edit_outlined, 'Перо'),
        _toolButton(ToolType.line, Icons.horizontal_rule, 'Линия'),
        _toolButton(ToolType.rectangle, Icons.crop_square, 'Прямоуг.'),
        _toolButton(ToolType.circle, Icons.circle_outlined, 'Круг'),
        _toolButton(ToolType.eraser, Icons.auto_fix_normal, 'Ластик'),
      ],
    );
  }

  Widget _toolButton(ToolType t, IconData icon, String label) {
    final selected = t == tool;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onToolChanged(t),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? const Color(0xFF2F6BFF) : Colors.grey.shade700,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: selected ? const Color(0xFF2F6BFF) : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionsRow() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _colors.map(_colorDot).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _widthPicker(),
      ],
    );
  }

  Widget _colorDot(Color c) {
    final selected = c.value == color.value;
    return GestureDetector(
      onTap: () => onColorChanged(c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _widthPicker() {
    return PopupMenuButton<double>(
      initialValue: strokeWidth,
      tooltip: 'Толщина',
      onSelected: onStrokeWidthChanged,
      itemBuilder: (_) => _widths.map((w) {
        return PopupMenuItem<double>(
          value: w,
          child: Row(
            children: [
              Container(
                width: 28,
                height: w,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(w),
                ),
              ),
              const SizedBox(width: 10),
              Text('${w.toInt()} px'),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 46,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: 22,
            height: strokeWidth.clamp(1.0, 12.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(strokeWidth),
            ),
          ),
        ),
      ),
    );
  }
}