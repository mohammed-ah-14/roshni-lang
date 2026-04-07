#lang racket/base
(require racket/file
         "interpreter.rkt")

;; ── Run a .rsn source file ────────────────────────────────
(define (run-file path)
  (unless (file-exists? path)
    (displayln (format "ROSHNI: file nahi mila: ~a" path))
    (exit 1))
  (let ([src (file->string path)])
    (eval-program src)))

;; ── Entry point ───────────────────────────────────────────
;; Usage: racket src/main.rkt tests/hello.rsn
(let ([args (current-command-line-arguments)])
  (if (= (vector-length args) 1)
      (run-file (vector-ref args 0))
      (begin
        (displayln "ROSHNI — ek Urdu programming language")
        (displayln "Istemal: racket src/main.rkt <file.rsn>")
        (displayln "Example: racket src/main.rkt tests/fibonacci.rsn"))))