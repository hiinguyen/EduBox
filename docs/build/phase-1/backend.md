# EduBox Phase 1 Backend Track Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.
> The executor is the opencode CLI on DeepSeek; every task below is self-contained and carries its full code, commands, expected output and commit.

**Spec:** `docs/superpowers/specs/2026-10-29-edubox-phase1-prototype-design.md` (outranks everything else).

**Contract:** `docs/build/phase-1/contract.md` at tag `phase-1-contract-v1` (commit `52d6d3c`).

**Goal:** Land every backend-track deliverable of phase 1: the MinIO object store, the seed steps, the seed CLI and its image target, and the two carried LOW items, so that no `backend-pending` test remains and the server gate passes.

**Architecture:** `S3ObjectStore` wraps `serverpod_cloud_storage_s3_compat` 4.0.4 against MinIO with path-style addressing, plus a second offline signer for the public host and a small ListObjectsV2 loop for `deletePrefix`.
`runSeedStep` empties the reset tables, empties the e2e bucket through `ObjectStore.deletePrefix`, and reloads the shared fixtures through the contract's `FixtureLoader`; the delta steps are idempotent.
`bin/seed.dart` builds a Serverpod instance without starting the API server, runs one step, and exits 0, 1 or 64; the server image compiles it next to `bin/server`.

**Tech stack:** Dart 3.12 / Serverpod 4.0.4, `serverpod_cloud_storage_s3_compat` 4.0.4, `http` 1.6.0, `xml` 7.0.1, `args` 2.7.0, PostgreSQL 16 and MinIO (`pgsty/minio:RELEASE.2026-08-04T00-00-00Z`) through Docker Compose.

**Verification provenance:** every code block in this plan was written into a scratch copy of the repo at `52d6d3c` on 2026-10-30 and passed `dart format`, `dart analyze --fatal-infos` and `dart test` there (96 tests, 0 skipped, authorization coverage 95.5%).
The storage code was run against the compose MinIO, the seed CLI against a throwaway database on `postgres_test`, and the Dockerfile change by building the image and running `./bin/seed` from it.
If a step's real output differs from the expected output written here, stop and report `BLOCKED: <task>/<step>: <output>` instead of improvising.

## Global constraints

Every task implicitly includes this section.

- Work in `/home/hii/Documents/EduBox` on branch `phase-1`.
  Run `git branch --show-current` first; expected `phase-1`.
- Toolchain for every shell: `export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"`.
- Serverpod and every `serverpod*` package stay at exactly `4.0.4`.
  Never downgrade or bump a pin in any `pubspec.yaml`, and never hand-edit `pubspec.lock`; run `dart pub get` at the repo root and commit the lock only if it changed.
- Do not run `serverpod generate` or `serverpod create-migration` (except the read-only diff check in Task 7): no task changes a model, table or endpoint signature.
- Path ownership (contract section 6).
  The backend track may edit only: the body of `S3ObjectStore` and its imports in `edubox_server/lib/src/storage/object_store.dart` (the `ObjectStore` interface and `ObjectNotFoundException` stay byte-identical), `edubox_server/lib/src/seed/seed_command.dart` (the `SeedStep` enum and `seedResetTables` stay byte-identical), `edubox_server/bin/seed.dart`, the build stage of `edubox_server/Dockerfile` (never the `ENTRYPOINT`/`CMD` section), the `dependencies` of `edubox_server/pubspec.yaml`, `edubox_server/test/integration/storage/**`, `edubox_server/test/integration/seed/**`, and the root `pubspec.lock` (regenerated only).
  Task 5 alone may edit `tool/bootstrap.sh`; Task 6 alone may edit `edubox_server/test/integration/e2e/e2e_control_test.dart`.
  Every other path is read-only, including `lib/src/generated/**`, `lib/src/e2e/**`, `lib/src/authz/**`, `lib/server.dart`, `bin/main.dart`, `config/**`, `dart_test.yaml`, `compose.yaml`, `.github/**`, `edubox_fixtures/**` and `docs/**`.
- Secrets: never stage or commit `edubox_server/config/passwords.yaml` or `skills-lock.json`.
  Stage only the exact paths a task lists with `git add <path> ...`; never use `git add -A`, `git add .` or `git commit -a`.
  Before each commit, `git status --short` must show only the task's paths plus the untracked `?? skills-lock.json`.
- Docker safety: allowed commands are `docker compose up -d --wait <services>`, `docker compose --profile e2e up -d --build --wait`, `docker compose --profile tools build seed`, `docker compose run --rm <service> ...`, `docker compose exec -T <service> ...` and `docker compose --profile e2e stop server`.
  Forbidden: any `docker ... prune`, `docker rm`/`docker rmi` of a container or image this task did not create, `docker compose down -v`, `docker volume rm`, and dropping any database other than the throwaway `edubox_seed_cli_check` of Task 3.
- Tests are never weakened: do not add `skip`, tags or `@Skip`, do not loosen an existing `expect`, and do not delete an existing test.
- Text: never type the em dash character; use a plain `-`.
- Commits use the conventional format `<type>: <description>` with no attribution trailer.

### The verification gate (run at the end of every task)

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
cd /home/hii/Documents/EduBox
bash tool/bootstrap.sh
docker compose up -d --wait postgres_test minio
docker compose run --rm minio-init
(cd edubox_fixtures && dart test)
(cd edubox_server && dart format --output=none --set-exit-if-changed .)
(cd edubox_server && dart analyze --fatal-infos)
(cd edubox_server && dart test --coverage=coverage \
  && dart run coverage:format_coverage --lcov --in=coverage \
     --out=coverage/lcov.info --report-on=lib \
  && dart run ../tool/coverage_gate.dart coverage/lcov.info)
```

Expected:

- `bootstrap: ... exists, left unchanged` and exit 0.
- `docker compose up` ends with `postgres_test-1 Healthy` and `minio-1 Healthy`; `minio-init` prints `Bucket created successfully` or `Your previous request to create the named bucket succeeded` lines and `Access permission ... is set to private` for `edubox-dev`, `edubox-test` and `edubox-e2e`.
- `edubox_fixtures`: `All tests passed!`.
- `dart format`: `Formatted N files (0 changed)` and exit 0.
  If it reports changed files, run `(cd edubox_server && dart format .)`, inspect `git diff`, and include only formatting of this task's files.
- `dart analyze`: `No issues found!`.
- `dart test`: last line `All tests passed!`.
- Coverage gate: `coverage gate: authorization 9x.x% (.../... lines) PASS` (at least 80.0%) and `skipped (no source directory)` for grading, rate-limit and lockout; exit 0.

### Exit-criteria map (roadmap phase 1)

| Criterion | Backend deliverable | Task |
| --- | --- | --- |
| 10 storage spike | `S3ObjectStore` against MinIO; signed URL on the public host; unsigned read denied; expiry; `deletePrefix` | 1 |
| 1-7, 9 (E2E) | seeded fixtures through `e2e.run(step: 'reset')` and the delta steps, which call `runSeedStep` and `S3ObjectStore.deletePrefix` | 1, 2, 4 |
| Contract 2.5/2.6 seed stubs | `runSeedStep`, `bin/seed`, Dockerfile seed target, compose `seed` service runnable | 2, 3, 4 |
| 3 (server part), 11, 12, 13, 14 | already implemented at the contract tag; re-proven by the gate | 7 |
| 16 | server lint/test/coverage from a clean clone; compose seed and `e2e.run` proven on the real stack | 4, 7 |
| Carried LOW: bootstrap missing keys | `tool/bootstrap.sh` lists example keys missing from `passwords.yaml` and exits 1 | 5 |
| Carried LOW: `E2eEndpoint.authorize` production test | direct test with a hand-built enabled config | 6 |
| 8, 15, 17 | frontend track only | - |

---

### Task 1: S3ObjectStore against MinIO (exit criterion 10)

**Routing signal:** risky (storage).

**Files:**

- Modify: `edubox_server/pubspec.yaml` (add `http` and `xml` to `dependencies`)
- Modify: `pubspec.lock` (only if `dart pub get` changes it)
- Modify: `edubox_server/lib/src/storage/object_store.dart` (imports and the `S3ObjectStore` class only)
- Modify: `edubox_server/test/integration/storage/object_store_test.dart` (remove the `backend-pending` tag, add five tests)

**Interfaces:**

- Consumes: `StorageConfig { Uri endpoint; Uri publicEndpoint; String bucket; String region; }` from `edubox_server/lib/src/config/edubox_config.dart`; the frozen `ObjectStore` interface and `ObjectNotFoundException(String path)` in `object_store.dart`.
- Produces: `S3ObjectStore({required StorageConfig config, required String accessKey, required String secretKey})` (constructor unchanged) implementing `put`, `get`, `signedGetUrl`, `deletePrefix`; `static const Duration maxSignedUrlLifetime = Duration(days: 7)`.
  Behaviour later tasks rely on: `deletePrefix(session, '')` empties the whole bucket; `get` of a missing key throws `ObjectNotFoundException`; an invalid key (empty, leading or trailing `/`, empty, `.` or `..` segment) throws `ArgumentError`; `signedGetUrl` throws `ArgumentError` outside 1 second to 7 days and never contacts the network.

**API facts (checked in `~/.pub-cache/hosted/pub.dev/`, do not guess others):**

- `serverpod_cloud_storage_s3_compat-4.0.4/lib/src/client/s3_client.dart`: `S3Client({required String accessKey, required String secretKey, required String bucket, required String region, required S3EndpointConfig endpoints, http.Client? httpClient})`; methods `getObject(key)`, `headObject(key)`, `deleteObject(key)` (each returns `Future<http.Response>`), `Uri buildPresignedUri({required String key, required String method, required Duration expiration, Map<String, String> queryParams})` (pure computation, throws `CloudStorageException` outside 1..604800 seconds), `SignedRequestParams buildSignedParams({required String key, Map<String, String>? queryParams, String method = 'GET'})` (returns `.uri` and `.headers`), and `void checkResponseError(http.Response)` (throws `NoPermissionsException` on 403, `S3Exception` on other non-2xx).
  It has no PUT and no list method, which is why listing uses `buildSignedParams` plus our own `http.Client`.
- `.../lib/src/s3_compat_cloud_storage.dart`: `S3CompatCloudStorage({required String storageId, required String accessKey, required String secretKey, required String bucket, required String region, required bool public, required S3EndpointConfig endpoints, required S3UploadStrategy uploadStrategy, S3Client? client})`; `storeFile({required Session session, required String path, required ByteData byteData, StoreFileOptions options})`; `retrieveFile({session, path})` throws `CloudStorageFileNotFoundException` on 404.
  Its `temporaryDownloadUrl` signs for the internal endpoint and does a HEAD first, so it is not used; the public signer is a second `S3Client`.
- `.../lib/src/config/custom_endpoint_config.dart`: `CustomEndpointConfig({required Uri baseUri, String serviceName})`; `buildBucketUri` returns `<baseUri>/<bucket>` (path-style, what MinIO needs).
- `.../lib/src/upload/presigned_put_strategy.dart`: `PresignedPutUploadStrategy()` sends a SigV4-signed `PUT` with the payload SHA-256.
  `MultipartPostUploadStrategy` is not used because it sends an `acl` form field.
- `serverpod-4.0.4/lib/src/cloud_storage/cloud_storage.dart`: `StoreFileOptions({DateTime? expiration, bool preventOverwrite = false, FileMetadata metadata})`, `FileMetadata({String? contentType, ...})`; both exported by `package:serverpod/serverpod.dart`, as is `CloudStorageFileNotFoundException`.
- `amazon_cognito_identity_dart_2-3.8.2/lib/sig_v4.dart` `buildCanonicalQueryString` encodes `/` in a query value as `%2F`, which MinIO accepts for `prefix=`.
- `xml-7.0.1/lib/src/xml/extensions/find.dart`: `findAllElements(name, namespaceUri: '*')` matches the local name in any namespace (the S3 list XML uses a default namespace); `innerText` is `XmlStringExtension` in `.../extensions/string.dart`.
- Proven against the compose MinIO on 2026-10-30: PUT, GET, 404 mapping, presigned GET on `127.0.0.1:9000` (200), unsigned GET (403), ListObjectsV2 at `/<bucket>/?list-type=2&max-keys=1000&prefix=...`, DELETE (204, also 204 for a missing key), and keys with spaces and Vietnamese letters.

- [ ] **Step 1: Start the services the test needs**

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
cd /home/hii/Documents/EduBox
git branch --show-current
bash tool/bootstrap.sh
docker compose up -d --wait postgres_test minio
docker compose run --rm minio-init
```

