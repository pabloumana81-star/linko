import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/professional_profile_screen.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'complete Supabase professional data maps from the production RPC',
    () async {
      final client = _client((request) {
        expect(request.url.path, '/rest/v1/rpc/list_available_professionals');
        return http.Response(
          jsonEncode([_completeRow]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);

      final profile = (await SupabaseProfessionalsRepository(
        client,
      ).getProfessionals()).single;

      expect(profile.biography, 'Trabajo residencial y comercial.');
      expect(profile.services, ['Electricidad', 'Domótica']);
      expect(profile.experienceYears, 9);
      expect(
        profile.experienceDescription,
        'Nueve años de experiencia certificada.',
      );
      expect(profile.portfolio, ['https://cdn.example.com/work.jpg']);
      expect(profile.completedJobsCount, 14);
      expect(profile.rating, 4.5);
      expect(profile.reviewCount, 2);
      expect(profile.reviews.single.comment, 'Trabajo real y puntual.');
      expect(profile.coverageArea, 'Gran Área Metropolitana');
      expect(profile.isVerified, isTrue);
    },
  );

  test(
    'professional update persists editable fields through the RPC',
    () async {
      late Map<String, dynamic> body;
      final client = _client((request) {
        expect(
          request.url.path,
          '/rest/v1/rpc/update_own_professional_profile',
        );
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 204, request: request);
      });
      addTearDown(client.dispose);

      await SupabaseProfessionalsRepository(
        client,
      ).updateOwnProfessionalProfile(
        const ProfessionalProfileUpdate(
          profession: 'Electricista',
          location: 'San José',
          biography: 'Perfil persistido',
          services: ['Instalaciones', 'Reparaciones'],
          experienceYears: 7,
          experienceDescription: 'Experiencia residencial',
          coverageArea: 'San José y Heredia',
        ),
      );

      expect(body['p_biography'], 'Perfil persistido');
      expect(body['p_services'], ['Instalaciones', 'Reparaciones']);
      expect(body['p_experience_years'], 7);
      expect(body['p_experience_description'], 'Experiencia residencial');
    },
  );

  test(
    'managed Storage paths and legacy HTTPS portfolio URLs coexist',
    () async {
      final row = Map<String, dynamic>.from(_completeRow)
        ..['portfolio'] = [
          {
            'path': '11111111-1111-1111-1111-111111111111/work.png',
            'name': 'work.png',
            'mime_type': 'image/png',
            'size': 512,
          },
          'https://legacy.example.com/work.jpg',
        ];
      final client = _client(
        (request) => http.Response(
          jsonEncode([row]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      final profile = (await SupabaseProfessionalsRepository(
        client,
      ).getProfessionals()).single;

      expect(profile.portfolio, hasLength(2));
      expect(
        profile.portfolio.first,
        contains('/storage/v1/object/public/professional-portfolio/'),
      );
      expect(profile.portfolio.last, 'https://legacy.example.com/work.jpg');
    },
  );

  test('server rejection prevents unauthorized professional updates', () async {
    final client = _client(
      (request) => http.Response(
        jsonEncode({
          'code': 'P0001',
          'message':
              'Solo un profesional autenticado puede editar este perfil.',
          'details': null,
          'hint': null,
        }),
        403,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    );
    addTearDown(client.dispose);

    expect(
      () =>
          SupabaseProfessionalsRepository(client).updateOwnProfessionalProfile(
            const ProfessionalProfileUpdate(
              profession: 'Electricista',
              location: '',
              biography: '',
              services: [],
              experienceYears: 0,
              experienceDescription: '',
              coverageArea: '',
            ),
          ),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('mock mode keeps profile editing deterministic', () async {
    final repositories = const BackendRepositoryFactory().create(
      config: const BackendConfig(mode: BackendMode.mock),
    );
    await repositories.professionals.updateOwnProfessionalProfile(
      const ProfessionalProfileUpdate(
        profession: 'Técnico mock',
        location: 'Cartago',
        biography: 'Biografía mock editable',
        services: ['Servicio mock'],
        experienceYears: 3,
        experienceDescription: 'Experiencia mock',
        coverageArea: 'Cartago',
      ),
    );

    final profile = await repositories.professionals
        .getOwnProfessionalProfile();
    expect(profile?.profession, 'Técnico mock');
    expect(profile?.biography, 'Biografía mock editable');
    expect(profile?.services, ['Servicio mock']);
  });

  testWidgets('empty production profile shows empty states without demo data', (
    tester,
  ) async {
    await _pumpProfile(tester, _emptyProfile);

    expect(find.byKey(const ValueKey('professional-services-empty')), findsOne);
    expect(
      find.byKey(const ValueKey('professional-portfolio-empty')),
      findsOne,
    );
    expect(find.byKey(const ValueKey('professional-reviews-empty')), findsOne);
    expect(find.text('8 años de experiencia'), findsNothing);
    expect(find.text('Responde en menos de 1 hora'), findsNothing);
    expect(
      find.text('Excelente servicio, muy puntual y profesional.'),
      findsNothing,
    );
  });

  testWidgets('production profile renders real reviews, counts and portfolio', (
    tester,
  ) async {
    await _pumpProfile(tester, _completeProfile);

    expect(find.text('14 servicios completados'), findsOne);
    expect(find.text('Trabajo real y puntual.'), findsOne);
    expect(find.text('Cliente LinkO'), findsOne);
    expect(find.text('Electricidad'), findsOne);
    expect(find.byType(Image), findsOne);
    expect(
      find.text('Excelente servicio, muy puntual y profesional.'),
      findsNothing,
    );
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  ProfessionalProfileData profile,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfessionalProfileScreen(
        professional: profile,
        completedJobsCount: profile.completedJobsCount,
        showMockDetails: false,
        onRequestService: () {},
      ),
    ),
  );
  await tester.pump();
}

SupabaseClient _client(http.Response Function(http.Request) handler) =>
    SupabaseClient(
      'https://profile-production-test.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async => handler(request)),
    );

final _completeRow = <String, dynamic>{
  'id': '11111111-1111-1111-1111-111111111111',
  'display_name': 'Profesional real',
  'avatar_url': 'https://cdn.example.com/avatar.jpg',
  'profession': 'Electricista',
  'rating': 4.5,
  'review_count': 2,
  'location': 'San José',
  'biography': 'Trabajo residencial y comercial.',
  'services': ['Electricidad', 'Domótica'],
  'experience_years': 9,
  'experience_description': 'Nueve años de experiencia certificada.',
  'portfolio': ['https://cdn.example.com/work.jpg'],
  'completed_jobs_count': 14,
  'reviews': [
    {
      'stars': 5,
      'comment': 'Trabajo real y puntual.',
      'created_at': '2026-08-08T12:00:00Z',
    },
  ],
  'coverage_area': 'Gran Área Metropolitana',
  'verification_status': 'verified',
};

const _emptyProfile = ProfessionalProfileData(
  id: 'empty',
  name: 'Perfil vacío',
  profession: 'Profesional',
  rating: 0,
  reviewCount: 0,
  location: '',
  isVerified: true,
);

final _completeProfile = ProfessionalProfileData(
  id: 'complete',
  name: 'Perfil completo',
  profession: 'Electricista',
  rating: 5,
  reviewCount: 1,
  location: 'San José',
  biography: 'Biografía real',
  services: const ['Electricidad'],
  experienceYears: 9,
  experienceDescription: 'Experiencia real',
  portfolio: const ['https://cdn.example.com/work.jpg'],
  completedJobsCount: 14,
  reviews: [
    ProfessionalReviewData(
      stars: 5,
      comment: 'Trabajo real y puntual.',
      createdAt: DateTime.utc(2026, 8, 8),
    ),
  ],
  coverageArea: 'GAM',
  isVerified: true,
);
