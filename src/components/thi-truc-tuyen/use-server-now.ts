import { toServerTime } from "@/lib/thi-truc-tuyen/clock";
import { useExam } from "./exam-provider";
import { useNow } from "./use-now";

/** The current time on the server's clock, ticking every second. */
export function useServerNow(): number {
  const { clockOffsetMs } = useExam();
  return toServerTime(useNow(), clockOffsetMs);
}
