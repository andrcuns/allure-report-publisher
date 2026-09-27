import AllureReporter from 'allure-vitest/reporter'
import {configDefaults, defineConfig} from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    // Route console output through the streams captured by command tests.
    disableConsoleIntercept: true,
    pool: 'forks',
    isolate: true,
    testTimeout: 60_000,
    hookTimeout: 60_000,
    clearMocks: true,
    restoreMocks: true,
    unstubEnvs: true,
    sequence: {hooks: 'list', setupFiles: 'list'},
    setupFiles: ['allure-vitest/setup', './test/support/setup.ts', './test/support/hooks.ts'],
    reporters: ['default', new AllureReporter({resultsDir: 'tmp/allure-results'})],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['**/*.d.ts', 'test/**', 'dist/**', 'tmp/**'],
      reporter: ['text', 'lcov', 'json', 'json-summary'],
      reportsDirectory: 'coverage',
    },
    projects: [
      {
        extends: true,
        test: {
          name: 'unit',
          include: ['test/**/*.test.ts'],
          exclude: [...configDefaults.exclude, 'test/e2e/**'],
          env: {E2E_TEST: 'false'},
        },
      },
      {
        extends: true,
        test: {
          name: 'e2e',
          include: ['test/e2e/**/*.test.ts'],
          env: {E2E_TEST: 'true'},
        },
      },
    ],
  },
})
