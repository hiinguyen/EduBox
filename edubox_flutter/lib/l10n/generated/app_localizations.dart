import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'EduBox'**
  String get appName;

  /// No description provided for @appOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở EduBox…'**
  String get appOpening;

  /// No description provided for @appMarkSemantics.
  ///
  /// In vi, this message translates to:
  /// **'EduBox'**
  String get appMarkSemantics;

  /// No description provided for @signInTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get signInTitle;

  /// No description provided for @emailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get signInButton;

  /// No description provided for @signInSubmitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập…'**
  String get signInSubmitting;

  /// No description provided for @showPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// No description provided for @emailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get passwordRequired;

  /// No description provided for @signInWrongCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu không đúng'**
  String get signInWrongCredentials;

  /// No description provided for @backendUnreachable.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được với EduBox'**
  String get backendUnreachable;

  /// No description provided for @backendUnreachableHint.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối mạng rồi thử lại.'**
  String get backendUnreachableHint;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @retrying.
  ///
  /// In vi, this message translates to:
  /// **'Đang thử lại…'**
  String get retrying;

  /// No description provided for @signInTooManyAttempts.
  ///
  /// In vi, this message translates to:
  /// **'Đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.'**
  String get signInTooManyAttempts;

  /// No description provided for @signInAccountDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đang bị tạm khóa. Vui lòng liên hệ nhà trường.'**
  String get signInAccountDisabled;

  /// No description provided for @signInUnknownError.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được. Vui lòng thử lại.'**
  String get signInUnknownError;

  /// No description provided for @signInHelp.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu hoặc chưa có tài khoản? Vui lòng liên hệ nhà trường.'**
  String get signInHelp;

  /// No description provided for @accountNotSetUp.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được thiết lập'**
  String get accountNotSetUp;

  /// No description provided for @accountNotSetUpBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đăng nhập đúng, nhưng tài khoản này chưa được gán vai trò (học sinh, giáo viên hoặc phụ huynh). Việc này do nhà trường thực hiện, không phải lỗi của bạn.'**
  String get accountNotSetUpBody;

  /// No description provided for @accountNotSetUpContact.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhờ giáo viên hoặc quản trị viên của trường thiết lập giúp, rồi bấm \"Kiểm tra lại\".'**
  String get accountNotSetUpContact;

  /// No description provided for @accountSignedInAs.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập bằng'**
  String get accountSignedInAs;

  /// No description provided for @accountSignedInAsSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập bằng {email}'**
  String accountSignedInAsSemantics(String email);

  /// No description provided for @accountCheckAgain.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại'**
  String get accountCheckAgain;

  /// No description provided for @accountChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get accountChecking;

  /// No description provided for @accountStillNotSetUp.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn chưa được thiết lập.'**
  String get accountStillNotSetUp;

  /// No description provided for @accountCheckedAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã kiểm tra lúc {time}'**
  String accountCheckedAt(String time);

  /// No description provided for @accountCheckFailedOffline.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kiểm tra được vì không có kết nối mạng.'**
  String get accountCheckFailedOffline;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @signOutBusy.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng xuất…'**
  String get signOutBusy;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi EduBox?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Em sẽ cần nhập lại email và mật khẩu để vào lại.'**
  String get signOutConfirmBody;

  /// No description provided for @signOutOfflineWarning.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến nên em sẽ chưa đăng nhập lại được cho tới khi có mạng.'**
  String get signOutOfflineWarning;

  /// No description provided for @signOutFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng xuất được. Hãy thử lại.'**
  String get signOutFailed;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get navLibrary;

  /// No description provided for @navTeacherOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get navTeacherOverview;

  /// No description provided for @studentHomeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào {name}'**
  String studentHomeGreeting(String name);

  /// No description provided for @studentHomeGreetingNoName.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào'**
  String get studentHomeGreetingNoName;

  /// No description provided for @studentHomeDateLine.
  ///
  /// In vi, this message translates to:
  /// **'{className} · {date}'**
  String studentHomeDateLine(String className, String date);

  /// No description provided for @studentHomeDateOnly.
  ///
  /// In vi, this message translates to:
  /// **'{date}'**
  String studentHomeDateOnly(String date);

  /// No description provided for @studentHomeLibraryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mới thêm vào thư viện'**
  String get studentHomeLibraryTitle;

  /// No description provided for @studentHomeLibraryCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} tài liệu cho lớp em'**
  String studentHomeLibraryCount(int count);

  /// No description provided for @studentHomeOpenLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Mở thư viện'**
  String get studentHomeOpenLibrary;

  /// No description provided for @studentHomeLoadingLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thư viện'**
  String get studentHomeLoadingLibrary;

  /// No description provided for @studentHomeLibraryError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thư viện.'**
  String get studentHomeLibraryError;

  /// No description provided for @studentHomeLibraryOfflineNoCache.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thư viện vì đang ngoại tuyến.'**
  String get studentHomeLibraryOfflineNoCache;

  /// No description provided for @studentHomeProfileError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin tài khoản.'**
  String get studentHomeProfileError;

  /// No description provided for @studentNoClass.
  ///
  /// In vi, this message translates to:
  /// **'Em chưa được xếp vào lớp nào.'**
  String get studentNoClass;

  /// No description provided for @studentNoClassHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhờ giáo viên thêm em vào lớp.'**
  String get studentNoClassHint;

  /// No description provided for @libraryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get libraryTitle;

  /// No description provided for @libraryTotal.
  ///
  /// In vi, this message translates to:
  /// **'{count} tài liệu'**
  String libraryTotal(int count);

  /// No description provided for @libraryListSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách tài liệu'**
  String get libraryListSemantics;

  /// No description provided for @librarySubjectOther.
  ///
  /// In vi, this message translates to:
  /// **'Môn khác'**
  String get librarySubjectOther;

  /// No description provided for @libraryLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thư viện'**
  String get libraryLoading;

  /// No description provided for @libraryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện của lớp chưa có tài liệu nào.'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Khi giáo viên duyệt tài liệu, tài liệu sẽ hiện ở đây.'**
  String get libraryEmptyHint;

  /// No description provided for @libraryOfflineNoData.
  ///
  /// In vi, this message translates to:
  /// **'Máy chưa lưu danh sách tài liệu. Kết nối mạng để xem thư viện.'**
  String get libraryOfflineNoData;

  /// No description provided for @libraryLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thư viện.'**
  String get libraryLoadError;

  /// No description provided for @libraryLoadErrorWithTime.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thư viện. Cập nhật lần cuối {time}.'**
  String libraryLoadErrorWithTime(String time);

  /// No description provided for @libraryItemSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{title}, {type}'**
  String libraryItemSemantics(String title, String type);

  /// No description provided for @contentTypeEbook.
  ///
  /// In vi, this message translates to:
  /// **'Sách'**
  String get contentTypeEbook;

  /// No description provided for @contentTypeVideo.
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get contentTypeVideo;

  /// No description provided for @contentTypeExercise.
  ///
  /// In vi, this message translates to:
  /// **'Bài tập'**
  String get contentTypeExercise;

  /// No description provided for @contentRowSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{title}, {type}, {subject}'**
  String contentRowSemantics(String title, String type, String subject);

  /// No description provided for @lastUpdatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lần cuối {time}.'**
  String lastUpdatedAt(String time);

  /// No description provided for @networkOffline.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được.'**
  String get networkOffline;

  /// No description provided for @networkOfflineStale.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến. Dữ liệu hiển thị có thể chưa mới nhất.'**
  String get networkOfflineStale;

  /// No description provided for @networkReconnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối lại, đang cập nhật…'**
  String get networkReconnecting;

  /// No description provided for @accountMenuTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accountMenuTooltip;

  /// No description provided for @parentMenuTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn'**
  String get parentMenuTooltip;

  /// No description provided for @teacherClassesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lớp của tôi'**
  String get teacherClassesTitle;

  /// No description provided for @teacherClassesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp'**
  String teacherClassesCount(int count);

  /// No description provided for @classColumnName.
  ///
  /// In vi, this message translates to:
  /// **'Lớp'**
  String get classColumnName;

  /// No description provided for @classColumnGrade.
  ///
  /// In vi, this message translates to:
  /// **'Khối'**
  String get classColumnGrade;

  /// No description provided for @classColumnSubjects.
  ///
  /// In vi, this message translates to:
  /// **'Môn học'**
  String get classColumnSubjects;

  /// No description provided for @classColumnStudents.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get classColumnStudents;

  /// No description provided for @classGradeValue.
  ///
  /// In vi, this message translates to:
  /// **'Khối {grade}'**
  String classGradeValue(int grade);

  /// No description provided for @classStudentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} học sinh'**
  String classStudentCount(int count);

  /// No description provided for @classRowSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{name}, khối {grade}, môn {subjects}, {count} học sinh'**
  String classRowSemantics(String name, int grade, String subjects, int count);

  /// No description provided for @valueMissing.
  ///
  /// In vi, this message translates to:
  /// **'-'**
  String get valueMissing;

  /// No description provided for @teacherRoleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giáo viên'**
  String get teacherRoleLabel;

  /// No description provided for @teacherClassesLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách lớp'**
  String get teacherClassesLoading;

  /// No description provided for @teacherClassesLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải {count} lớp'**
  String teacherClassesLoaded(int count);

  /// No description provided for @teacherClassesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa được phân công lớp nào. Liên hệ quản trị viên của trường để được thêm vào lớp.'**
  String get teacherClassesEmpty;

  /// No description provided for @teacherClassesOfflineNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh sách lớp trên máy này. Danh sách sẽ hiện khi có mạng.'**
  String get teacherClassesOfflineNoData;

  /// No description provided for @teacherClassesError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách lớp.'**
  String get teacherClassesError;

  /// No description provided for @teacherClassesStaleError.
  ///
  /// In vi, this message translates to:
  /// **'Không cập nhật được danh sách lớp. Cập nhật lần cuối {time}.'**
  String teacherClassesStaleError(String time);

  /// No description provided for @parentHomeStudentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get parentHomeStudentLabel;

  /// No description provided for @parentHomeStudentSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh: {name}'**
  String parentHomeStudentSemantics(String name);

  /// No description provided for @parentHomeNoChild.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này chưa được liên kết với học sinh nào. Hãy liên hệ nhà trường để được hỗ trợ.'**
  String get parentHomeNoChild;

  /// No description provided for @parentHomeLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin học sinh.'**
  String get parentHomeLoadError;

  /// No description provided for @parentHomeOfflineNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông tin học sinh trên máy này. Hãy kết nối mạng để tải.'**
  String get parentHomeOfflineNoData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
