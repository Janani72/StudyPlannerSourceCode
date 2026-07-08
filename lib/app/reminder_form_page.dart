import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';

class ReminderFormPage extends StatefulWidget {
  final ReminderItem? existingReminder;

  const ReminderFormPage({super.key, this.existingReminder});

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _attachCtrl;
  
  late ReminderCategory _category;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late ReminderPriority _priority;
  late Color _labelColor;
  late RepeatType _repeat;
  late int _preDueMinutes;

  final List<Color> _colorOptions = [
    const Color(0xFF7C4DFF), // Electric Violet
    const Color(0xFF00E5FF), // Cyber Cyan
    const Color(0xFFFF5252), // Hot Crimson
    const Color(0xFFFFAB40), // Sunset Amber
    const Color(0xFFFF4081), // Neon Pink
    const Color(0xFF90A4AE), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _attachCtrl = TextEditingController(text: r?.attachmentPath ?? '');
    
    _category = r?.category ?? ReminderCategory.study;
    _dueDate = r?.dueDate ?? DateTime.now();
    _dueTime = r?.dueTime ?? const TimeOfDay(hour: 9, minute: 0);
    _priority = r?.priority ?? ReminderPriority.medium;
    _labelColor = r?.labelColor ?? _colorOptions[0];
    _repeat = r?.repeat ?? RepeatType.oneTime;
    _preDueMinutes = r?.preDueMinutes ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _attachCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final id = widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final item = ReminderItem(
      id: id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      dueDate: _dueDate,
      dueTime: _dueTime,
      priority: _priority,
      labelColor: _labelColor,
      attachmentPath: _attachCtrl.text.isNotEmpty ? _attachCtrl.text : null,
      repeat: _repeat,
      preDueMinutes: _preDueMinutes,
      isCompleted: widget.existingReminder?.isCompleted ?? false,
      completedAt: widget.existingReminder?.completedAt,
    );

    if (widget.existingReminder != null) {
      provider.updateReminder(item);
    } else {
      provider.addReminder(item);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}';
    final timeStr = '${_dueTime.hourOfPeriod}:${_dueTime.minute.toString().padLeft(2, '0')} ${_dueTime.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingReminder != null ? 'Edit Reminder' : 'New Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Input
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description / Notes',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Priority
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReminderCategory>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: ReminderCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _category = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ReminderPriority>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                    items: ReminderPriority.values.map((pri) {
                      return DropdownMenuItem(
                        value: pri,
                        child: Text(pri.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _priority = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recurrence & Pre-Due notifications
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RepeatType>(
                    value: _repeat,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: RepeatType.values.map((rep) {
                      return DropdownMenuItem(
                        value: rep,
                        child: Text(rep.name == 'oneTime' ? 'One Time' : rep.name[0].toUpperCase() + rep.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _repeat = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _preDueMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Alert Before',
                      prefixIcon: Icon(Icons.notifications_active_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('On Due Time')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                      DropdownMenuItem(value: 60, child: Text('1 hour before')),
                      DropdownMenuItem(value: 1440, child: Text('1 day before')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _preDueMinutes = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(dateStr),
                    onPressed: _selectDate,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(timeStr),
                    onPressed: _selectTime,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Label color picker
            const Text(
              'Color Tag',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (ctx, idx) {
                  final col = _colorOptions[idx];
                  final isSelected = _labelColor.value == col.value;
                  return GestureDetector(
                    onTap: () => setState(() => _labelColor = col),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black87,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Attachment Mock Field
            TextFormField(
              controller: _attachCtrl,
              decoration: const InputDecoration(
                labelText: 'Attachment Path (Optional)',
                prefixIcon: Icon(Icons.attach_file_rounded),
                helperText: 'Provide a filepath or URL link',
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(widget.existingReminder != null ? 'Save Changes' : 'Create Reminder'),
              onPressed: _saveForm,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
