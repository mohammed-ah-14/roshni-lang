#lang racket/base
(require racket/match
         racket/string
         "parser.rkt")


;; ═══════════════════════════════════════════════════════════
;; ROSHNI INTERPRETER — src/interpreter.rkt
;;
;; Architecture (unchanged from v1):
;;   • Environment = a hash-table mapping name → value
;;   • Child scopes (function bodies) get a fresh child env
;;     that falls back to the parent for lookups (lexical scope)
;;   • eval-node dispatches on the AST tag
;;   • Functions stored as  (closure params body env)
;;   • wapas (return) throws a Racket exception to unwind
;;     the call stack cleanly
;;
;; New in this version:
;;   • Logical operators: and, or   (bin-op)
;;   • Logical not:       not       (unary-op)
;;   • Display: #t → "sahi", #f → "ghalat"   (was haan/nahi)
;;   • Updated runtime error messages to match new keywords
;;
;; Note: all AST tags are UNCHANGED — only the surface syntax
;; of ROSHNI changed (rakho/banao/…). The interpreter sees the
;; same (dhara-decl …), (jalao-decl …) nodes as before.
;; ═══════════════════════════════════════════════════════════


;; ── Return-value signal ────────────────────────────────────
;; When the user writes  wapas <expr>,  the evaluator raises
;; this struct so the enclosing bulao-call can catch it without
;; having to check every statement's return value manually.
(struct roshni-return (value) #:transparent)


;; ═══════════════════════════════════════════════════════════
;; ENVIRONMENT HELPERS
;;
;; An environment is like a name-tag drawer:
;;   env-set!    adds/replaces a tag in the current drawer
;;   env-get     searches this drawer then parent drawers
;;   env-update! finds an existing tag in any drawer and changes it
;; ═══════════════════════════════════════════════════════════

(define (make-env)
  (make-hash))

(define (make-child-env parent)
  (let ([child (make-hash)])
    (hash-set! child 'parent parent)
    child))

(define (env-get env name)
  (cond
    [(eq? name 'parent) #f]
    [(hash-has-key? env name)
     (hash-ref env name)]
    [(hash-has-key? env 'parent)
     (env-get (hash-ref env 'parent) name)]
    [else
     (error (format "ROSHNI: '~a' — yeh variable nahi mila (undefined)" name))]))

(define (env-set! env name value)
  (hash-set! env name value))

;; env-update! searches up the parent chain to find where
;; the variable was originally declared, then updates it there.
(define (env-update! env name value)
  (cond
    [(hash-has-key? env name)
     (hash-set! env name value)]
    [(hash-has-key? env 'parent)
     (env-update! (hash-ref env 'parent) name value)]
    [else
     (error (format "ROSHNI: '~a' — pehle rakho se define karo (undefined variable)" name))]))


;; ═══════════════════════════════════════════════════════════
;; BINARY OPERATOR DISPATCH
;;
;; apply-binop : symbol × value × value → value
;; All arithmetic, comparison, and logical operators go here.
;; ═══════════════════════════════════════════════════════════
(define (apply-binop op left right)
  (case op
    ;; String concatenation
    ;; jodna converts both sides using roshni-display, then joins them.
    ;; This means ANY value type works on either side:
    ;;   "wazn: " jodna 42 jodna " kg"  →  "wazn: 42 kg"
    ;;   "sach: " jodna sahi            →  "sach: sahi"
    [(jodna)
     (string-append (roshni-display left) (roshni-display right))]
    ;; Arithmetic
    [(+)   (+ left right)]
    [(-)   (- left right)]
    [(*)   (* left right)]
    [(/)   (if (= right 0)
               (error "ROSHNI: taqseem sifar se nahi hoti (division by zero)")
               (exact->inexact (/ left right)))]
    ;; Equality
    [(==)  (equal? left right)]
    [(!=)  (not (equal? left right))]
    ;; Ordering
    [(<)   (<  left right)]
    [(>)   (>  left right)]
    [(<=)  (<= left right)]
    [(>=)  (>= left right)]
    ;; Logical — left and right are already fully evaluated values
    [(and) (and left right)]
    [(or)  (or  left right)]
    [else
     (error (format "ROSHNI: anjaan operator '~a'" op))]))


;; ═══════════════════════════════════════════════════════════
;; CORE EVALUATOR
;;
;; eval-node : ast-node × env → value
;;
;; This is the heart of the interpreter. It pattern-matches on
;; each AST node tag and computes a result.
;; Think of it as a translator: AST node in, Racket value out.
;; ═══════════════════════════════════════════════════════════
(define (eval-node node env)
  (match node

    ;; ── Literals ──────────────────────────────────────────
    [(list 'num-lit   v) v]
    [(list 'float-lit v) v]
    [(list 'str-lit   v) v]
    [(list 'bool-lit  v) v]

    ;; ── Variable lookup ───────────────────────────────────
    [(list 'id-ref name)
     (env-get env name)]

    ;; ── rakho: variable declaration ───────────────────────
    ;; rakho x = 5  →  bind "x" → 5 in current env
    [(list 'dhara-decl name expr)
     (let ([val (eval-node expr env)])
       (env-set! env name val)
       val)]

    ;; ── assignment: variable reassignment ─────────────────
    ;; x = 10  →  find "x" in scope chain and update it
    [(list 'assign-stmt name expr)
     (let ([val (eval-node expr env)])
       (env-update! env name val)
       val)]

    ;; ── banao: function definition ────────────────────────
    ;; Stores a closure capturing the CURRENT environment,
    ;; enabling lexical (not dynamic) scoping.
    ;; A closure is: (closure params body captured-env)
    [(list 'jalao-decl name params body)
     (let ([closure (list 'closure params body env)])
       (env-set! env name closure)
       closure)]

    ;; ── bulao: function call ──────────────────────────────
    ;; Steps:
    ;;   1. Look up the closure stored under the function name
    ;;   2. Create a child env from the closure's captured env
    ;;   3. Bind each parameter to its evaluated argument
    ;;   4. Run the body — catch any wapas (return) signals
    [(list 'bulao-call name args)
     (let ([closure (env-get env name)])
       (unless (and (list? closure) (eq? (car closure) 'closure))
         (error (format "ROSHNI: '~a' koi function nahi hai" name)))
       (let* ([params    (cadr  closure)]
              [body      (caddr closure)]
              [saved-env (cadddr closure)]
              [child     (make-child-env saved-env)]
              [arg-vals  (map (lambda (a) (eval-node a env)) args)])
         (for-each (lambda (p v) (env-set! child p v))
                   params arg-vals)
         (with-handlers
           ([roshni-return? (lambda (r) (roshni-return-value r))])
           (let ([result #f])
             (for-each (lambda (stmt)
                         (set! result (eval-node stmt child)))
                       body)
             result))))]

    ;; ── wapas: return ─────────────────────────────────────
    ;; Raises an exception that bulao-call catches above.
    [(list 'wapas-stmt expr)
     (raise (roshni-return (eval-node expr env)))]

    ;; ── dikhao: print ─────────────────────────────────────
    [(list 'dikha-stmt expr)
     (let ([val (eval-node expr env)])
       (display (roshni-display val))
       (newline)
       val)]

    ;; ── agar/warna-agar/warna: if / elif / else ───────────
    ;;
    ;; How elif works here (no special case needed!):
    ;; The parser encodes  warna-agar cond -> body tail  as:
    ;;   else-body = ((jab-stmt cond body tail))
    ;; i.e., a list with ONE element: a nested jab-stmt.
    ;; eval-body runs that list, reaches the jab-stmt node,
    ;; and this very clause handles it recursively. ✓
    ;;
    [(list 'jab-stmt cond-expr then-body else-body)
     (let ([cond-val (eval-node cond-expr env)])
       (if cond-val
           (eval-body then-body env)
           (if (null? else-body)
               #f
               (eval-body else-body env))))]

    ;; ── har: for-each loop ────────────────────────────────
    ;; har nums as x ->  body  end
    ;; Binds x to each element in a fresh child scope each iteration.
    [(list 'dohra-har list-name var-name body)
     (let ([lst (env-get env list-name)])
       (unless (list? lst)
         (error (format "ROSHNI: '~a' koi fehrist nahi hai (not a list)" list-name)))
       (for-each (lambda (item)
                   (let ([child (make-child-env env)])
                     (env-set! child var-name item)
                     (eval-body body child)))
                 lst))]

    ;; ── jabtak: while loop ────────────────────────────────
    [(list 'dohra-while cond-expr body)
     (let loop ()
       (when (eval-node cond-expr env)
         (eval-body body env)
         (loop)))]

    ;; ── Binary operations ─────────────────────────────────
    [(list 'bin-op op left right)
     (apply-binop op (eval-node left env) (eval-node right env))]

    ;; ── Unary operations ──────────────────────────────────
    ;; Handles both  -x  (arithmetic negate) and  nai x  (logical not)
    [(list 'unary-op '- expr)
     (- (eval-node expr env))]
    [(list 'unary-op 'not expr)
     (not (eval-node expr env))]

    ;; ── fehrist: list literal ─────────────────────────────
    ;; fehrist(1, 2, 3)  →  evaluates each item → Racket list
    [(list 'jama-expr items)
     (map (lambda (item) (eval-node item env)) items)]

    ;; ── lo: list index access ─────────────────────────────
    ;; lo nums[0]  →  first element of nums
    [(list 'nikalo-expr list-name idx-expr)
     (let* ([lst (env-get env list-name)]
            [idx (eval-node idx-expr env)])
       (unless (list? lst)
         (error (format "ROSHNI: '~a' koi fehrist nahi hai" list-name)))
       (unless (< idx (length lst))
         (error (format "ROSHNI: fehrist ki seema se bahar — index ~a" idx)))
       (list-ref lst idx))]

    ;; ── expr-stmt: expression as a statement ─────────────
    [(list 'expr-stmt expr)
     (eval-node expr env)]

    ;; ── Fallback ──────────────────────────────────────────
    [_
     (error (format "ROSHNI: pehchaana nahi gaya node: ~a" node))]))


;; ── eval-body: run a list of statements, return last value ─
(define (eval-body stmts env)
  (let ([result #f])
    (for-each (lambda (s) (set! result (eval-node s env)))
              stmts)
    result))


;; ═══════════════════════════════════════════════════════════
;; DISPLAY HELPER
;;
;; roshni-display: converts a Racket value to a ROSHNI string.
;; Numbers, booleans, and lists all get their own formatting.
;; ═══════════════════════════════════════════════════════════
(define (roshni-display val)
  (cond
    ;; Booleans show as sahi / ghalat  (updated from haan/nahi)
    [(eq? val #t)   "sahi"]
    [(eq? val #f)   "ghalat"]
    ;; Lists show as [ item, item, ... ]
    [(list? val)
     (string-append "["
       (string-join (map roshni-display val) ", ")
     "]")]
    ;; Integers print without decimal point; floats keep theirs
    [(number? val)
     (if (integer? val)
         (number->string (inexact->exact val))
         (number->string val))]
    [else
     (format "~a" val)]))


;; ═══════════════════════════════════════════════════════════
;; PUBLIC API
;; eval-program : string → runs ROSHNI source code
;; Called by main.rkt.
;; ═══════════════════════════════════════════════════════════
(define (eval-program source-str)
  (let* ([ast (parse-roshni source-str)]
         [env (make-env)])
    (for-each (lambda (node) (eval-node node env))
              ast)))

(provide eval-program)