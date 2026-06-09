import 'package:flutter/material.dart';

class SidebarViewModel extends ChangeNotifier {
  bool _isCommandRegistryExpanded = true;
  bool _isAssetRegistryExpanded = true;

  bool get isCommandRegistryExpanded => _isCommandRegistryExpanded;
  bool get isAssetRegistryExpanded => _isAssetRegistryExpanded;

  void toggleCommandRegistry() {
    _isCommandRegistryExpanded = !_isCommandRegistryExpanded;
    notifyListeners();
  }

  void toggleAssetRegistry() {
    _isAssetRegistryExpanded = !_isAssetRegistryExpanded;
    notifyListeners();
  }

  void expandCommandRegistry() {
    _isCommandRegistryExpanded = true;
    notifyListeners();
  }

  void expandAssetRegistry() {
    _isAssetRegistryExpanded = true;
    notifyListeners();
  }
}
