import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/models/set_model.dart';
import '../controllers/collection_controller.dart';
import '../widgets/set_card.dart';
import 'package:go_router/go_router.dart';

/// Sort options for sets
enum SetSortOption {
  releaseDate,    // By set code (OP-01, OP-02, etc.)
  completionAsc,  // Completion % ascending
  completionDesc, // Completion % descending
}

/// Page 2 - Collection Home (Lista Set)
/// Vertical set cards with completion %, FAB for import/scan
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionController _controller = CollectionController();
  SetSortOption _currentSort = SetSortOption.completionDesc;

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  /// Get sorted sets based on current sort option
  List<SetModel> get _sortedSets {
    final sets = List<SetModel>.from(_controller.sets);
    switch (_currentSort) {
      case SetSortOption.releaseDate:
        // Sort by code (OP-01, OP-02, etc.) - earlier sets first
        sets.sort((a, b) => a.code.compareTo(b.code));
        break;
      case SetSortOption.completionAsc:
        // Sort by completion % ascending (least complete first)
        sets.sort((a, b) => a.completionPercentage.compareTo(b.completionPercentage));
        break;
      case SetSortOption.completionDesc:
        // Sort by completion % descending (most complete first)
        sets.sort((a, b) => b.completionPercentage.compareTo(a.completionPercentage));
        break;
    }
    return sets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Collection',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_controller.sets.length} sets',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Sort button
                  PopupMenuButton<SetSortOption>(
                    icon: const Icon(Icons.sort, color: AppColors.cyan),
                    color: AppColors.darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.glassBorder),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _currentSort = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: SetSortOption.releaseDate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _currentSort == SetSortOption.releaseDate
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data di uscita',
                                style: TextStyle(
                                  color: _currentSort == SetSortOption.releaseDate
                                      ? AppColors.cyan
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SetSortOption.completionDesc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: _currentSort == SetSortOption.completionDesc
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '% Completamento ↓',
                                style: TextStyle(
                                  color: _currentSort == SetSortOption.completionDesc
                                      ? AppColors.cyan
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SetSortOption.completionAsc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: _currentSort == SetSortOption.completionAsc
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '% Completamento ↑',
                                style: TextStyle(
                                  color: _currentSort == SetSortOption.completionAsc
                                      ? AppColors.cyan
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Sync button
                  IconButton(
                    onPressed: _controller.isLoading ? null : _syncFromApi,
                    icon: _controller.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyan,
                            ),
                          )
                        : const Icon(Icons.sync, color: AppColors.cyan),
                  ),
                  // Three-dot menu for import/export
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.cyan),
                    color: AppColors.darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.glassBorder),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'import':
                          _importCollection();
                          break;
                        case 'export':
                          _exportCollection();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.file_upload, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 12),
                            Text('Import Collection', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.file_download, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 12),
                            Text('Export Collection', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.sets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }

    if (_controller.error != null) {
      return _buildErrorState();
    }

    if (_controller.sets.isEmpty) {
      return _buildEmptyState();
    }

    final sortedSets = _sortedSets;

    return RefreshIndicator(
      onRefresh: _controller.loadSets,
      color: AppColors.cyan,
      backgroundColor: AppColors.darkBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sortedSets.length,
        itemBuilder: (context, index) {
          final set = sortedSets[index];
          return SetCard(
            set: set,
            onTap: () => _navigateToSet(set),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 80,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No sets yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Sync from API or add cards to get started',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _syncFromApi,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Sync Sets'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    // Check if it's a network/connection error
    final errorMsg = _controller.error ?? '';
    final isNetworkError = errorMsg.toLowerCase().contains('network') ||
        errorMsg.toLowerCase().contains('connection') ||
        errorMsg.toLowerCase().contains('timeout') ||
        errorMsg.toLowerCase().contains('socket');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 80,
              color: isNetworkError ? AppColors.textMuted : AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              isNetworkError ? 'No Internet Connection' : 'Something went wrong',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isNetworkError
                  ? 'Please check your internet connection and try again.'
                  : errorMsg,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _controller.clearError();
                _controller.loadSets();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSet(SetModel set) {
    context.go('/set/${set.code}');
  }

  Future<void> _syncFromApi() async {
    await _controller.syncSetsFromApi();
  }

  Future<void> _importCollection() async {
    try {
      // Pick JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        );
      }

      // Read file
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      // Import collection
      final count = await _controller.importCollection(jsonString);
      
      // Close dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importate $count carte nella collezione'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close dialog if open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import fallito: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportCollection() async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        );
      }

      // Get JSON data
      final jsonString = await _controller.exportCollection();
      
      // Get temp directory and create file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/onepiece_collection_$timestamp.json');
      await file.writeAsString(jsonString);

      // Close dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'One Piece TCG Collection Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esportate ${_controller.sets.length} set'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close dialog if open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esportazione fallita: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
