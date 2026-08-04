import 'package:linko/features/requests/domain/models/app_user.dart';

class ProfessionalProfile {
  const ProfessionalProfile({
    required this.id,
    required this.user,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.location,
    this.isVerified = false,
  });

  final String id;
  final AppUser user;
  final String profession;
  final double rating;
  final int reviewCount;
  final String location;
  final bool isVerified;
}
