import 'dart:io';

void main() {
  final files = [
    'lib/features/auth/presentation/login_screen.dart',
    'lib/features/auth/presentation/sign_up_screen.dart',
    'lib/features/onboarding/presentation/splash_screen.dart',
    'lib/features/students/presentation/parent_dashboard.dart',
    'lib/features/trips/presentation/driver_dashboard.dart'
  ];

  for (var path in files) {
    var file = File(path);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      content = content.replaceAll("Image.asset(", "SvgPicture.asset(");
      content = content.replaceAll("'assets/images/light_logo.jpg'", "'assets/images/logo.svg'");
      if (!content.contains("flutter_svg.dart")) {
        content = "import 'package:flutter_svg/flutter_svg.dart';\n$content";
      }
      file.writeAsStringSync(content);
    }
  }
}
