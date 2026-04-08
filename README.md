# ROSHNI — روشنی

**ROSHNI** (روشنی, meaning *Light*) is a programming language with **Urdu-derived keywords**.

Instead of writing `if`, `while`, `print`, or `return`, you write `jab`, `dohra`, `dikha`, and `wapas` — bringing the syntax closer to Urdu speakers while demonstrating how a complete interpreter pipeline (lexer → parser → interpreter) works from scratch.

---

## What ROSHNI Looks Like

```
%% Fibonacci in ROSHNI
jalao fib (n) ->
  jab n <= 1 ->
    wapas n
  warna
    wapas (bulao fib n - 1) + (bulao fib n - 2)
  end
end

dikha bulao fib 10
```

Output: `55`

---

## Key Features

- **Urdu keywords** — all control flow, I/O, and declarations use Urdu-derived words
- **Variables** — dynamically typed, declared with `dhara`
- **Functions** — first-class, lexically scoped closures defined with `jalao`, called with `bulao`
- **Recursion** — fully supported (see Fibonacci example above)
- **Conditionals** — `jab` / `warna` (if / else)
- **Loops** — `dohra har` (for-each over a list) and `dohra` (while)
- **Lists** — created with `jama(...)`, iterated, and indexed with `nikalo`
- **Boolean literals** — `haan` (true) and `nahi` (false)
- **Comments** — anything after `%%` is ignored
- **Arithmetic & comparisons** — `+`, `-`, `*`, `/`, `==`, `!=`, `<`, `>`, `<=`, `>=`

---

## Keyword Reference

| ROSHNI | Urdu Script | Meaning | English Equivalent |
|--------|-------------|---------|-------------------|
| `dhara` | دھارا | stream / flow | `var` / `let` |
| `jalao` | جلاؤ | ignite | `def` / function |
| `bulao` | بلاؤ | call | function call |
| `dikha` | دکھا | show | `print` |
| `dohra har` | دوہرا ہر | repeat each | `for` loop |
| `dohra` | دوہرا | repeat | `while` loop |
| `jab` | جب | when | `if` |
| `warna` | ورنہ | otherwise | `else` |
| `wapas` | واپس | return | `return` |
| `jama` | جمع | gather | list / array |
| `nikalo` | نکالو | extract | index access |
| `haan` | ہاں | yes | `true` |
| `nahi` | نہیں | no | `false` |
| `end` | — | end of block | `}` |
| `%%` | — | comment | `//` |

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
| **Magic Racket** (VSCode extension) | Latest | Syntax highlighting for `.rkt` and `.rsn` files |

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
%% My first ROSHNI program
dhara name = "Duniya"
dikha "Salam"
dikha name
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

*ROSHNI — روشنی — Let there be light.*  
