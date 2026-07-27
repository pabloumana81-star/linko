import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/home/presentation/widgets/quotation_widgets.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';

class QuotationFormScreen extends StatefulWidget {
  const QuotationFormScreen({
    required this.request,
    required this.onReview,
    this.initialDraft,
    super.key,
  });

  final IncomingServiceRequest request;
  final QuotationDraft? initialDraft;
  final ValueChanged<QuotationDraft> onReview;

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _laborController;
  late final TextEditingController _materialsController;
  late final TextEditingController _descriptionController;
  QuotationDuration? _duration;
  QuotationStartTiming _startTiming = QuotationStartTiming.asSoonAsPossible;
  DateTime? _proposedDate;
  int _validityDays = 7;

  int get _labor => int.tryParse(_laborController.text) ?? 0;
  int get _materials => int.tryParse(_materialsController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _laborController = TextEditingController(
      text: draft == null ? '' : '${draft.laborAmount}',
    );
    _materialsController = TextEditingController(
      text: draft == null || draft.materialsAmount == 0
          ? ''
          : '${draft.materialsAmount}',
    );
    _descriptionController = TextEditingController(
      text: draft?.workDescription ?? '',
    );
    _duration = draft?.estimatedDuration;
    _startTiming = draft?.startTiming ?? _startTiming;
    _proposedDate = draft?.proposedStartDate;
    _validityDays = draft?.validityDays ?? _validityDays;
  }

  @override
  void dispose() {
    _laborController.dispose();
    _materialsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _proposedDate == null || _proposedDate!.isBefore(now)
          ? now
          : _proposedDate!,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('es', 'CR'),
    );
    if (selected != null && mounted) {
      setState(() => _proposedDate = selected);
    }
  }

  void _review() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {});
    if (!valid ||
        _duration == null ||
        (_startTiming == QuotationStartTiming.proposedDate &&
            _proposedDate == null)) {
      return;
    }
    widget.onReview(
      QuotationDraft(
        requestId: widget.request.id,
        customerName: widget.request.customerName,
        serviceCategory: widget.request.serviceCategory,
        workDescription: _descriptionController.text.trim(),
        laborAmount: _labor,
        materialsAmount: _materials,
        estimatedDuration: _duration!,
        startTiming: _startTiming,
        proposedStartDate: _proposedDate,
        validityDays: _validityDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar cotización')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QuotationRequestSummary(request: widget.request),
                    const SizedBox(height: 32),
                    const RequestSectionTitle(label: 'Costo del servicio'),
                    const SizedBox(height: 12),
                    CurrencyInputField(
                      label: 'Mano de obra',
                      controller: _laborController,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el costo de mano de obra.';
                        }
                        if ((int.tryParse(value) ?? 0) <= 0) {
                          return 'El monto debe ser mayor que cero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CurrencyInputField(
                      label: 'Materiales',
                      controller: _materialsController,
                      onChanged: (_) => setState(() {}),
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 18),
                    QuotationCostSummary(labor: _labor, materials: _materials),
                    const SizedBox(height: 32),
                    const RequestSectionTitle(
                      label: 'Detalles de la cotización',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Descripción del trabajo',
                        hintText:
                            'Explica qué incluye el servicio y cualquier '
                            'consideración importante.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        if (length == 0) {
                          return 'Describe el trabajo incluido.';
                        }
                        if (length < 20) {
                          return 'La descripción debe tener al menos 20 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const RequestSectionTitle(label: 'Duración estimada'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: QuotationDuration.values.map((option) {
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: _duration == option,
                          onSelected: (_) => setState(() => _duration = option),
                        );
                      }).toList(),
                    ),
                    if (_duration == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Selecciona una duración estimada.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    const RequestSectionTitle(
                      label: '¿Cuándo podrías iniciar?',
                    ),
                    RadioGroup<QuotationStartTiming>(
                      groupValue: _startTiming,
                      onChanged: (value) {
                        setState(() => _startTiming = value!);
                        if (value == QuotationStartTiming.proposedDate) {
                          _selectDate();
                        }
                      },
                      child: Column(
                        children: QuotationStartTiming.values
                            .map(
                              (option) => RadioListTile<QuotationStartTiming>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(option.label),
                                value: option,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    if (_startTiming == QuotationStartTiming.proposedDate) ...[
                      OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _proposedDate?.spanishDate ?? 'Seleccionar fecha',
                        ),
                      ),
                      if (_proposedDate == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Selecciona una fecha propuesta.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 30),
                    const RequestSectionTitle(
                      label: 'Validez de la cotización',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [3, 7, 15, 30].map((days) {
                        return ChoiceChip(
                          label: Text('$days días'),
                          selected: _validityDays == days,
                          onSelected: (_) =>
                              setState(() => _validityDays = days),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                child: FilledButton(
                  onPressed: _review,
                  child: const Text('Revisar cotización'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on DateTime {
  String get spanishDate {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '$day de ${months[month - 1]} de $year';
  }
}
