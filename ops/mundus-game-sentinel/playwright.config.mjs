import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir:'.',testMatch:'browser-smoke.spec.mjs',timeout:45000,expect:{timeout:8000},fullyParallel:false,workers:1,
  outputDir:'artifacts/playwright',reporter:[['list'],['json',{outputFile:'artifacts/browser-results.json'}]],
  use:{ignoreHTTPSErrors:true,screenshot:'only-on-failure',video:'off',trace:'retain-on-failure'}
});
