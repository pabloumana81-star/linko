import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/home/presentation/professional_profile_editor.dart';
import 'package:linko/features/home/presentation/providers/professional_profile_management_provider.dart';

void main() {
  Future<void> pumpEditor(
    WidgetTester tester,
    ProfessionalFilePicker picker,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownProfessionalProfileProvider.overrideWith((ref) async => null),
          ownVerificationDocumentsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProfessionalProfileEditor(pickFiles: picker),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('canceling the system picker is a safe no-op on mobile', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      ({required type, required allowedExtensions, required withData}) async =>
          null,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('add-portfolio-image')),
    );
    await tester.tap(find.byKey(const ValueKey('add-portfolio-image')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable system picker shows a controlled Spanish error', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      ({required type, required allowedExtensions, required withData}) async =>
          throw StateError('picker unavailable'),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('add-verification-document')),
    );
    await tester.tap(find.byKey(const ValueKey('add-verification-document')));
    await tester.pump();

    expect(
      find.text('No pudimos abrir el archivo seleccionado.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected files without bytes fail without starting an upload', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      ({required type, required allowedExtensions, required withData}) async =>
          FilePickerResult([PlatformFile(name: 'foto.jpg', size: 12)]),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('add-portfolio-image')),
    );
    await tester.tap(find.byKey(const ValueKey('add-portfolio-image')));
    await tester.pump();

    expect(
      find.text('No pudimos abrir el archivo seleccionado.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('professional-storage-loading')),
      findsNothing,
    );
  });
}
