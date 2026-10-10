# Agent Development Guide

This document provides coding guidelines and commands for agentic coding assistants working on the allure-report-publisher codebase.

## Project Overview

allure-report-publisher is a CLI tool built with oclif that publishes Allure 3 test reports to cloud storage providers (AWS S3, GCS). It integrates with GitHub Actions and GitLab CI for automated PR/MR updates.

## Build, Lint, and Test Commands

### Building

```bash
pnpm run build              # Incremental TypeScript build
pnpm run cleanBuild         # Clean and rebuild from scratch
```

### Linting and Formatting

```bash
pnpm run lint               # Run oxlint on all files
pnpm run lint:agent         # Run oxlint with agent-friendly output
pnpm run format             # Format JavaScript and TypeScript with oxfmt
pnpm run fmt:check          # Check formatting without modifying files
```

### Testing

```bash
pnpm run test                        # All tests, including Docker E2E, with coverage
pnpm run test:unit                   # Unit/command tests, no Docker required
pnpm run test:e2e                    # Real Docker E2E tests with coverage
pnpm run test:typecheck              # Typecheck tests, support, and Vitest config
pnpm run test:watch                  # Watch tests (includes Docker E2E by default)
pnpm run build
pnpm exec vitest run test/path/to/file.test.ts
pnpm exec vitest run -t "test name pattern"
```

Use Node 26 for development and pnpm 12.6.0, as selected by `mise.toml`. Test tooling requires Node 22.12.0+ on the Node 22 line; the published CLI engine remains `>=22.0.0`.

Test scripts build oclif command metadata before running. Direct `pnpm exec vitest` commands require a prior build on a fresh checkout. Watch mode does not rebuild that metadata: after changing command flags/help, rebuild and restart watch mode. Use `pnpm run test:watch --project unit` to watch without Docker.

### Development

```bash
bin/dev.js COMMAND          # Run CLI from source without building
pnpm install                # Install dependencies
mise install                # Install dev tools (requires mise)
```

### Other Commands

```bash
pnpm run prepack            # Generate manifest and README
pnpm run readme             # Update README with command docs
```

## Code Style and Conventions

### General Principles

- Use **strict TypeScript** with explicit types (no `any`)
- Prefer **composition over inheritance**
- Use **abstract classes** for shared behavior with required implementations
- Follow **oclif conventions** for command structure
- Keep classes **focused and single-purpose**

### Import Conventions

1. **Always use `.js` extensions** in imports (required for ES modules):

   ```typescript
   import {logger} from '../../utils/logger.js'
   import {S3Uploader} from '../../lib/uploader/cloud/s3.js'
   ```

2. **Group imports** in this order:
   - External packages (alphabetically)
   - Internal modules starting with '../../' or './'
   - Types (if importing separately)

3. **Use named imports** for clarity:

   ```typescript
   import {readFileSync, writeFileSync} from 'node:fs'
   import path from 'node:path'
   ```

4. **Use `node:` prefix** for Node.js built-ins:

   ```typescript
   import {readFileSync} from 'node:fs'
   import path from 'node:path'
   import {fileURLToPath} from 'node:url'
   ```

### Formatting

- **2 spaces** for indentation
- **No semicolons** at end of statements
- **Single quotes** for strings (except when avoiding escapes)
- **Trailing commas** in multiline objects/arrays
- Formatter config: `.oxfmtrc.json`
- Linter config: `.oxlintrc.json` (test overrides allow supported Chai-style assertions)

### TypeScript Conventions

#### Type Definitions

```typescript
// Use explicit return types on public methods
public async upload(): Promise<void> {
  // ...
}

// Define types for complex objects
type SummaryStats = {
  passed: number
  failed: number
  flaky: number
  total: number
}

// Use union types for enums
export type UpdatePRMode = 'actions' | 'comment' | 'description'
```

#### Null/Undefined Handling

```typescript
// Use optional chaining and nullish coalescing
const value = data?.stats?.passed ?? 0

// Check for undefined explicitly
if (this._reportFiles === undefined) return
```

#### Class Patterns

