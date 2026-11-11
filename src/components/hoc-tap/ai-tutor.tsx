"use client";

import { useEffect, useRef, useState } from "react";
import type { FormEvent } from "react";
import { Card } from "@/components/ui/card";
import { postChatMessage } from "@/lib/hoc-tap/chat-client";
import { chatInputSchema } from "@/lib/hoc-tap/schemas";
import type { ChatMessage } from "@/lib/hoc-tap/types";
import { AssistantBubble, StudentBubble } from "./chat-messages";
import { TutorComposer } from "./tutor-composer";
import { TutorHeader } from "./tutor-header";

interface AiTutorProps {
  readonly initialMessages: readonly ChatMessage[];
  readonly initialThreadId: string | null;
  readonly studentName: string;
}

export function AiTutor({ initialMessages, initialThreadId, studentName }: AiTutorProps) {
  const [messages, setMessages] = useState<readonly ChatMessage[]>(initialMessages);
  const [threadId, setThreadId] = useState(initialThreadId);
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPending, setIsPending] = useState(false);
  const streamRef = useRef<HTMLDivElement>(null);
  const hasInteractedRef = useRef(false);

  useEffect(() => {
    const stream = streamRef.current;
    if (!hasInteractedRef.current || !stream) return;
    stream.scrollTo({ top: stream.scrollHeight });
  }, [messages, isPending]);

  async function send(rawText: string): Promise<boolean> {
    if (isPending) return false;
    const parsed = chatInputSchema.safeParse(rawText);
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? null);
      return false;
    }
    hasInteractedRef.current = true;
    setError(null);
    setIsPending(true);
    const result = await postChatMessage(parsed.data, threadId);
    setIsPending(false);
    if (!result.ok) {
      setError(result.error.message);
      return false;
    }
    setThreadId(result.data.threadId);
    setMessages((previous) => [...previous, ...result.data.messages]);
    return true;
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (await send(draft)) setDraft("");
  }

  return (
    <Card
      as="section"
      aria-labelledby="tutor-heading"
      className="flex flex-col overflow-hidden p-0! shadow-md!"
    >
      <TutorHeader />
      <div
        ref={streamRef}
        role="log"
        aria-live="polite"
        aria-label="Cuộc trò chuyện với gia sư AI"
        className="flex max-h-[460px] flex-col gap-space-md overflow-y-auto bg-surface p-space-md"
      >
        {messages.length === 0 ? (
          <p className="text-center font-body-sm text-body-sm text-on-surface-variant">
            Hãy gửi câu hỏi đầu tiên để bắt đầu cùng gia sư AI.
          </p>
        ) : null}
        {messages.map((message) =>
          message.role === "student" ? (
            <StudentBubble key={message.id} message={message} studentName={studentName} />
          ) : (
            <AssistantBubble key={message.id} message={message} onSuggestion={send} />
          ),
        )}
        {isPending ? (
          <p className="font-label-sm text-label-sm text-on-surface-variant">
            Gia sư AI đang suy nghĩ...
          </p>
        ) : null}
      </div>
      <TutorComposer
        draft={draft}
        error={error}
        isPending={isPending}
        onDraftChange={setDraft}
        onSubmit={handleSubmit}
        onHintRequest={send}
      />
    </Card>
  );
}
