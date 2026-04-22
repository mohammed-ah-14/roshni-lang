# ROSHNI — روشنی

**ROSHNI** (روشنی, meaning *Light*) is a programming language with **Urdu-derived keywords**.

Instead of writing `if`, `while`, `print`, or `return`, you write `agar`, `jabtak`, `dikhao`, and `wapas` — bringing the syntax closer to Urdu speakers while demonstrating how a complete interpreter pipeline (lexer → parser → interpreter) works from scratch.

---

## What ROSHNI Looks Like

```
tanqeed Fibonacci ROSHNI mein
banao fib (n) ->
  agar n <= 1 ->
    wapas n
  warna
    wapas (bulao fib n - 1) + (bulao fib n - 2)
  end
end

dikhao bulao fib 10
```

Output: `55`

---

## What's New (v2)

- **All keywords renamed** to more natural Urdu words (`rakho`, `banao`, `agar`, `dikhao`, …)
- **`warna-agar`** — else-if (elif) chains, any number of them
- **Logical operators** — `aur` (and), `ya` (or), `nai` (not)
- **Word arithmetic** — write `3 jama 4` instead of `3 + 4` (both work)
- **Word comparisons** — write `x barabar y` instead of `x == y` (both work)
- **`tanqeed`** — starts a line comment

---

## Key Features

- **Urdu keywords** — all control flow, I/O, and declarations use Urdu-derived words
- **Variables** — dynamically typed, declared with `rakho`
- **Functions** — first-class, lexically scoped closures defined with `banao`, called with `bulao`
- **Recursion** — fully supported (see Fibonacci above)
- **Conditionals** — `agar` / `warna-agar` / `warna` (if / else-if / else)
- **Loops** — `har ... as` (for-each over a list) and `jabtak` (while)
- **Lists** — created with `fehrist(...)`, iterated with `har`, indexed with `lo`
- **Boolean literals** — `sahi` (true) and `ghalat` (false)
- **Logical operators** — `aur` (and), `ya` (or), `nai` (not)
- **Arithmetic operators** — symbol (`+`, `-`, `*`, `/`) **or** word form (`jama`, `tafreeq`, `zarb`, `taqseem`)
- **Comparison operators** — symbol (`==`, `!=`, `<`, `>`, `<=`, `>=`) **or** word form
- **Comments** — anything after `tanqeed` on a line is ignored

---

## Keyword Reference

| ROSHNI | Urdu Script | Meaning | English Equivalent |
|--------|-------------|---------|-------------------|
| `rakho` | رکھو | keep / store | `var` / `let` |
| `banao` | بناؤ | build / make | `def` / function |
| `bulao` | بلاؤ | call | function call |
| `dikhao` | دکھاؤ | show | `print` |
| `jabtak` | جب تک | while / as long as | `while` loop |
| `har` | ہر | every / each | `for` loop |
| `agar` | اگر | if | `if` |
| `warna` | ورنہ | otherwise | `else` |
| `warna-agar` | ورنہ اگر | otherwise if | `elif` / `else if` |
| `fehrist` | فہرست | list / collection | list / array |
| `lo` | لو | take / get | index access |
| `wapas` | واپس | return | `return` |
| `sahi` | صحیح | correct / true | `true` |
| `ghalat` | غلط | wrong / false | `false` |
| `aur` | اور | and | `&&` / `and` |
| `ya` | یا | or | `\|\|` / `or` |
| `nai` | نئی | not | `!` / `not` |
| `jodna` | جوڑنا | join / connect | string concatenation (`+` for strings) |
| `end` | — | end of block | `}` |
| `tanqeed` | تنقید | comment | `//` |
| `as` | — | loop alias | `as` / `in` |

### Word Operator Reference

| ROSHNI word | Symbol | Meaning |
|-------------|--------|---------|
| `jama` | `+` | addition |
| `tafreeq` | `-` | subtraction |
| `zarb` | `*` | multiplication |
| `taqseem` | `/` | division |
| `barabar` | `==` | equal to |
| `nai-barabar` | `!=` | not equal to |
| `zyada` | `>` | greater than |
| `kam` | `<` | less than |
| `zyada-ya-barabar` | `>=` | greater than or equal |
| `kam-ya-barabar` | `<=` | less than or equal |

