/**
 * Offset to add to the browser clock to get server time, measured when the page
 * was rendered. It only corrects display and ordering; the server decides deadlines.
 */
export function getClockOffsetMs(serverNow: number, clientNow: number): number {
  return serverNow - clientNow;
}

export function toServerTime(clientNow: number, offsetMs: number): number {
  return clientNow + offsetMs;
}
