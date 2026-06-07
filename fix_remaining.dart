import 'dart:io';

void main() {
  final files = [
    'lib/core/widgets/illustrations.dart',
    'lib/features/students/presentation/parent_dashboard.dart',
    'lib/features/trips/presentation/driver_dashboard.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
    file.writeAsStringSync(content);
  }
}
