# ROSHNI Test Writing Guide
### روشنی — ek Urdu programming language

Hey! This guide will walk you through writing test files for **ROSHNI** — a programming language with Urdu keywords. You don't need to know Racket or any compiler theory. Just follow the examples below.

Each test is a `.rsn` file saved inside the `tests/` folder.  
Run any test like this:
```bash
racket src/main.rkt tests/YOUR_FILE.rsn
```

---

## How ROSHNI Works — In 30 Seconds

ROSHNI looks like a normal programming language, but the keywords are Urdu words. Here's a quick mental map:

| You want to... | ROSHNI keyword | Example |
|---|---|---|
| Store a value | `rakho` | `rakho x = 5` |
| Print something | `dikhao` | `dikhao "Salam!"` |
| Write a comment | `tanqeed` | `tanqeed yeh sirf comment hai` |
| Call a function | `bulao` | `bulao jama 3, 4` |
| Define a function | `banao` | `banao jama (a, b) -> ... end` |
| If condition | `agar` | `agar x > 5 -> ... end` |
| Else | `warna` | `warna ... end` |
| Else-if | `warna-agar` | `warna-agar x == 5 -> ...` |
| While loop | `jabtak` | `jabtak x < 10 -> ... end` |
| For-each loop | `har` | `har ginti as adad -> ... end` |
| Make a list | `fehrist` | `fehrist(1, 2, 3)` |
| Get item from list | `lo` | `lo nums[0]` |
| Return from function | `wapas` | `wapas x + 1` |
| Join strings | `jodna` | `"wazn: " jodna 5000` |
| True / False | `sahi` / `ghalat` | `rakho flag = sahi` |

---

## The Test Files You Need to Create

---

### 1. `tests/hello.rsn` — Hello World

The simplest possible program. Just prints two lines.

```
tanqeed Test 1: Hello World
rakho naam = "Duniya"
dikhao "Salam"
dikhao naam
```

**Expected output:**
```
Salam
Duniya
```

---

### 2. `tests/variables.rsn` — Variables and Reassignment

Tests declaring variables and updating them.

```
tanqeed Test 2: Variables

tanqeed Declare
rakho x = 10
rakho y = 3.14
rakho sandesa = "ROSHNI mein khush amdeed"
rakho sach = sahi

tanqeed Print originals
dikhao x
dikhao y
dikhao sandesa
dikhao sach

tanqeed Reassign
x = 99
dikhao x
```

**Expected output:**
```
10
3.14
ROSHNI mein khush amdeed
sahi
99
```

---

### 3. `tests/arithmetic.rsn` — Arithmetic (Symbol and Word forms)

Tests all four operations using both the symbol (`+`) and word (`jama`) forms. Both must work.

```
tanqeed Test 3: Arithmetic

rakho a = 20
rakho b = 6

tanqeed Symbol operators
dikhao a + b
dikhao a - b
dikhao a * b
dikhao a / b

tanqeed Word operators (exact same result)
dikhao a jama b
dikhao a tafreeq b
dikhao a zarb b
dikhao a taqseem b

tanqeed Mixed in one expression
dikhao (a + b) * 2
```

**Expected output:**
```
26
14
120
3.3333333333333335
26
14
120
3.3333333333333335
52
```

---

### 4. `tests/comparison.rsn` — Comparisons (Symbol and Word forms)

Tests all comparison operators using both forms.

```
tanqeed Test 4: Comparisons

rakho x = 10
rakho y = 20

tanqeed Symbol form
dikhao x == y
dikhao x != y
dikhao x < y
dikhao x > y
dikhao x <= 10
dikhao x >= 10

tanqeed Word form
dikhao x barabar y
dikhao x nai-barabar y
dikhao x kam y
dikhao x zyada y
dikhao x kam-ya-barabar 10
dikhao x zyada-ya-barabar 10
```

**Expected output:**
```
ghalat
sahi
sahi
ghalat
sahi
sahi
ghalat
sahi
sahi
ghalat
sahi
sahi
```

---

### 5. `tests/logical.rsn` — Logical Operators

Tests `aur` (and), `ya` (or), and `nai` (not).

```
tanqeed Test 5: Logical operators

rakho a = sahi
rakho b = ghalat

dikhao a aur b
dikhao a ya b
dikhao nai a
dikhao nai b

tanqeed Chained logic
dikhao sahi aur sahi aur sahi
dikhao ghalat ya ghalat ya sahi
```

**Expected output:**
```
ghalat
sahi
ghalat
sahi
sahi
sahi
```

