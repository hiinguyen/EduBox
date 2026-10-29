import 'dart:convert';
import 'dart:io';

import 'package:edubox_flutter/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vietnamese is the only supported and default locale', () async {
    expect(AppLocalizations.supportedLocales, const [Locale('vi')]);
    expect(AppLocalizations.delegate.isSupported(const Locale('vi')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isFalse);

    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(l10n.appName, 'EduBox');
    expect(l10n.signInWrongCredentials, 'Email hoặc mật khẩu không đúng');
    expect(l10n.backendUnreachable, 'Không kết nối được với EduBox');
    expect(l10n.accountNotSetUp, 'Tài khoản chưa được thiết lập');
    expect(l10n.retry, 'Thử lại');
  });

  test('the ARB is the single phase 1 key list with no duplicates', () {
    final file = File('lib/l10n/app_vi.arb');
    expect(file.existsSync(), isTrue, reason: 'missing app_vi.arb');
    final raw = file.readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['@@locale'], 'vi');

    final keys = decoded.keys.where((key) => !key.startsWith('@')).toList();
    expect(keys, isNotEmpty);
    for (final key in keys) {
      expect(decoded[key], isA<String>(), reason: key);
      expect((decoded[key] as String).trim(), isNotEmpty, reason: key);
    }

    final declared = RegExp(
      r'^\s{2}"([^"@][^"]*)"\s*:',
      multiLine: true,
    ).allMatches(raw).map((match) => match.group(1)!).toList();
    expect(
      declared.toSet(),
      hasLength(declared.length),
      reason: 'duplicate key',
    );

    // Resolved aliases: one canonical key per concept.
    expect(keys, isNot(contains('signingOut')));
    expect(keys, isNot(contains('eduboxMarkSemantics')));
    expect(keys, contains('signOutBusy'));
    expect(keys, contains('appMarkSemantics'));

    // Shared keys appear once.
    expect(keys.where((key) => key == 'retry'), hasLength(1));
    expect(keys.where((key) => key == 'signOut'), hasLength(1));
    expect(keys.where((key) => key == 'networkOffline'), hasLength(1));
  });

  test('every phase 1 screen key is present', () {
    final decoded =
        jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
            as Map<String, dynamic>;
    const required = {
      // App and sign-in.
      'appName',
      'appOpening',
      'signInTitle',
      'emailLabel',
      'passwordLabel',
      'signInButton',
      'signInSubmitting',
      'showPassword',
      'hidePassword',
      'emailRequired',
      'emailInvalid',
      'passwordRequired',
      'signInWrongCredentials',
      'backendUnreachable',
      'backendUnreachableHint',
      'signInTooManyAttempts',
      'signInAccountDisabled',
      'signInUnknownError',
      'signInHelp',
      // Account not set up.
      'accountNotSetUp',
      'accountNotSetUpBody',
      'accountNotSetUpContact',
      'accountSignedInAs',
      'accountSignedInAsSemantics',
      'accountCheckAgain',
      'accountChecking',
      'accountStillNotSetUp',
      'accountCheckedAt',
      'accountCheckFailedOffline',
      'signOut',
      'signOutBusy',
      'appMarkSemantics',
      // Student home and library.
      'navHome',
      'navLibrary',
      'studentHomeGreeting',
      'studentHomeGreetingNoName',
      'studentHomeDateLine',
      'studentHomeDateOnly',
      'studentHomeLibraryTitle',
      'studentHomeLibraryCount',
      'studentHomeOpenLibrary',
      'studentHomeLoadingLibrary',
      'studentHomeLibraryError',
      'studentHomeLibraryOfflineNoCache',
      'studentHomeProfileError',
      'studentNoClass',
      'studentNoClassHint',
      'libraryTitle',
      'libraryTotal',
      'libraryListSemantics',
      'librarySubjectOther',
      'libraryLoading',
      'libraryEmpty',
      'libraryEmptyHint',
      'libraryOfflineNoData',
      'libraryLoadError',
      'libraryLoadErrorWithTime',
      'libraryItemSemantics',
      'contentTypeEbook',
      'contentTypeVideo',
      'contentTypeExercise',
      'contentRowSemantics',
      'lastUpdatedAt',
      'networkOffline',
      'accountMenuTooltip',
      // Teacher home.
      'navTeacherOverview',
      'teacherClassesTitle',
      'teacherClassesCount',
      'classColumnName',
      'classColumnGrade',
      'classColumnSubjects',
      'classColumnStudents',
      'classGradeValue',
      'classStudentCount',
      'classRowSemantics',
      'valueMissing',
      'teacherRoleLabel',
      'teacherClassesLoading',
      'teacherClassesLoaded',
      'teacherClassesEmpty',
      'teacherClassesOfflineNoData',
      'teacherClassesError',
      'teacherClassesStaleError',
      'retrying',
      'networkOfflineStale',
      'networkReconnecting',
      // Parent home.
      'parentHomeStudentLabel',
      'parentHomeStudentSemantics',
      'parentHomeNoChild',
      'parentHomeLoadError',
      'parentHomeOfflineNoData',
      'parentMenuTooltip',
      // Shared sign-out dialog.
      'signOutConfirmTitle',
      'signOutConfirmBody',
      'signOutOfflineWarning',
      'signOutFailed',
      'cancel',
      'retry',
    };
    expect(decoded.keys.toSet(), containsAll(required));
  });
}