```typescript
// Private fields prefixed with underscore for cached values
private _reportFiles: string[] | undefined

// Getters for lazy initialization
protected get runId() {
  if (this._runId !== undefined) return this._runId
  this._runId = this.ciInfo?.runId || this.historyUuid()
  return this._runId
}
```

### Naming Conventions

- **Classes**: PascalCase (e.g., `BaseCloudUploader`, `ReportGenerator`)
- **Methods/Functions**: camelCase (e.g., `uploadReport`, `getReportFiles`)
- **Constants**: camelCase (e.g., `const logger = new Logger()`)
- **Private fields**: camelCase with underscore prefix (e.g., `_reportFiles`)
- **Files**: kebab-case (e.g., `report-generator.ts`, `url-section-builder.ts`)
- **Test files**: `*.test.ts` suffix

### Error Handling

#### Commands

```typescript
// In oclif commands, use this.error() to exit with error
try {
  await this.validateInputs(flags)
  // ... command logic
} catch (error) {
  this.error(error as Error, {exit: 1})
}
```

#### Async Operations with Spinner

```typescript
// Use spin() utility for async operations with user feedback
await spin(uploader.uploadReport(), 'uploading report files')
await spin(uploader.downloadHistory(), 'downloading history', {ignoreError: true})
```

#### Validation

```typescript
// Validate early, throw descriptive errors
if (flags.parallel < 1) {
  throw new Error(`Invalid parallel threads: ${flags.parallel}\nParallel threads must be >= 1`)
}

if (!existsSync(flags.config)) {
  throw new Error(`Config file not found at path: ${flags.config}`)
}
```

### Logging

```typescript
// Use the logger utility (not console.log directly)
logger.section('Generating allure report')  // Section headers
logger.info('Processing files...')          // Info messages
logger.success('Upload complete')           // Success messages
logger.warn('No history found')             // Warnings
logger.error('Upload failed')               // Errors
logger.debug('Debug details')               // Debug info (buffered)
```

### Testing Conventions

- Use **Vitest** for the runner, assertions, spies, module mocks, and coverage
- Import `describe`, `it`, `expect`, lifecycle functions, and `vi` explicitly from `vitest`
- Use `test/support/command.ts` for in-process oclif command tests, passing an argument array
- Use **Testcontainers** for real E2E services; Docker must be available for E2E/default runs
- Keep Allure results in `tmp/allure-results/` and LCOV coverage in `coverage/`
- Test files mirror source structure: `test/lib/ci/pr/report-summary.test.ts`

```typescript
import {describe, expect, it} from 'vitest'

import {runCommand} from '../../support/command.js'

describe('upload help', () => {
  it('prints help', async () => {
    const {stdout, error} = await runCommand(['upload', 's3', '--help'])
    expect(error).toBeUndefined()
    expect(stdout).toContain('Generate and upload allure report to s3 bucket')
  })
})
```

## Architecture Patterns

### Command Structure

- Commands extend `BaseUploadCommand` or `BaseCloudUploadCommand`
- Flags defined as static properties
- Abstract methods for uploader instantiation
- Validation in `validateInputs()`
- Main logic in `run()`

### Uploader Pattern

- Cloud uploaders extend `BaseCloudUploader`
- Abstract methods: `uploadHistory()`, `uploadReport()`, `reportUrlBase()`, `createLatestCopy()`
- Lazy initialization with caching (e.g., `_reportFiles`)

### Provider Pattern

- CI providers extend `BaseCiProvider`
- Implement `addReportSection()` for platform-specific PR/MR updates

## File References

When providing code references to users, use the pattern `file_path:line_number`:

```
Clients are marked as failed in src/lib/uploader/cloud/s3.ts:42
```

## Common Pitfalls to Avoid

- ❌ Importing without `.js` extension - will cause runtime errors
- ❌ Using `console.log()` directly - use `logger` utility
- ❌ Missing `node:` prefix for Node built-ins - inconsistent with codebase style
- ❌ Using `any` type - violates strict TypeScript configuration
- ❌ Forgetting `async`/`await` for Promise-returning methods
- ❌ Not using `spin()` for user-facing async operations
