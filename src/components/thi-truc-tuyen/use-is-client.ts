import { useSyncExternalStore } from "react";

function subscribe(): () => void {
  return () => undefined;
}

/** False during server render and hydration, true afterwards, without an effect. */
export function useIsClient(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => true,
    () => false,
  );
}
