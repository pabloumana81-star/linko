import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/providers/professional_profile_management_provider.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';

class ProfessionalProfileEditor extends ConsumerStatefulWidget {
  const ProfessionalProfileEditor({super.key});

  @override
  ConsumerState<ProfessionalProfileEditor> createState() =>
      _ProfessionalProfileEditorState();
}

class _ProfessionalProfileEditorState
    extends ConsumerState<ProfessionalProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final _profession = TextEditingController();
  final _location = TextEditingController();
  final _biography = TextEditingController();
  final _services = TextEditingController();
  final _experienceYears = TextEditingController();
  final _experience = TextEditingController();
  final _coverageArea = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _profession.dispose();
    _location.dispose();
    _biography.dispose();
    _services.dispose();
    _experienceYears.dispose();
    _experience.dispose();
    _coverageArea.dispose();
    super.dispose();
  }

  void _initialize(ProfessionalProfile? profile) {
    if (_initialized) return;
    _initialized = true;
    _profession.text = profile?.profession ?? '';
    _location.text = profile?.location ?? '';
    _biography.text = profile?.biography ?? '';
    _services.text = profile?.services.join(', ') ?? '';
    _experienceYears.text = '${profile?.experienceYears ?? 0}';
    _experience.text = profile?.experienceDescription ?? '';
    _coverageArea.text = profile?.coverageArea ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final services = _services.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      await ref
          .read(professionalProfileManagementProvider)
          .save(
            ProfessionalProfileUpdate(
              profession: _profession.text.trim(),
              location: _location.text.trim(),
              biography: _biography.text.trim(),
              services: services,
              experienceYears: int.parse(_experienceYears.text),
              experienceDescription: _experience.text.trim(),
              coverageArea: _coverageArea.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil profesional actualizado.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos actualizar el perfil profesional.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(ownProfessionalProfileProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text(
        'No pudimos cargar la información profesional.',
        key: ValueKey('professional-editor-error'),
      ),
      data: (value) {
        _initialize(value);
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información profesional',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                value == null
                    ? 'Completa estos datos para crear tu perfil profesional.'
                    : 'Mantén actualizada la información que ven los clientes.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('professional-editor-profession'),
                controller: _profession,
                decoration: const InputDecoration(labelText: 'Profesión'),
                validator: (text) => text == null || text.trim().isEmpty
                    ? 'Ingresa tu profesión.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _biography,
                decoration: const InputDecoration(labelText: 'Biografía'),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('professional-editor-services'),
                controller: _services,
                decoration: const InputDecoration(
                  labelText: 'Servicios',
                  helperText: 'Separa cada servicio con una coma.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experienceYears,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Años de experiencia',
                ),
                validator: (text) {
                  final value = int.tryParse(text ?? '');
                  return value == null || value < 0 || value > 80
                      ? 'Ingresa un valor entre 0 y 80.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experience,
                decoration: const InputDecoration(
                  labelText: 'Descripción de experiencia',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coverageArea,
                decoration: const InputDecoration(
                  labelText: 'Área de cobertura',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Las fotos del portafolio estarán disponibles cuando el almacenamiento seguro esté configurado.',
                key: ValueKey('professional-portfolio-storage-pending'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('save-professional-profile'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
              ),
            ],
          ),
        );
      },
    );
  }
}
