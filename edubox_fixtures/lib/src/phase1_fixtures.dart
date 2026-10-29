import 'fixture_types.dart';

/// Dev-only password shared by every seeded demo account.
///
/// It exists only in the local Docker Compose stack and in tests; it is not a
/// secret and must never be reused anywhere else.
const String devPassword = 'EduBox-dev-2026';

/// Fixed fixture keys, so tests never repeat string literals.
abstract final class FixtureKeys {
  // Accounts.
  static const studentAn = 'student_an';
  static const studentHa = 'student_ha';
  static const studentBao = 'student_bao';
  static const studentNoClass = 'student_no_class';
  static const teacherLan = 'teacher_lan';
  static const teacherNam = 'teacher_nam';
  static const parentBinh = 'parent_binh';
  static const parentNoChild = 'parent_no_child';
  static const noProfile = 'no_profile';
  static const nullRole = 'null_role';
  static const blockedStudent = 'blocked_student';

  // Classes.
  static const class7A = 'class_7a';
  static const class7B = 'class_7b';
  static const class8A = 'class_8a';
  static const class9A = 'class_9a';

  // Content.
  static const ebookFractions = 'ebook_fractions';
  static const videoNarrative = 'video_narrative';
  static const exerciseFractions = 'exercise_fractions';
  static const ebookCells = 'ebook_cells';
  static const ebookClassRules = 'ebook_class_rules';
  static const ebookEnglishShared = 'ebook_english_shared';
  static const draftGeometry = 'draft_geometry';
  static const approvedOtherClass = 'approved_other_class';
  static const approved7BGrammar = 'approved_7b_grammar';

  // Reconnect deltas (applied only by the e2e control step, see contract.md).
  static const deltaReviewEbook = 'delta_review_ebook';
  static const deltaClass8B = 'delta_class_8b';
}

DateTime _at(int day, int hour) => DateTime.utc(2026, 10, day, hour);

/// The phase 1 fixture set. The seed command, the server tests, the app's
/// fake backend, and the app contract tests all read this one definition.
const List<AccountFixture> phase1Accounts = [
  AccountFixture(
    key: FixtureKeys.studentAn,
    email: 'hs.an@edubox.test',
    name: 'Nguyễn Minh An',
    role: 'student',
  ),
  AccountFixture(
    key: FixtureKeys.studentHa,
    email: 'hs.ha@edubox.test',
    name: 'Trần Thu Hà',
    role: 'student',
  ),
  AccountFixture(
    key: FixtureKeys.studentBao,
    email: 'hs.bao@edubox.test',
    name: 'Lê Quốc Bảo',
    role: 'student',
  ),
  AccountFixture(
    key: FixtureKeys.studentNoClass,
    email: 'hs.huy@edubox.test',
    name: 'Phạm Gia Huy',
    role: 'student',
  ),
  AccountFixture(
    key: FixtureKeys.teacherLan,
    email: 'gv.lan@edubox.test',
    name: 'Võ Thị Lan',
    role: 'teacher',
  ),
  AccountFixture(
    key: FixtureKeys.teacherNam,
    email: 'gv.nam@edubox.test',
    name: 'Đỗ Văn Nam',
    role: 'teacher',
  ),
  AccountFixture(
    key: FixtureKeys.parentBinh,
    email: 'ph.binh@edubox.test',
    name: 'Nguyễn Văn Bình',
    role: 'parent',
    linkedStudentKey: FixtureKeys.studentAn,
  ),
  AccountFixture(
    key: FixtureKeys.parentNoChild,
    email: 'ph.thao@edubox.test',
    name: 'Lý Thanh Thảo',
    role: 'parent',
  ),
  AccountFixture(
    key: FixtureKeys.noProfile,
    email: 'chua.thiet.lap@edubox.test',
    name: '',
    hasProfile: false,
  ),
  AccountFixture(
    key: FixtureKeys.nullRole,
    email: 'chua.co.vai.tro@edubox.test',
    name: 'Đặng Hữu Phúc',
  ),
  AccountFixture(
    key: FixtureKeys.blockedStudent,
    email: 'hs.bi.khoa@edubox.test',
    name: 'Hoàng Thị Mai',
    role: 'student',
    blocked: true,
  ),
];

