import 'package:flutter/foundation.dart';

/// Lets tabs tell each other that tasks/posts changed, so the Clock, Journal,
/// Feed and Profile tabs (kept alive in an IndexedStack) can refetch.
class DataSync extends ChangeNotifier {
  /// Who triggered the latest change, so it can skip refetching its own edit.
  Object? source;

  void bump([Object? from]) {
    source = from;
    notifyListeners();
  }
}
