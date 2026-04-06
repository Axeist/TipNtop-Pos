import { getDay } from "date-fns";

export interface HappyHourSlot {
  start_time: string;
}

/** Mon–Fri; includes slot starts through 4:00–4:59 PM (last block 4–5 PM). Excludes starts at 5:00 PM and later. */
export function isHappyHour(date: Date, slot: HappyHourSlot | null): boolean {
  if (!slot) return false;
  const day = getDay(date);
  const startHour = Number(slot.start_time.split(":")[0]);
  return day >= 1 && day <= 5 && startHour >= 11 && startHour < 17;
}

/** Same window as {@link isHappyHour} for the current local time (hour-level check). */
export function isHappyHourNow(): boolean {
  const now = new Date();
  const day = now.getDay();
  const h = now.getHours();
  return day >= 1 && day <= 5 && h >= 11 && h < 17;
}
