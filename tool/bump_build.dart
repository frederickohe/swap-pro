// Manages Swappro build numbers for Google Play (versionCode) / App Store (CFBundleVersion).
//
// Usage:
//   dart run tool/bump_build.dart              # show current version
//   dart run tool/bump_build.dart bump         # increment build number (+N)
//   dart run tool/bump_build.dart set 42       # set build number to 42
//   dart run tool/bump_build.dart name 1.0.1   # set user-facing version name

import 'dart:io';

final _versionLine = RegExp(r'^version:\s*([\d.]+)\+(\d+)\s*$', multiLine: true);

void main(List<String> args) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found. Run from the project root.');
    exit(1);
  }

  final content = pubspec.readAsStringSync();
  final match = _versionLine.firstMatch(content);
  if (match == null) {
    stderr.writeln(
      'Could not parse version from pubspec.yaml (expected format: version: 1.0.0+1)',
    );
    exit(1);
  }

  var versionName = match.group(1)!;
  var buildNumber = int.parse(match.group(2)!);

  if (args.isEmpty || args.first == 'show') {
    _printVersion(versionName, buildNumber);
    return;
  }

  final command = args.first;
  switch (command) {
    case 'bump':
      buildNumber += 1;
    case 'set':
      if (args.length < 2) {
        stderr.writeln('Usage: dart run tool/bump_build.dart set <build-number>');
        exit(1);
      }
      buildNumber = int.parse(args[1]);
    case 'name':
      if (args.length < 2) {
        stderr.writeln('Usage: dart run tool/bump_build.dart name <version-name>');
        exit(1);
      }
      versionName = args[1];
    default:
      stderr.writeln('Unknown command: $command');
      stderr.writeln('Commands: show, bump, set <N>, name <X.Y.Z>');
      exit(1);
  }

  if (command == 'bump' || command == 'set' || command == 'name') {
    final updated = content.replaceFirst(
      _versionLine,
      'version: $versionName+$buildNumber',
    );
    pubspec.writeAsStringSync(updated);
    stdout.writeln('Updated pubspec.yaml');
    _printVersion(versionName, buildNumber);
  }
}

void _printVersion(String versionName, int buildNumber) {
  stdout.writeln('Version: $versionName+$buildNumber');
  stdout.writeln('  versionName (user-facing): $versionName');
  stdout.writeln('  versionCode / build number: $buildNumber');
}
