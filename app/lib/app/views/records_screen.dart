import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/report_provider.dart';
import '../widgets/report_card.dart';
import 'add_report_screen.dart';
import 'report_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports(
        refresh: true,
        endpoint: 'reports',
      );
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final endpoint = _tabController.index == 0
            ? 'reports'
            : 'prescriptions';
        context.read<ReportProvider>().loadReports(
          refresh: true,
          endpoint: endpoint,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Medical Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Prescriptions'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<ReportProvider>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReportScreen()),
          );
          if (!mounted || result != true) return;
          final endpoint = _tabController.index == 0
              ? 'reports'
              : 'prescriptions';
          provider.loadReports(refresh: true, endpoint: endpoint);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Record',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RecordsTab(endpoint: 'reports', type: 'Report'),
          _RecordsTab(endpoint: 'prescriptions', type: 'Prescription'),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatefulWidget {
  final String endpoint;
  final String type;

  const _RecordsTab({required this.endpoint, required this.type});

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ReportProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reports.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.errorMessage != null && provider.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => provider.loadReports(
                    refresh: true,
                    endpoint: widget.endpoint,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No ${widget.type} records found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first record',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              provider.loadReports(refresh: true, endpoint: widget.endpoint),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: provider.reports.length + (provider.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.reports.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final report = provider.reports[index];
              return ReportCard(
                report: report,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReportDetailScreen(reportId: report.recordId),
                    ),
                  );
                },
                onDelete: () =>
                    _confirmDelete(context, provider, report.recordId),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ReportProvider provider,
    String reportId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Record',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this record? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteReport(reportId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
