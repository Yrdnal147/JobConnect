import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  
  final regex = RegExp(
    r'gradient:\s*LinearGradient\(\s*begin:\s*Alignment\.topLeft,\s*end:\s*Alignment\.bottomRight,\s*colors:\s*\[AppColorsLight\.primary,\s*Color\(0xFF4A148C\)\],\s*\),?',
    multiLine: true,
  );

  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      if (regex.hasMatch(content)) {
        content = content.replaceAll(regex, 'color: AppColorsLight.primary,');
        entity.writeAsStringSync(content);
        print('Updated ${entity.path}');
        count++;
      }
    }
  }
  print('Total files updated: \$count');
}
