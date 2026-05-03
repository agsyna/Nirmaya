import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/access_view_model.dart';
import '../widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

// Top level helper functions
void _showConfigDialog(BuildContext context, AccessViewModel viewModel, String requestId, {bool isUpdate = false, List<dynamic>? initialScopes}) {
  List<String> selectedScopes = initialScopes != null ? List<String>.from(initialScopes) : ['reports']; // default
  int selectedExpiryMinutes = 60; // 1 hour default
  bool isSaving = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isUpdate ? 'Update Access' : 'Configure Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: isSaving 
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Scope:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                CheckboxListTile(
                  title: const Text('Reports'),
                  value: selectedScopes.contains('reports'),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) selectedScopes.add('reports');
                      else selectedScopes.remove('reports');
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Prescriptions'),
                  value: selectedScopes.contains('prescriptions'),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) selectedScopes.add('prescriptions');
                      else selectedScopes.remove('prescriptions');
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Health Data'),
                  value: selectedScopes.contains('health_data'),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) selectedScopes.add('health_data');
                      else selectedScopes.remove('health_data');
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text('Expires In:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                DropdownButton<int>(
                  value: selectedExpiryMinutes,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('1 Hour')),
                    DropdownMenuItem(value: 1440, child: Text('24 Hours')),
                    DropdownMenuItem(value: 10080, child: Text('7 Days')),
                    DropdownMenuItem(value: 43200, child: Text('30 Days')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedExpiryMinutes = val);
                  },
                ),
              ],
            ),
            actions: isSaving ? [] : [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedScopes.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Please select at least one scope', style: GoogleFonts.poppins())),
                    );
                    return;
                  }
                  
                  setState(() { isSaving = true; });
                  
                  bool success = false;
                  if (isUpdate) {
                    success = await viewModel.updateAccessRequest(
                      requestId: requestId,
                      scope: selectedScopes,
                      expiresInMinutes: selectedExpiryMinutes,
                    );
                  } else {
                    success = await viewModel.approveAccessRequest(
                      requestId: requestId,
                      scope: selectedScopes,
                      expiresInMinutes: selectedExpiryMinutes,
                    );
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? (isUpdate ? 'Access updated successfully' : 'Access granted successfully') : (viewModel.errorMessage ?? 'Failed to complete action'),
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(isUpdate ? 'Update Access' : 'Grant Access', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

void _handleAction(BuildContext context, AccessViewModel viewModel, String requestId, String action) async {
  if (action == 'approve') {
    _showConfigDialog(context, viewModel, requestId);
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );

  bool success = false;
  if (action == 'reject') {
    success = await viewModel.rejectAccessRequest(requestId);
  } else if (action == 'revoke') {
    success = await viewModel.revokeAccessRequest(requestId);
  }

  if (context.mounted) {
    Navigator.pop(context); // close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Action successful' : (viewModel.errorMessage ?? 'Failed to perform action'),
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}

Widget _buildDoctorCard(BuildContext context, AccessViewModel viewModel, dynamic request) {
  final status = request['status'] ?? 'pending';
  final doctorInfo = request['doctorInfo'] ?? {};
  final doctorName = doctorInfo['name'] ?? 'Unknown Doctor';
  
  Color statusColor;
  if (status == 'approved') statusColor = AppColors.success;
  else if (status == 'rejected' || status == 'revoked') statusColor = AppColors.error;
  else statusColor = AppColors.warning;

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  doctorName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requested on: ${request['createdAt'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(request['createdAt']).toLocal()) : 'Unknown'}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (status == 'approved' && request['expiresAt'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Access Valid Until: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(request['expiresAt']).toLocal())}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, viewModel, request['requestId'], 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text('Reject', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, viewModel, request['requestId'], 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else if (status == 'approved') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, viewModel, request['requestId'], 'revoke'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text('Revoke', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showConfigDialog(context, viewModel, request['requestId'], isUpdate: true, initialScopes: request['approvedScope']),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('Update', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class AccessScreen extends StatefulWidget {
  final String? patientId;
  const AccessScreen({super.key, this.patientId});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccessViewModel>().loadShareTokens(
        refresh: true,
        patientId: widget.patientId,
      );
      context.read<AccessViewModel>().loadAccessRequests();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AccessViewModel>().loadMore();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Manage Access',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Doctor Requests'),
              Tab(text: 'Active Shares'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DoctorRequestsTab(),
            _ActiveSharesTab(),
          ],
        ),
      ),
    );
  }
}

class _DoctorRequestsTab extends StatelessWidget {
  const _DoctorRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessViewModel>(
      builder: (context, viewModel, _) {
        final pendingOrRejectedRequests = viewModel.accessRequests.where((req) => req['status'] != 'approved').toList();

        if (viewModel.isLoading && pendingOrRejectedRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (pendingOrRejectedRequests.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => viewModel.loadAccessRequests(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Text(
                    'No pending access requests.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => viewModel.loadAccessRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingOrRejectedRequests.length,
            itemBuilder: (context, index) {
              return _buildDoctorCard(context, viewModel, pendingOrRejectedRequests[index]);
            },
          ),
        );
      },
    );
  }
}

class _ActiveSharesTab extends StatelessWidget {
  const _ActiveSharesTab();

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'doctor':
        return const Color(0xFF2196F3);
      case 'public':
        return const Color(0xFF9C27B0);
      case 'family':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.primary;
    }
  }

  void _confirmRevoke(BuildContext context, AccessViewModel viewModel, dynamic token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Revoke Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to revoke this access?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.revokeShareToken(token.id);
            },
            child: Text('Revoke', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessViewModel>(
      builder: (context, viewModel, _) {
        final approvedRequests = viewModel.accessRequests.where((req) => req['status'] == 'approved').toList();
        final manualTokens = viewModel.shareTokens;
        
        final hasItems = approvedRequests.isNotEmpty || manualTokens.isNotEmpty;

        if (viewModel.isLoading && !hasItems) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!hasItems) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              viewModel.loadAccessRequests();
              viewModel.loadShareTokens(refresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Text(
                    'No active shares.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            viewModel.loadAccessRequests();
            viewModel.loadShareTokens(refresh: true);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: approvedRequests.length + manualTokens.length,
            itemBuilder: (context, index) {
              if (index < approvedRequests.length) {
                return _buildDoctorCard(context, viewModel, approvedRequests[index]);
              }
              
              final token = manualTokens[index - approvedRequests.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: token.isExpired
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(token.accessLevel),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    token.accessLevel.toUpperCase(),
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scope: ${token.scope.join(", ")}',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (token.isExpired)
                            Chip(label: const Text('Expired'), backgroundColor: AppColors.error.withValues(alpha: 0.2))
                          else
                            Chip(label: Text('${token.daysRemaining}d left'), backgroundColor: AppColors.success.withValues(alpha: 0.2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('Expires: ${_formatDate(token.expiresAt)}', style: GoogleFonts.poppins(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _confirmRevoke(context, viewModel, token),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text('Revoke', style: GoogleFonts.poppins(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
