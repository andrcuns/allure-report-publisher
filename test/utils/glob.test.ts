import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'

import {getAllureResultsPaths, globPaths} from '../../src/utils/glob.js'
import {expect} from '../support/setup.js'

describe('glob utilities', () => {
  let tempDir: string

  beforeEach(() => {
    tempDir = join(tmpdir(), `glob-test-${Date.now()}`)
    mkdirSync(tempDir, {recursive: true})
  })

  afterEach(() => {
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('globPaths()', () => {
    it('returns matching file paths', async () => {
      const file1 = join(tempDir, 'test1.txt')
      const file2 = join(tempDir, 'test2.txt')
      writeFileSync(file1, 'content')
      writeFileSync(file2, 'content')

      const results = await globPaths(join(tempDir, '*.txt'))

      expect(results).to.have.lengthOf(2)
      expect(results).to.include(file1)
      expect(results).to.include(file2)
    })

    it('returns absolute paths', async () => {
      const file = join(tempDir, 'test.txt')
      writeFileSync(file, 'content')

      const results = await globPaths(join(tempDir, '*.txt'))

      expect(results[0]).to.match(/^\//)
    })

    it('returns empty array when no matches found', async () => {
      const results = await globPaths(join(tempDir, '*.nonexistent'))

      expect(results).to.have.lengthOf(0)
    })

    it('includes directories by default', async () => {
      const dir = join(tempDir, 'subdir')
      mkdirSync(dir)

      const results = await globPaths(join(tempDir, '*'))

      expect(results).to.include(dir)
    })

    it('excludes directories when nodir option is true', async () => {
      const dir = join(tempDir, 'subdir')
      const file = join(tempDir, 'file.txt')
      mkdirSync(dir)
      writeFileSync(file, 'content')

      const results = await globPaths(join(tempDir, '*'), {nodir: true})

      expect(results).to.not.include(dir)
      expect(results).to.include(file)
    })
  })

  describe('getAllureResultsPaths()', () => {
    it('returns paths to directories containing json files', async () => {
      const resultsDir = join(tempDir, 'allure-results')
      mkdirSync(resultsDir)
      writeFileSync(join(resultsDir, 'result.json'), '{}')

      const results = await getAllureResultsPaths(resultsDir)

      expect(results).to.have.lengthOf(1)
      expect(results[0]).to.equal(resultsDir)
    })

    it('returns multiple directories when pattern matches multiple', async () => {
      const dir1 = join(tempDir, 'results1')
      const dir2 = join(tempDir, 'results2')
      mkdirSync(dir1)
      mkdirSync(dir2)
      writeFileSync(join(dir1, 'result.json'), '{}')
      writeFileSync(join(dir2, 'result.json'), '{}')

      const results = await getAllureResultsPaths(join(tempDir, 'results*'))

      expect(results).to.have.lengthOf(2)
      expect(results).to.include(dir1)
      expect(results).to.include(dir2)
    })

    it('throws error when pattern matches no paths', async () => {
      expect(getAllureResultsPaths(join(tempDir, 'nonexistent'))).to.be.rejectedWith(
        Error,
        /did not match any paths.*Use --ignore-missing-results/,
      )
    })

    it('throws error when pattern matches non-directory', async () => {
      const file = join(tempDir, 'file.txt')
      writeFileSync(file, 'content')

      try {
        await getAllureResultsPaths(file)
        expect.fail('Expected error to be thrown')
      } catch (error) {
        expect((error as Error).message).to.include('non-directory paths')
        expect((error as Error).message).to.include('Use --ignore-missing-results')
      }
    })

    it('throws error when directory contains no json files', async () => {
      const resultsDir = join(tempDir, 'empty-results')
      mkdirSync(resultsDir)

      try {
        await getAllureResultsPaths(resultsDir)
        expect.fail('Expected error to be thrown')
      } catch (error) {
        expect((error as Error).message).to.include('No allure results found')
        expect((error as Error).message).to.include('Use --ignore-missing-results')
      }
    })

    it('does not include ignore message when ignoreMissing is true', async () => {
      try {
        await getAllureResultsPaths(join(tempDir, 'nonexistent'), true)
        expect.fail('Expected error to be thrown')
      } catch (error) {
        expect((error as Error).message).to.not.include('Use --ignore-missing-results')
      }
    })

    it('validates that at least one directory contains json files', async () => {
      const dir1 = join(tempDir, 'results1')
      const dir2 = join(tempDir, 'results2')
      mkdirSync(dir1)
      mkdirSync(dir2)
      writeFileSync(join(dir1, 'result.json'), '{}')

      const results = await getAllureResultsPaths(join(tempDir, 'results*'))

      expect(results).to.have.lengthOf(2)
    })
  })
})
