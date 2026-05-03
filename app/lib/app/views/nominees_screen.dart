import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../models/nominee_model.dart';
import '../providers/nominee_provider.dart';
import '../widgets/custom_app_bar.dart';

class NomineesScreen extends StatefulWidget {
  const NomineesScreen({super.key});

  @override
  State<NomineesScreen> createState() => _NomineesScreenState();
}

class _NomineesScreenState extends State<NomineesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NomineeProvider>().loadNominees();
    });
  }

  // ==================== Show Add / Edit Sheet ====================
  void _showNomineeSheet({Nominee? nominee}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NomineeFormSheet(existing: nominee),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Nominees',
        onBackPressed: () => Navigator.pop(context),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 12),
        //     child: GestureDetector(
        //       onTap: () => _showNomineeSheet(),
        //       child: const Icon(Icons.add, color: Colors.white, size: 28),
        //     ),
        //   ),
        // ],
      ),
      body: Consumer<NomineeProvider>(
        builder: (context, provider, _) {
          // ---- Loading (initial) ----
          if (provider.isLoading && provider.nominees.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ---- Error ----
          if (provider.errorMessage != null && provider.nominees.isEmpty) {
            return _buildErrorState(provider);
          }

          // ---- Empty ----
          if (provider.nominees.isEmpty) {
            return _buildEmptyState();
          }

          // ---- List ----
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.loadNominees,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(provider)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _NomineeCard(nominee: provider.nominees[index]),
                      childCount: provider.nominees.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNomineeSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Add Nominee',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==================== Sub-widgets ====================

  Widget _buildHeader(NomineeProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 69, 5, 69),
        // gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          // BoxShadow(
          //   color: AppColors.shadow,
          //   blurRadius: 8,
          //   offset: Offset(0, 3),
          // ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_outlined, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${provider.count} Nominee${provider.count == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'People authorised to act on your behalf',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_disabled_outlined,
            size: 72,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No nominees yet',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add a nominee',
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NomineeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadNominees,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// Nominee Card
// ==========================================================================

class _NomineeCard extends StatelessWidget {
  final Nominee nominee;
  const _NomineeCard({required this.nominee});

  void _onEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NomineeFormSheet(existing: nominee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = nominee.name.isNotEmpty
        ? nominee.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            initials.toUpperCase(),
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          nominee.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          nominee.email,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          tooltip: 'Edit nominee',
          onPressed: () => _onEdit(context),
        ),
      ),
    );
  }
}

// ==========================================================================
// Add / Edit Bottom Sheet Form
// ==========================================================================

class _NomineeFormSheet extends StatefulWidget {
  final Nominee? existing;
  const _NomineeFormSheet({this.existing});

  @override
  State<_NomineeFormSheet> createState() => _NomineeFormSheetState();
}

class _NomineeFormSheetState extends State<_NomineeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirmation dialog for edits
    if (_isEditing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Update Nominee',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to update this nominee?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Update',
                style: GoogleFonts.poppins(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);

    final provider = context.read<NomineeProvider>();
    bool success;

    if (_isEditing) {
      success = await provider.editNominee(
        id: widget.existing!.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
    } else {
      success = await provider.addNominee(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Nominee updated successfully'
                : 'Nominee added successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Something went wrong',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _isEditing ? 'Edit Nominee' : 'Add Nominee',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Full Name', Icons.person_outline),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                'Email Address',
                Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                'Phone Number',
                Icons.phone_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                if (!phoneRegex.hasMatch(v.trim())) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Nominee',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
