import 'app_locale_controller.dart';

/// Every user-facing string the app's own widgets show, in Vietnamese
/// and English. Anything Flutter's own built-in widgets show (the
/// date/time picker chrome) is localized separately via
/// `flutter_localizations` + `MaterialApp.locale`, not through here.
class Strings {
  final AppLang lang;
  const Strings(this.lang);

  bool get isVi => lang == AppLang.vi;

  String _pick(String vi, String en) => isVi ? vi : en;

  String get appTitle => "BaoKhongNgu";
  String get tabTodo => _pick('Việc cần làm', 'To-do');
  String get tabDont => _pick('Việc không làm', "Don't");
  String get pending => _pick('Đang chờ', 'Pending');
  String get holding => _pick('Đang giữ', 'Holding');
  String get doneToday => _pick('Xong hôm nay', 'Done today');
  String get heldToday => _pick('Giữ được hôm nay', 'Held today');
  String get emptyList => _pick(
        'Chưa có việc nào, bấm nút + để thêm.',
        'No tasks yet — tap + to add one.',
      );
  String completed(int n) => _pick('Đã hoàn thành ($n)', 'Completed ($n)');
  String get addTask => _pick('Thêm việc mới', 'Add a new task');

  String get newTask => _pick('Việc mới', 'New task');
  String get taskDetails => _pick('Chi tiết việc', 'Task details');
  String get cancel => _pick('Huỷ', 'Cancel');
  String get close => _pick('Đóng', 'Close');
  String get save => _pick('Lưu', 'Save');
  String get titleLabel => _pick('Tên công việc', 'Task title');
  String get titleRequired => _pick('Nhập tên công việc trước đã', 'Enter a title first');
  String get notesLabel => _pick('Ghi chú (không bắt buộc)', 'Notes (optional)');
  String get noDueDate => _pick('Không có hạn', 'No due date');
  String dueOn(String date) => _pick('Hạn: $date', 'Due: $date');
  String get reminderLabel => _pick('Nhắc nhở', 'Reminder');
  String get remNone => _pick('Không nhắc', 'No reminder');
  String get remOnce => _pick('Một lần đúng lúc đến hạn', 'Once, right at the due time');
  String get remDaily => _pick('Nhắc mỗi ngày', 'Every day');
  String get remEveryN => _pick('Nhắc mỗi ... ngày (tuỳ chỉnh)', 'Every ... days (custom)');
  String get remWeekday => _pick('Theo thứ trong tuần', 'On specific weekdays');
  String atTime(String time) => _pick('Vào lúc $time', 'At $time');
  String get everyPrefix => _pick('Nhắc mỗi', 'Every');
  String get daysSuffix => _pick('ngày', 'days');
  String get applyRule => _pick('Áp dụng quy tắc đã lưu', 'Apply a saved rule');
  String get saveAsRule => _pick('+ Lưu cài đặt này thành quy tắc', '+ Save this as a rule');

  String get trashTitle => _pick('Thùng rác', 'Trash');
  String get trashEmpty => _pick('Thùng rác trống.', 'Trash is empty.');
  String trashCount(int n) => _pick('$n/20 mục — tự xoá hẳn sau 5 ngày', '$n/20 items — auto-deleted after 5 days');
  String daysLeft(int d) => _pick('Còn $d ngày trước khi xoá hẳn', '$d days left before permanent deletion');
  String get restore => _pick('Khôi phục', 'Restore');
  String get deleteForever => _pick('Xoá vĩnh viễn', 'Delete forever');

  String get calendarTitle => _pick('Lịch', 'Calendar');
  String get calendarNote => _pick(
        'Số nhỏ bên dưới là ngày âm lịch. Ngày mùng 1 âm lịch hiện thêm số tháng (vd: 1/9).',
        'The small number below is the lunar date. The 1st of a lunar month also shows the month (e.g. 1/9).',
      );

  String get rulesTitle => _pick('Quy tắc nhắc nhở', 'Reminder rules');
  String get rulesNote => _pick(
        'Tạo quy tắc mới khi đặt nhắc nhở cho một việc, rồi bấm "Lưu cài đặt này thành quy tắc".',
        'Create a rule while setting a reminder on a task, then tap "Save this as a rule".',
      );
  String get rulesEmpty => _pick('Chưa có quy tắc nào.', 'No rules yet.');

  String overdue(int d) => _pick('Quá hạn $d ngày', 'Overdue ${d}d');
  String get today => _pick('Hôm nay', 'Today');
  String get tomorrow => _pick('Ngày mai', 'Tomorrow');
  String inDays(int d) => _pick('$d ngày nữa', 'In $d days');

  String get backupTitle => _pick('Sao lưu & khôi phục', 'Backup & restore');
  String get exportBackup => _pick('Xuất bản sao lưu', 'Export a backup');
  String get restoreBackup => _pick('Khôi phục từ bản sao lưu', 'Restore from backup');
  String get checkIntegrity => _pick('Kiểm tra tính toàn vẹn dữ liệu', 'Check data integrity');
  String get restoreConfirmTitle => _pick('Khôi phục dữ liệu?', 'Restore data?');
  String get restoreConfirmBody => _pick(
        'Thao tác này sẽ thay thế toàn bộ việc và quy tắc hiện có bằng nội dung trong bản sao lưu. Không thể hoàn tác.',
        'This replaces every current task and rule with what is in the backup file. This cannot be undone.',
      );
  String get confirm => _pick('Đồng ý', 'Confirm');
  String exportSuccess(String path) => _pick('Đã lưu bản sao lưu tại:\n$path', 'Backup saved at:\n$path');
  String restoreSuccess(int tasks, int rules) => _pick(
        'Đã khôi phục $tasks việc và $rules quy tắc.',
        'Restored $tasks tasks and $rules rules.',
      );
  String skippedRows(int n) => _pick('Bỏ qua $n dòng dữ liệu không hợp lệ.', 'Skipped $n invalid rows.');
  String get noBackupFile => _pick('Chưa có bản sao lưu nào trên máy.', 'No backup file on this device yet.');
  String get noIssuesFound => _pick('Không phát hiện lỗi dữ liệu nào.', 'No data issues found.');
  String issuesFound(int n) => _pick('Phát hiện $n vấn đề:', 'Found $n issue(s):');

  static const Map<int, String> weekdayViShort = {
    1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN',
  };
  static const Map<int, String> weekdayEnShort = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };
  Map<int, String> get weekdayShort => isVi ? weekdayViShort : weekdayEnShort;
}
