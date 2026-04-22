#lang racket/base

(require parser-tools/yacc
         parser-tools/lex
         "lexer.rkt")


;; ═══════════════════════════════════════════════════════════
;; ROSHNI PARSER — src/parser.rkt
;;
;; Turns the token stream from lexer.rkt into an AST.
;;
;; Think of the parser like a grammar teacher reading a sentence:
;;   "rakho x = 5 + 3"
;; The teacher recognises: "this is a declaration, the name is x,
;; and the value is the expression 5 + 3."  The AST is just
;; that understanding written as a nested list:
;;   (dhara-decl "x" (bin-op + (num-lit 5) (num-lit 3)))
;;
;; LALR(1): the parser peeks at ONE upcoming token to decide
;; which grammar rule applies.
;;
;; New in this version:
;;   • All keywords renamed (rakho/banao/dikhao/…)
;;   • warna-agar (elif) with a right-recursive agar-tail rule
;;   • Logical operators: aur (and), ya (or), nai (not)
;;   • HAR replaces DOHRA HAR; JABTAK replaces DOHRA
;;   • FEHRIST replaces JAMA for list literals
;;   • LO replaces NIKALO for index access
;;   • Internal AST tags are UNCHANGED — only surface syntax changed
;; ═══════════════════════════════════════════════════════════


;; ── Wrap the lexer into a thunk (zero-arg function) ───────
;; The parser calls this thunk repeatedly to get the next token.
(define (make-token-thunk port)
  (lambda ()
    (roshni-lexer port)))


