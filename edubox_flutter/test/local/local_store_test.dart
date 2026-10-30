import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/outbox.dart';
import 'package:edubox_flutter/src/contract/session.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EduBoxDatabase db;
  late CachedDataStore store;
  late FakeBackend fake;

  setUp(() {
    db = EduBoxDatabase.inMemory();
    store = CachedDataStore(db);
    fake = FakeBackend();
  });

  tearDown(() async {
    await fake.dispose();
    await store.close();
  });

  test('session round-trips with role and linked child', () async {
    await fake.auth.signIn(
      email: 'ph.binh@edubox.test',
      password: devPassword,
    );
    await store.saveSession(fake.currentSession!);

    final restored = await store.readSession();
    expect(restored, isNotNull);
    expect(restored!.cachedAt, isNotNull);
    expect(restored.value.signedInEmail, 'ph.binh@edubox.test');
    expect(restored.value.role, UserRole.parent);
    expect(restored.value.profile!.linkedStudentName, 'Nguyễn Minh An');
  });

  test('a not-set-up session round-trips as notSetUp', () async {
    await fake.auth.signIn(
      email: 'chua.co.vai.tro@edubox.test',
      password: devPassword,
    );
    await store.saveSession(fake.currentSession!);

    final restored = await store.readSession();
    expect(restored!.value.isNotSetUp, isTrue);
    expect(restored.value.signedInEmail, 'chua.co.vai.tro@edubox.test');
  });

  test('teacher classes round-trip in order, and an empty cache is distinct '
      'from no cache', () async {
    await fake.auth.signIn(
      email: 'gv.lan@edubox.test',
      password: devPassword,
    );
    final classes = (await fake.classes.mine()).valueOrNull!;
    await store.saveTeacherClasses(classes);

    final restored = await store.readTeacherClasses();
    expect(restored!.cachedAt, isNotNull);
    expect(restored.value.map((item) => item.name), ['7A', '7B', '8A']);
    expect(restored.value.first.subjects, [
      'Toán',
      'Ngữ văn',
      'Khoa học tự nhiên',
    ]);
    expect(restored.value.last.studentCount, 0);

    await store.saveTeacherClasses(const []);
    expect((await store.readTeacherClasses())!.value, isEmpty);

    await store.clearAll();
    expect(await store.readTeacherClasses(), isNull);
  });

  test('student library round-trips classes and items', () async {
    await fake.auth.signIn(
      email: 'hs.an@edubox.test',
      password: devPassword,
    );
    final library = (await fake.library.library()).valueOrNull!;
    await store.saveStudentLibrary(library);

    final restored = await store.readStudentLibrary();
    expect(restored!.cachedAt, isNotNull);
    expect(restored.value.classes.single.name, '7A');
    expect(restored.value.items.map((item) => item.title), [
      'Từ vựng Tiếng Anh 7 - Unit 1',
      'Nội quy lớp học',
      'Tế bào và mô',
      'Luyện tập: Phép cộng phân số',
      'Đọc hiểu văn bản tự sự',
      'Phân số và số thập phân',
    ]);
    expect(restored.value.items.first.type, ContentType.ebook);
  });

  test('parent home round-trips, including a missing linked child', () async {
    await store.saveParentHome(
      const ParentHomeData(linkedStudentName: 'Nguyễn Minh An'),
    );
    expect(
      (await store.readParentHome())!.value.linkedStudentName,
      'Nguyễn Minh An',
    );

    await store.saveParentHome(const ParentHomeData(linkedStudentName: null));
    final restored = await store.readParentHome();
    expect(restored!.value.linkedStudentName, isNull);
    expect(restored.value.hasLinkedChild, isFalse);
  });

  test(
    'outbox preserves order, exposes failed entries and retries them',
    () async {
      final outbox = DriftOutbox(db);
      final first = await outbox.enqueue(
        OutboxWrite(
          operation: 'progress.markComplete',
          payload: const {'contentId': 1},
          createdAt: DateTime.utc(2026, 10, 29, 8),
        ),
      );
      final second = await outbox.enqueue(
        OutboxWrite(
          operation: 'submissions.submit',
          payload: const {'submissionId': 'local-1'},
          createdAt: DateTime.utc(2026, 10, 29, 9),
        ),
      );

      expect((await outbox.pending()).map((write) => write.id), [
        first,
        second,
      ]);
      await outbox.markFailed(first, 'permission denied');

      expect((await outbox.pending()).map((write) => write.id), [second]);
      final failed = (await outbox.all()).first;
      expect(failed.state, OutboxState.failed);
      expect(failed.attempts, 1);
      expect(failed.lastError, 'permission denied');

      await outbox.retry(first);
      expect((await outbox.pending()).map((write) => write.id), [
        first,
        second,
      ]);

      await outbox.markSent(second);
      expect((await outbox.pending()).map((write) => write.id), [first]);
      expect((await outbox.all()), hasLength(1));
    },
  );
}
