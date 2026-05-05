import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/core/utils/isolate_processor_service.dart';
import 'package:ui/features/assets/services/asset_storage_service.dart';
import 'package:ui/features/assets/view_models/asset_view_model.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/workflow/workflow_screen.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/view_models/sidebar_view_model.dart';

void main() {
  final apiClient = ApiClient();
  final isolateProcessor = IsolateProcessorService();
  final assetStorage = AssetStorageService(isolateProcessor: isolateProcessor);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: isolateProcessor),
        ChangeNotifierProvider(create: (_) => TaskProvider()..fetchStatus()),
        ChangeNotifierProvider(create: (_) => AssetViewModel(storageService: assetStorage)),
        ChangeNotifierProvider(create: (_) => SidebarViewModel()),
        ChangeNotifierProvider(create: (_) => WorkflowEngine(apiClient: apiClient)),
        Provider(create: (_) => WorkflowPersistence()),
        ChangeNotifierProvider(
          create: (context) => WorkflowViewModel(
            apiClient: apiClient,
            engine: context.read<WorkflowEngine>(),
            persistence: context.read<WorkflowPersistence>(),
            assetStorage: assetStorage,
          )..loadDraft(), // FR-015
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sikulite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WorkflowScreen(),
    );
  }
}
