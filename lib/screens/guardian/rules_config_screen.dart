import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/rules_model.dart';

class RulesConfigScreen extends ConsumerStatefulWidget {
  const RulesConfigScreen({super.key});

  @override
  ConsumerState<RulesConfigScreen> createState() => _RulesConfigScreenState();
}

class _RulesConfigScreenState extends ConsumerState<RulesConfigScreen> {
  final _onTimeCtrl = TextEditingController();
  final _lateCtrl = TextEditingController();
  final _onTimeJamaahCtrl = TextEditingController();
  final _lateJamaahCtrl = TextEditingController();

  final _fajrBufferCtrl = TextEditingController();
  final _dhuhrBufferCtrl = TextEditingController();
  final _asrBufferCtrl = TextEditingController();
  final _maghribBufferCtrl = TextEditingController();
  final _ishaBufferCtrl = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRules());
  }

  Future<void> _loadRules() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final rules = await ref.read(databaseProvider).getRules(user.uid);
    if (mounted) {
      setState(() {
        _onTimeCtrl.text = '${rules.onTimePoints}';
        _lateCtrl.text = '${rules.latePoints}';
        _onTimeJamaahCtrl.text = '${rules.onTimeJamaahPoints}';
        _lateJamaahCtrl.text = '${rules.lateJamaahPoints}';

        _fajrBufferCtrl.text = rules.fajrBuffer != null ? '${rules.fajrBuffer}' : '';
        _dhuhrBufferCtrl.text = rules.dhuhrBuffer != null ? '${rules.dhuhrBuffer}' : '';
        _asrBufferCtrl.text = rules.asrBuffer != null ? '${rules.asrBuffer}' : '';
        _maghribBufferCtrl.text = rules.maghribBuffer != null ? '${rules.maghribBuffer}' : '';
        _ishaBufferCtrl.text = rules.ishaBuffer != null ? '${rules.ishaBuffer}' : '';

        _loaded = true;
      });
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final onTime = int.tryParse(_onTimeCtrl.text);
    final late = int.tryParse(_lateCtrl.text);
    final onTimeJ = int.tryParse(_onTimeJamaahCtrl.text);
    final lateJ = int.tryParse(_lateJamaahCtrl.text);

    if (onTime == null || late == null || onTimeJ == null || lateJ == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter valid numbers for all fields'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    int? parseBuffer(String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }

    final fajrB = parseBuffer(_fajrBufferCtrl.text);
    final dhuhrB = parseBuffer(_dhuhrBufferCtrl.text);
    final asrB = parseBuffer(_asrBufferCtrl.text);
    final maghribB = parseBuffer(_maghribBufferCtrl.text);
    final ishaB = parseBuffer(_ishaBufferCtrl.text);

    if ((_fajrBufferCtrl.text.isNotEmpty && fajrB == null) ||
        (_dhuhrBufferCtrl.text.isNotEmpty && dhuhrB == null) ||
        (_asrBufferCtrl.text.isNotEmpty && asrB == null) ||
        (_maghribBufferCtrl.text.isNotEmpty && maghribB == null) ||
        (_ishaBufferCtrl.text.isNotEmpty && ishaB == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter valid numbers for timing buffers, or leave them empty.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(databaseProvider).setRules(RulesModel(
            guardianId: user.uid,
            onTimePoints: onTime,
            latePoints: late,
            onTimeJamaahPoints: onTimeJ,
            lateJamaahPoints: lateJ,
            fajrBuffer: fajrB,
            dhuhrBuffer: dhuhrB,
            asrBuffer: asrB,
            maghribBuffer: maghribB,
            ishaBuffer: ishaB,
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Configuration saved!'),
          backgroundColor: Colors.green,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _onTimeCtrl.dispose();
    _lateCtrl.dispose();
    _onTimeJamaahCtrl.dispose();
    _lateJamaahCtrl.dispose();

    _fajrBufferCtrl.dispose();
    _dhuhrBufferCtrl.dispose();
    _asrBufferCtrl.dispose();
    _maghribBufferCtrl.dispose();
    _ishaBufferCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configure Points & Rules')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scoring Matrix',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define how many points children earn for each prayer condition.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 32),

                  // On-Time section
                  _sectionLabel('On-Time Prayers', Colors.green),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ruleField(
                          'On-Time (Single)',
                          _onTimeCtrl,
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _ruleField(
                          "On-Time + Jama'ah",
                          _onTimeJamaahCtrl,
                          Icons.people_outline,
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Late section
                  _sectionLabel('Late Prayers', Colors.orange),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ruleField(
                          'Late (Single)',
                          _lateCtrl,
                          Icons.access_time_rounded,
                          Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _ruleField(
                          "Late + Jama'ah",
                          _lateJamaahCtrl,
                          Icons.people_outline,
                          Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Waqt al-Fadila buffers section
                  _sectionLabel('Custom Waqt al-Fadila Windows (Optional)', Colors.teal),
                  const SizedBox(height: 8),
                  Text(
                    'Define the maximum minutes allowed after the prayer start time to count it as "On-Time". Leave empty to use smart defaults (e.g. Dhuhr until Asr).',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _bufferField('Fajr Extra Time', _fajrBufferCtrl, Icons.wb_twilight_rounded, Colors.teal),
                        const SizedBox(height: 16),
                        _bufferField('Dhuhr Extra Time', _dhuhrBufferCtrl, Icons.wb_sunny_outlined, Colors.teal),
                        const SizedBox(height: 16),
                        _bufferField('Asr Extra Time', _asrBufferCtrl, Icons.cloud_queue_rounded, Colors.teal),
                        const SizedBox(height: 16),
                        _bufferField('Maghrib Extra Time', _maghribBufferCtrl, Icons.nights_stay_outlined, Colors.teal),
                        const SizedBox(height: 16),
                        _bufferField('Isha Extra Time', _ishaBufferCtrl, Icons.dark_mode_outlined, Colors.teal),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20)),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Configuration',
                            style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _ruleField(
      String label, TextEditingController ctrl, IconData icon, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixText: 'pts',
        suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
    );
  }

  Widget _bufferField(
      String label, TextEditingController ctrl, IconData icon, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixText: 'min',
        suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        hintText: 'Smart Default (Fajr → Sunrise, Dhuhr → Asr, etc.)',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
    );
  }
}