---

### 6. `tests/conditionals.rsn` — If / Else-If / Else

Tests `agar`, `warna-agar`, and `warna`. Make sure to test a case for each branch.

```
tanqeed Test 6: Conditionals

rakho darja = 85

tanqeed --- Test agar only ---
agar darja > 80 ->
  dikhao "achha hai"
end

tanqeed --- Test agar + warna ---
agar darja > 90 ->
  dikhao "A"
warna
  dikhao "A nahi"
end

tanqeed --- Test agar + warna-agar + warna ---
agar darja zyada-ya-barabar 90 ->
  dikhao "A"
warna-agar darja zyada-ya-barabar 80 ->
  dikhao "B"
warna-agar darja zyada-ya-barabar 70 ->
  dikhao "C"
warna
  dikhao "Fail"
end
```

**Expected output:**
```
achha hai
A nahi
B
```

---

### 7. `tests/jabtak.rsn` — While Loop

Tests the `jabtak` (while) loop. Make sure the loop variable updates inside the body or it will run forever!

```
tanqeed Test 7: While loop

rakho i = 1
jabtak i <= 5 ->
  dikhao i
  i = i + 1
end

tanqeed Countdown
rakho n = 3
jabtak n > 0 ->
  dikhao n
  n = n - 1
end
dikhao "Blast off!"
```

**Expected output:**
```
1
2
3
4
5
3
2
1
Blast off!
```

---

### 8. `tests/har.rsn` — For-Each Loop

Tests the `har ... as` loop over a list.

```
tanqeed Test 8: For-each loop

rakho phal = fehrist("aam", "kela", "anaar")

har phal as cheez ->
  dikhao cheez
end

tanqeed Sum of a list
rakho ginti = fehrist(10, 20, 30, 40)
rakho majmua = 0

har ginti as adad ->
  majmua = majmua + adad
end

dikhao "Majmua:"
dikhao majmua
```

**Expected output:**
```
aam
kela
anaar
Majmua:
100
```

---

### 9. `tests/fehrist.rsn` — Lists and Index Access

Tests creating a list with `fehrist` and accessing items with `lo`.

```
tanqeed Test 9: Lists

rakho rang = fehrist("laal", "sabz", "neela")

tanqeed Access by index
dikhao lo rang[0]
dikhao lo rang[1]
dikhao lo rang[2]

tanqeed Print the whole list
dikhao rang

tanqeed Numbers list
rakho nums = fehrist(100, 200, 300)
dikhao lo nums[0] + lo nums[2]
```

**Expected output:**
```
laal
sabz
neela
[laal, sabz, neela]
400
```

---

### 10. `tests/jodna.rsn` — String Concatenation

Tests joining strings and non-string values using `jodna`.

```
tanqeed Test 10: String concatenation

rakho naam = "Ahmed"
rakho umra = 22
rakho wazn = 70.5

dikhao "Naam: " jodna naam
dikhao "Umra: " jodna umra jodna " saal"
dikhao "Wazn: " jodna wazn jodna " kg"

tanqeed Joining booleans
rakho pass = sahi
dikhao "Nateeja: " jodna pass

tanqeed Arithmetic computes first, then joins
dikhao "5 + 3 = " jodna 5 + 3
```

**Expected output:**
```
Naam: Ahmed
Umra: 22 saal
Wazn: 70.5 kg
Nateeja: sahi
5 + 3 = 8
```

---

### 11. `tests/functions.rsn` — Basic Functions

Tests defining and calling functions with `banao` and `bulao`.

```
tanqeed Test 11: Functions

tanqeed No-argument function
banao salaam () ->
  dikhao "As-salamu alaykum!"
end

bulao salaam

tanqeed One argument
banao double (n) ->
  wapas n * 2
end

dikhao bulao double 7

tanqeed Two arguments
banao jama_karo (a, b) ->
  wapas a + b
end

dikhao bulao jama_karo 10, 15
```

**Expected output:**
```
As-salamu alaykum!
14
25
```

---

### 12. `tests/recursion.rsn` — Recursion

Tests functions that call themselves. Fibonacci is the classic example.

```
tanqeed Test 12: Recursion

banao fib (n) ->
  agar n <= 1 ->
    wapas n
  warna
    wapas (bulao fib n - 1) + (bulao fib n - 2)
  end
end

dikhao bulao fib 0
dikhao bulao fib 1
dikhao bulao fib 5
dikhao bulao fib 10

tanqeed Factorial
banao factorial (n) ->
  agar n <= 1 ->
    wapas 1
  warna
    wapas n * (bulao factorial n - 1)
  end
end

dikhao bulao factorial 5
dikhao bulao factorial 10
```