const List<ClassFixture> phase1Classes = [
  ClassFixture(
    key: FixtureKeys.class7A,
    name: '7A',
    gradeLevel: 7,
    teacherKey: FixtureKeys.teacherLan,
    subjects: ['Toán', 'Ngữ văn', 'Khoa học tự nhiên'],
    studentKeys: [FixtureKeys.studentAn],
  ),
  ClassFixture(
    key: FixtureKeys.class7B,
    name: '7B',
    gradeLevel: 7,
    teacherKey: FixtureKeys.teacherLan,
    subjects: ['Toán', 'Tiếng Anh'],
    studentKeys: [FixtureKeys.studentHa],
  ),
  // Empty subjects and no students: the teacher-home "-" and "0" edge cases.
  ClassFixture(
    key: FixtureKeys.class8A,
    name: '8A',
    gradeLevel: 8,
    teacherKey: FixtureKeys.teacherLan,
    subjects: [],
    studentKeys: [],
  ),
  // Another teacher's class: its content must never reach student An.
  ClassFixture(
    key: FixtureKeys.class9A,
    name: '9A',
    gradeLevel: 9,
    teacherKey: FixtureKeys.teacherNam,
    subjects: ['Vật lý'],
    studentKeys: [FixtureKeys.studentBao],
  ),
];

final List<ContentFixture> phase1Content = [
  ContentFixture(
    key: FixtureKeys.ebookFractions,
    type: FixtureContentType.ebook,
    title: 'Phân số và số thập phân',
    subject: 'Toán',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(20, 8),
  ),
  ContentFixture(
    key: FixtureKeys.videoNarrative,
    type: FixtureContentType.video,
    title: 'Đọc hiểu văn bản tự sự',
    subject: 'Ngữ văn',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(21, 8),
  ),
  ContentFixture(
    key: FixtureKeys.exerciseFractions,
    type: FixtureContentType.exercise,
    title: 'Luyện tập: Phép cộng phân số',
    subject: 'Toán',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(22, 8),
  ),
  ContentFixture(
    key: FixtureKeys.ebookCells,
    type: FixtureContentType.ebook,
    title: 'Tế bào và mô',
    subject: 'Khoa học tự nhiên',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(23, 8),
  ),
  // Empty subject: grouped under `librarySubjectOther`.
  ContentFixture(
    key: FixtureKeys.ebookClassRules,
    type: FixtureContentType.ebook,
    title: 'Nội quy lớp học',
    subject: '',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(24, 8),
  ),
  // Scoped to two classes; its subject is not in 7A's subjects list.
  ContentFixture(
    key: FixtureKeys.ebookEnglishShared,
    type: FixtureContentType.ebook,
    title: 'Từ vựng Tiếng Anh 7 - Unit 1',
    subject: 'Tiếng Anh',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A, FixtureKeys.class7B],
    createdAt: _at(25, 8),
  ),
  // Draft for 7A: never visible to students (exit criterion 1).
  ContentFixture(
    key: FixtureKeys.draftGeometry,
    type: FixtureContentType.ebook,
    title: 'Bản nháp: Hình học chương 2',
    subject: 'Toán',
    gradeLevel: 7,
    status: FixtureContentStatus.draft,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7A],
    createdAt: _at(26, 8),
  ),
  // Approved for another teacher's class: never visible to An.
  ContentFixture(
    key: FixtureKeys.approvedOtherClass,
    type: FixtureContentType.video,
    title: 'Chuyển động cơ học',
    subject: 'Vật lý',
    gradeLevel: 9,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherNam,
    classKeys: [FixtureKeys.class9A],
    createdAt: _at(26, 9),
  ),
  ContentFixture(
    key: FixtureKeys.approved7BGrammar,
    type: FixtureContentType.ebook,
    title: 'Ngữ pháp: Thì hiện tại đơn',
    subject: 'Tiếng Anh',
    gradeLevel: 7,
    status: FixtureContentStatus.approved,
    ownerKey: FixtureKeys.teacherLan,
    classKeys: [FixtureKeys.class7B],
    createdAt: _at(27, 8),
  ),
];

/// Reconnect delta (exit criterion 7): one new approved item for 7A.
final ContentFixture reconnectDeltaContent = ContentFixture(
  key: FixtureKeys.deltaReviewEbook,
  type: FixtureContentType.ebook,
  title: 'Ôn tập chương 1',
  subject: 'Toán',
  gradeLevel: 7,
  status: FixtureContentStatus.approved,
  ownerKey: FixtureKeys.teacherLan,
  classKeys: [FixtureKeys.class7A],
  createdAt: _at(28, 8),
);

/// Reconnect delta (exit criterion 7): one new class for teacher Lan.
const ClassFixture reconnectDeltaClass = ClassFixture(
  key: FixtureKeys.deltaClass8B,
  name: '8B',
  gradeLevel: 8,
  teacherKey: FixtureKeys.teacherLan,
  subjects: ['Toán'],
  studentKeys: [],
);
