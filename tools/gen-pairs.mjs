// Parse a unified diff into [{old,new}] replacement pairs (context lines included),
// so the re-apply script does not have to hard-code the patched snippets.
import { readFileSync, writeFileSync } from 'node:fs'

const [, , patchPath, outPath] = process.argv
const lines = readFileSync(patchPath, 'utf8').split(/\r?\n/)

const pairs = []
let inHunk = false
let oldLines = []
let newLines = []

function flush() {
  if (oldLines.length === 0 && newLines.length === 0) return
  pairs.push({ old: oldLines.join('\n'), new: newLines.join('\n') })
  oldLines = []
  newLines = []
}

for (const line of lines) {
  if (line.startsWith('diff --git') || line.startsWith('index ') || line.startsWith('--- ') || line.startsWith('+++ ')) {
    inHunk = false
    continue
  }
  if (line.startsWith('@@')) {
    flush()
    inHunk = true
    continue
  }
  if (!inHunk) continue
  if (line.startsWith(' ')) {
    oldLines.push(line.slice(1))
    newLines.push(line.slice(1))
  } else if (line.startsWith('-')) {
    oldLines.push(line.slice(1))
  } else if (line.startsWith('+')) {
    newLines.push(line.slice(1))
  } else if (line.startsWith('\\')) {
    // "\ No newline at end of file" — ignore
  }
}
flush()

writeFileSync(outPath, JSON.stringify(pairs, null, 2) + '\n', 'utf8')
console.log(`pairs: ${pairs.length}`)
for (const p of pairs) {
  console.log(`--- old ${p.old.length}b / new ${p.new.length}b ---`)
  console.log(p.new.split('\n').filter((l) => l.trim()).slice(0, 3).join('\n'))
}
