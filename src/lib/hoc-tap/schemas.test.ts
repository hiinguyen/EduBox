import { describe, expect, it } from "vitest";
import { MAX_CHAT_LENGTH, MAX_NOTE_LENGTH } from "./constants";
import {
  chatInputSchema,
  chatRequestSchema,
  saveNoteInputSchema,
  updateProgressInputSchema,
} from "./schemas";

describe("chatInputSchema", () => {
  it("trims surrounding whitespace from a valid message", () => {
    const result = chatInputSchema.safeParse("  f'(x) = 3x^2 - 3  ");

    expect(result.data).toBe("f'(x) = 3x^2 - 3");
  });

  it("rejects an empty message with a Vietnamese error", () => {
    const result = chatInputSchema.safeParse("   ");

    expect(result.error?.issues[0]?.message).toBe("Vui lòng nhập câu hỏi hoặc câu trả lời.");
  });

  it("rejects a message longer than the limit", () => {
    expect(chatInputSchema.safeParse("a".repeat(MAX_CHAT_LENGTH + 1)).success).toBe(false);
  });

  it("rejects non-string input", () => {
    expect(chatInputSchema.safeParse(42).success).toBe(false);
  });
});

describe("chatRequestSchema", () => {
  it("accepts a message without a thread id", () => {
    expect(chatRequestSchema.safeParse({ message: "xin chào" }).success).toBe(true);
  });

  it("rejects an empty thread id", () => {
    expect(chatRequestSchema.safeParse({ message: "a", threadId: "" }).success).toBe(false);
  });
});

describe("saveNoteInputSchema", () => {
  const valid = { lessonId: "l1", atSeconds: 90, body: "Nhớ xét dấu" };

  it("accepts a valid note", () => {
    expect(saveNoteInputSchema.safeParse(valid).success).toBe(true);
  });

  it("rejects a negative or fractional timestamp", () => {
    expect(saveNoteInputSchema.safeParse({ ...valid, atSeconds: -1 }).success).toBe(false);
    expect(saveNoteInputSchema.safeParse({ ...valid, atSeconds: 1.5 }).success).toBe(false);
  });

  it("rejects an over-length body", () => {
    const body = "a".repeat(MAX_NOTE_LENGTH + 1);

    expect(saveNoteInputSchema.safeParse({ ...valid, body }).success).toBe(false);
  });
});

describe("updateProgressInputSchema", () => {
  it("accepts a position with an optional completion flag", () => {
    const result = updateProgressInputSchema.safeParse({ lessonId: "l1", positionSeconds: 10 });

    expect(result.success).toBe(true);
  });

  it("rejects an unreasonable position", () => {
    const result = updateProgressInputSchema.safeParse({ lessonId: "l1", positionSeconds: 1e9 });

    expect(result.success).toBe(false);
  });
});
