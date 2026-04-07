# ROSHNI — Tester Guide (Member 2)
> A programming language with Urdu keywords.


This guide is for **Member 2 (Tester)**. By the end of this document you will have Racket installed, understand how to read and write ROSHNI code, and have a full set of test programs ready to run and document.

---

## Table of Contents

1. [Tools Installation](#1-tools-installation)
2. [Getting the Project](#2-getting-the-project)
3. [Project Structure](#3-project-structure)
4. [Learn the ROSHNI Language](#4-learn-the-roshni-language)
5. [How to Run a ROSHNI Program](#5-how-to-run-a-roshni-program)
6. [Test Programs to Write](#6-test-programs-to-write)


---

## 1. Tools Installation

You need two things: **Racket** (the language ROSHNI is built on) and **VSCode** with one extension.

### Step 1 — Install Homebrew (Mac only, skip if already installed)

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After it finishes, verify:

```bash
brew --version
# Should print: Homebrew 4.x.x
```

> **M1/M2 Mac note:** After install, Homebrew will tell you to add a line to your `~/.zshrc`. Do that step before continuing, then run `source ~/.zshrc`.

---

### Step 2 — Install Racket

```bash
brew install --cask racket
```

This downloads around 350MB and takes 2–3 minutes. After it finishes:

```bash
racket --version
# Should print: Welcome to Racket v8.x.x
```

If `racket` is not found after install, add this to your `~/.zshrc`:

```bash
export PATH="/Applications/Racket v8.x/bin:$PATH"
```

Then reload:

```bash
source ~/.zshrc
```

---

### Step 3 — Install VSCode Extensions

Open VSCode, press `⌘ + Shift + X` to open Extensions, and install:

| Extension | Publisher | Why |
|-----------|-----------|-----|
| **Magic Racket** | Evzen Wybitul | Syntax highlighting + REPL for Racket |

---

### Step 4 — Associate `.rsn` files with Racket syntax

Press `⌘ + Shift + P`, type `Open User Settings JSON`, and add this inside the JSON object:

```json
"files.associations": {
  "*.rsn": "racket"
}
```

This makes VSCode highlight `.rsn` files (ROSHNI source files) with Racket colors.

---

## 2. Getting the Project

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/roshni-lang.git
cd roshni-lang
code .
```

---

## 3. Project Structure

```
roshni-lang/
├── src/
│   ├── lexer.rkt         ← reads source code → token stream
│   ├── parser.rkt        ← tokens → AST (tree structure)
│   ├── interpreter.rkt   ← AST → actual output
│   └── main.rkt          ← entry point, you run this
├── tests/
│   ├── hello.rsn         ← your test files go here
│   └── ...
└── report/
```

You only need to work inside the `tests/` folder. You do not need to touch any `.rkt` files.

---

## 4. Learn the ROSHNI Language

ROSHNI uses **Urdu-derived keywords** instead of English ones. Here is the complete keyword table:

| ROSHNI keyword | Urdu script | Meaning | English equivalent |
|----------------|-------------|---------|-------------------|
| `dhara` | دھارا | stream / flow | `var` / `let` |
| `jalao` | جلاؤ | ignite | `def` / `function` |
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
| `end` | — | end of block | `}` closing brace |
| `%%` | — | comment | `//` |

---

### 4.1 Variables — `dhara`

```
dhara name = value
```

Examples:

```
dhara x = 10
dhara pi = 3.14
dhara greeting = "Salam"
dhara flag = haan
```

---

### 4.2 Print — `dikha`

```
dikha expression
```

Examples:

```
dikha "Salam Duniya!"
dikha x
dikha x + 5
```

---

### 4.3 Arithmetic

Operators: `+`, `-`, `*`, `/`
Use parentheses to control order:

```
dhara a = 10
dhara b = 3
dikha a + b
dikha (a + b) * 2
dikha a / b
```

---

### 4.4 Comparisons and Booleans

Comparison operators: `==`, `!=`, `<`, `>`, `<=`, `>=`
Boolean values: `haan` (true) and `nahi` (false)

```
dhara x = 5
dikha x == 5
dikha x > 10
```

---

### 4.5 Conditionals — `jab` / `warna`

```
jab condition ->
  statements
warna
  statements
end
```

The `warna` (else) block is optional:

```
jab condition ->
  statements
end
```

Example:

```
dhara umar = 20
jab umar >= 18 ->
  dikha "Aap baligha hain"
warna
  dikha "Aap na-baligha hain"
end
```

---

### 4.6 Functions — `jalao` / `bulao` / `wapas`

Define a function with `jalao`, call it with `bulao`, return a value with `wapas`:

```
jalao functionName (param1 param2) ->
  statements
  wapas value
end
```

```
bulao functionName arg1 arg2
```

Example:

```
jalao double (n) ->
  wapas n * 2
end

dikha bulao double 5
```

Recursive example:

```
jalao fib (n) ->
  jab n <= 1 ->
    wapas n
  warna
    wapas (bulao fib n - 1) + (bulao fib n - 2)
  end
end

dikha bulao fib 10
```

---

### 4.7 Lists — `jama` / `dohra har` / `nikalo`

Create a list:

```
dhara nums = jama(1, 2, 3, 4, 5)
dikha nums
```

Loop over a list:

```
dohra har nums as x ->
  dikha x
end
```

Access by index (zero-based):

```
dikha nikalo nums[0]
dikha nikalo nums[2]
```

---

### 4.8 Comments

Anything after `%%` on a line is ignored:

```
%% This is a comment
dhara x = 5   %% inline comment
```

---

## 5. How to Run a ROSHNI Program

From the root of the project folder:

```bash
racket src/main.rkt tests/yourfile.rsn
```

Examples:

```bash
racket src/main.rkt tests/hello.rsn
racket src/main.rkt tests/fibonacci.rsn
racket src/main.rkt tests/lists.rsn
```

> The `55 shift/reduce conflicts` warning that may appear is harmless — it comes from the parser generator and does not affect correctness.

---

## 6. Test Programs to Write

Create each file inside the `tests/` folder. For each test, write the program, run it, and record the actual output next to the expected output in the results table in section 7.

---

### Test 1 — `tests/hello.rsn`
**Purpose:** Basic print and string output

```
%% Test 1: Hello World
dikha "Salam Duniya!"
dikha "ROSHNI mein aapka swaagat hai"
```

Expected output:
```
Salam Duniya!
ROSHNI mein aapka swaagat hai
```

---

### Test 2 — `tests/arithmetic.rsn`
**Purpose:** Variables, arithmetic operators, operator precedence

```
%% Test 2: Arithmetic
dhara a = 10
dhara b = 3
dikha a + b
dikha a - b
dikha a * b
dikha a / b
dikha (a + b) * 2
dhara jawab = (8 + 2) * 5
dikha jawab
```

Expected output:
```
13
7
30
3.3333333333333335
26
50
```

---

### Test 3 — `tests/conditionals.rsn`
**Purpose:** `jab`/`warna` conditionals, comparisons, boolean values

```
%% Test 3: Conditionals
dhara umar = 20
jab umar >= 18 ->
  dikha "Aap baligha hain"
warna
  dikha "Aap na-baligha hain"
end

dhara score = 45
jab score >= 50 ->
  dikha "Pass"
warna
  dikha "Fail"
end

dhara flag = haan
jab flag == haan ->
  dikha "flag haan hai"
end

dhara x = 10
jab x != 5 ->
  dikha "x paanch nahi hai"
end
```

Expected output:
```
Aap baligha hain
Fail
flag haan hai
x paanch nahi hai
```

---

### Test 4 — `tests/functions.rsn`
**Purpose:** Function definition, calling, return values

```
%% Test 4: Functions
jalao double (n) ->
  wapas n * 2
end

jalao add (a b) ->
  wapas a + b
end

jalao square (n) ->
  wapas n * n
end

dikha bulao double 5
dikha bulao double 100
dikha bulao add 3 7
dikha bulao square 9
```

Expected output:
```
10
200
10
81
```

---

### Test 5 — `tests/fibonacci.rsn`
**Purpose:** Recursion

```
%% Test 5: Fibonacci — recursion test
jalao fib (n) ->
  jab n <= 1 ->
    wapas n
  warna
    wapas (bulao fib n - 1) + (bulao fib n - 2)
  end
end

dikha bulao fib 0
dikha bulao fib 1
dikha bulao fib 5
dikha bulao fib 8
dikha bulao fib 10
```

Expected output:
```
0
1
5
21
55
```

---

### Test 6 — `tests/lists.rsn`
**Purpose:** List creation, for-each loop, list printing

```
%% Test 6: Lists and loops
dhara nums = jama(1, 2, 3, 4, 5)
dikha nums

dohra har nums as x ->
  dikha x * 2
end

dhara cities = jama("Karachi", "Lahore", "Islamabad")
dikha cities

dohra har cities as shahar ->
  dikha shahar
end
```

Expected output:
```
[1, 2, 3, 4, 5]
2
4
6
8
10
[Karachi, Lahore, Islamabad]
Karachi
Lahore
Islamabad
```

---

### Test 7 — `tests/list_index.rsn`
**Purpose:** List index access with `nikalo`

```
%% Test 7: List index access
dhara rang = jama("laal", "neela", "hara")
dikha nikalo rang[0]
dikha nikalo rang[1]
dikha nikalo rang[2]
```

Expected output:
```
laal
neela
hara
```

---

### Test 8 — `tests/booleans.rsn`
**Purpose:** Boolean literals and boolean logic in conditions

```
%% Test 8: Booleans
dhara a = haan
dhara b = nahi

dikha a
dikha b

jab a == haan ->
  dikha "a is haan"
end

jab b == nahi ->
  dikha "b is nahi"
end

jab a != b ->
  dikha "a aur b alag hain"
end
```

Expected output:
```
haan
nahi
a is haan
b is nahi
a aur b alag hain
```

---

### Test 9 — `tests/nested_conditions.rsn`
**Purpose:** Nested `jab`/`warna` blocks inside functions

```
%% Test 9: Nested conditionals inside a function
jalao classify (n) ->
  jab n > 0 ->
    dikha "musbat (positive)"
  warna
    jab n == 0 ->
      dikha "sifar (zero)"
    warna
      dikha "manfi (negative)"
    end
  end
end

bulao classify 10
bulao classify 0
bulao classify -5
```

Expected output:
```
musbat (positive)
sifar (zero)
manfi (negative)
```

---

### Test 10 — `tests/full_program.rsn`
**Purpose:** Full integration — variables, functions, lists, loops, conditionals all together

```
%% Test 10: Full integration program
%% Find the maximum number in a list

jalao isGreater (a b) ->
  jab a > b ->
    wapas a
  warna
    wapas b
  end
end

dhara numbers = jama(3, 7, 1, 9, 4, 6, 2)
dikha "Fehrist:"
dikha numbers

dhara max = 0
dohra har numbers as n ->
  dhara max = bulao isGreater max n
end

dikha "Sab se bara number:"
dikha max
```

Expected output:
```
Fehrist:
[3, 7, 1, 9, 4, 6, 2]
Sab se bara number:
9
```

---


## Quick Reference Card

```
%% comment

dhara x = 5                          variable
dikha x                              print
dikha "hello"                        print string

jab x > 0 ->                         if
  dikha "musbat"
warna                                else (optional)
  dikha "manfi"
end                                  end of block

jalao funcName (a b) ->              define function
  wapas a + b                        return
end

bulao funcName 3 4                   call function

dhara nums = jama(1, 2, 3)           create list
dohra har nums as x ->               for-each loop
  dikha x
end

nikalo nums[0]                       index into list
haan   nahi                          true   false
%%     ->    end                     comment  arrow  block-end
```

---

*ROSHNI — روشنی — Let there be light.*
*PLP Course — April 2026*
