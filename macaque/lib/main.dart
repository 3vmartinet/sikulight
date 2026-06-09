import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:macaque/core/api_client.dart';
import 'package:macaque/core/utils/isolate_processor_service.dart';
import 'package:macaque/features/assets/services/asset_storage_service.dart';
import 'package:macaque/features/assets/view_models/asset_view_model.dart';
import 'package:macaque/features/tasks/task_provider.dart';
import 'package:macaque/features/workflow/workflow_screen.dart';
import 'package:macaque/features/workflow/services/workflow_engine.dart';
import 'package:macaque/features/workflow/services/workflow_persistence.dart';
import 'package:macaque/features/workflow/services/session_persistence_service.dart';
import 'package:macaque/features/workflow/view_models/workspace_view_model.dart';
import 'package:macaque/features/workflow/view_models/sidebar_view_model.dart';

void main() {
  final apiClient = ApiClient();
  final isolateProcessor = IsolateProcessorService();
  final assetStorage = AssetStorageService(isolateProcessor: isolateProcessor);
  final sessionService = SessionPersistenceService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: isolateProcessor),
        ChangeNotifierProvider(create: (_) => TaskProvider()..fetchStatus()),
        ChangeNotifierProvider(
          create: (_) => AssetViewModel(storageService: assetStorage),
        ),
        ChangeNotifierProvider(create: (_) => SidebarViewModel()),
        ChangeNotifierProvider(
          create: (_) => WorkflowEngine(apiClient: apiClient),
        ),
        Provider(create: (_) => WorkflowPersistence()),
        Provider.value(value: sessionService),
        ChangeNotifierProvider(
          create: (context) => WorkspaceViewModel(
            sessionService: sessionService,
            engine: context.read<WorkflowEngine>(),
            persistence: context.read<WorkflowPersistence>(),
            apiClient: apiClient,
            assetStorage: assetStorage,
          )..restoreSession(),
        ),
      ],
      child: const MacaqueApp(),
    ),
  );
}

class MacaqueApp extends StatefulWidget {
  const MacaqueApp({super.key});

  @override
  State<MacaqueApp> createState() => _MacaqueAppState();
}

class _MacaqueAppState extends State<MacaqueApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      context.read<WorkspaceViewModel>().saveSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macaque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WorkflowScreen(),
    );
  }
}
