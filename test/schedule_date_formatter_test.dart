import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/utils/schedule_date_formatter.dart';

void main() {
  test('formats scheduled dates with localized user-friendly labels', () {
    final formatted = ScheduleDateFormatter.format(DateTime(2026, 7, 30, 0, 2));

    expect(formatted.dateLabel, 'Jueves 30 de julio');
    expect(formatted.timeLabel, '12:02 a. m.');
  });

  test('converts legacy technical schedule labels', () {
    final formatted = ScheduleDateFormatter.fromStoredLabel(
      '30/7/2026 a las 0:02',
    );

    expect(formatted.dateLabel, 'Jueves 30 de julio');
    expect(formatted.timeLabel, '12:02 a. m.');
  });
}