;; ═══════════════════════════════════════════════════════════
;; THE PARSER
;; ═══════════════════════════════════════════════════════════
(define roshni-parser
  (parser

   (end EOF)
   (tokens value-tokens punct-tokens)

   (error (lambda (tok-ok? tok-name tok-value)
            (if tok-ok?
                (error (format "ROSHNI parse error: ghalat token '~a' (qeemat: ~a)"
                               tok-name tok-value))
                (error (format "ROSHNI parse error: anjaan token '~a'"
                               tok-name)))))
   (suppress)

   ;; ── Operator precedence (low → high, bottom wins) ──────
   ;;
   ;; Imagine a weighing scale: heavier operators sink to the
   ;; bottom of the expression tree, meaning they bind tighter.
   ;;
   ;; Example:  sahi ya ghalat aur sahi
   ;;           → sahi ya (ghalat aur sahi)   ← aur binds tighter
   ;;
   (precs
    (left  YA)              ;; ya  (or)          — loosest
    (left  AUR)             ;; aur (and)
    (right NAI_NOT)         ;; nai (not)         — unary prefix
    (left  JODNA)           ;; jodna (concat)    — below comparisons so
                            ;;   "val: " jodna 3 + 4  →  "val: 7"  ✓
    (left  EQ2 NEQ)         ;; == barabar  != nai-barabar
    (left  LT GT LTE GTE)  ;; < kam  > zyada  <= >=
    (left  PLUS MINUS)      ;; + jama  - tafreeq
    (left  TIMES DIVIDE))   ;; * zarb  / taqseem — tightest

   (start program)

   ;; ════════════════════════════════════════════════════════
   ;; GRAMMAR RULES
   ;; ════════════════════════════════════════════════════════
   (grammar

    ;; ── program: a list of top-level statements ───────────
    (program
     [()              '()]
     [(stmt program)  (cons $1 $2)])

    ;; ── stmt: all statement forms ─────────────────────────
    (stmt
     [(rakho-stmt)   $1]    ;; variable declaration
     [(assign-stmt)  $1]    ;; variable reassignment
     [(banao-stmt)   $1]    ;; function definition
     [(dikhao-stmt)  $1]    ;; print
     [(jabtak-stmt)  $1]    ;; while loop
     [(har-stmt)     $1]    ;; for-each loop
     [(agar-stmt)    $1]    ;; if / elif / else
     [(wapas-stmt)   $1]    ;; return
     [(expr-stmt)    $1])   ;; expression as statement

    ;; ── rakho: variable declaration ──────────────────────
    ;; rakho x = <expr>
    ;; AST: (dhara-decl "x" <expr>)
    ;; (internal tag kept as dhara-decl for interpreter compat.)
    (rakho-stmt
     [(RAKHO ID EQ expr)
      (list 'dhara-decl $2 $4)])

    ;; ── assignment: variable reassignment ────────────────
    ;; x = <expr>     (no rakho — updating existing variable)
    ;; AST: (assign-stmt "x" <expr>)
    (assign-stmt
     [(ID EQ expr)
      (list 'assign-stmt $1 $3)])

    ;; ── banao: function definition ────────────────────────
    ;; banao funcName (p1 p2) -> body end
    ;; AST: (jalao-decl "funcName" ("p1" "p2") (body...))
    (banao-stmt
     [(BANAO ID LPAREN param-list RPAREN ARROW body END)
      (list 'jalao-decl $2 $4 $7)])

    ;; ── param-list: comma-separated parameter names ───────
    (param-list
     [()                      '()]
     [(ID)                    (list $1)]
     [(ID COMMA param-list)   (cons $1 $3)])

    ;; ── body: one or more statements ──────────────────────
    ;; A body is the list of statements inside a block.
    (body
     [(stmt)         (list $1)]
     [(stmt body)    (cons $1 $2)])

    ;; ── dikhao: print ─────────────────────────────────────
    ;; dikhao <expr>
    ;; AST: (dikha-stmt <expr>)
    (dikhao-stmt
     [(DIKHAO expr)
      (list 'dikha-stmt $2)])

    ;; ── jabtak: while loop ────────────────────────────────
    ;; jabtak <cond> -> body end
    ;; AST: (dohra-while <cond> (body...))
    (jabtak-stmt
     [(JABTAK expr ARROW body END)
      (list 'dohra-while $2 $4)])

    ;; ── har: for-each loop ────────────────────────────────
    ;; har <list-id> as <var> -> body end
    ;; AST: (dohra-har "listName" "x" (body...))
    (har-stmt
     [(HAR ID AS ID ARROW body END)
      (list 'dohra-har $2 $4 $6)])

    ;; ── agar/warna-agar/warna: if / elif / else ───────────
    ;;
    ;; agar x > 5 ->       ← AGAR opens the if
    ;;   body
    ;; warna-agar x == 5 ->  ← WARNA_AGAR (zero or more)
    ;;   body
    ;; warna               ← WARNA opens the else
    ;;   body
    ;; end
    ;;
    ;; The "agar-tail" rule handles everything AFTER the then-body:
    ;;   END              → no else, close block
    ;;   WARNA body END   → plain else
    ;;   WARNA_AGAR ...   → elif, which recurses into another agar-tail
    ;;
    ;; Because elif becomes a nested jab-stmt inside the else-body,
    ;; the interpreter handles it for free — it just runs eval-body
    ;; on the else-body, which hits the nested jab-stmt.
    ;;
    ;; AST: (jab-stmt <cond> (then-body) (else-body-or-'()))
    ;;
    (agar-stmt
     [(AGAR expr ARROW body agar-tail)
      (list 'jab-stmt $2 $4 $5)])

    (agar-tail
     ;; No else — block ends here
     [(END)
      '()]
     ;; Plain warna (else)
     [(WARNA body END)
      $2]
     ;; warna-agar (elif) — wraps as a single jab-stmt in a list,
     ;; so eval-body will execute it naturally as the else branch.
     [(WARNA_AGAR expr ARROW body agar-tail)
      (list (list 'jab-stmt $2 $4 $5))])

    ;; ── wapas: return ─────────────────────────────────────
    ;; wapas <expr>
    ;; AST: (wapas-stmt <expr>)
    (wapas-stmt
     [(WAPAS expr)
      (list 'wapas-stmt $2)])

    ;; ── expr-stmt: expression as a statement ─────────────
    ;; Allows  bulao fib 10  as a standalone line.
    (expr-stmt
     [(expr)
      (list 'expr-stmt $1)])

    ;; ── expr: all expressions ─────────────────────────────
    ;;
    ;; Word operators (jama, tafreeq, …) and symbol operators
    ;; (+, -, …) produce the SAME tokens, so the parser sees
    ;; only one set of rules here.
    ;;
    (expr
     ;; String concatenation — converts BOTH sides to their string
     ;; representation before joining, so numbers/booleans work too:
     ;;   "bhari hai: " jodna 5000 jodna " kg"  →  "bhari hai: 5000 kg"
     [(expr JODNA  expr)   (list 'bin-op 'jodna $1 $3)]
     ;; Arithmetic
     [(expr PLUS   expr)   (list 'bin-op '+   $1 $3)]
     [(expr MINUS  expr)   (list 'bin-op '-   $1 $3)]
     [(expr TIMES  expr)   (list 'bin-op '*   $1 $3)]
     [(expr DIVIDE expr)   (list 'bin-op '/   $1 $3)]
     ;; Comparison
     [(expr EQ2    expr)   (list 'bin-op '==  $1 $3)]
     [(expr NEQ    expr)   (list 'bin-op '!=  $1 $3)]
     [(expr LT     expr)   (list 'bin-op '<   $1 $3)]
     [(expr GT     expr)   (list 'bin-op '>   $1 $3)]
     [(expr LTE    expr)   (list 'bin-op '<=  $1 $3)]
     [(expr GTE    expr)   (list 'bin-op '>=  $1 $3)]
     ;; Logical binary
     [(expr AUR    expr)   (list 'bin-op 'and $1 $3)]
     [(expr YA     expr)   (list 'bin-op 'or  $1 $3)]
     ;; Logical unary: nai sahi  →  ghalat
     [(NAI_NOT expr)       (list 'unary-op 'not $2)]
     ;; Arithmetic unary: -5  or  -(x + 1)
     [(MINUS expr)         (list 'unary-op '-   $2)]
     ;; Parenthesised: (3 + 4)
     [(LPAREN expr RPAREN) $2]
     ;; Function call: bulao fib 10
     [(BULAO ID arg-list)  (list 'bulao-call $2 $3)]
     ;; Index access: lo nums[0]
     [(LO ID LBRACK expr RBRACK)
      (list 'nikalo-expr $2 $4)]
     ;; List literal: fehrist(1, 2, 3)
     [(FEHRIST LPAREN expr-list RPAREN)
      (list 'jama-expr $3)]
     ;; Literals
     [(NUMBER)  (list 'num-lit   $1)]
     [(FLOAT)   (list 'float-lit $1)]
     [(STRING)  (list 'str-lit   $1)]
     [(SAHI)    (list 'bool-lit  #t)]
     [(GHALAT)  (list 'bool-lit  #f)]
     ;; Variable reference
     [(ID)      (list 'id-ref    $1)])

    ;; ── arg-list: arguments passed to bulao ───────────────
    ;; bulao fib 10         → one arg
    ;; bulao add 3, 7       → two args
    ;; bulao greet          → no args
    (arg-list
     [()                      '()]
     [(expr)                  (list $1)]
     [(expr COMMA arg-list)   (cons $1 $3)])

    ;; ── expr-list: comma-separated expressions ─────────────
    ;; Used inside fehrist(1, 2, 3)
    (expr-list
     [(expr)                  (list $1)]
     [(expr COMMA expr-list)  (cons $1 $3)])

    ))) ;; end roshni-parser


;; ═══════════════════════════════════════════════════════════
;; PUBLIC API
;; parse-roshni : string → list of AST nodes
;; ═══════════════════════════════════════════════════════════
(define (parse-roshni source-str)
  (let* ([port  (open-input-string source-str)]
         [thunk (make-token-thunk port)])
    (roshni-parser thunk)))

(provide parse-roshni)