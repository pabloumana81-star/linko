import 'dart:typed_data';

import 'package:linko/features/requests/domain/models/professional_profile.dart';

class ProfessionalUploadFile {
  const ProfessionalUploadFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class ProfessionalVerificationDocument {
  const ProfessionalVerificationDocument({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
  });
  final String? path;
  final String name;
  final String mimeType;
  final int size;
}

class ProfessionalStorageRules {
  const ProfessionalStorageRules._();
  static const portfolioMaxBytes = 5 * 1024 * 1024;
  static const verificationMaxBytes = 10 * 1024 * 1024;
  static const portfolioMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};
  static const verificationMimeTypes = {
    ...portfolioMimeTypes,
    'application/pdf',
  };

  static void validatePortfolio(ProfessionalUploadFile file) =>
      _validate(file, allowed: portfolioMimeTypes, maxBytes: portfolioMaxBytes);
  static void validateVerification(ProfessionalUploadFile file) => _validate(
    file,
    allowed: verificationMimeTypes,
    maxBytes: verificationMaxBytes,
  );
  static void _validate(
    ProfessionalUploadFile file, {
    required Set<String> allowed,
    required int maxBytes,
  }) {
    if (!allowed.contains(file.mimeType)) {
      throw ArgumentError('El tipo de archivo no está permitido.');
    }
    if (file.bytes.isEmpty || file.bytes.length > maxBytes) {
      throw ArgumentError('El archivo supera el tamaño permitido.');
    }
  }
}

abstract interface class ProfessionalsRepository {
  Future<List<ProfessionalProfile>> getProfessionals();
  Future<ProfessionalProfile?> getProfessionalById(String professionalId);
  Future<ProfessionalProfile?> getOwnProfessionalProfile();
  Future<void> updateOwnProfessionalProfile(ProfessionalProfileUpdate update);
  Future<void> uploadOwnPortfolioImage(ProfessionalUploadFile file);
  Future<void> deleteOwnPortfolioImage(String imageUrl);
  Future<List<ProfessionalVerificationDocument>> getOwnVerificationDocuments();
  Future<void> uploadOwnVerificationDocument(ProfessionalUploadFile file);
  Future<void> deleteOwnVerificationDocument(String objectPath);
  Stream<List<ProfessionalProfile>> watchProfessionals();
}
