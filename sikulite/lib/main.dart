import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikulite/core/api_client.dart';
import 'package:sikulite/core/utils/isolate_processor_service.dart';
import 'package:sikulite/features/assets/services/asset_storage_service.dart';
import 'package:sikulite/features/assets/view_models/asset_view_model.dart';
import 'package:sikulite/features/tasks/task_provider.dart';
import 'package:sikulite/features/workflow/workflow_screen.dart';
import 'package:sikulite/features/workflow/services/workflow_engine.dart';
import 'package:sikulite/features/workflow/services/workflow_persistence.dart';
import 'package:sikulite/features/workflow/services/session_persistence_service.dart';
import 'package:sikulite/features/workflow/view_models/workspace_view_model.dart';
import 'package:sikulite/features/workflow/view_models/sidebar_view_model.dart';

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
      child: const SikuliteApp(),
    ),
  );
}

class SikuliteApp extends StatefulWidget {
  const SikuliteApp({super.key});

  @override
  State<SikuliteApp> createState() => _SikuliteAppState();
}

class _SikuliteAppState extends State<SikuliteApp> with WidgetsBindingObserver {
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
      title: 'Sikulite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WorkflowScreen(),
    );
  }
}