Expected: `phase-1`, then both services `Healthy`, then the three buckets reported private.

- [ ] **Step 2: Add the dependencies**

In `edubox_server/pubspec.yaml`, replace the whole `dependencies:` block with exactly this (keep `dev_dependencies` unchanged):

```yaml
dependencies:
  crypto: ^3.0.6
  edubox_fixtures:
    path: ../edubox_fixtures
  http: ^1.6.0
  serverpod: 4.0.4
  serverpod_auth_idp_server: 4.0.4
  serverpod_cloud_storage_s3_compat: 4.0.4
  xml: ^7.0.1
  yaml: ^3.1.3
```

Then run:

```sh
cd /home/hii/Documents/EduBox && dart pub get && git status --short pubspec.lock
```

Expected: `Got dependencies!` (or `Resolving dependencies... Got dependencies!`), and most likely no output from `git status` because both packages are already locked transitively (`http 1.6.0`, `xml 7.0.1`).

- [ ] **Step 3: Write the failing tests**

Replace the whole content of `edubox_server/test/integration/storage/object_store_test.dart` with:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/storage/object_store.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Exit criterion 10: store, read back, sign a URL for the configured public
/// host, and prove unsigned and expired access are denied.
///
/// Needs MinIO and the `edubox-test` bucket:
/// `docker compose up -d --wait minio && docker compose run --rm minio-init`.
void main() {
  withServerpod('Object storage spike (MinIO)', (sessionBuilder, endpoints) {
    // Deliberately distinct hosts: signing must use the public endpoint, not
    // the internal one the server talks to.
    final config = StorageConfig(
      endpoint: Uri.parse('http://localhost:9000'),
      publicEndpoint: Uri.parse('http://127.0.0.1:9000'),
      bucket: 'edubox-test',
      region: 'us-east-1',
    );
    final store = S3ObjectStore(
      config: config,
      accessKey: 'edubox-dev',
      secretKey: 'dev-only-minio-password',
    );

    Future<ByteData> fetch(Uri uri) async {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(uri)).close();
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        }
        final bytes = await response.fold<List<int>>(
          <int>[],
          (all, chunk) => all..addAll(chunk),
        );
        return ByteData.sublistView(Uint8List.fromList(bytes));
      } finally {
        client.close(force: true);
      }
    }

    Future<int> status(Uri uri) async {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(uri)).close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        client.close(force: true);
      }
    }

    test('puts, reads back byte-identical, signs for the public host, and '
        'denies unsigned reads', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      const path = 'spike/hello.bin';

      await store.put(
        session,
        path,
        bytes,
        contentType: 'application/octet-stream',
      );
      final read = await store.get(session, path);
      expect(read.buffer.asUint8List(), bytes.buffer.asUint8List());

      final signed = await store.signedGetUrl(session, path);
      expect(signed.host, config.publicEndpoint.host);
      expect(signed.port, config.publicEndpoint.port);
      final signedBytes = await fetch(signed);
      expect(signedBytes.buffer.asUint8List(), bytes.buffer.asUint8List());

      expect(
        await status(
          Uri.parse('http://localhost:9000/${config.bucket}/$path'),
        ),
        anyOf(401, 403, 404),
      );
    });

    test('a short signed URL expires', () async {
      final session = sessionBuilder.build();
      const path = 'spike/expiring.bin';
      await store.put(
        session,
        path,
        ByteData.sublistView(Uint8List.fromList([9])),
      );

      final signed = await store.signedGetUrl(
        session,
        path,
        expiresIn: const Duration(seconds: 1),
      );
      expect(signed.queryParameters['X-Amz-Expires'], '1');
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(await status(signed), anyOf(401, 403));
    });

    test('deletePrefix removes only the matching objects', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([7]));
      await store.put(session, 'prefix/a.bin', bytes);
      await store.put(session, 'prefix/b.bin', bytes);
      await store.put(session, 'keep/c.bin', bytes);

      await store.deletePrefix(session, 'prefix/');

      await expectLater(
        store.get(session, 'prefix/a.bin'),
        throwsA(isA<ObjectNotFoundException>()),
      );
      await expectLater(
        store.get(session, 'prefix/b.bin'),
        throwsA(isA<ObjectNotFoundException>()),
      );
      expect(
        (await store.get(session, 'keep/c.bin')).buffer.asUint8List(),
        bytes.buffer.asUint8List(),
      );
      await store.deletePrefix(session, 'keep/');
    });
    test('get of a missing object throws ObjectNotFoundException', () async {
      final session = sessionBuilder.build();
      await expectLater(
        store.get(session, 'spike/does-not-exist.bin'),
        throwsA(
          isA<ObjectNotFoundException>().having(
            (error) => error.path,
            'path',
            'spike/does-not-exist.bin',
          ),
        ),
      );
    });

    test('keys with spaces and Vietnamese letters round-trip and are '
        'removed by deletePrefix', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([4, 2]));
      const path = 'unicode/bài tập ữ.bin';
      await store.put(session, path, bytes);

      expect(
        (await store.get(session, path)).buffer.asUint8List(),
        bytes.buffer.asUint8List(),
      );
      final signedBytes = await fetch(await store.signedGetUrl(session, path));
      expect(signedBytes.buffer.asUint8List(), bytes.buffer.asUint8List());

      await store.deletePrefix(session, 'unicode/');
      await expectLater(
        store.get(session, path),
        throwsA(isA<ObjectNotFoundException>()),
      );
    });

    test('deletePrefix on a prefix with no objects is a no-op', () async {
      final session = sessionBuilder.build();
      await store.deletePrefix(session, 'nothing-here-${_runId()}/');
    });

    test('rejects keys that could escape the bucket', () async {
      final session = sessionBuilder.build();
      final bytes = ByteData.sublistView(Uint8List.fromList([1]));
      for (final path in [
        '',
        '/leading.bin',
        'trailing/',
        'a//b.bin',
        '../escape.bin',
        'a/./b.bin',
        'a/../b.bin',
      ]) {
        await expectLater(
          store.put(session, path, bytes),
          throwsArgumentError,
          reason: path,
        );
        await expectLater(
          store.get(session, path),
          throwsArgumentError,
          reason: path,
        );
        await expectLater(
          store.signedGetUrl(session, path),
          throwsArgumentError,
          reason: path,
        );
      }
      await expectLater(
        store.deletePrefix(session, '/leading/'),
        throwsArgumentError,
      );
    });

    test('signed URL lifetime must be 1 second to 7 days', () async {
      final session = sessionBuilder.build();
      for (final expiresIn in [
        Duration.zero,
        const Duration(milliseconds: 999),
        const Duration(days: 7, seconds: 1),
      ]) {
        expect(
          () =>
              store.signedGetUrl(session, 'spike/x.bin', expiresIn: expiresIn),
          throwsArgumentError,
          reason: '$expiresIn',
        );
      }
      final longest = await store.signedGetUrl(
        session,
        'spike/x.bin',
        expiresIn: const Duration(days: 7),
      );
      expect(longest.queryParameters['X-Amz-Expires'], '604800');
    });
  });
}

