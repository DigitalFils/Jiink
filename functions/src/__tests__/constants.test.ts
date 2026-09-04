import { applicationFeeFor, PLATFORM_FEE_BPS } from "../constants";

describe("applicationFeeFor", () => {
  it("takes 8% of the sale amount", () => {
    expect(PLATFORM_FEE_BPS).toBe(800);
    expect(applicationFeeFor(1000)).toBe(80);
  });

  it("rounds to the nearest whole pence", () => {
    expect(applicationFeeFor(999)).toBe(80); // 79.92 -> 80
    expect(applicationFeeFor(1)).toBe(0); // 0.08 -> 0
  });

  it("returns 0 for a free listing", () => {
    expect(applicationFeeFor(0)).toBe(0);
  });
});
