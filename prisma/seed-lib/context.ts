import type { PrismaClient } from "../../src/generated/prisma/client";

/** Profile ids resolved once while seeding people, shared by the later seed steps. */
export interface SeedContext {
  readonly db: PrismaClient;
  readonly studentIds: Readonly<Record<string, string>>;
  readonly parentIds: Readonly<Record<string, string>>;
  readonly teacherIds: Readonly<Record<string, string>>;
  readonly userIds: Readonly<Record<string, string>>;
  readonly classIds: Readonly<Record<string, string>>;
}

/** A moment `daysFromToday` away at the given local wall-clock time. */
export function localTime(daysFromToday: number, hour: number, minute = 0, second = 0): Date {
  const date = new Date();
  date.setDate(date.getDate() + daysFromToday);
  date.setHours(hour, minute, second, 0);
  return date;
}

export function lookup(record: Readonly<Record<string, string>>, key: string): string {
  const value = record[key];

  if (!value) {
    throw new Error(`Seed reference not found: ${key}`);
  }
  return value;
}
