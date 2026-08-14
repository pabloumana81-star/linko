import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/home/presentation/mode_profile_screen.dart';
import 'package:linko/features/home/presentation/providers/customer_profile_provider.dart';

void main() {
  testWidgets('customer profile renders the authenticated route snapshot', (
    tester,
  ) async {
    final stream = StreamController<AppUserProfile?>.broadcast(sync: true);
    addTearDown(stream.close);

    await _pumpProfile(tester, stream: stream.stream);

    expect(find.text('Cliente sesión existente'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'refresh and provider invalidation keep profile content visible',
    (tester) async {
      final streams = <StreamController<AppUserProfile?>>[];
      var providerBuilds = 0;
      Stream<AppUserProfile?> provider(Ref ref) {
        providerBuilds++;
        final stream = StreamController<AppUserProfile?>.broadcast(sync: true);
        streams.add(stream);
        return stream.stream;
      }

      await _pumpProfile(tester, provider: provider);
      streams.single.add(
        _profile.copyWith(
          displayName: 'Cliente actualizado',
          updatedAt: _profile.updatedAt.add(const Duration(seconds: 1)),
        ),
      );
      await tester.pump();
      expect(find.text('Cliente actualizado'), findsOneWidget);

      final context = tester.element(find.byType(ModeProfileScreen));
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(customerProfileProvider);
      await tester.pump();

      expect(providerBuilds, 2);
      expect(find.text('Cliente actualizado'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      for (final stream in streams) {
        await stream.close();
      }
    },
  );

  testWidgets('customer profile failure shows retry and navigation', (
    tester,
  ) async {
    var attempts = 0;
    Stream<AppUserProfile?> provider(Ref ref) {
      attempts++;
      return Stream<AppUserProfile?>.error(StateError('Supabase unavailable'));
    }

    await _pumpProfile(tester, provider: provider);
    await tester.pump();

    expect(find.text('No pudimos cargar tu perfil.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(attempts, 2);
  });

  testWidgets('missing customer profile shows a controlled state', (
    tester,
  ) async {
    await _pumpProfile(tester, stream: Stream<AppUserProfile?>.value(null));
    await tester.pump();

    expect(find.text('No encontramos tu perfil de cliente.'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
  });

  testWidgets('resume refreshes once while retaining the profile snapshot', (
    tester,
  ) async {
    var providerBuilds = 0;
    final streams = <StreamController<AppUserProfile?>>[];
    Stream<AppUserProfile?> provider(Ref ref) {
      providerBuilds++;
      final stream = StreamController<AppUserProfile?>.broadcast(sync: true);
      streams.add(stream);
      return stream.stream;
    }

    await _pumpProfile(tester, provider: provider);

    final state = tester.state(find.byType(ModeProfileScreen)) as dynamic;
    state.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(providerBuilds, 2);
    expect(find.text('Cliente sesión existente'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    for (final stream in streams) {
      await stream.close();
    }
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  Stream<AppUserProfile?>? stream,
  Stream<AppUserProfile?> Function(Ref ref)? provider,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerProfileProvider.overrideWith(
          provider ?? (ref) => stream ?? const Stream.empty(),
        ),
      ],
      child: MaterialApp(
        home: ModeProfileScreen(
          mode: AppMode.customer,
          profileSnapshot: _profile,
          onChangeMode: () {},
          onHomeSelected: () {},
          onRequestsSelected: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

final _profile = AppUserProfile(
  id: 'customer-profile',
  displayName: 'Cliente sesión existente',
  email: 'cliente@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  createdAt: DateTime.utc(2026, 8, 12),
);
