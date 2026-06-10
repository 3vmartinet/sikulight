class AppConstants {
  static const String assetMetadataFileName = '.assets.json';
  static const String thumbnailDirName = '.thumbnails';
  static const double collapsedSidebarWidth = 50.0;
  static const double expandedSidebarWidth = 300.0;
  static const double thumbnailSize = 128.0;
  static const Duration uiTransitionDuration = Duration(milliseconds: 200);
  static const Duration watcherDebounceDuration = Duration(milliseconds: 500);
  
  // Supported image formats
  static const List<String> supportedImageExtensions = ['png', 'jpg', 'jpeg'];

  // Workflow file extensions
  static const String workflowExtension = '.macaque';
  static const String workflowExtensionName = 'macaque';
}