/// A per-run suffix so repeated runs never share object keys.
String _runId() => DateTime.now().microsecondsSinceEpoch.toString();
```

The first three tests are the contract's acceptance tests unchanged; only the `@Tags(['backend-pending'])` / `library;` header and the "BACKEND TRACK" doc lines were removed.

- [ ] **Step 4: Run the tests and see them fail**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/storage/object_store_test.dart
```

Expected: `Some tests failed.` with errors like `UnimplementedError: BACKEND TRACK: S3ObjectStore.put`, `...S3ObjectStore.get`, `...S3ObjectStore.deletePrefix` and `...S3ObjectStore.signedGetUrl`; no test is reported as skipped.

- [ ] **Step 5: Implement S3ObjectStore**

Replace the whole content of `edubox_server/lib/src/storage/object_store.dart` with the file below.
The `ObjectStore` interface and `ObjectNotFoundException` are byte-identical to the committed file; only the imports and the `S3ObjectStore` class change.

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_cloud_storage_s3_compat/serverpod_cloud_storage_s3_compat.dart'
    show
        CustomEndpointConfig,
        PresignedPutUploadStrategy,
        S3Client,
        S3CompatCloudStorage;
import 'package:xml/xml.dart'
    show XmlDocument, XmlFindExtension, XmlStringExtension;

import '../config/edubox_config.dart';

/// Private object storage (MinIO locally), used by phase 2 content files.
///
/// CONTRACT: this interface is frozen. BACKEND TRACK: implement
/// [S3ObjectStore] (exit criterion 10) and make the pending tests in
/// `test/integration/storage/object_store_test.dart` pass.
abstract interface class ObjectStore {
  /// Stores [bytes] at [path], replacing any existing object.
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  });

  /// Reads the object at [path]. Throws [ObjectNotFoundException] when it
  /// does not exist.
  Future<ByteData> get(Session session, String path);

  /// A short-lived presigned GET URL for [path], signed for the configured
  /// public endpoint (not the internal one). [expiresIn] is 1 second to
  /// 7 days.
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  });

  /// Deletes every object whose path starts with [prefix] (an empty prefix
  /// empties the bucket; used by the seed `reset` step on the e2e bucket).
  Future<void> deletePrefix(Session session, String prefix);
}

/// Thrown by [ObjectStore.get] for a missing object.
class ObjectNotFoundException implements Exception {
  const ObjectNotFoundException(this.path);
  final String path;

  @override
  String toString() => 'ObjectNotFoundException: $path';
}

/// The MinIO / S3-compatible implementation.
///
/// Reads, writes, deletes and listing go to [StorageConfig.endpoint] with
/// path-style addressing (`<endpoint>/<bucket>/<key>`). Presigned URLs are
/// signed for [StorageConfig.publicEndpoint] by a second [S3Client] that never
/// sends a request, so the server never needs to reach the public host.
/// Credentials are the passwords `storageAccessKey` and `storageSecretKey`.
class S3ObjectStore implements ObjectStore {
  S3ObjectStore({
    required this.config,
    required this.accessKey,
    required this.secretKey,
  });

  final StorageConfig config;
  final String accessKey;
  final String secretKey;

  /// The longest presigned URL lifetime S3 allows.
  static const Duration maxSignedUrlLifetime = Duration(days: 7);

  /// Signed requests to the internal endpoint.
  late final S3Client _client = _clientFor(config.endpoint);

  /// Signs presigned GET URLs for the public endpoint only.
  late final S3Client _publicSigner = _clientFor(config.publicEndpoint);

  late final S3CompatCloudStorage _storage = S3CompatCloudStorage(
    storageId: 'edubox-${config.bucket}',
    accessKey: accessKey,
    secretKey: secretKey,
    bucket: config.bucket,
    region: config.region,
    public: false,
    endpoints: CustomEndpointConfig(
      baseUri: config.endpoint,
      serviceName: 'MinIO',
    ),
    uploadStrategy: PresignedPutUploadStrategy(),
    client: _client,
  );

  /// Sends the ListObjectsV2 requests, which [S3Client] has no method for.
  late final http.Client _http = http.Client();

  S3Client _clientFor(Uri baseUri) => S3Client(
    accessKey: accessKey,
    secretKey: secretKey,
    bucket: config.bucket,
    region: config.region,
    endpoints: CustomEndpointConfig(baseUri: baseUri, serviceName: 'MinIO'),
  );

  @override
  Future<void> put(
    Session session,
    String path,
    ByteData bytes, {
    String? contentType,
  }) async {
    _checkPath(path);
    await _storage.storeFile(
      session: session,
      path: path,
      byteData: bytes,
      options: StoreFileOptions(
        metadata: FileMetadata(contentType: contentType),
      ),
    );
  }

  @override
  Future<ByteData> get(Session session, String path) async {
    _checkPath(path);
    try {
      return await _storage.retrieveFile(session: session, path: path);
    } on CloudStorageFileNotFoundException {
      throw ObjectNotFoundException(path);
    }
  }

