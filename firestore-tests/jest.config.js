/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["<rootDir>/src/**/*.test.ts"],
  // Rules-unit-testing spins up a real emulator connection per test file;
  // one Jest worker keeps every test talking to the same emulator instance
  // instead of racing several against it.
  maxWorkers: 1,
};
