class ScheduleDatePresentation {
  const ScheduleDatePresentation({
    required this.dateLabel,
    required this.timeLabel,
  });

  final String dateLabel;
  final String timeLabel;
}

abstract final class ScheduleDateFormatter {
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static ScheduleDatePresentation format(DateTime dateTime) {
    final period = dateTime.hour < 12 ? 'a. m.' : 'p. m.';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return ScheduleDatePresentation(
      dateLabel:
          '${_weekdays[dateTime.weekday - 1]} ${dateTime.day} '
          'de ${_months[dateTime.month - 1]}',
      timeLabel: '$hour:$minute $period',
    );
  }

  static ScheduleDatePresentation fromStoredLabel(String label) {
    final technical = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4}) a las '
      r'(\d{1,2}):(\d{2})(?:\s*(a\.?\s*m\.?|p\.?\s*m\.?|AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(label.trim());
    if (technical == null) {
      final lines = label.split('\n');
      return ScheduleDatePresentation(
        dateLabel: lines.first,
        timeLabel: lines.length > 1 ? lines.sublist(1).join(' ') : '',
      );
    }

    var hour = int.parse(technical.group(4)!);
    final period = technical.group(6)?.toLowerCase().replaceAll(' ', '');
    if ((period == 'p.m.' || period == 'pm') && hour < 12) {
      hour += 12;
    } else if ((period == 'a.m.' || period == 'am') && hour == 12) {
      hour = 0;
    }
    return format(
      DateTime(
        int.parse(technical.group(3)!),
        int.parse(technical.group(2)!),
        int.parse(technical.group(1)!),
        hour,
        int.parse(technical.group(5)!),
      ),
    );
  }
}
