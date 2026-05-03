import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../models/medication_model.dart';
import '../providers/medication_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'Tablet';
  String _selectedFrequency = 'Once daily';
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _reminderTimes[index] = time);
    }
  }

  void _addReminderTime() {
    setState(() {
      _reminderTimes.add(const TimeOfDay(hour: 21, minute: 0));
    });
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length > 1) {
      setState(() => _reminderTimes.removeAt(index));
    }
  }

  int? _requiredReminderCount(String frequency) {
    switch (frequency) {
      case 'Once daily':
      case 'Once a week':
        return 1;
      case 'Twice daily':
      case 'Every 12 hours':
        return 2;
      case 'Thrice daily':
      case 'Every 8 hours':
        return 3;
      case 'Every 6 hours':
        return 4;
      default:
        return null;
    }
  }

  TimeOfDay _defaultTimeForSlot(int index) {
    const defaults = [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 23, minute: 0),
    ];
    return index < defaults.length
        ? defaults[index]
        : const TimeOfDay(hour: 9, minute: 0);
  }

  void _applyFrequencyDefaults(String frequency) {
    final count = _requiredReminderCount(frequency);

    if (count == null) {
      return;
    }

    final updated = List<TimeOfDay>.generate(
      count,
      (index) => index < _reminderTimes.length
          ? _reminderTimes[index]
          : _defaultTimeForSlot(index),
    );

    setState(() {
      _reminderTimes = updated;
      if (frequency == 'Once a week') {
        _selectedDays = [
          _selectedDays.isEmpty ? DateTime.now().weekday : _selectedDays.first,
        ];
      } else if (_selectedDays.isEmpty) {
        _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedFrequency == 'Once a week') {
        _selectedDays = [day];
        return;
      }

      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one day',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final medication = Medication(
      name: _nameController.text.trim(),
      type: _selectedType,
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      daysOfWeek: _selectedDays,
      reminderTimes: _reminderTimes,
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = context.read<MedicationProvider>();
    final success = await provider.addMedication(medication);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medication added & reminders set!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Medication',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine name
              CustomTextField(
                controller: _nameController,
                label: 'Medicine Name',
                hint: 'e.g., Paracetamol',
                prefixIcon: Icons.medication,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter medicine name';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Type selector
              Text(
                'Type',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.medicationTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Dosage
              CustomTextField(
                controller: _dosageController,
                label: 'Dosage',
                hint: 'e.g., 500 mg',
                prefixIcon: Icons.science,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter dosage';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Frequency
              Text(
                'Frequency',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat, size: 20),
                ),
                items: AppConstants.medicationFrequencies
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedFrequency = v);
                    _applyFrequencyDefaults(v);
                  }
                },
              ),

              const SizedBox(height: 18),

              Text(
                _selectedFrequency == 'Once a week' ? 'Day' : 'Days',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _weekdayLabel(day),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),

              // Reminder times
              Text(
                'Reminder Times',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_reminderTimes.length, (i) {
                final time = _reminderTimes[i];
                final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                final period = time.period == DayPeriod.am ? 'AM' : 'PM';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$hour:${time.minute.toString().padLeft(2, '0')} $period',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_reminderTimes.length > 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap:
                              _requiredReminderCount(_selectedFrequency) == null
                              ? () => _removeReminderTime(i)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  _requiredReminderCount(_selectedFrequency) ==
                                      null
                                  ? AppColors.errorLight
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color:
                                  _requiredReminderCount(_selectedFrequency) ==
                                      null
                                  ? AppColors.error
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (_requiredReminderCount(_selectedFrequency) == null)
                GestureDetector(
                  onTap: _addReminderTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add another time',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Times are auto-set for $_selectedFrequency. You can still edit each time.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

              const SizedBox(height: 18),

              // Notes
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'e.g., Take after meals',
                prefixIcon: Icons.note,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              // Save button
              PrimaryButton(
                text: 'Save Medication',
                icon: Icons.check,
                onPressed: _save,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
