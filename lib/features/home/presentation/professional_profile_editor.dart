import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
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
  bool _storageBusy = false;

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

  Future<void> _pickPortfolioImage() async {
    final file = await _pickFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return;
    await _runStorageAction(
      () =>
          ref.read(professionalProfileManagementProvider).uploadPortfolio(file),
      success: 'Imagen agregada al portafolio.',
    );
  }

  Future<void> _pickVerificationDocument() async {
    final file = await _pickFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (file == null) return;
    await _runStorageAction(
      () => ref
          .read(professionalProfileManagementProvider)
          .uploadVerification(file),
      success: 'Documento de verificación agregado.',
    );
  }

  Future<ProfessionalUploadFile?> _pickFile({
    required List<String> allowedExtensions,
  }) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    final selected = selection?.files.single;
    final bytes = selected?.bytes;
    if (selected == null || bytes == null) return null;
    return ProfessionalUploadFile(
      name: selected.name,
      mimeType: _mimeType(selected.extension),
      bytes: Uint8List.fromList(bytes),
    );
  }

  Future<void> _runStorageAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _storageBusy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos completar la operación con el archivo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _storageBusy = false);
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
              const SizedBox(height: 20),
              if (_storageBusy) ...[
                const LinearProgressIndicator(
                  key: ValueKey('professional-storage-loading'),
                ),
                const SizedBox(height: 12),
              ],
              _PortfolioEditor(
                images: value?.portfolio ?? const [],
                busy: _storageBusy,
                onAdd: _pickPortfolioImage,
                onDelete: (url) => _runStorageAction(
                  () => ref
                      .read(professionalProfileManagementProvider)
                      .deletePortfolio(url),
                  success: 'Imagen eliminada del portafolio.',
                ),
              ),
              const SizedBox(height: 20),
              _VerificationDocumentsEditor(
                documents: ref.watch(ownVerificationDocumentsProvider),
                busy: _storageBusy,
                onAdd: _pickVerificationDocument,
                onDelete: (path) => _runStorageAction(
                  () => ref
                      .read(professionalProfileManagementProvider)
                      .deleteVerification(path),
                  success: 'Documento de verificación eliminado.',
                ),
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

String _mimeType(String? extension) => switch (extension?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  'pdf' => 'application/pdf',
  _ => 'application/octet-stream',
};

class _PortfolioEditor extends StatelessWidget {
  const _PortfolioEditor({
    required this.images,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  final List<String> images;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Portafolio', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text(
        images.isEmpty
            ? 'Aún no has agregado imágenes.'
            : 'Tus imágenes públicas.',
      ),
      if (images.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final image in images)
              Stack(
                children: [
                  SizedBox(
                    width: 112,
                    height: 88,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE6E8EC),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton.filledTonal(
                      key: ValueKey('delete-portfolio-$image'),
                      tooltip: 'Eliminar imagen',
                      onPressed: busy ? null : () => onDelete(image),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey('add-portfolio-image'),
        onPressed: busy ? null : onAdd,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Agregar imagen'),
      ),
      const Text('JPG, PNG o WebP. Máximo 5 MB.'),
    ],
  );
}

class _VerificationDocumentsEditor extends StatelessWidget {
  const _VerificationDocumentsEditor({
    required this.documents,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  final AsyncValue<List<ProfessionalVerificationDocument>> documents;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Documentos de verificación',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 6),
      const Text(
        'Son privados y solo tú y el equipo administrador pueden consultarlos.',
      ),
      documents.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('No pudimos cargar tus documentos.'),
        data: (items) => Column(
          children: [
            if (items.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Aún no has agregado documentos.'),
              ),
            for (final document in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  document.mimeType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(document.name),
                subtitle: Text(
                  document.path == null
                      ? 'Referencia heredada; archivo no administrado por LinkO.'
                      : '${(document.size / 1024).ceil()} KB',
                ),
                trailing: IconButton(
                  key: ValueKey(
                    'delete-verification-${document.path ?? document.name}',
                  ),
                  tooltip: 'Eliminar documento',
                  onPressed: busy || document.path == null
                      ? null
                      : () => onDelete(document.path!),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
          ],
        ),
      ),
      OutlinedButton.icon(
        key: const ValueKey('add-verification-document'),
        onPressed: busy ? null : onAdd,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Agregar documento'),
      ),
      const Text('JPG, PNG, WebP o PDF. Máximo 10 MB.'),
    ],
  );
}
