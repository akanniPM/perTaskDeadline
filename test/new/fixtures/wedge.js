export default function wedge() {
  const buf = new Int32Array(new SharedArrayBuffer(4))
  while (true) {
    Atomics.wait(buf, 0, 0)
  }
}