**Expected output:**
```
0
1
5
55
120
3628800
```

---

### 13. `tests/scope.rsn` — Variable Scope

Tests that variables inside a function don't leak out, and that functions can read outer variables.

```
tanqeed Test 13: Scope

rakho x = 100

banao inner () ->
  tanqeed x from outer scope is visible here
  dikhao x
  rakho y = 999
  tanqeed y only lives inside this function
end

bulao inner
tanqeed y is gone now — the next line would crash if uncommented
tanqeed dikhao y

tanqeed Outer x is unchanged
dikhao x
```

**Expected output:**
```
100
100
```

---

### 14. `tests/full_program.rsn` — Full Mixed Program

A bigger program that combines most features together.

```
tanqeed Test 14: Full mixed program

tanqeed --- Grade calculator ---

banao hisaab_lagao (marks) ->
  agar marks zyada-ya-barabar 90 ->
    wapas "A"
  warna-agar marks zyada-ya-barabar 80 ->
    wapas "B"
  warna-agar marks zyada-ya-barabar 70 ->
    wapas "C"
  warna-agar marks zyada-ya-barabar 60 ->
    wapas "D"
  warna
    wapas "Fail"
  end
end

rakho imtihaan = fehrist(92, 78, 65, 55, 88)
rakho girda = 0

har imtihaan as nishaan ->
  girda = girda + nishaan
end

rakho kul = 5
girda = girda taqseem kul

dikhao "Girda: " jodna girda
dikhao "Darjah: " jodna (bulao hisaab_lagao girda)

tanqeed --- Multiplication table for 3 ---
dikhao "--- Jadwal: 3 ---"
rakho i = 1
jabtak i <= 5 ->
  dikhao "3 x " jodna i jodna " = " jodna 3 * i
  i = i + 1
end
```

**Expected output:**
```
Girda: 75.6
Darjah: C
--- Jadwal: 3 ---
3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
3 x 4 = 12
3 x 5 = 15
```

---

## Quick Reference — Cheat Sheet

```
tanqeed --- Variables ---
rakho naam = "Ali"
rakho adad = 42
rakho raqam = 3.14
rakho flag  = sahi          tanqeed or: ghalat

tanqeed --- Print ---
dikhao "Salam!"
dikhao adad

tanqeed --- String join ---
dikhao "Umra: " jodna adad jodna " saal"

tanqeed --- Arithmetic ---
rakho jawab = (3 + 4) * 2   tanqeed symbols
rakho jawab = 3 jama 4      tanqeed word form, same thing

tanqeed --- Comparison ---
agar x barabar y -> ...     tanqeed ==
agar x nai-barabar y -> ... tanqeed !=
agar x zyada y -> ...       tanqeed >
agar x kam y -> ...         tanqeed <

tanqeed --- Logical ---
agar a aur b -> ...
agar a ya b -> ...
agar nai a -> ...

tanqeed --- If/elif/else ---
agar x > 10 ->
  dikhao "bara"
warna-agar x == 10 ->
  dikhao "barabar"
warna
  dikhao "chota"
end

tanqeed --- While loop ---
jabtak x < 10 ->
  x = x + 1
end

tanqeed --- For-each loop ---
har myList as item ->
  dikhao item
end

tanqeed --- List ---
rakho nums = fehrist(1, 2, 3)
dikhao lo nums[0]

tanqeed --- Function ---
banao square (n) ->
  wapas n * n
end
dikhao bulao square 5
```

---

## Common Mistakes to Avoid

| Mistake | Wrong | Right |
|---|---|---|
| Forgetting `end` | `agar x > 5 -> dikhao x` | add `end` after the body |
| Using `=` for comparison | `agar x = 5 ->` | `agar x == 5 ->` or `agar x barabar 5 ->` |
| Printing without `dikhao` | `"Salam"` | `dikhao "Salam"` |
| Calling function without `bulao` | `square 5` | `bulao square 5` |
| Using a variable before `rakho` | `x = 5` at top | `rakho x = 5` first |
| Updating in wrong scope | reassigning inside a func a var that was never declared | declare with `rakho` in outer scope first |
| Infinite loop | `jabtak sahi -> ...` with no break | always update the condition variable inside the loop |

---

*Shukriya! — شکریہ — Thank you for writing the tests!*
