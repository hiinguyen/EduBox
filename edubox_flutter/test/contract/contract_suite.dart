import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contract every [EduBoxBackend] must satisfy.
///
/// Phase 1 runs it against [FakeBackend]; phase 5 imports the same function
/// and passes the generated-client binding, so the screen code and the tests
/// do not change when the real server arrives.
typedef BackendFactory = Future<EduBoxBackend> Function();

void runBackendContractTests({
  required String name,
  required BackendFactory createBackend,
}) {
  group(name, () {
    late EduBoxBackend backend;

    setUp(() async => backend = await createBackend());
    tearDown(() => backend.dispose());

    Future<AuthSession> signInAs(String key) async {
      final account = FixtureSet.phase1().account(key);
      final result = await backend.auth.signIn(
        email: account.email,
        password: devPassword,
      );
      expect(result.isOk, isTrue, reason: 'sign-in failed for $key: $result');
      return result.valueOrNull!;
    }

    test('student signs in, resolves the student role, and reads the library '
        'with exactly the approved fixture content', () async {
      final session = await signInAs(FixtureKeys.studentAn);
      expect(session.isReady, isTrue);
      expect(session.role, UserRole.student);
      expect(session.profile!.name, 'Nguyễn Minh An');
      expect(session.profile!.email, 'hs.an@edubox.test');

      final me = await backend.profile.me();
      expect(me.valueOrNull!.status, ProfileStatus.ready);
      expect(me.valueOrNull!.profile!.role, UserRole.student);

      final library = await backend.library.library();
      expect(library.isOk, isTrue);
      final expected = FixtureSet.phase1().libraryOfStudent(
        FixtureKeys.studentAn,
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title).toList(),
        expected.map((item) => item.title).toList(),
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title),
        isNot(contains('Bản nháp: Hình học chương 2')),
      );
      expect(
        library.valueOrNull!.items.map((item) => item.title),
        isNot(contains(defaultOtherClassTitle)),
      );
      expect(library.valueOrNull!.classes.single.name, '7A');
      expect(library.valueOrNull!.classes.single.subjects, [
        'Toán',
        'Ngữ văn',
        'Khoa học tự nhiên',
      ]);
    });

    test('teacher signs in and sees only their own classes', () async {
      final session = await signInAs(FixtureKeys.teacherLan);
      expect(session.role, UserRole.teacher);

      final result = await backend.classes.mine();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.map((item) => item.name), ['7A', '7B', '8A']);
      expect(result.valueOrNull!.first.subjects, [
        'Toán',
        'Ngữ văn',
        'Khoa học tự nhiên',
      ]);
      expect(
        result.valueOrNull!.map((item) => item.name),
        isNot(contains('9A')),
      );
    });

    test('parent signs in and reads the linked child name', () async {
      final session = await signInAs(FixtureKeys.parentBinh);
      expect(session.role, UserRole.parent);
      expect(session.linkedStudentName, 'Nguyễn Minh An');

      final result = await backend.parent.home();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.linkedStudentName, 'Nguyễn Minh An');
      expect(result.valueOrNull!.hasLinkedChild, isTrue);
    });

    test('an auth user without a profile resolves to notSetUp', () async {
      final session = await signInAs(FixtureKeys.noProfile);
      expect(session.isReady, isFalse);
      expect(session.status, ProfileStatus.notSetUp);
      expect(session.signedInEmail, 'chua.thiet.lap@edubox.test');

      final me = await backend.profile.me();
      expect(me.isOk, isTrue);
      expect(me.valueOrNull!.status, ProfileStatus.notSetUp);
      expect(me.valueOrNull!.profile, isNull);
    });

    test('a user with a null role resolves to notSetUp', () async {
      final session = await signInAs(FixtureKeys.nullRole);
      expect(session.isReady, isFalse);
      expect(session.status, ProfileStatus.notSetUp);
    });

    test(
      'wrong credentials are typed and reveal no account existence',
      () async {
        final wrongPassword = await backend.auth.signIn(
          email: 'hs.an@edubox.test',
          password: 'not-the-password',
        );
        final unknownEmail = await backend.auth.signIn(
          email: 'nobody@edubox.test',
          password: devPassword,
        );
        expect(wrongPassword.errorOrNull, isA<WrongCredentialsError>());
        expect(unknownEmail.errorOrNull, isA<WrongCredentialsError>());
      },
    );

    test('every role method denies a wrong role', () async {
      await signInAs(FixtureKeys.studentAn);
      expect(
        (await backend.classes.mine()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<PermissionDeniedError>(),
      );

      await backend.auth.signOut();
      await signInAs(FixtureKeys.teacherLan);
      expect(
        (await backend.library.library()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
    });

    test('unauthenticated calls are denied', () async {
      expect(
        (await backend.profile.me()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.classes.mine()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.library.library()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
      expect(
        (await backend.parent.home()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
    });

    test('restoreSession returns null when nothing is stored', () async {
      final result = await backend.auth.restoreSession();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('signOut clears the session', () async {
      await signInAs(FixtureKeys.studentAn);
      final result = await backend.auth.signOut();
      expect(result.isOk, isTrue);
      expect(
        (await backend.library.library()).errorOrNull,
        isA<PermissionDeniedError>(),
      );
    });

    test('pingStream emits three messages with the caller role', () async {
      final session = await signInAs(FixtureKeys.studentAn);
      final messages = await backend.diagnostics.pingStream().toList();
      expect(messages, hasLength(3));
      expect(messages.map((message) => message.sequence), [1, 2, 3]);
      expect(
        messages.every((message) => message.role == session.role),
        isTrue,
      );
      expect(messages.every((message) => message.total == 3), isTrue);
    });
  });
}

/// The title of the fixture approved for another teacher's class.
const defaultOtherClassTitle = 'Chuyển động cơ học';
