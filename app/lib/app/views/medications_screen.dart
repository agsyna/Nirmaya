import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../models/medication_model.dart';
import '../providers/medication_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/medication_card.dart';
import 'add_medication_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Medications',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.background,
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.medications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week day selector
                _buildWeekSelector(provider),

                const SizedBox(height: 8),

                // Scheduled section
                if (provider.activeMedications.isNotEmpty) ...[
                  _buildScheduledSection(provider),
                ] else ...[
                  _buildEmptyScheduledSection(),
                ],

                // Your medications section
                _buildYourMedications(provider),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<MedicationProvider>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (!mounted || result != true) return;
          provider.loadMedications();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeekSelector(MedicationProvider provider) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.surface,
      child: Column(
        children: [
          // Day labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((d) {
                return Text(
                  d,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Date circles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final date = weekStart.add(Duration(days: i));
                final isSelected =
                    provider.selectedDate.day == date.day &&
                    provider.selectedDate.month == date.month &&
                    provider.selectedDate.year == date.year;
                final isToday =
                    now.day == date.day &&
                    now.month == date.month &&
                    now.year == date.year;

                return GestureDetector(
                  onTap: () => provider.selectDate(date),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledSection(MedicationProvider provider) {
    final now = DateTime.now();
    final doses = <_ScheduledDose>[];

    for (final med in provider.activeMedications) {
      for (final time in med.reminderTimes) {
        doses.add(_ScheduledDose(medication: med, reminderTime: time));
      }
    }

    doses.sort((a, b) {
      final left = a.reminderTime.hour * 60 + a.reminderTime.minute;
      final right = b.reminderTime.hour * 60 + b.reminderTime.minute;
      return left.compareTo(right);
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ...doses.map((dose) {
            final med = dose.medication;
            final time = dose.reminderTime;
            final log = provider.getLogForDose(med.id!, dose.reminderTime);
            String status;
            if (log != null) {
              status = log.status;
            } else {
              final scheduledDT = DateTime(
                provider.selectedDate.year,
                provider.selectedDate.month,
                provider.selectedDate.day,
                time.hour,
                time.minute,
              );
              if (scheduledDT.isBefore(now)) {
                status = 'passed';
              } else {
                status = 'upcoming';
              }
            }

            return MedicationCard(
              medication: med,
              reminderTime: time,
              status: status,
              onTake: () {
                provider.takeMedication(med.id!, time);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${med.name} marked as taken ✓',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduledSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No doses scheduled for this day',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildYourMedications(MedicationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your medications',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),

            if (provider.medications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 48,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No medications added yet',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first medication',
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...provider.medications.map((med) {
                return Dismissible(
                  key: Key('med_${med.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    provider.deleteMedication(med.id!);
                  },
                  child: MedicationCard(
                    medication: med,
                    onTap: () {
                      // Could navigate to edit screen
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ScheduledDose {
  final Medication medication;
  final TimeOfDay reminderTime;

  const _ScheduledDose({required this.medication, required this.reminderTime});
}
