#lang racket/base
(require racket/match
         racket/string
         "parser.rkt")   ;; gives us parse-roshni
                          ;; parser.rkt already requires lexer.rkt

;; ═══════════════════════════════════════════════════════════
;; ROSHNI INTERPRETER — src/interpreter.rkt
;;
;; Architecture:
;;   • Environment = a hash-table mapping name→value
;;   • Child scopes (function bodies) get a fresh child env
;;     that falls back to the parent for lookups
;;   • eval-node dispatches on the AST tag
;;   • eval-program runs a list of top-level statements
;;   • Functions stored as (closure params body env)
;;   • Return values use a Racket exception to unwind the
;;     call stack cleanly — same trick Racket itself uses
;; ═══════════════════════════════════════════════════════════


;; ── Return-value signal ───────────────────────────────────
;; wapas (return) throws this struct so the function
;; call handler can catch it without walking the stack.
(struct roshni-return (value) #:transparent)


;; ── Environment helpers ───────────────────────────────────

;; make-env : creates a fresh top-level environment
(define (make-env)
  (make-hash))

;; make-child-env : creates a child scope that inherits parent
(define (make-child-env parent)
  (let ([child (make-hash)])
    ;; store parent reference for environment chain lookups
    (hash-set! child 'parent parent)
    child))

;; env-get : look up a name; error if not found
;; Searches up the parent chain
(define (env-get env name)
  (cond
    [(eq? name 'parent) #f]  ; skip 'parent key
    [(hash-has-key? env name)
     (hash-ref env name)]
    [(hash-has-key? env 'parent)
     (env-get (hash-ref env 'parent) name)]
    [else
     (error (format "ROSHNI: undefined variable '~a'" name))]))

;; env-set! : bind a name to a value in this scope
(define (env-set! env name value)
  (hash-set! env name value))

;; env-update! : update an existing variable in the environment chain
;; Searches up the parent chain to find where the variable is defined
(define (env-update! env name value)
  (cond
    [(hash-has-key? env name)
     (hash-set! env name value)]
    [(hash-has-key? env 'parent)
     (env-update! (hash-ref env 'parent) name value)]
    [else
     (error (format "ROSHNI: undefined variable '~a'" name))]))


;; ── Binary operator dispatch ──────────────────────────────
(define (apply-binop op left right)
  (case op
    [(+)  (+ left right)]
    [(-)  (- left right)]
    [(*)  (* left right)]
    [(/)  (if (= right 0)
              (error "ROSHNI: taqseem sifar se nahi hoti (division by zero)")
              (exact->inexact (/ left right)))]
    [(==) (equal? left right)]
    [(!=) (not (equal? left right))]
    [(<)  (< left right)]
    [(>)  (> left right)]
    [(<=) (<= left right)]
    [(>=) (>= left right)]
    [else (error (format "ROSHNI: anjaan operator '~a'" op))]))


;; ── Core evaluator ────────────────────────────────────────
;; eval-node : ast-node × env → value
;; Dispatches on the tag (first element) of each AST node.
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

    ;; ── dhara: variable declaration ───────────────────────
    ;; dhara x = 5  →  bind "x" → 5 in current env
    [(list 'dhara-decl name expr)
     (let ([val (eval-node expr env)])
       (env-set! env name val)
       val)]

    ;; ── assignment: variable reassignment ─────────────────
    ;; x = 10  →  update existing "x" to 10 (searches parent scopes)
    [(list 'assign-stmt name expr)
     (let ([val (eval-node expr env)])
       (env-update! env name val)
       val)]

    ;; ── jalao: function definition ────────────────────────
    ;; Stores a closure: (closure params body captured-env)
    ;; We capture the current env so the function can access
    ;; variables from its definition scope (lexical scoping).
    [(list 'jalao-decl name params body)
     (let ([closure (list 'closure params body env)])
       (env-set! env name closure)
       closure)]

    ;; ── bulao: function call ──────────────────────────────
    ;; 1. Look up the function closure in env
    ;; 2. Create a child environment from the closure's env
    ;; 3. Bind each parameter to the evaluated argument
    ;; 4. Run the body — catch any wapas (return) signal
    [(list 'bulao-call name args)
     (let ([closure (env-get env name)])
       (unless (and (list? closure) (eq? (car closure) 'closure))
         (error (format "ROSHNI: '~a' koi function nahi hai" name)))
       (let* ([params    (cadr closure)]
              [body      (caddr closure)]
              [saved-env (cadddr closure)]
              [child     (make-child-env saved-env)]
              [arg-vals  (map (lambda (a) (eval-node a env)) args)])
         ;; bind params to arg values
         (for-each (lambda (p v) (env-set! child p v))
                   params arg-vals)
         ;; execute body, catching wapas return signals
         (with-handlers
           ([roshni-return? (lambda (r) (roshni-return-value r))])
           (let ([result #f])
             (for-each (lambda (stmt)
                         (set! result (eval-node stmt child)))
                       body)
             result))))]

    ;; ── wapas: return ────────────────────────────────────
    [(list 'wapas-stmt expr)
     (raise (roshni-return (eval-node expr env)))]

    ;; ── dikha: print ─────────────────────────────────────
    [(list 'dikha-stmt expr)
     (let ([val (eval-node expr env)])
       (display (roshni-display val))
       (newline)
       val)]

    ;; ── jab/warna: if / else ─────────────────────────────
    [(list 'jab-stmt cond-expr then-body else-body)
     (let ([cond-val (eval-node cond-expr env)])
       (if cond-val
           (eval-body then-body env)
           (if (null? else-body)
               #f
               (eval-body else-body env))))]

    ;; ── dohra har: for-each loop ─────────────────────────
    ;; dohra har nums as x ->  body  end
    ;; Look up the list, iterate, bind x each time
    [(list 'dohra-har list-name var-name body)
     (let ([lst (env-get env list-name)])
       (unless (list? lst)
         (error (format "ROSHNI: '~a' koi fehrist nahi hai (not a list)" list-name)))
       (for-each (lambda (item)
                   (let ([child (make-child-env env)])
                     (env-set! child var-name item)
                     (eval-body body child)))
                 lst))]

    ;; ── dohra while: while loop ──────────────────────────
    [(list 'dohra-while cond-expr body)
     (let loop ()
       (when (eval-node cond-expr env)
         (eval-body body env)
         (loop)))]

    ;; ── Binary operations ────────────────────────────────
    [(list 'bin-op op left right)
     (apply-binop op (eval-node left env) (eval-node right env))]

    ;; ── Unary minus ──────────────────────────────────────
    [(list 'unary-op '- expr)
     (- (eval-node expr env))]

    ;; ── jama: list literal ───────────────────────────────
    [(list 'jama-expr items)
     (map (lambda (item) (eval-node item env)) items)]

    ;; ── nikalo: list index ───────────────────────────────
    ;; nikalo nums[0]  → get first element
    [(list 'nikalo-expr list-name idx-expr)
     (let* ([lst (env-get env list-name)]
            [idx (eval-node idx-expr env)])
       (unless (list? lst)
         (error (format "ROSHNI: '~a' koi fehrist nahi hai" list-name)))
       (unless (< idx (length lst))
         (error (format "ROSHNI: fehrist ki seema se bahar (index ~a out of range)" idx)))
       (list-ref lst idx))]

    ;; ── expr-stmt: expression as statement ───────────────
    [(list 'expr-stmt expr)
     (eval-node expr env)]

    ;; ── fallback ─────────────────────────────────────────
    [_
     (error (format "ROSHNI: anjaan node: ~a" node))]))


;; ── eval-body: run a list of statements, return last value ─
(define (eval-body stmts env)
  (let ([result #f])
    (for-each (lambda (s) (set! result (eval-node s env)))
              stmts)
    result))


;; ── roshni-display: pretty-print values ──────────────────
;; Converts Racket values to ROSHNI-friendly display strings.
(define (roshni-display val)
  (cond
    [(eq? val #t)   "haan"]
    [(eq? val #f)   "nahi"]
    [(list? val)
     (string-append "["
       (string-join (map (lambda (v) (roshni-display v)) val) ", ")
     "]")]
    [(number? val)
     ;; print integers without decimal, floats with
     (if (integer? val)
         (number->string (exact->inexact val) 10)
         (number->string val))]
    [else (format "~a" val)]))


;; ═══════════════════════════════════════════════════════════
;; PUBLIC API
;; eval-program : string → runs the ROSHNI source code
;; This is what main.rkt calls.
;; ═══════════════════════════════════════════════════════════
(define (eval-program source-str)
  (let* ([ast (parse-roshni source-str)]
         [env (make-env)])
    (for-each (lambda (node) (eval-node node env))
              ast)))

(provide eval-program)