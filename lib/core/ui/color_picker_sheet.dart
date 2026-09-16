import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Picks an arbitrary colour, returning it as `#rrggbb`, or null if cancelled.
///
/// Hand-rolled rather than pulled from a package: what is needed here is three
/// sliders and a hex field, and a picker package would bring its own theming to
/// argue with. HSV rather than RGB sliders because "a bit more orange" is a hue
/// nudge and an unholy mess in RGB.
Future<String?> showColorPicker(
  BuildContext context, {
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ColorPickerDialog(initial: parseHexColor(initial)),
  );
}

/// `#rrggbb`, lowercase, no alpha.
///
/// Alpha is dropped on purpose: it is never round-tripped — the API stores a
/// plain hex string, and the category endpoint validates `^#[0-9A-Fa-f]{6}$`.
String hexOf(Color color) {
  String channel(double c) =>
      (c * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.initial});

  final Color? initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial ?? Colors.red);
  late final _hex = TextEditingController(text: hexOf(_color).substring(1));

  Color get _color => _hsv.toColor();

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  /// Keeps the hex field in step when a slider moves.
  ///
  /// Not the other way round — [_applyHex] deliberately does not rewrite the
  /// field, or typing a partial value would fight the cursor.
  void _setHsv(HSVColor value) {
    setState(() => _hsv = value);
    final text = hexOf(_color).substring(1);
    if (_hex.text.toLowerCase() != text) _hex.text = text;
  }

  void _applyHex(String raw) {
    final parsed = parseHexColor(raw);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Custom colour'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                hexOf(_color),
                style: TextStyle(
                  // The preview doubles as the legibility check: whatever the
                  // user picks, this is the pairing their labels will get.
                  color: onColor(_color),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _GradientSlider(
              label: 'Hue',
              value: _hsv.hue,
              max: 360,
              colors: [
                for (var degree = 0; degree <= 360; degree += 60)
                  HSVColor.fromAHSV(1, degree.toDouble(), 1, 1).toColor(),
              ],
              onChanged: (value) => _setHsv(_hsv.withHue(value)),
            ),
            _GradientSlider(
              label: 'Saturation',
              value: _hsv.saturation,
              max: 1,
              colors: [
                HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
              ],
              onChanged: (value) => _setHsv(_hsv.withSaturation(value)),
            ),
            _GradientSlider(
              label: 'Brightness',
              value: _hsv.value,
              max: 1,
              colors: [
                Colors.black,
                HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
              ],
              onChanged: (value) => _setHsv(_hsv.withValue(value)),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Hex',
                prefixText: '#',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              ],
              onChanged: _applyHex,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(hexOf(_color)),
          child: const Text('Use colour'),
        ),
      ],
    );
  }
}

/// A slider over a gradient of the values it selects, so the track shows what
/// each end does rather than making the user scrub to find out.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                // Clears the thumb's radius, so the gradient lines up with the
                // travel of the slider rather than running past it.
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  // Material 3 draws a gap and a stop indicator around the
                  // thumb, both of which punch holes in the gradient below.
                  trackGap: 0,
                  thumbSize: const WidgetStatePropertyAll(Size(6, 26)),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: value.clamp(0, max),
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
