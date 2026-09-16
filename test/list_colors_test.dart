import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/theme/app_theme.dart';
import 'package:pham_dash_flutter/core/ui/color_picker_sheet.dart';

void main() {
  group('the palette', () {
    // The whole point of the change: these were Tailwind 100-level pastels
    // (#fee2e2 and friends), which read as washed out against a 4px stripe.
    test('red is red', () {
      expect(
        kListColors.firstWhere((option) => option.name == 'Red').value,
        '#ff0000',
      );
    });

    test('every swatch but None parses', () {
      for (final option in kListColors.skip(1)) {
        expect(
          parseHexColor(option.value),
          isNotNull,
          reason: '${option.name} (${option.value}) did not parse',
        );
      }
    });

    test('None is first and carries no colour', () {
      expect(kListColors.first.name, 'None');
      expect(kListColors.first.value, isNull);
    });

    // Saturated swatches are the reason onColor exists; a palette that drifted
    // back toward pastels would make every foreground below identical.
    test('the swatches are saturated, not pastel', () {
      for (final option in kListColors.skip(1)) {
        final hsv = HSVColor.fromColor(parseHexColor(option.value)!);
        expect(
          hsv.saturation,
          greaterThan(0.5),
          reason: '${option.name} is washed out',
        );
      }
    });
  });

  group('onColor', () {
    test('white on the dark end of the palette', () {
      for (final hex in ['#ff0000', '#0000ff', '#800080', '#008000']) {
        expect(onColor(parseHexColor(hex)!), Colors.white, reason: hex);
      }
    });

    test('black on the light end', () {
      for (final hex in ['#ffd700', '#ffffff', '#fef9c3']) {
        expect(onColor(parseHexColor(hex)!), Colors.black87, reason: hex);
      }
    });
  });

  group('chipLabelStyleOn', () {
    test('defers to the theme when there is no colour', () {
      expect(chipLabelStyleOn(null, selected: false), isNull);
    });

    // A selected chip is painted with selectedColor, not backgroundColor, so
    // forcing a foreground for the colour it is *not* using would read wrong.
    test('defers to the theme while selected', () {
      expect(chipLabelStyleOn(Colors.red, selected: true), isNull);
    });

    test('pairs an unselected chip with its own colour', () {
      expect(
        chipLabelStyleOn(parseHexColor('#ff0000'), selected: false)?.color,
        Colors.white,
      );
    });
  });

  group('hexOf', () {
    test('round-trips through parseHexColor', () {
      for (final option in kListColors.skip(1)) {
        expect(hexOf(parseHexColor(option.value)!), option.value);
      }
    });

    test('is lowercase #rrggbb with no alpha', () {
      expect(hexOf(const Color(0xFF00FF7F)), '#00ff7f');
      // Alpha is dropped: the API stores six hex digits and validates category
      // colours against exactly that.
      expect(hexOf(const Color(0x8012AB34)), '#12ab34');
    });

    test('pads single-digit channels', () {
      expect(hexOf(const Color(0xFF010203)), '#010203');
    });
  });
}
