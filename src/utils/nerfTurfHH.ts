/** PS5 rate under NERFTURFHH. */
export const NERFTURFHH_PS5_HOURLY = 100;
/** Non–standard 8-ball tables under NERFTURFHH. */
export const NERFTURFHH_TABLE_OTHER_HOURLY = 150;
/** Standard table game station under NERFTURFHH. */
export const NERFTURFHH_TABLE_STANDARD_HOURLY = 200;

export function getNerfTurfHHTableHourlyRate(station: {
  type: string;
  name: string;
}): number {
  if (station.type !== "8ball") return NERFTURFHH_TABLE_OTHER_HOURLY;
  const n = station.name.toLowerCase();
  if (n.includes("standard")) return NERFTURFHH_TABLE_STANDARD_HOURLY;
  return NERFTURFHH_TABLE_OTHER_HOURLY;
}
