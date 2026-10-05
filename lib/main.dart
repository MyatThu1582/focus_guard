import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FocusGuardApp());
}

class FocusGuardApp extends StatelessWidget {
  const FocusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Guard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const FocusGuardHomePage(),
    );
  }
}

class FocusGuardHomePage extends StatefulWidget {
  const FocusGuardHomePage({super.key});

  @override
  State<FocusGuardHomePage> createState() =>
      _FocusGuardHomePageState();
}

class _FocusGuardHomePageState
    extends State<FocusGuardHomePage>
    with WidgetsBindingObserver {

  static const MethodChannel _channel =
      MethodChannel('focus_guard/apps');

  bool accessibilityEnabled = false;
  bool protectionEnabled = true;

  bool scheduleEnabled = false;

  int startHour = 22;
  int startMinute = 0;

  int endHour = 7;
  int endMinute = 0;

  int blockedAppsCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {

    if (state == AppLifecycleState.resumed) {
      loadDashboard();
    }
  }

  // =========================================================
  // Load dashboard data
  // =========================================================

  Future<void> loadDashboard() async {

    try {

      final accessibility =
          await _channel.invokeMethod(
        'isAccessibilityEnabled',
      );

      final protection =
          await _channel.invokeMethod(
        'getProtectionEnabled',
      );

      final blockedApps =
          await _channel.invokeMethod(
        'getBlockedApps',
      );

      final schedule =
          await _channel.invokeMethod(
        'getSchedule',
      );

      setState(() {

        accessibilityEnabled =
            accessibility == true;

        protectionEnabled =
            protection == true;

        blockedAppsCount =
            (blockedApps as List?)?.length ?? 0;

        if (schedule is Map) {

          scheduleEnabled =
              schedule['enabled'] == true;

          startHour =
              schedule['startHour'] ?? 22;

          startMinute =
              schedule['startMinute'] ?? 0;

          endHour =
              schedule['endHour'] ?? 7;

          endMinute =
              schedule['endMinute'] ?? 0;
        }
      });

    } catch (e) {

      debugPrint(
        'Dashboard error: $e',
      );
    }
  }

  // =========================================================
  // Accessibility settings
  // =========================================================

  Future<void> openAccessibilitySettings() async {

    await _channel.invokeMethod(
      'openAccessibilitySettings',
    );
  }

  // =========================================================
  // Protection toggle
  // =========================================================

  Future<void> toggleProtection(
    bool value,
  ) async {

    await _channel.invokeMethod(
      'setProtectionEnabled',
      {
        'enabled': value,
      },
    );

    setState(() {
      protectionEnabled = value;
    });
  }

  // =========================================================
  // Schedule editor
  // =========================================================

  Future<void> editSchedule() async {

    TimeOfDay startTime = TimeOfDay(
      hour: startHour,
      minute: startMinute,
    );

    TimeOfDay endTime = TimeOfDay(
      hour: endHour,
      minute: endMinute,
    );

    final result = await showModalBottomSheet<
        Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {

        bool enabled = scheduleEnabled;

        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Daily Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Selected apps will be blocked during this time.',
                  ),

                  const SizedBox(height: 20),

                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'Enable Schedule',
                    ),
                    value: enabled,
                    onChanged: (value) {

                      setSheetState(() {
                        enabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'Start',
                    ),
                    trailing: Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {

                      final picked =
                          await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );

                      if (picked != null) {

                        setSheetState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),

                  ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'End',
                    ),
                    trailing: Text(
                      endTime.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {

                      final picked =
                          await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );

                      if (picked != null) {

                        setSheetState(() {
                          endTime = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {

                        Navigator.pop(
                          context,
                          {
                            'enabled': enabled,
                            'startHour':
                                startTime.hour,
                            'startMinute':
                                startTime.minute,
                            'endHour':
                                endTime.hour,
                            'endMinute':
                                endTime.minute,
                          },
                        );
                      },
                      child: const Text(
                        'Save Schedule',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    await _channel.invokeMethod(
      'setSchedule',
      {
        'enabled': result['enabled'],
        'startHour': result['startHour'],
        'startMinute': result['startMinute'],
        'endHour': result['endHour'],
        'endMinute': result['endMinute'],
      },
    );

    await loadDashboard();
  }

  // =========================================================
  // App selection
  // =========================================================

  Future<void> openAppSelection() async {

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppSelectionPage(),
      ),
    );

    await loadDashboard();
  }

  // =========================================================
  // Format time
  // =========================================================

  String formatTime(
    int hour,
    int minute,
  ) {

    final time = TimeOfDay(
      hour: hour,
      minute: minute,
    );

    return time.format(context);
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {

    final protectionActive =
        accessibilityEnabled &&
        protectionEnabled &&
        scheduleEnabled;

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Focus Guard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(

        onRefresh: loadDashboard,

        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // =====================================================
            // Protection status
            // =====================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Protection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [

                        Icon(
                          protectionActive
                              ? Icons.shield
                              : Icons.shield_outlined,
                          size: 42,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                protectionActive
                                    ? 'Active'
                                    : 'Not Active',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                protectionActive
                                    ? 'Selected apps are protected during the schedule.'
                                    : 'Protection is currently not running.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Protection',
                      ),
                      subtitle: const Text(
                        'Allow Focus Guard to block selected apps.',
                      ),
                      value: protectionEnabled,
                      onChanged: toggleProtection,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // Accessibility status
            // =====================================================

            Card(
              child: ListTile(
                leading: Icon(
                  accessibilityEnabled
                      ? Icons.check_circle
                      : Icons.error_outline,
                  size: 34,
                ),

                title: Text(
                  accessibilityEnabled
                      ? 'Accessibility Service'
                      : 'Accessibility Disabled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  accessibilityEnabled
                      ? 'Connected ✓'
                      : 'Accessibility permission is required.',
                ),

                trailing: accessibilityEnabled
                    ? null
                    : FilledButton(
                        onPressed:
                            openAccessibilitySettings,
                        child: const Text(
                          'Enable',
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // Blocked apps
            // =====================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.apps,
                  size: 32,
                ),

                title: const Text(
                  'Blocked Apps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  '$blockedAppsCount apps selected',
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: openAppSelection,
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // Schedule
            // =====================================================

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.schedule,
                  size: 32,
                ),

                title: const Text(
                  'Daily Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  scheduleEnabled
                      ? '${formatTime(startHour, startMinute)} → ${formatTime(endHour, endMinute)}'
                      : 'Schedule disabled',
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: editSchedule,
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // Explanation
            // =====================================================

            if (!accessibilityEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Icon(
                        Icons.info_outline,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Accessibility access is required for Focus Guard to detect when a selected app is opened.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// APP SELECTION PAGE
// ===================================================================

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({super.key});

  @override
  State<AppSelectionPage> createState() =>
      _AppSelectionPageState();
}

class _AppSelectionPageState
    extends State<AppSelectionPage> {

  static const MethodChannel _channel =
      MethodChannel('focus_guard/apps');

  List<Map<String, dynamic>> apps = [];

  Set<String> selectedApps = {};

  bool isLoading = true;
  bool isSaving = false;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    setState(() {
      isLoading = true;
    });

    try {

      final result =
          await _channel.invokeMethod(
        'getInstalledApps',
      );

      final blockedResult =
          await _channel.invokeMethod(
        'getBlockedApps',
      );

      final rawApps =
          (result as List?) ?? [];

      final rawBlocked =
          (blockedResult as List?) ?? [];

      final loadedApps =
          rawApps
              .map(
                (app) =>
                    Map<String, dynamic>.from(app),
              )
              .toList();

      final blockedApps =
          rawBlocked
              .map((e) => e.toString())
              .toSet();

      setState(() {

        apps = loadedApps;

        selectedApps = blockedApps;

        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveSelectedApps() async {

    setState(() {
      isSaving = true;
    });

    try {

      await _channel.invokeMethod(
        'setBlockedApps',
        {
          'apps': selectedApps.toList(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Blocked apps saved.',
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save apps.',
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredApps {

    if (searchQuery.trim().isEmpty) {
      return apps;
    }

    final query =
        searchQuery.trim().toLowerCase();

    return apps.where((app) {

      final name =
          app['name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return name.contains(query);

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Block Apps',
        ),
      ),

      body: isLoading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : Column(
              children: [

                Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          '${selectedApps.length} apps selected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        onChanged: (value) {

                          setState(() {
                            searchQuery =
                                value;
                          });
                        },

                        decoration:
                            InputDecoration(
                          hintText:
                              'Search apps...',
                          prefixIcon:
                              const Icon(
                            Icons.search,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(

                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      100,
                    ),

                    itemCount:
                        filteredApps.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 6,
                    ),

                    itemBuilder:
                        (context, index) {

                      final app =
                          filteredApps[index];

                      final name =
                          app['name']
                                  ?.toString() ??
                              'Unknown App';

                      final packageName =
                          app['packageName']
                                  ?.toString() ??
                              '';

                      final selected =
                          selectedApps
                              .contains(
                        packageName,
                      );

                      return Card(
                        child:
                            CheckboxListTile(
                          value: selected,

                          onChanged: (_) {

                            setState(() {

                              if (selected) {
                                selectedApps
                                    .remove(
                                  packageName,
                                );
                              } else {
                                selectedApps
                                    .add(
                                  packageName,
                                );
                              }
                            });
                          },

                          title: Text(
                            name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          subtitle: Text(
                            packageName,
                            style:
                                const TextStyle(
                              fontSize: 11,
                            ),
                          ),

                          secondary:
                              CircleAvatar(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0]
                                      .toUpperCase()
                                  : '?',
                            ),
                          ),

                          controlAffinity:
                              ListTileControlAffinity
                                  .trailing,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

      bottomNavigationBar:
          SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : saveSelectedApps,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                isSaving
                    ? 'Saving...'
                    : 'Save Selected Apps',
              ),
            ),
          ),
        ),
      ),
    );
  }
}