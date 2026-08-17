import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/widgets/photo_attachment_area.dart';
import 'package:linko/features/home/presentation/widgets/professional_summary_card.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/timing_option_card.dart';

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({
    required this.professional,
    required this.selectedService,
    required this.onContinue,
    super.key,
  });

  final ProfessionalProfileData professional;
  final String selectedService;
  final ValueChanged<RequestDraft> onContinue;

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  RequestTiming? _timing;
  DateTime? _selectedDate;
  int _attachedPhotoCount = 0;
  String? _timingError;
  String? _dateError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTiming(RequestTiming timing) async {
    setState(() {
      _timing = timing;
      _timingError = null;
      if (timing != RequestTiming.specificDate) {
        _selectedDate = null;
        _dateError = null;
      }
    });

    if (timing == RequestTiming.specificDate) {
      await _pickDate();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
        _dateError = null;
      });
    }
  }

  void _addPhoto() {
    if (_attachedPhotoCount >= 5) {
      return;
    }

    setState(() {
      _attachedPhotoCount++;
    });
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final timingIsValid = _timing != null;
    final dateIsValid =
        _timing != RequestTiming.specificDate || _selectedDate != null;

    setState(() {
      _timingError = timingIsValid
          ? null
          : 'Selecciona cuándo necesitas el servicio.';
      _dateError = dateIsValid ? null : 'Selecciona una fecha.';
    });

    if (!formIsValid || !timingIsValid || !dateIsValid) {
      return;
    }

    widget.onContinue(
      RequestDraft(
        professional: widget.professional,
        selectedService: widget.selectedService,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        timing: _timing!,
        selectedDate: _selectedDate,
        attachedPhotoCount: _attachedPhotoCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Solicitar servicio'),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: ProfessionalSummaryCard(
                    professional: widget.professional,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RequestSectionTitle(label: '¿Qué necesitas?'),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('request-description'),
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText:
                                'Describe el trabajo que necesitas realizar.',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Describe el trabajo que necesitas '
                                  'realizar.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const RequestSectionTitle(
                          label: '¿Dónde se realizará?',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('request-location'),
                          controller: _locationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Provincia, cantón o dirección',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa la ubicación del servicio.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        const RequestSectionTitle(
                          label: '¿Cuándo lo necesitas?',
                        ),
                        const SizedBox(height: 12),
                        for (final timing in RequestTiming.values) ...[
                          TimingOptionCard(
                            key: ValueKey('request-timing-${timing.name}'),
                            label: timing.label,
                            selected: _timing == timing,
                            onTap: () => _selectTiming(timing),
                          ),
                          if (timing != RequestTiming.values.last)
                            const SizedBox(height: 10),
                        ],
                        if (_timingError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _timingError!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.error),
                          ),
                        ],
                        if (_timing == RequestTiming.specificDate) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              _selectedDate?.spanishDate ?? 'Seleccionar fecha',
                            ),
                          ),
                          if (_dateError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _dateError!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colorScheme.error),
                            ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        const RequestSectionTitle(label: 'Agrega fotos'),
                        const SizedBox(height: 12),
                        PhotoAttachmentArea(
                          attachedCount: _attachedPhotoCount,
                          onAddPhoto: _addPhoto,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _continue,
                  child: const Text('Continuar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
