import {Config, run, settings} from '@oclif/core'
import type {Command} from '@oclif/core'
import {fileURLToPath} from 'node:url'
import {vi} from 'vitest'

export type CommandResult = {
  stdout: string
  stderr: string
  error?: Error
}

type WriteCallback = (error?: Error | null) => void

function collect(chunks: string[]): NodeJS.WriteStream['write'] {
  return (
    chunk: string | Uint8Array,
    encodingOrCallback?: BufferEncoding | WriteCallback,
    onWrite?: WriteCallback,
  ): boolean => {
    const encoding = typeof encodingOrCallback === 'string' ? encodingOrCallback : undefined
    chunks.push(typeof chunk === 'string' ? chunk : Buffer.from(chunk).toString(encoding))
    const completeWrite = typeof encodingOrCallback === 'function' ? encodingOrCallback : onWrite
    completeWrite?.()
    return true
  }
}

export async function captureCommand(action: () => Promise<unknown>): Promise<CommandResult> {
  const stdout: string[] = []
  const stderr: string[] = []
  const originalEnv = {...process.env}
  const originalExitCode = process.exitCode
  const stdoutSpy = vi.spyOn(process.stdout, 'write').mockImplementation(collect(stdout))
  const stderrSpy = vi.spyOn(process.stderr, 'write').mockImplementation(collect(stderr))
  let failure: Error | undefined

  try {
    await action()
  } catch (error) {
    failure = error instanceof Error ? error : new Error(String(error), {cause: error})
  } finally {
    stdoutSpy.mockRestore()
    stderrSpy.mockRestore()
    process.env = originalEnv
    process.exitCode = originalExitCode
  }

  return {
    stdout: stdout.join(''),
    stderr: stderr.join(''),
    ...(failure ? {error: failure} : {}),
  }
}

export async function runCommand(argv: readonly string[]): Promise<CommandResult> {
  return captureCommand(async () => {
    const [{default: S3}, {default: Gcs}] = await Promise.all([
      import('../../src/commands/upload/s3.js'),
      import('../../src/commands/upload/gcs.js'),
    ])
    const sourceCommands: Record<string, Command.Class> = {
      'upload:s3': S3,
      'upload:gcs': Gcs,
    }
    const root = fileURLToPath(new URL('../../', import.meta.url))
    const autoTranspile = settings.enableAutoTranspile
    const restore: (() => void)[] = []
    settings.enableAutoTranspile = false

    try {
      const config = await Config.load({root, devPlugins: false, userPlugins: false})
      for (const [id, source] of Object.entries(sourceCommands)) {
        const descriptor = config.findCommand(id, {must: true})
        const previousId = source.id
        const previousPlugin = source.plugin
        source.id = id
        source.plugin = config.plugins.get(config.name)
        restore.push(() => {
          source.id = previousId
          source.plugin = previousPlugin
        })
        const loader = vi.spyOn(descriptor, 'load').mockResolvedValue(source)
        restore.push(() => loader.mockRestore())
      }
      await run([...argv], config)
    } finally {
      for (const undo of restore.reverse()) undo()
      settings.enableAutoTranspile = autoTranspile
    }
  })
}
