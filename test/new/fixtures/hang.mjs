let capturedPort
let capturedName

export default function task(options = {}) {
  if (options.port) capturedPort = options.port
  if (options.name) capturedName = options.name
  return new Promise(() => {})
}

export async function reportTeardown() {
  capturedPort?.postMessage({ type: 'teardown', name: capturedName ?? null })
}

export async function hangingTeardown() {
  capturedPort?.postMessage({ type: 'teardown-started', name: capturedName ?? null })
  await new Promise(() => {})
}

export async function throwingTeardown() {
  throw new Error('teardown failed intentionally')
}
