import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\Admin\AndroidStudioProjects\jewelry_app\lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  // Simplistic matching that handles single line Snackbars
  final singleLineRegex = RegExp(
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*\)\s*\);"
  );

  // Multi-line replacement for complex snackbars e.g in coupon_card.dart
  final complexRegex = RegExp(
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*Text\((.*?)\),.*?\}\)\s*\);|ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*Text\((.*?)\),[\s\S]*?\)\s*,\s*\);"
  );

  int totalReplaced = 0;

  for (final file in files) {
    if (file.path.contains('luxury_toast.dart')) continue;

    String source = file.readAsStringSync();
    if (!source.contains('ScaffoldMessenger')) continue;

    bool fileChanged = false;

    // First replace simple ones
    String newSource = source.replaceAllMapped(singleLineRegex, (match) {
      fileChanged = true;
      String textParam = match.group(1) ?? "''";
      return "LuxuryToast.show(context, message: $textParam);";
    });

    // Then try complex ones if any remain
    if (newSource.contains('ScaffoldMessenger.of(context).showSnackBar')) {
      newSource = newSource.replaceAllMapped(RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?Text\((.*?)\)[\s\S]*?\);\n?", multiLine: true), (match) {
        // This is a greedy approach but should work for this specific app's snackbars.
        // Needs careful check. Let's just catch all text inside Text(...) inside the showSnackBar
        fileChanged = true;
        String textParam = match.group(1) ?? "''";
        return "LuxuryToast.show(context, message: $textParam);\n";
      });
    }

    if (fileChanged) {
      if (!newSource.contains('luxury_toast.dart')) {
        // Check if there are other imports, put it under the last material/cupertino import
        if (newSource.startsWith("import")) {
          newSource = "import 'package:jewelry_app/core/utils/luxury_toast.dart';\n" + newSource;
        } else {
          newSource = "import 'package:jewelry_app/core/utils/luxury_toast.dart';\n" + newSource;
        }
      }
      file.writeAsStringSync(newSource);
      print('Updated ${file.path}');
      totalReplaced++;
    }
  }

  print('Total files updated: $totalReplaced');
}
