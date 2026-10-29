// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'EduBox';

  @override
  String get appOpening => 'Đang mở EduBox…';

  @override
  String get appMarkSemantics => 'EduBox';

  @override
  String get signInTitle => 'Đăng nhập';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get signInButton => 'Đăng nhập';

  @override
  String get signInSubmitting => 'Đang đăng nhập…';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Email chưa đúng định dạng';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get signInWrongCredentials => 'Email hoặc mật khẩu không đúng';

  @override
  String get backendUnreachable => 'Không kết nối được với EduBox';

  @override
  String get backendUnreachableHint => 'Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String get retry => 'Thử lại';

  @override
  String get retrying => 'Đang thử lại…';

  @override
  String get signInTooManyAttempts =>
      'Đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.';

  @override
  String get signInAccountDisabled =>
      'Tài khoản này đang bị tạm khóa. Vui lòng liên hệ nhà trường.';

  @override
  String get signInUnknownError => 'Không đăng nhập được. Vui lòng thử lại.';

  @override
  String get signInHelp =>
      'Quên mật khẩu hoặc chưa có tài khoản? Vui lòng liên hệ nhà trường.';

  @override
  String get accountNotSetUp => 'Tài khoản chưa được thiết lập';

  @override
  String get accountNotSetUpBody =>
      'Bạn đã đăng nhập đúng, nhưng tài khoản này chưa được gán vai trò (học sinh, giáo viên hoặc phụ huynh). Việc này do nhà trường thực hiện, không phải lỗi của bạn.';

  @override
  String get accountNotSetUpContact =>
      'Hãy nhờ giáo viên hoặc quản trị viên của trường thiết lập giúp, rồi bấm \"Kiểm tra lại\".';

  @override
  String get accountSignedInAs => 'Đang đăng nhập bằng';

  @override
  String accountSignedInAsSemantics(String email) {
    return 'Đang đăng nhập bằng $email';
  }

  @override
  String get accountCheckAgain => 'Kiểm tra lại';

  @override
  String get accountChecking => 'Đang kiểm tra…';

  @override
  String get accountStillNotSetUp => 'Vẫn chưa được thiết lập.';

  @override
  String accountCheckedAt(String time) {
    return 'Đã kiểm tra lúc $time';
  }

  @override
  String get accountCheckFailedOffline =>
      'Chưa kiểm tra được vì không có kết nối mạng.';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get signOutBusy => 'Đang đăng xuất…';

  @override
  String get signOutConfirmTitle => 'Đăng xuất khỏi EduBox?';

  @override
  String get signOutConfirmBody =>
      'Em sẽ cần nhập lại email và mật khẩu để vào lại.';

  @override
  String get signOutOfflineWarning =>
      'Đang ngoại tuyến nên em sẽ chưa đăng nhập lại được cho tới khi có mạng.';

  @override
  String get signOutFailed => 'Không đăng xuất được. Hãy thử lại.';

  @override
  String get cancel => 'Hủy';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navLibrary => 'Thư viện';

  @override
  String get navTeacherOverview => 'Tổng quan';

  @override
  String studentHomeGreeting(String name) {
    return 'Chào $name';
  }

  @override
  String get studentHomeGreetingNoName => 'Xin chào';

  @override
  String studentHomeDateLine(String className, String date) {
    return '$className · $date';
  }

  @override
  String studentHomeDateOnly(String date) {
    return '$date';
  }

  @override
  String get studentHomeLibraryTitle => 'Mới thêm vào thư viện';

  @override
  String studentHomeLibraryCount(int count) {
    return '$count tài liệu cho lớp em';
  }

  @override
  String get studentHomeOpenLibrary => 'Mở thư viện';

  @override
  String get studentHomeLoadingLibrary => 'Đang tải thư viện';

  @override
  String get studentHomeLibraryError => 'Không tải được thư viện.';

  @override
  String get studentHomeLibraryOfflineNoCache =>
      'Không tải được thư viện vì đang ngoại tuyến.';

  @override
  String get studentHomeProfileError => 'Không tải được thông tin tài khoản.';

  @override
  String get studentNoClass => 'Em chưa được xếp vào lớp nào.';

  @override
  String get studentNoClassHint => 'Hãy nhờ giáo viên thêm em vào lớp.';

  @override
  String get libraryTitle => 'Thư viện';

  @override
  String libraryTotal(int count) {
    return '$count tài liệu';
  }

  @override
  String get libraryListSemantics => 'Danh sách tài liệu';

  @override
  String get librarySubjectOther => 'Môn khác';

  @override
  String get libraryLoading => 'Đang tải thư viện';

  @override
  String get libraryEmpty => 'Thư viện của lớp chưa có tài liệu nào.';

  @override
  String get libraryEmptyHint =>
      'Khi giáo viên duyệt tài liệu, tài liệu sẽ hiện ở đây.';

  @override
  String get libraryOfflineNoData =>
      'Máy chưa lưu danh sách tài liệu. Kết nối mạng để xem thư viện.';

  @override
  String get libraryLoadError => 'Không tải được thư viện.';

  @override
  String libraryLoadErrorWithTime(String time) {
    return 'Không tải được thư viện. Cập nhật lần cuối $time.';
  }

  @override
  String libraryItemSemantics(String title, String type) {
    return '$title, $type';
  }

  @override
  String get contentTypeEbook => 'Sách';

  @override
  String get contentTypeVideo => 'Video';

  @override
  String get contentTypeExercise => 'Bài tập';

  @override
  String contentRowSemantics(String title, String type, String subject) {
    return '$title, $type, $subject';
  }

  @override
  String lastUpdatedAt(String time) {
    return 'Cập nhật lần cuối $time.';
  }

  @override
  String get networkOffline =>
      'Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được.';

  @override
  String get networkOfflineStale =>
      'Đang ngoại tuyến. Dữ liệu hiển thị có thể chưa mới nhất.';

  @override
  String get networkReconnecting => 'Đã kết nối lại, đang cập nhật…';

  @override
  String get accountMenuTooltip => 'Tài khoản';

  @override
  String get parentMenuTooltip => 'Tùy chọn';

  @override
  String get teacherClassesTitle => 'Lớp của tôi';

  @override
  String teacherClassesCount(int count) {
    return '$count lớp';
  }

  @override
  String get classColumnName => 'Lớp';

  @override
  String get classColumnGrade => 'Khối';

  @override
  String get classColumnSubjects => 'Môn học';

  @override
  String get classColumnStudents => 'Học sinh';

  @override
  String classGradeValue(int grade) {
    return 'Khối $grade';
  }

  @override
  String classStudentCount(int count) {
    return '$count học sinh';
  }

  @override
  String classRowSemantics(String name, int grade, String subjects, int count) {
    return '$name, khối $grade, môn $subjects, $count học sinh';
  }

  @override
  String get valueMissing => '-';

  @override
  String get teacherRoleLabel => 'Giáo viên';

  @override
  String get teacherClassesLoading => 'Đang tải danh sách lớp';

  @override
  String teacherClassesLoaded(int count) {
    return 'Đã tải $count lớp';
  }

  @override
  String get teacherClassesEmpty =>
      'Bạn chưa được phân công lớp nào. Liên hệ quản trị viên của trường để được thêm vào lớp.';

  @override
  String get teacherClassesOfflineNoData =>
      'Chưa có danh sách lớp trên máy này. Danh sách sẽ hiện khi có mạng.';

  @override
  String get teacherClassesError => 'Không tải được danh sách lớp.';

  @override
  String teacherClassesStaleError(String time) {
    return 'Không cập nhật được danh sách lớp. Cập nhật lần cuối $time.';
  }

  @override
  String get parentHomeStudentLabel => 'Học sinh';

  @override
  String parentHomeStudentSemantics(String name) {
    return 'Học sinh: $name';
  }

  @override
  String get parentHomeNoChild =>
      'Tài khoản này chưa được liên kết với học sinh nào. Hãy liên hệ nhà trường để được hỗ trợ.';

  @override
  String get parentHomeLoadError => 'Không tải được thông tin học sinh.';

  @override
  String get parentHomeOfflineNoData =>
      'Chưa có thông tin học sinh trên máy này. Hãy kết nối mạng để tải.';
}
