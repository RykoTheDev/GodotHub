import 'package:flutter/foundation.dart';

bool get isMac => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;

bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;

const defaultCornerRadius = 7;