  @override
  Future<Uri> signedGetUrl(
    Session session,
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async {
    _checkPath(path);
    if (expiresIn < const Duration(seconds: 1) ||
        expiresIn > maxSignedUrlLifetime) {
      throw ArgumentError.value(
        expiresIn,
        'expiresIn',
        'Must be between 1 second and 7 days',
      );
    }
    return _publicSigner.buildPresignedUri(
      key: path,
      method: 'GET',
      expiration: expiresIn,
    );
  }

  @override
  Future<void> deletePrefix(Session session, String prefix) async {
    if (prefix.startsWith('/')) {
      throw ArgumentError.value(prefix, 'prefix', 'Must not start with "/"');
    }
    // Every listed key is deleted before the next listing, so the first page
    // is always the next batch; no continuation token is needed.
    while (true) {
      final page = await _listFirstPage(prefix);
      for (final key in page.keys) {
        final response = await _client.deleteObject(key);
        if (response.statusCode == 404) continue;
        _client.checkResponseError(response);
      }
      if (!page.isTruncated || page.keys.isEmpty) return;
    }
  }

  Future<({List<String> keys, bool isTruncated})> _listFirstPage(
    String prefix,
  ) async {
    final params = _client.buildSignedParams(
      key: '',
      queryParams: {'list-type': '2', 'max-keys': '1000', 'prefix': prefix},
    );
    final response = await _http.get(params.uri, headers: params.headers);
    _client.checkResponseError(response);
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    return (
      keys: [
        for (final element in document.findAllElements(
          'Key',
          namespaceUri: '*',
        ))
          element.innerText,
      ],
      isTruncated: document
          .findAllElements('IsTruncated', namespaceUri: '*')
          .any((element) => element.innerText.trim() == 'true'),
    );
  }

  /// Rejects keys that could escape the bucket or address it ambiguously.
  static void _checkPath(String path) {
    final segments = path.split('/');
    if (path.isEmpty ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw ArgumentError.value(
        path,
        'path',
        'Must be a relative object key without empty, "." or ".." segments',
      );
    }
  }
}
```

Check that the frozen part is untouched (run in `bash`; it compares the interface and the exception with the committed version):

```bash
cd /home/hii/Documents/EduBox
frozen() { sed -n '/^abstract interface class ObjectStore/,/^}/p;/^class ObjectNotFoundException/,/^}/p' "$1"; }
diff <(git show HEAD:edubox_server/lib/src/storage/object_store.dart | frozen /dev/stdin) <(frozen edubox_server/lib/src/storage/object_store.dart) && echo "frozen part identical"
```

Expected: `frozen part identical`.

- [ ] **Step 6: Run the tests and see them pass**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/storage/object_store_test.dart
```

Expected: `+8: All tests passed!`.
The expiry test waits 2 seconds by design.

- [ ] **Step 7: Run the verification gate**

Run the gate block from "Global constraints" exactly.
Expected: as listed there; the seed suite is still skipped by its `backend-pending` tag until Task 2, which is fine here.

- [ ] **Step 8: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add edubox_server/pubspec.yaml edubox_server/lib/src/storage/object_store.dart edubox_server/test/integration/storage/object_store_test.dart
git diff --quiet pubspec.lock || git add pubspec.lock
git commit -m "feat: implement S3ObjectStore against MinIO (exit criterion 10)"
```

Expected `git status --short` before staging: ` M edubox_server/pubspec.yaml`, ` M edubox_server/lib/src/storage/object_store.dart`, ` M edubox_server/test/integration/storage/object_store_test.dart`, possibly ` M pubspec.lock`, and `?? skills-lock.json` (never staged).

---

### Task 2: Seed steps (`runSeedStep`)

**Routing signal:** risky (auth tables and full data reset).

**Files:**

- Modify: `edubox_server/lib/src/seed/seed_command.dart` (imports and `runSeedStep` plus private helpers; `SeedStep` and `seedResetTables` byte-identical)
- Modify: `edubox_server/test/integration/seed/seed_command_test.dart` (remove the `backend-pending` tag, update the doc comment, add one idempotency test)

**Interfaces:**

- Consumes: `ObjectStore.deletePrefix` (Task 1 implements the real one; the tests use their own `_RecordingStore`); `FixtureLoader` in `edubox_server/lib/src/seed/fixture_loader.dart`: `load(Session, FixtureSet, {Set<String>? credentialsFor})` (null means credentials for every account), `insertClass(Session, ClassFixture, Map<String, int> userIds) -> Future<int>`, `insertContent(Session, ContentFixture, {required Map<String, int> userIds, required Map<String, int> classIds}) -> Future<int>`; fixtures from `package:edubox_fixtures/edubox_fixtures.dart`: `FixtureSet.phase1()`, `.accounts`, `.classes`, `.account(key)`, `FixtureKeys.nullRole`, `reconnectDeltaContent` (title `Ôn tập chương 1`, class 7A), `reconnectDeltaClass` (name `8B`, teacher Lan).
- Produces: `Future<void> runSeedStep(Session session, SeedStep step, {required ObjectStore e2eStore})` (signature unchanged).
  `reset` empties all `seedResetTables` with one `TRUNCATE ... RESTART IDENTITY CASCADE`, calls `e2eStore.deletePrefix(session, '')`, then loads the phase 1 fixtures with credentials for all 15 accounts (14 `users` rows, 5 classes, 9 content rows, 15 email accounts).
  `reconnectLibrary`, `reconnectClasses` and `assignRole` require a prior reset (they throw `StateError` naming the missing fixture otherwise) and are idempotent.

**API facts:**

- `serverpod_database-4.0.4/lib/src/database.dart`: `Future<int> unsafeExecute(String query, {int? timeoutInSeconds, Transaction? transaction, QueryParameters? parameters})`, reached as `session.db.unsafeExecute(...)`.
  Table names are constants from `seedResetTables`, never user input, and each is double-quoted.
- Generated table classes (read-only, `edubox_server/lib/src/generated/protocol.dart`): `EduboxUser` (`users`; `role` is a raw nullable `String`), `SchoolClass` (`classes`), `ContentRecord` (`content`); each has `.db.findFirstRow(session, where: (t) => ...)`, `.db.find(session)`, `.db.count(session, where: ...)`, `.db.updateRow(session, row)`, and `copyWith`.
- Serverpod test tools give each `withServerpod` group its own ephemeral database on `postgres_test`, and these groups use `rollbackDatabase: RollbackDatabase.disabled`, so the reset never touches another suite.

- [ ] **Step 1: Un-tag the acceptance tests and add the idempotency test**

In `edubox_server/test/integration/seed/seed_command_test.dart` make three exact edits.

Edit A: delete the first three lines of the file, which are exactly:

```dart
@Tags(['backend-pending'])
library;

```

so the file now starts with `import 'dart:typed_data';`.

Edit B: replace these three doc lines

```dart
/// BACKEND TRACK: implement `runSeedStep` and remove the `backend-pending`
/// tag. These are the acceptance tests for the seed contract in
/// docs/build/phase-1/contract.md sections 2.5-2.6.
```

with

```dart
/// The acceptance tests for the seed contract in
/// docs/build/phase-1/contract.md sections 2.5-2.6.
```

Edit C: in the second group (`'seed reconnect and role steps'`), insert this test immediately before the line `      test(` that precedes `'assign-role makes the null-role fixture ready on the next call',`:

```dart
      test('the delta steps are idempotent', () async {
        for (var run = 0; run < 2; run++) {
          await runSeedStep(
            session,
            SeedStep.reconnectLibrary,
            e2eStore: store,
          );
          await runSeedStep(
            session,
            SeedStep.reconnectClasses,
            e2eStore: store,
          );
          await runSeedStep(session, SeedStep.assignRole, e2eStore: store);
        }
        expect(
          await ContentRecord.db.count(
            session,
            where: (table) => table.title.equals(reconnectDeltaContent.title),
          ),
          1,
        );
        expect(
          await SchoolClass.db.count(
            session,
            where: (table) => table.name.equals(reconnectDeltaClass.name),
          ),
          1,
        );
        expect(
          await ContentRecord.db.count(session),
          FixtureSet.phase1().content.length + 1,
        );
        expect(
          await SchoolClass.db.count(session),
          FixtureSet.phase1().classes.length + 1,
        );
      });
```

- [ ] **Step 2: Run the tests and see them fail**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/seed/seed_command_test.dart
```

Expected: `Some tests failed.` with `UnimplementedError: BACKEND TRACK: runSeedStep(reset)` from `setUp`; no test is reported as skipped.

- [ ] **Step 3: Implement the seed steps**

Replace the whole content of `edubox_server/lib/src/seed/seed_command.dart` with the file below.
The `SeedStep` enum and `seedResetTables` are byte-identical to the committed file.

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../storage/object_store.dart';
import 'fixture_loader.dart';

/// The steps of the seed command.
///
/// CLI: `docker compose run --rm seed [--step <cliName>]` (default `reset`),
/// which runs `bin/seed --mode development --step <cliName>` against the
/// development database and the e2e bucket. Exit code 0 on success, 1 on any
/// failure, 64 on a usage error.
enum SeedStep {
  /// Truncates [seedResetTables], empties the e2e bucket, then loads
  /// `FixtureSet.phase1()` through `FixtureLoader` with credentials for every
  /// account. Every e2e run starts with this.
  reset('reset'),

  /// Exit criterion 7: inserts `reconnectDeltaContent` (a new approved item
  /// for class 7A) on top of a reset database.
  reconnectLibrary('reconnect-library'),

  /// Exit criterion 7: inserts `reconnectDeltaClass` (class 8B for teacher
  /// Lan) on top of a reset database.
  reconnectClasses('reconnect-classes'),

  /// Account-not-set-up check-again coverage: sets the null-role fixture's
  /// role to `student`.
  assignRole('assign-role');

  const SeedStep(this.cliName);

  /// The `--step` value.
  final String cliName;

  /// Parses a `--step` value; returns null for an unknown value.
  static SeedStep? tryParse(String value) {
    for (final step in values) {
      if (step.cliName == value) return step;
    }
    return null;
  }
}

/// Every table the `reset` step truncates (`TRUNCATE ... RESTART IDENTITY
/// CASCADE`): all EduBox data tables plus the Serverpod auth tables. The
/// schema and the migration bookkeeping tables are never touched.
///
/// A server test fails when a table of the latest migration that is not a
/// Serverpod system table is missing from this list, so a new phase that
/// adds a table must add it here.
const List<String> seedResetTables = [
  // EduBox data.
  'content_classes',
  'content',
  'class_members',
  'class_subjects',
  'classes',
  'users',
  // Serverpod auth (serverpod_auth_core and serverpod_auth_idp).
  'serverpod_auth_core_jwt_refresh_token',
  'serverpod_auth_core_profile',
  'serverpod_auth_core_profile_image',
  'serverpod_auth_core_session',
  'serverpod_auth_core_user',
  'serverpod_auth_idp_anonymous_account',
  'serverpod_auth_idp_apple_account',
  'serverpod_auth_idp_email_account',
  'serverpod_auth_idp_email_account_password_reset_request',
  'serverpod_auth_idp_email_account_request',
  'serverpod_auth_idp_facebook_account',
  'serverpod_auth_idp_firebase_account',
  'serverpod_auth_idp_github_account',
  'serverpod_auth_idp_google_account',
  'serverpod_auth_idp_microsoft_account',
  'serverpod_auth_idp_passkey_account',
  'serverpod_auth_idp_passkey_challenge',
  'serverpod_auth_idp_rate_limited_request_attempt',
  'serverpod_auth_idp_secret_challenge',
];

/// Runs one seed step.
///
/// `reset` empties every table in [seedResetTables] in one statement, empties
/// the e2e bucket through `e2eStore.deletePrefix(session, '')`, then loads
/// `FixtureSet.phase1()` with credentials for every account. The delta steps
/// expect a reset database, look fixtures up by email and class name, and are
/// idempotent: running one twice changes nothing the second time. See
/// docs/build/phase-1/contract.md sections 2.5-2.6.
Future<void> runSeedStep(
  Session session,
  SeedStep step, {
  required ObjectStore e2eStore,
}) async {
  switch (step) {
    case SeedStep.reset:
      await _reset(session, e2eStore);
    case SeedStep.reconnectLibrary:
      await _insertReconnectContent(session);
    case SeedStep.reconnectClasses:
      await _insertReconnectClass(session);
    case SeedStep.assignRole:
      await _assignNullRoleFixture(session);
  }
}

Future<void> _reset(Session session, ObjectStore e2eStore) async {
  final tables = seedResetTables.map((table) => '"$table"').join(', ');
  await session.db.unsafeExecute(
    'TRUNCATE TABLE $tables RESTART IDENTITY CASCADE',
  );
  await e2eStore.deletePrefix(session, '');
  await const FixtureLoader().load(session, FixtureSet.phase1());
}

Future<void> _insertReconnectContent(Session session) async {
  final existing = await ContentRecord.db.findFirstRow(
    session,
    where: (table) => table.title.equals(reconnectDeltaContent.title),
  );
  if (existing != null) return;
  await const FixtureLoader().insertContent(
    session,
    reconnectDeltaContent,
    userIds: await _userIdsByKey(session),
    classIds: await _classIdsByKey(session),
  );
}

Future<void> _insertReconnectClass(Session session) async {
  final existing = await SchoolClass.db.findFirstRow(
    session,
    where: (table) => table.name.equals(reconnectDeltaClass.name),
  );
  if (existing != null) return;
  await const FixtureLoader().insertClass(
    session,
    reconnectDeltaClass,
    await _userIdsByKey(session),
  );
}

Future<void> _assignNullRoleFixture(Session session) async {
  final email = FixtureSet.phase1().account(FixtureKeys.nullRole).email;
  final user = await EduboxUser.db.findFirstRow(
    session,
    where: (table) => table.email.equals(email),
  );
  if (user == null) {
    throw StateError(
      'Fixture ${FixtureKeys.nullRole} has no users row; run the reset step '
      'first.',
    );
  }
  await EduboxUser.db.updateRow(session, user.copyWith(role: 'student'));
}

/// `users.id` per fixture account key, for every seeded account that has a
/// profile. Throws when a profile fixture is missing (no reset yet).
Future<Map<String, int>> _userIdsByKey(Session session) async {
  final idByEmail = {
    for (final user in await EduboxUser.db.find(session)) user.email: user.id!,
  };
  return {
    for (final account in FixtureSet.phase1().accounts)
      if (account.hasProfile) account.key: _require(idByEmail, account.email),
  };
}

/// `classes.id` per fixture class key for the phase 1 classes.
Future<Map<String, int>> _classIdsByKey(Session session) async {
  final idByName = {
    for (final row in await SchoolClass.db.find(session)) row.name: row.id!,
  };
  return {
    for (final fixture in FixtureSet.phase1().classes)
      fixture.key: _require(idByName, fixture.name),
  };
}

int _require(Map<String, int> ids, String name) {
  final id = ids[name];
  if (id == null) {
    throw StateError(
      'Fixture "$name" is not seeded; run the reset step first.',
    );
  }
  return id;
}
```

Check that the frozen part is untouched (run in `bash`):

```bash
cd /home/hii/Documents/EduBox
frozen() { sed -n '/^enum SeedStep/,/^];/p' "$1"; }
diff <(git show HEAD:edubox_server/lib/src/seed/seed_command.dart | frozen /dev/stdin) <(frozen edubox_server/lib/src/seed/seed_command.dart) && echo "seed enum and table list identical"
```

Expected: `seed enum and table list identical`.

- [ ] **Step 4: Run the tests and see them pass**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/seed/
```

Expected: `+9: All tests passed!` (5 reset tests and 4 step tests).
Then confirm nothing is skipped any more:

```sh
cd /home/hii/Documents/EduBox && grep -rn "backend-pending" edubox_server/test || echo "no backend-pending tests left"
```

Expected: `no backend-pending tests left`.
(`edubox_server/dart_test.yaml` still defines the tag; it is contract-owned and stays.)

- [ ] **Step 5: Run the verification gate**

Run the gate block from "Global constraints" exactly.
Expected: as listed there, now with no skipped suite.

- [ ] **Step 6: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add edubox_server/lib/src/seed/seed_command.dart edubox_server/test/integration/seed/seed_command_test.dart
git commit -m "feat: implement seed reset, reconnect deltas and assign-role"
```

---

### Task 3: Seed CLI (`bin/seed.dart`)

**Routing signal:** routine.

**Files:**

- Modify: `edubox_server/pubspec.yaml` (add `args` to `dependencies`)
- Modify: `pubspec.lock` (only if `dart pub get` changes it)
- Create: `edubox_server/bin/seed.dart`
- Create: `edubox_server/test/integration/seed/seed_cli_test.dart`

**Interfaces:**

- Consumes: `runSeedStep` and `SeedStep` (Task 2), `S3ObjectStore` (Task 1), `EduboxConfig.load({required String runMode, String serverDirectory})` (`edubox_server/lib/src/config/edubox_config.dart`; reads `config/<mode>.yaml` and the `EDUBOX_STORAGE_*` overrides), `configureAuthServices(Serverpod)` (`edubox_server/lib/src/auth/auth_setup.dart`), the generated `Serverpod(List<String> args)` in `edubox_server/lib/src/generated/serverpod.dart` (pre-wired with `Protocol` and `Endpoints`, re-exports `package:serverpod/serverpod.dart`).
- Produces (public, used by Task 4 and the compose `seed` service): `./bin/seed [--mode development|test] [--step reset|reconnect-library|reconnect-classes|assign-role]`, defaults `development` and `reset`; exit 0 on success and `--help`, 1 on any failure, 64 on a usage error (including `--mode production`/`staging`); success prints `seed: ok:<step> (mode <mode>, bucket <bucket>)`.
  Dart API: `class SeedArgs { String runMode; SeedStep step; }`, `SeedArgs? parseSeedArgs(List<String>)`, `String get seedUsage`, `const int seedExitUsage = 64`, `const List<String> seedRunModes`, `Future<int> runSeedCli(SeedArgs)`.

**API facts:**

- `serverpod-4.0.4/lib/src/server/command_line_args.dart`: Serverpod's own `ArgParser` knows only `--mode`, `--server-id`, `--logging`, `--role`, `--apply-migrations`, `--apply-repair-migration`; on any unknown option it logs a warning and drops every argument (falling back to defaults).
  So the CLI parses `--step` itself and passes only `['--mode', mode]` to Serverpod.
- `serverpod-4.0.4/lib/src/server/serverpod.dart`: the constructor loads `config/<mode>.yaml` and `config/passwords.yaml` from `Directory.current` and creates the database pool without connecting; `createSession({bool enableLogging = true})` returns a usable `Session` without `start()`; `String? getPassword(String key)`; `serverDirectory`; `shutdown({bool exitProcess = true})` is safe without `start()`.
  `serverpod_database-4.0.4/lib/src/adapters/postgres/postgres_pool_manager.dart`: `pool` awaits `started`, so the first query opens the pool lazily.
  Not calling `start()` means no port is bound, so the CLI can run next to a running server.
- Database environment overrides read by Serverpod 4.0.4: `SERVERPOD_DATABASE_HOST`, `SERVERPOD_DATABASE_PORT`, `SERVERPOD_DATABASE_NAME`, `SERVERPOD_DATABASE_USER`, `SERVERPOD_DATABASE_PASSWORD`.
- `args-2.7.0`: `ArgParser()..addOption(name, abbr:, allowed:, defaultsTo:, help:)..addFlag(name, abbr:, negatable:, help:)`; `parse` throws `FormatException` on an unknown option or a value outside `allowed`; `ArgResults.option(name)`, `.flag(name)`, `.rest`; `ArgParser.usage`.
- A test may import the CLI with the relative path `'../../../bin/seed.dart'`; importing a library that declares `main` is allowed.

- [ ] **Step 1: Add the dependency**

In `edubox_server/pubspec.yaml`, replace the whole `dependencies:` block with exactly:

```yaml
dependencies:
  args: ^2.7.0
  crypto: ^3.0.6
  edubox_fixtures:
    path: ../edubox_fixtures
  http: ^1.6.0
  serverpod: 4.0.4
  serverpod_auth_idp_server: 4.0.4
  serverpod_cloud_storage_s3_compat: 4.0.4
  xml: ^7.0.1
  yaml: ^3.1.3
```

```sh
cd /home/hii/Documents/EduBox && dart pub get && git status --short pubspec.lock
```

Expected: `Got dependencies!`; most likely no lock change (`args 2.7.0` is already locked).

- [ ] **Step 2: Write the failing test**

Create `edubox_server/test/integration/seed/seed_cli_test.dart`:

```dart
import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:test/test.dart';

import '../../../bin/seed.dart';

void main() {
  group('parseSeedArgs', () {
    test('defaults to the development mode and the reset step', () {
      final args = parseSeedArgs(const []);
      expect(args, isNotNull);
      expect(args!.runMode, 'development');
      expect(args.step, SeedStep.reset);
    });

    test('accepts every step by its CLI name, in both option forms', () {
      for (final step in SeedStep.values) {
        expect(
          parseSeedArgs(['--mode', 'test', '--step', step.cliName])?.step,
          step,
          reason: step.cliName,
        );
        expect(
          parseSeedArgs(['--mode=development', '--step=${step.cliName}'])?.step,
          step,
          reason: step.cliName,
        );
      }
      expect(parseSeedArgs(['-m', 'test'])?.runMode, 'test');
    });

    test('rejects production, staging, unknown steps, stray arguments and '
        '--help as usage errors', () {
      for (final args in [
        ['--mode', 'production'],
        ['--mode', 'staging'],
        ['--step', 'nope'],
        ['--unknown'],
        ['reset'],
        ['--help'],
      ]) {
        expect(parseSeedArgs(args), isNull, reason: args.join(' '));
      }
    });

    test('the usage text names both options', () {
      expect(seedUsage, contains('--mode'));
      expect(seedUsage, contains('--step'));
      expect(seedExitUsage, 64);
    });
  });
}
```

- [ ] **Step 3: Run it and see it fail**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/seed/seed_cli_test.dart
```

Expected: a load failure such as `Error when reading 'bin/seed.dart'` or `Couldn't read file` and `Some tests failed.`

- [ ] **Step 4: Implement the CLI**

Create `edubox_server/bin/seed.dart`:

```dart
import 'dart:io';

import 'package:args/args.dart';
import 'package:edubox_server/src/auth/auth_setup.dart';
import 'package:edubox_server/src/config/edubox_config.dart';
import 'package:edubox_server/src/generated/serverpod.dart';
import 'package:edubox_server/src/seed/seed_command.dart';
import 'package:edubox_server/src/storage/object_store.dart';

/// Exit code for a usage error (BSD `EX_USAGE`).
const int seedExitUsage = 64;

/// The run modes the seed CLI accepts. Production and staging are refused:
/// the seed wipes every EduBox and auth table.
const List<String> seedRunModes = ['development', 'test'];

/// A parsed seed command line.
class SeedArgs {
  const SeedArgs({required this.runMode, required this.step});

  final String runMode;
  final SeedStep step;
}

final ArgParser _parser = ArgParser()
  ..addOption(
    'mode',
    abbr: 'm',
    allowed: seedRunModes,
    defaultsTo: 'development',
    help: 'Serverpod run mode; selects config/<mode>.yaml and passwords.',
  )
  ..addOption(
    'step',
    allowed: [for (final step in SeedStep.values) step.cliName],
    defaultsTo: SeedStep.reset.cliName,
    help: 'The seed step to run.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');

/// The usage text printed on a usage error.
String get seedUsage =>
    'Usage: seed [--mode development|test] [--step <step>]\n'
    '${_parser.usage}';

/// Parses the seed command line. Returns null on a usage error or `--help`.
SeedArgs? parseSeedArgs(List<String> args) {
  final ArgResults results;
  try {
    results = _parser.parse(args);
  } on FormatException {
    return null;
  }
  if (results.flag('help') || results.rest.isNotEmpty) return null;
  return SeedArgs(
    runMode: results.option('mode')!,
    step: SeedStep.tryParse(results.option('step')!)!,
  );
}

/// `docker compose run --rm seed [--step <step>]` runs
/// `./bin/seed --mode development [--step <step>]` against the development
/// database and the bucket named by `EDUBOX_STORAGE_BUCKET` (the e2e bucket).
/// Exit codes: 0 success (and `--help`), 1 failure, 64 usage error.
Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(seedUsage);
    return;
  }
  final parsed = parseSeedArgs(args);
  if (parsed == null) {
    stderr.writeln(seedUsage);
    exit(seedExitUsage);
  }
  exit(await runSeedCli(parsed));
}

/// Runs one seed step without starting the API server: Serverpod only loads
/// the config and passwords and opens the database pool lazily.
Future<int> runSeedCli(SeedArgs args) async {
  // Serverpod's own parser drops every argument when it meets an unknown
  // one, so it only ever receives the run mode.
  final pod = Serverpod(['--mode', args.runMode]);
  configureAuthServices(pod);
  final session = await pod.createSession(enableLogging: false);
  try {
    final config = EduboxConfig.load(
      runMode: args.runMode,
      serverDirectory: pod.serverDirectory.path,
    );
    final store = S3ObjectStore(
      config: config.storage,
      accessKey: _requirePassword(pod, 'storageAccessKey'),
      secretKey: _requirePassword(pod, 'storageSecretKey'),
    );
    await runSeedStep(session, args.step, e2eStore: store);
    stdout.writeln(
      'seed: ok:${args.step.cliName} (mode ${args.runMode}, '
      'bucket ${config.storage.bucket})',
    );
    return 0;
  } catch (error, stackTrace) {
    stderr.writeln('seed: FAILED ${args.step.cliName}: $error');
    stderr.writeln(stackTrace);
    return 1;
  } finally {
    await session.close();
    await pod.shutdown(exitProcess: false);
  }
}

String _requirePassword(Serverpod pod, String key) {
  final value = pod.getPassword(key);
  if (value == null || value.isEmpty) {
    throw StateError('Missing password "$key" in config/passwords.yaml.');
  }
  return value;
}
```

- [ ] **Step 5: Run the unit test and see it pass**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/seed/seed_cli_test.dart
```

Expected: `+4: All tests passed!`.

- [ ] **Step 6: Run the CLI for real against a throwaway database**

This uses a database created only for this check on the `postgres_test` container (tmpfs, test-only) and the `edubox-test` bucket, so no developer data is touched.

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
cd /home/hii/Documents/EduBox
docker compose up -d --wait postgres_test minio
docker compose run --rm minio-init
docker compose exec -T postgres_test psql -U postgres -d edubox_test -c 'CREATE DATABASE edubox_seed_cli_check'
docker compose exec -T postgres_test psql -q -U postgres -d edubox_seed_cli_check < edubox_server/migrations/20261029133845455/definition.sql > /dev/null
cd edubox_server
for step in reset reconnect-library reconnect-classes assign-role; do
  SERVERPOD_DATABASE_NAME=edubox_seed_cli_check dart run bin/seed.dart --mode test --step "$step" 2>&1 | grep 'seed:'
done
dart run bin/seed.dart --mode production > /dev/null 2>&1; echo "production exit=$?"
dart run bin/seed.dart --help | grep '^Usage:'
cd ..
docker compose exec -T postgres_test psql -U postgres -d edubox_seed_cli_check -tAc "select (select count(*) from users), (select count(*) from classes), (select count(*) from content), (select count(*) from serverpod_auth_idp_email_account), (select role from users where email = 'chua.co.vai.tro@edubox.test')"
docker compose exec -T postgres_test psql -U postgres -d edubox_test -c 'DROP DATABASE edubox_seed_cli_check'
```

Expected, in order:

```text
CREATE DATABASE
seed: ok:reset (mode test, bucket edubox-test)
seed: ok:reconnect-library (mode test, bucket edubox-test)
seed: ok:reconnect-classes (mode test, bucket edubox-test)
seed: ok:assign-role (mode test, bucket edubox-test)
production exit=64
Usage: seed [--mode development|test] [--step <step>]
14|6|10|15|student
DROP DATABASE
```

(14 profiles, 5 classes + 8B, 9 content rows + the delta item, 15 email accounts, and the null-role fixture now `student`.)

- [ ] **Step 7: Run the verification gate**

Run the gate block from "Global constraints" exactly.

- [ ] **Step 8: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add edubox_server/pubspec.yaml edubox_server/bin/seed.dart edubox_server/test/integration/seed/seed_cli_test.dart
git diff --quiet pubspec.lock || git add pubspec.lock
git commit -m "feat: add the seed CLI (bin/seed.dart)"
```

---

### Task 4: Seed executable in the server image, proven on the compose stack

**Routing signal:** routine (image build; the verification resets the local development database, which contract.md section 2.6 and the roadmap accept for e2e runs).

**Files:**

- Modify: `edubox_server/Dockerfile` (build stage only; the final-stage `ENTRYPOINT ["./bin/server"]` and `CMD` lines stay byte-identical)

**Interfaces:**

- Consumes: `edubox_server/bin/seed.dart` (Task 3); the compose `seed` service (`entrypoint: ["./bin/seed", "--mode", "development"]`, env `EDUBOX_STORAGE_BUCKET: edubox-e2e`, config mounted at `/app/config`) and the `server` service (`EDUBOX_E2E_CONTROL: "true"`), both read-only in `compose.yaml`.
- Produces: `/app/bin/seed` in the image next to `/app/bin/server`, so `docker compose run --rm seed [--step <step>]` works.

**API facts:**

- `dart build cli --target bin/<name>.dart --output <dir>` writes `<dir>/bundle/bin/<name>` and the native libraries (`libserverpod_argon2.so`, `libsqlite3.so`, `libsqlite3_connection_pool.so`) to `<dir>/bundle/lib/` (checked with the Dart SDK used by `dart:3.12.2`, 2026-10-30).
  A second build in the same workspace may reuse cached hook output and leave its own `bundle/lib/` empty, so only the `seed` executable is moved into the server bundle, whose `bundle/lib/` already holds the same libraries.
- The final stage copies the whole `build/bundle/` to `/app`, so `bin/seed` lands at `/app/bin/seed`.
- Serverpod endpoints answer `POST http://<host>:8080/<endpoint>/<method>` with a JSON object of the named parameters, and return the JSON-encoded result (`serverpod_client-4.0.4/lib/src/serverpod_client_shared.dart`, `serverpod-4.0.4/lib/src/server/server.dart` `encodeForProtocol`); `e2e.run` returns `"ok:<step>"`.

- [ ] **Step 1: See the compose seed service fail today**

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
cd /home/hii/Documents/EduBox
bash tool/bootstrap.sh
docker compose --profile e2e up -d --build --wait
docker compose run --rm minio-init
docker compose --profile tools build seed
docker compose run --rm seed --step reset; echo "seed exit=$?"
```

Expected: the stack ends with `server-1 Healthy`; the last command fails with an error saying `./bin/seed` does not exist (for example `exec: "./bin/seed": stat ./bin/seed: no such file or directory`) and a non-zero `seed exit=`.
The image builds take several minutes.

- [ ] **Step 2: Add the seed build to the Dockerfile**

In `edubox_server/Dockerfile`, replace exactly these two lines

```dockerfile
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server
```

with

```dockerfile
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server

# Compile the seed CLI (compose `seed` service: `./bin/seed`). Only the
# executable is kept: it loads the same native libraries from bundle/lib.
RUN dart build cli --target bin/seed.dart --output build_seed
RUN mv build_seed/bundle/bin/seed build/bundle/bin/seed
```

Nothing else in the file changes.

- [ ] **Step 3: Rebuild and run the seed through compose**

```sh
cd /home/hii/Documents/EduBox
docker compose --profile e2e up -d --build --wait
docker compose --profile tools build seed
docker compose run --rm --entrypoint /bin/sh minio-init -c 'mc alias set local http://minio:9000 edubox-dev dev-only-minio-password > /dev/null && echo probe | mc pipe local/edubox-e2e/probe/hello.txt > /dev/null && mc ls --recursive local/edubox-e2e'
docker compose run --rm seed --step reset 2>&1 | grep 'seed:'
docker compose run --rm --entrypoint /bin/sh minio-init -c 'mc alias set local http://minio:9000 edubox-dev dev-only-minio-password > /dev/null && mc ls --recursive local/edubox-e2e; echo "listed"'
docker compose exec -T postgres psql -U postgres -d edubox -tAc "select (select count(*) from users), (select count(*) from classes), (select count(*) from content), (select count(*) from serverpod_auth_idp_email_account)"
```

Expected, in order: a listing line ending in `probe/hello.txt`; `seed: ok:reset (mode development, bucket edubox-e2e)`; only `listed` (the bucket was emptied); `14|5|9|15`.

- [ ] **Step 4: Prove the on-device path (`e2e.run`) on the same stack**

```sh
cd /home/hii/Documents/EduBox
curl -sS -X POST http://localhost:8080/e2e/run -H 'Content-Type: application/json' -d '{"token":"dev-only-e2e-control-token","step":"reconnect-library"}'; echo
curl -sS -X POST http://localhost:8080/e2e/run -H 'Content-Type: application/json' -d '{"token":"dev-only-e2e-control-token","step":"reconnect-classes"}'; echo
docker compose exec -T postgres psql -U postgres -d edubox -tAc "select (select count(*) from classes), (select count(*) from content)"
curl -sS -X POST http://localhost:8080/e2e/run -H 'Content-Type: application/json' -d '{"token":"dev-only-e2e-control-token","step":"reset"}'; echo
docker compose exec -T postgres psql -U postgres -d edubox -tAc "select (select count(*) from classes), (select count(*) from content)"
curl -sS -o /dev/null -w '%{http_code}\n' -X POST http://localhost:8080/e2e/run -H 'Content-Type: application/json' -d '{"token":"wrong-token","step":"reset"}'
docker compose --profile e2e stop server
```

Expected, in order: `"ok:reconnect-library"`, `"ok:reconnect-classes"`, `6|10`, `"ok:reset"`, `5|9`, an HTTP status other than `200` for the wrong token, and the server stopped.
The `dev-only-e2e-control-token` value comes from the committed `passwords.example.yaml` (development section).

- [ ] **Step 5: Run the verification gate**

Run the gate block from "Global constraints" exactly.

- [ ] **Step 6: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add edubox_server/Dockerfile
git commit -m "build: compile the seed CLI into the server image"
```

---

### Task 5: Bootstrap reports passwords keys missing from passwords.yaml (carried LOW)

**Routing signal:** routine.

**Files:**

- Modify: `tool/bootstrap.sh` (contract-owned; the orchestrator authorizes this task only)

**Interfaces:**

- Consumes: `edubox_server/config/passwords.example.yaml` (two-level YAML: run-mode section, then `key: 'value'` lines indented two spaces; comments start with `#`).
- Produces: unchanged behaviour when `passwords.yaml` is missing (copy, exit 0) or complete (`exists, left unchanged`, exit 0).
  New: when `passwords.yaml` lacks any `<section>.<key>` of the example, the script prints `bootstrap: ERROR ... is missing keys that passwords.example.yaml defines:` followed by `  - <section>.<key>` lines on stderr and exits 1.
  Extra keys in `passwords.yaml` (for example a developer's `openRouterApiKey`) are allowed.
  It never modifies an existing `passwords.yaml`.
  It also fixes the pre-existing ShellCheck warning SC1007 (`CDPATH= cd` becomes `CDPATH='' cd`).

- [ ] **Step 1: Write the failing check**

Run this scripted test against the current script in a temporary copy (it never touches the real `passwords.yaml`):

```sh
cd /home/hii/Documents/EduBox
T=$(mktemp -d)
mkdir -p "$T/tool" "$T/edubox_server/config"
cp tool/bootstrap.sh "$T/tool/"
cp edubox_server/config/passwords.example.yaml "$T/edubox_server/config/"
sh "$T/tool/bootstrap.sh" > /dev/null; echo "first exit=$?"
sh "$T/tool/bootstrap.sh" > /dev/null; echo "complete exit=$?"
grep -v "e2eControlToken: 'test-only" "$T/edubox_server/config/passwords.yaml" > "$T/p.tmp"
cat "$T/p.tmp" > "$T/edubox_server/config/passwords.yaml"
sh "$T/tool/bootstrap.sh"; echo "missing exit=$?"
rm -r "$T"
```

Expected with the current script (the failure): `first exit=0`, `complete exit=0`, then only `bootstrap: ... exists, left unchanged` and `missing exit=0`.
The required behaviour is `missing exit=1` with `  - test.e2eControlToken` listed.

- [ ] **Step 2: Implement**

Replace the whole content of `tool/bootstrap.sh` with (keep the file executable; `git` already tracks its mode):

```sh
#!/usr/bin/env sh
# Idempotent first-run setup for a clean checkout.
#
# Creates edubox_server/config/passwords.yaml from the committed dev-only
# passwords.example.yaml when it is missing. It never overwrites an existing
# passwords.yaml, so a developer's own OpenRouter key survives.
#
# When passwords.yaml exists, it checks that every `<runMode>.<key>` in the
# example is also present there (a key added to the example after the file was
# created, e.g. test.e2eControlToken). Missing keys are listed and the script
# exits 1, so the test run fails here with a clear message instead of later
# with a confusing authorization error.
set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
example="$repo_root/edubox_server/config/passwords.example.yaml"
target="$repo_root/edubox_server/config/passwords.yaml"

# Prints `<section>.<key>` for every key nested one level under a top-level
# section, ignoring comments and blank lines.
yaml_keys() {
  awk '
    /^[[:space:]]*(#|$)/ { next }
    /^[A-Za-z0-9_]+:[[:space:]]*(#.*)?$/ {
      section = $0
      sub(/:.*/, "", section)
      next
    }
    /^[^[:space:]]/ { section = ""; next }
    section != "" && /^[[:space:]]+[A-Za-z0-9_]+:/ {
      key = $0
      sub(/^[[:space:]]+/, "", key)
      sub(/:.*/, "", key)
      print section "." key
    }
  ' "$1" | LC_ALL=C sort -u
}

if [ ! -f "$target" ]; then
  cp "$example" "$target"
  echo "bootstrap: created $target from passwords.example.yaml (dev-only values)"
  exit 0
fi

echo "bootstrap: $target exists, left unchanged"

target_keys=$(yaml_keys "$target")
missing=$(yaml_keys "$example" | while IFS= read -r key; do
  if ! printf '%s\n' "$target_keys" | grep -Fqx -- "$key"; then
    printf '%s\n' "$key"
  fi
done)

if [ -n "$missing" ]; then
  echo "bootstrap: ERROR $target is missing keys that passwords.example.yaml defines:" >&2
  printf '%s\n' "$missing" | sed 's/^/  - /' >&2
  echo "bootstrap: copy them from passwords.example.yaml (dev-only values), or move" >&2
  echo "bootstrap: passwords.yaml aside and re-run tool/bootstrap.sh." >&2
  exit 1
fi
```

- [ ] **Step 3: Run the check again and see it pass**

Run the exact block from Step 1 again.
Expected:

```text
first exit=0
complete exit=0
bootstrap: <tmp>/edubox_server/config/passwords.yaml exists, left unchanged
bootstrap: ERROR <tmp>/edubox_server/config/passwords.yaml is missing keys that passwords.example.yaml defines:
  - test.e2eControlToken
bootstrap: copy them from passwords.example.yaml (dev-only values), or move
bootstrap: passwords.yaml aside and re-run tool/bootstrap.sh.
missing exit=1
```

Then confirm the real checkout still passes and the script is lint-clean:

```sh
cd /home/hii/Documents/EduBox
bash tool/bootstrap.sh; echo "real exit=$?"
docker run --rm -v "$PWD/tool:/mnt:ro" koalaman/shellcheck:stable /mnt/bootstrap.sh; echo "shellcheck exit=$?"
```

Expected: `bootstrap: ... exists, left unchanged`, `real exit=0`, no ShellCheck findings, `shellcheck exit=0`.
If `real exit=1`, your own `passwords.yaml` is missing the listed keys: copy those lines from `passwords.example.yaml` into it by hand (never commit it) and rerun.

- [ ] **Step 4: Run the verification gate**

Run the gate block from "Global constraints" exactly.

- [ ] **Step 5: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add tool/bootstrap.sh
git commit -m "fix: bootstrap fails on passwords keys missing from passwords.yaml"
```

---

### Task 6: Direct test of the E2E run-mode gate with a hand-built config (carried LOW)

**Routing signal:** risky (auth).

**Files:**

- Modify: `edubox_server/test/integration/e2e/e2e_control_test.dart` (contract-owned; the orchestrator authorizes this task only; add one test, change nothing else)

**Interfaces:**

- Consumes (read-only, `edubox_server/lib/src/e2e/e2e_endpoint.dart`): `static bool E2eEndpoint.enabledForRunMode(String runMode, EduboxConfig config)` and `static bool E2eEndpoint.authorize({required String runMode, required EduboxConfig config, required String? expectedToken, required String providedToken})`; `const EduboxConfig({required StorageConfig storage, required bool e2eControl})` and `const StorageConfig({required Uri endpoint, required Uri publicEndpoint, required String bucket, required String region})` from `edubox_config.dart`; `EduboxConfig.e2eControlRunModes == {'development', 'test'}`.
  The file already imports `edubox_config.dart` and `e2e_endpoint.dart` and defines `const _testToken = 'test-only-e2e-control-token';`.
- Produces: a test that fails if the endpoint's own run-mode check is removed, which the existing tests (built through `EduboxConfig.load`) cannot detect.

- [ ] **Step 1: Write the test**

In `edubox_server/test/integration/e2e/e2e_control_test.dart`, inside `group('e2e control run-mode gate', () {`, insert this test immediately before the line `    test('the committed development mode leaves the route off', () {`:

```dart
    test('authorize rejects other run modes even for a hand-built config '
        'whose e2eControl is true', () {
      // Built directly, so EduboxConfig.load's run-mode gate never ran: only
      // the endpoint's own run-mode check stands between this config and the
      // route.
      final config = EduboxConfig(
        storage: StorageConfig(
          endpoint: Uri.parse('http://localhost:9000'),
          publicEndpoint: Uri.parse('http://localhost:9000'),
          bucket: 'edubox-test',
          region: 'us-east-1',
        ),
        e2eControl: true,
      );
      for (final mode in ['production', 'staging', 'preview', '']) {
        expect(
          E2eEndpoint.enabledForRunMode(mode, config),
          isFalse,
          reason: mode,
        );
        expect(
          E2eEndpoint.authorize(
            runMode: mode,
            config: config,
            expectedToken: _testToken,
            providedToken: _testToken,
          ),
          isFalse,
          reason: mode,
        );
      }
      // The same config is accepted in an allowed mode, so the denial above
      // comes from the run mode alone.
      expect(
        E2eEndpoint.authorize(
          runMode: 'test',
          config: config,
          expectedToken: _testToken,
          providedToken: _testToken,
        ),
        isTrue,
      );
    });
```

- [ ] **Step 2: Run it**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/e2e/e2e_control_test.dart -N "hand-built"
```

Expected: `+1: All tests passed!`.
It passes at once because the gate already exists; Step 3 proves it guards that gate.

- [ ] **Step 3: Prove the test catches a missing gate, then restore**

Temporarily remove the run-mode check from the read-only endpoint, run the test, and restore the file with git:

```sh
cd /home/hii/Documents/EduBox/edubox_server
sed -i 's/      EduboxConfig.e2eControlRunModes.contains(runMode) \&\& config.e2eControl;/      config.e2eControl;/' lib/src/e2e/e2e_endpoint.dart
grep -n '      config.e2eControl;' lib/src/e2e/e2e_endpoint.dart
dart test test/integration/e2e/e2e_control_test.dart -N "hand-built" 2>&1 | grep -E 'Expected: false|Some tests failed'
git checkout -- lib/src/e2e/e2e_endpoint.dart
git diff --quiet -- lib/src/e2e/ && echo "endpoint restored"
```

Expected: the `grep -n` shows one line (`30:      config.e2eControl;` or nearby), then `Expected: false` and `Some tests failed.`, then `endpoint restored`.
If `endpoint restored` is not printed, stop: `lib/src/e2e/**` must not be committed.

- [ ] **Step 4: Run the full file**

```sh
cd /home/hii/Documents/EduBox/edubox_server && dart test test/integration/e2e/e2e_control_test.dart
```

Expected: `All tests passed!` (the two `withServerpod` tests and the five run-mode gate tests).

- [ ] **Step 5: Run the verification gate**

Run the gate block from "Global constraints" exactly.

- [ ] **Step 6: Commit**

```sh
cd /home/hii/Documents/EduBox
git status --short
git add edubox_server/test/integration/e2e/e2e_control_test.dart
git commit -m "test: E2eEndpoint.authorize denies non-e2e run modes for a hand-built config"
```

Expected `git status --short` before staging: only ` M edubox_server/test/integration/e2e/e2e_control_test.dart` and `?? skills-lock.json`.

---

### Task 7: Backend phase gate from a clean clone (exit criteria 11-14, 16 server side)

**Routing signal:** routine (verification only; no commit unless a step fails, in which case report `BLOCKED:` instead of fixing outside this plan).

**Files:** none.

**Interfaces:**

- Consumes: everything committed by Tasks 1-6.
- Produces: evidence that a fresh checkout with only the prerequisites passes the server lint, generation check, tests and coverage gate, with no skipped test.

- [ ] **Step 1: Clone the committed branch into a temporary directory**

```sh
export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"
CLEAN=$(mktemp -d)
git clone --quiet --branch phase-1 /home/hii/Documents/EduBox "$CLEAN/EduBox"
cd "$CLEAN/EduBox"
test ! -e edubox_server/config/passwords.yaml && echo "no passwords.yaml in the clone"
bash tool/bootstrap.sh
dart pub get > /dev/null && echo "pub get ok"
```

Expected: `no passwords.yaml in the clone`, `bootstrap: created ... from passwords.example.yaml (dev-only values)`, `pub get ok`.

- [ ] **Step 2: Services, generation check, lint, tests, coverage**

Still in `$CLEAN/EduBox` (the compose project name is `edubox`, so this reuses the already running `postgres_test` and `minio` containers):

```sh
docker compose up -d --wait postgres_test minio
docker compose run --rm minio-init
(cd edubox_fixtures && dart test 2>&1 | tail -1)
(cd edubox_server && serverpod generate > /dev/null)
git status --porcelain -- edubox_server/lib/src/generated edubox_client/lib/src/protocol edubox_server/test/integration/test_tools; echo "generated-diff-check-done"
(cd edubox_server && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos)
(cd edubox_server && dart test --coverage=coverage 2>&1 | tail -1 \
  && dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib \
  && dart run ../tool/coverage_gate.dart coverage/lcov.info)
grep -rn "backend-pending" edubox_server/test || echo "no backend-pending tests left"
(cd edubox_server && dart build cli --target bin/main.dart --output build > /dev/null && echo "server build ok")
```

Expected: `All tests passed!` for the fixtures; only `generated-diff-check-done` (no generated diff); `Formatted N files (0 changed)` and `No issues found!`; `All tests passed!` for the server; `coverage gate: authorization ... PASS` with the three skipped gates; `no backend-pending tests left`; `server build ok`.

- [ ] **Step 3: Clean up the clone**

```sh
cd /home/hii/Documents/EduBox && rm -rf "$CLEAN" && git status --short
```

Expected: only `?? skills-lock.json`.

- [ ] **Step 4: Report**

Report the task list with commit hashes (`git log --oneline phase-1-contract-v1..HEAD`) and the gate output lines from Step 2.
No commit in this task.

## Follow-ups outside the backend track (for the orchestrator, not the executor)

- `docs/build/phase-1/contract.md` sections 2.5, 2.7 and 5 still describe `S3ObjectStore`, `runSeedStep` and `bin/seed` as stubs, and the `ObjectStore` doc comment in `object_store.dart` still says "BACKEND TRACK: implement"; both are contract-owned text.
- `edubox_server/dart_test.yaml` still defines the now unused `backend-pending` tag (contract-owned).
- `S3ObjectStore` is not registered as a Serverpod cloud storage in `lib/server.dart` (contract-owned); phase 1 does not need it, phase 2's `content.fileUrl` will construct it from `EduboxConfig` the way `E2eEndpoint` does.
- The bootstrap check in Task 5 is proven by a scripted temp-dir test, not a committed one, because no backend-owned path fits a shell test; a committed test would need a path such as `tool/test/` added to the ownership table.
