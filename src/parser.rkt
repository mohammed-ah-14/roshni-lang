#lang racket/base

(require parser-tools/yacc
         parser-tools/lex
         "lexer.rkt")


;; ═══════════════════════════════════════════════════════════
;; ROSHNI PARSER — src/parser.rkt
;; Turns the token stream from lexer.rkt into an AST.
;;
;; Each grammar rule returns a tagged list (AST node), e.g.:
;;   (dhara-decl "x" (num-lit 5))
;;   (jalao-decl "fib" ("n") (body ...))
;;   (dikha-stmt (str-lit "hello"))
;; ═══════════════════════════════════════════════════════════


;; ── Token source: wraps the lexer for the parser ──────────
;; The parser needs a thunk (a zero-arg function) that returns
;; the next token each time it is called.
(define (make-token-thunk port)
  (lambda ()
    (roshni-lexer port)))


;; ═══════════════════════════════════════════════════════════
;; THE PARSER
;; define-parser uses LALR(1) — it reads one token ahead to
;; decide which rule to apply.
;; ═══════════════════════════════════════════════════════════
(define roshni-parser
  (parser

   ;; ── Which token signals end of input ──
   (end EOF)

   ;; ── Token declarations ──
   ;; value-tokens carry a value (ID, NUMBER, FLOAT, STRING)
   ;; punct-tokens are empty (keywords, operators, punctuation)
   (tokens value-tokens punct-tokens)

   ;; ── Error handler ──
   (error (lambda (tok-ok? tok-name tok-value)
            (if tok-ok?
                (error (format "ROSHNI parse error: unexpected token '~a' (value: ~a)"
                               tok-name tok-value))
                (error (format "ROSHNI parse error: invalid token '~a'"
                               tok-name)))))
    (suppress)

   ;; ── Operator precedence (low → high, bottom wins) ──
   ;; This resolves ambiguity in arithmetic expressions.
   ;; Higher position = tighter binding (evaluated first).
   (precs
    (left  EQ2 NEQ)          ; == !=   (lowest)
    (left  LT GT LTE GTE)    ; < > <= >=
    (left  PLUS MINUS)       ; + -
    (left  TIMES DIVIDE))    ; * /     (highest among ops)

   ;; ── Starting rule ──
   (start program)

   ;; ════════════════════════════════════════════════════════
   ;; GRAMMAR RULES
   ;; Format: (rule-name
   ;;           [(token token ...) action]
   ;;           [(token token ...) action] ...)
   ;; $1 $2 $3 ... refer to the matched items left-to-right.
   ;; ════════════════════════════════════════════════════════
   (grammar

    ;; ── program: the top level is a list of statements ────
    (program
     [()           '()]                         ; empty program
     [(stmt program) (cons $1 $2)])             ; prepend stmt to rest

    ;; ── stmt: all statement types ─────────────────────────
    (stmt
     [(dhara-stmt)   $1]   ; variable declaration
     [(jalao-stmt)   $1]   ; function definition
     [(dikha-stmt)   $1]   ; print statement
     [(dohra-stmt)   $1]   ; loop (for-each or while)
     [(jab-stmt)     $1]   ; conditional if/else
     [(wapas-stmt)   $1]   ; return statement
     [(expr-stmt)    $1])  ; standalone expression

    ;; ── dhara: variable declaration ───────────────────────
    ;; dhara x = <expr>
    ;; AST: (dhara-decl "x" <expr-node>)
    (dhara-stmt
     [(DHARA ID EQ expr)
      (list 'dhara-decl $2 $4)])

    ;; ── jalao: function definition ────────────────────────
    ;; jalao funcName (param1 param2 ...) -> body... end
    ;; AST: (jalao-decl "funcName" ("p1" "p2") (body...))
    (jalao-stmt
     [(JALAO ID LPAREN param-list RPAREN ARROW body END)
      (list 'jalao-decl $2 $4 $7)])

    ;; ── param-list: comma-separated parameter names ───────
    ;; Returns a plain list of strings: ("n") or ("x" "y")
    (param-list
     [()                        '()]
     [(ID)                      (list $1)]
     [(ID COMMA param-list)     (cons $1 $3)])

    ;; ── body: one or more statements ──────────────────────
    ;; A body is a list of statement AST nodes.
    ;; We use a dedicated rule so functions, loops, and
    ;; conditionals all share the same body parsing logic.
    (body
     [(stmt)               (list $1)]
     [(stmt body)          (cons $1 $2)])

    ;; ── dikha: print statement ────────────────────────────
    ;; dikha <expr>
    ;; AST: (dikha-stmt <expr-node>)
    (dikha-stmt
     [(DIKHA expr)
      (list 'dikha-stmt $2)])

    ;; ── dohra: loops ──────────────────────────────────────
    ;; for-each:  dohra har <list-id> as <var> -> body end
    ;; while:     dohra <cond-expr> -> body end
    ;; AST for-each: (dohra-har "listName" "x" (body...))
    ;; AST while:    (dohra-while <cond> (body...))
    (dohra-stmt
     [(DOHRA HAR ID AS ID ARROW body END)
      (list 'dohra-har $3 $5 $7)]
     [(DOHRA expr ARROW body END)
      (list 'dohra-while $2 $4)])

    ;; ── jab/warna: if / else ──────────────────────────────
    ;; jab <cond> -> body warna body end
    ;; jab <cond> -> body end   (no else)
    ;; AST: (jab-stmt <cond> (then-body) (else-body or '()))
    (jab-stmt
     [(JAB expr ARROW body WARNA body END)
      (list 'jab-stmt $2 $4 $6)]
     [(JAB expr ARROW body END)
      (list 'jab-stmt $2 $4 '())])

    ;; ── wapas: return ─────────────────────────────────────
    ;; wapas <expr>
    ;; AST: (wapas-stmt <expr-node>)
    (wapas-stmt
     [(WAPAS expr)
      (list 'wapas-stmt $2)])

    ;; ── expr-stmt: expression used as a statement ─────────
    ;; Handles function calls standing alone on a line:
    ;;   bulao fib 10
    (expr-stmt
     [(expr)
      (list 'expr-stmt $1)])

    ;; ── expr: all expressions ─────────────────────────────
    ;; Arithmetic, comparison, literals, calls, identifiers.
    ;; Precedence rules above handle ambiguity automatically.
    (expr
     ;; Binary arithmetic
     [(expr PLUS   expr)  (list 'bin-op '+ $1 $3)]
     [(expr MINUS  expr)  (list 'bin-op '- $1 $3)]
     [(expr TIMES  expr)  (list 'bin-op '* $1 $3)]
     [(expr DIVIDE expr)  (list 'bin-op '/ $1 $3)]
     ;; Comparisons
     [(expr EQ2    expr)  (list 'bin-op '== $1 $3)]
     [(expr NEQ    expr)  (list 'bin-op '!= $1 $3)]
     [(expr LT     expr)  (list 'bin-op '<  $1 $3)]
     [(expr GT     expr)  (list 'bin-op '>  $1 $3)]
     [(expr LTE    expr)  (list 'bin-op '<= $1 $3)]
     [(expr GTE    expr)  (list 'bin-op '>= $1 $3)]
     ;; Unary minus: -5  or  -(x + 1)
     [(MINUS expr)        (list 'unary-op '- $2)]
     ;; Parenthesised expression: (3 + 4)
     [(LPAREN expr RPAREN) $2]
     ;; Function call: bulao fib 10  or  bulao add x y
     [(BULAO ID arg-list) (list 'bulao-call $2 $3)]
     ;; List index: nikalo nums[0]
     [(NIKALO ID LBRACK expr RBRACK) (list 'nikalo-expr $2 $4)]
     ;; List literal: jama(1, 2, 3)
     [(JAMA LPAREN expr-list RPAREN) (list 'jama-expr $3)]
     ;; Literals
     [(NUMBER)  (list 'num-lit  $1)]
     [(FLOAT)   (list 'float-lit $1)]
     [(STRING)  (list 'str-lit  $1)]
     [(HAAN)    (list 'bool-lit #t)]
     [(NAHI)    (list 'bool-lit #f)]
     ;; Variable reference
     [(ID)      (list 'id-ref   $1)])

    ;; ── arg-list: arguments for bulao calls ───────────────
    ;; bulao fib 10           → one arg
    ;; bulao add 3, 7         → two args (comma-separated)
    ;; bulao greet            → no args
    ;; Args are comma-separated expressions (like param-list).
    (arg-list
     [()                        '()]
     [(expr)                    (list $1)]
     [(expr COMMA arg-list)     (cons $1 $3)])

    ;; ── expr-list: comma-separated expressions ────────────
    ;; Used inside jama(1, 2, 3)
    (expr-list
     [(expr)                    (list $1)]
     [(expr COMMA expr-list)    (cons $1 $3)])

    ))) ;; end of define roshni-parser

(provide parse-roshni)


;; ═══════════════════════════════════════════════════════════
;; PUBLIC API
;; parse-roshni : string → list of AST nodes
;; This is what interpreter.rkt and main.rkt will call.
;; ═══════════════════════════════════════════════════════════
(define (parse-roshni source-str)
  (let* ([port  (open-input-string source-str)]
         [thunk (make-token-thunk port)])
    (roshni-parser thunk)))


; ;; ═══════════════════════════════════════════════════════════
; ;; PARSER TESTS — remove before final submission
; ;; Run with:  racket src/parser.rkt
; ;; ═══════════════════════════════════════════════════════════
; (define (test-parse label code)
;   (display (string-append "--- " label " ---\n"))
;   (let ([ast (parse-roshni code)])
;     (for-each (lambda (node)
;                 (display node)
;                 (newline))
;               ast))
;   (newline))

; ;; Test 1: variable declaration
; (test-parse "dhara (variable)"
;   "dhara x = 5")

; ;; Test 2: print string
; (test-parse "dikha (print)"
;   "dikha \"salam duniya\"")

; ;; Test 3: arithmetic expression
; (test-parse "arithmetic"
;   "dhara jawab = (3 + 4) * 2")

; ;; Test 4: boolean
; (test-parse "boolean"
;   "dhara flag = haan")

; ;; Test 5: list
; (test-parse "jama (list)"
;   "dhara nums = jama(1, 2, 3)")

; ;; Test 6: function call
; (test-parse "bulao (function call)"
;   "bulao double 10")

; ;; Test 7: conditional
; (test-parse "jab/warna (if/else)"
;   "jab x == 5 ->
;      dikha \"haan!\"
;    warna
;      dikha \"nahi!\"
;    end")

; ;; Test 8: for-each loop
; (test-parse "dohra har (for-each loop)"
;   "dohra har nums as x ->
;      dikha x
;    end")

; ;; Test 9: function definition
; (test-parse "jalao (function definition)"
;   "jalao double (n) ->
;      wapas n * 2
;    end")

; ;; Test 10: full fibonacci program
; (test-parse "fibonacci program"
;   "jalao fib (n) ->
;      jab n <= 1 ->
;        wapas n
;      warna
;        wapas (bulao fib n) + (bulao fib n)
;      end
;    end
;    dhara jawab = bulao fib 5
;    dikha jawab")