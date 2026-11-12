import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';

final projectResolutionEpochProvider = NotifierProvider<ProjectResolutionEpochNotifier, int>(ProjectResolutionEpochNotifier.new);

class ProjectResolutionEpochNotifier extends Notifier<int> {
  @override
  int build() {
    final unsubscribe = subscribeResolutionEpoch(() => state = getResolutionEpoch());
    ref.onDispose(unsubscribe);
    return getResolutionEpoch();
  }
}
