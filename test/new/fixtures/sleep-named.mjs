import { setTimeout as delay } from 'node:timers/promises'

export default async function task({ time = 100, value = 'ok' } = {}) {
  await delay(time)
  return value
}
