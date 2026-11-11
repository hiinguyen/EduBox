import { fail } from "@/lib/server/action-result";

export const DEADLINE_PASSED_MESSAGE = "Đã hết giờ làm bài nên không thể lưu thêm đáp án.";
export const ALREADY_SUBMITTED_MESSAGE = "Bài làm đã được nộp, không thể thay đổi.";
export const NOT_STARTABLE_MESSAGE = "Bài thi này hiện không thể bắt đầu. Hãy tải lại trang.";
export const OVERDUE_MESSAGE = "Bài thi đã quá hạn nộp nên không thể bắt đầu.";
export const NETWORK_MESSAGE =
  "Không thể kết nối máy chủ. Đáp án vẫn được giữ trên thiết bị này, hãy thử lại.";

/** The shared error set has no dedicated deadline code, so these are CONFLICT with their own message. */
export const deadlinePassed = () => fail("CONFLICT", DEADLINE_PASSED_MESSAGE);
export const alreadySubmitted = () => fail("CONFLICT", ALREADY_SUBMITTED_MESSAGE);
export const notStartable = () => fail("CONFLICT", NOT_STARTABLE_MESSAGE);
export const overdue = () => fail("CONFLICT", OVERDUE_MESSAGE);