> Both forms are always valid. Mix and match freely:
> `rakho jawab = 3 jama 4 * 2`  →  `11`

---

## Project Structure

```
roshni-lang/
├── src/
│   ├── lexer.rkt         ← tokenises source code
│   ├── parser.rkt        ← builds the AST from tokens
│   ├── interpreter.rkt   ← walks the AST and executes it
│   └── main.rkt          ← CLI entry point
├── tests/
│   ├── hello.rsn
│   ├── fibonacci.rsn
│   └── ...               ← .rsn is the ROSHNI file extension
└── report/
```

---

## Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [Racket](https://racket-lang.org/) | v8.x or later | The runtime ROSHNI is built on |
| [VSCode](https://code.visualstudio.com/) | Any recent | Editor |
| **Magic Racket** (VSCode extension) | Latest | Syntax highlighting for `.rkt` files |

### Installation (macOS)

```bash
# 1. Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Racket
brew install --cask racket

# 3. Verify
racket --version
# Expected: Welcome to Racket v8.x.x
```

If `racket` is not found after install, add this to your `~/.zshrc` and run `source ~/.zshrc`:

```bash
export PATH="/Applications/Racket v8.x/bin:$PATH"
```

### VSCode Setup

1. Install the **Magic Racket** extension (publisher: Evzen Wybitul)
2. Add `.rsn` file association — open `Settings JSON` (`⌘ Shift P` → "Open User Settings JSON") and add:

```json
"files.associations": {
  "*.rsn": "racket"
}
```

---

## Running a Program

```bash
racket src/main.rkt tests/hello.rsn
```

---

## Writing Your First Program

Create a file `tests/hello.rsn`:

```
tanqeed Mera pehla ROSHNI program
rakho naam = "Duniya"
dikhao "Salam"
dikhao naam
```

Run it:

```bash
racket src/main.rkt tests/hello.rsn
```

Expected output:
```
Salam
Duniya
```

---

## More Examples

### Conditionals with elif

```
rakho darja = 85

agar darja zyada-ya-barabar 90 ->
  dikhao "A"
warna-agar darja zyada-ya-barabar 80 ->
  dikhao "B"
warna-agar darja zyada-ya-barabar 70 ->
  dikhao "C"
warna
  dikhao "F"
end
```

Output: `B`

### Logical Operators

```
rakho umra = 20
rakho raqam = 500

agar umra zyada-ya-barabar 18 aur raqam zyada 100 ->
  dikhao "daakhla ho sakta hai"
warna
  dikhao "daakhla nahi ho sakta"
end
```

### Word Arithmetic

```
rakho a = 10
rakho b = 3
dikhao a jama b         tanqeed 13
dikhao a tafreeq b      tanqeed 7
dikhao a zarb b         tanqeed 30
dikhao a taqseem b      tanqeed 3.333...
```

### Lists and Loops

```
rakho ginti = fehrist(1, 2, 3, 4, 5)
rakho majmua = 0

har ginti as adad ->
  majmua = majmua + adad
end

dikhao majmua
```

Output: `15`

### String Concatenation with jodna

`jodna` joins any values together as a string — numbers, booleans, and lists all convert automatically:

```
rakho wazn = 5000
dikhao "Haathi ka wazn: " jodna wazn jodna " kg"
tanqeed Output: Haathi ka wazn: 5000 kg

rakho naam = "Ali"
rakho umra = 25
dikhao "Naam: " jodna naam jodna ", Umra: " jodna umra

rakho natija = sahi
dikhao "Test pass hua: " jodna natija
tanqeed Output: Test pass hua: sahi
```

Because `jodna` has lower precedence than arithmetic, expressions compute first:
```
dikhao "Jawab: " jodna 3 + 4
tanqeed Output: Jawab: 7      (3+4 computed first, then joined)
```

### While Loop

```
rakho i = 1
jabtak i <= 5 ->
  dikhao i
  i = i + 1
end
```

---

*ROSHNI — روشنی — Let there be light.*
