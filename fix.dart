import 'dart:io';

void main() {
  final file = File('lib/features/trips/presentation/trip_detail_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('desiredAccuracy: LocationAccuracy.high', 'locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)');
  content = content.replaceAll('error: (_, __) =>', 'error: (e, st) =>');
  content = content.replaceAll('child: _approachingStudentId != null && session != null', 'child: _approachingStudentId != null');
  content = content.replaceAll('final attendanceMap = session != null\\n                                                ? ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {}\\n                                                : const <String, String>{};', 'final attendanceMap = ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {};');
  content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
  
  file.writeAsStringSync(content);
  print('done');
}
