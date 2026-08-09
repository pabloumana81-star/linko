import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';

void main() {
  group('reglas de archivos profesionales', () {
    test('acepta imágenes de portafolio válidas', () {
      expect(
        () => ProfessionalStorageRules.validatePortfolio(
          ProfessionalUploadFile(
            name: 'trabajo.webp',
            mimeType: 'image/webp',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ),
        returnsNormally,
      );
    });

    test('rechaza tipos y tamaños no permitidos', () {
      expect(
        () => ProfessionalStorageRules.validatePortfolio(
          ProfessionalUploadFile(
            name: 'archivo.pdf',
            mimeType: 'application/pdf',
            bytes: Uint8List.fromList([1]),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => ProfessionalStorageRules.validateVerification(
          ProfessionalUploadFile(
            name: 'grande.pdf',
            mimeType: 'application/pdf',
            bytes: Uint8List(ProfessionalStorageRules.verificationMaxBytes + 1),
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('almacenamiento profesional mock', () {
    late MockProfessionalsRepository repository;

    setUp(() {
      repository = MockProfessionalsRepository(MockRequestRepository());
    });

    test('agrega y elimina portafolio de forma determinista', () async {
      await repository.uploadOwnPortfolioImage(
        ProfessionalUploadFile(
          name: 'cocina.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final profile = await repository.getOwnProfessionalProfile();
      expect(profile?.portfolio, ['https://mock.linko/portfolio/1.png']);

      await repository.deleteOwnPortfolioImage(profile!.portfolio.single);
      expect(
        (await repository.getOwnProfessionalProfile())?.portfolio,
        isEmpty,
      );
    });

    test('agrega y elimina documentos privados sin URLs públicas', () async {
      await repository.uploadOwnVerificationDocument(
        ProfessionalUploadFile(
          name: 'identidad.pdf',
          mimeType: 'application/pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final documents = await repository.getOwnVerificationDocuments();
      expect(documents, hasLength(1));
      expect(documents.single.name, 'identidad.pdf');
      expect(documents.single.path, 'mock-professional/1.pdf');
      expect(documents.single.path, isNot(startsWith('http')));

      await repository.deleteOwnVerificationDocument(documents.single.path!);
      expect(await repository.getOwnVerificationDocuments(), isEmpty);
    });
  });

  test('la migración separa portafolio público y verificación privada', () {
    final migration = File(
      'supabase/migrations/202608100001_production_professional_storage.sql',
    ).readAsStringSync();

    expect(migration, contains("'professional-portfolio'"));
    expect(migration, contains("'professional-verification'"));
    expect(migration, contains('true,\n  5242880'));
    expect(migration, contains('false,\n  10485760'));
    expect(migration, contains('Admins read verification files'));
    expect(migration, contains('Professionals read own verification files'));
    expect(migration, contains('(storage.foldername(name))[1]'));
    expect(migration, isNot(contains('service_role')));

    final enforcement = File(
      'supabase/migrations/202608100002_enforce_storage_metadata.sql',
    ).readAsStringSync();
    expect(enforcement, contains('validate_professional_portfolio_storage'));
    expect(enforcement, contains('validate_professional_verification_storage'));
    expect(
      enforcement,
      contains("object.bucket_id = 'professional-portfolio'"),
    );
    expect(
      enforcement,
      contains("object.bucket_id = 'professional-verification'"),
    );
    expect(enforcement, contains('object.owner_id = new.id::text'));
    expect(
      enforcement,
      contains('Una verificación aprobada no puede modificarse.'),
    );
  });
}
