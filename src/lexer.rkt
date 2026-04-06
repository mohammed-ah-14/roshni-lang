#lang racket/base

(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre))

;; ── 1. Value-carrying tokens ──
(define-tokens value-tokens
  (ID NUMBER FLOAT STRING))

;; ── 2. Empty tokens (keywords + punctuation) ──
(define-empty-tokens punct-tokens
  (DHARA JALAO BULAO DIKHA
   DOHRA HAR JAB WARNA
   JAMA  NIKALO WAPAS
   HAAN  NAHI   AS
   ARROW EQ    EQ2   NEQ
   LT    GT    LTE   GTE
   PLUS  MINUS TIMES DIVIDE
   LPAREN RPAREN
   LBRACK RBRACK
   COMMA  EOF))

;; ── 3. Shorthand patterns ──
(define-lex-abbrevs
  (digit   (:/ "09"))
  (letter  (:or (:/ "az") (:/ "AZ")))
  (id-char (:or letter digit (char-set "_"))))

;; ── 4. The lexer ──
;; Using plain `lexer` (not lexer-src-pos) to avoid nested position-token wrapping
(define roshni-lexer
  (lexer
   ;; Skip whitespace
   ((:+ (:or " " "\t" "\n" "\r")) (roshni-lexer input-port))
   ;; Skip comments  %% this is a comment
   ((:seq "%%" (:* (:~ "\n")))    (roshni-lexer input-port))

   ;; Keywords — must come BEFORE the identifier rule
   ("dhara"  (token-DHARA))
   ("jalao"  (token-JALAO))
   ("bulao"  (token-BULAO))
   ("dikha"  (token-DIKHA))
   ("dohra"  (token-DOHRA))
   ("har"    (token-HAR))
   ("jab"    (token-JAB))
   ("warna"  (token-WARNA))
   ("jama"   (token-JAMA))
   ("nikalo" (token-NIKALO))
   ("wapas"  (token-WAPAS))
   ("haan"   (token-HAAN))
   ("nahi"   (token-NAHI))
   ("as"     (token-AS))

   ;; Identifiers
   ((:seq letter (:* id-char)) (token-ID lexeme))

   ;; Float must come BEFORE integer
   ((:seq (:+ digit) "." (:+ digit)) (token-FLOAT (string->number lexeme)))
   ((:+ digit)                        (token-NUMBER (string->number lexeme)))

   ;; Strings
   ((:seq "\"" (:* (:~ "\"")) "\"")
    (token-STRING (substring lexeme 1 (- (string-length lexeme) 1))))

   ;; Multi-char operators — must come BEFORE single-char ones
   ("->" (token-ARROW))
   ("==" (token-EQ2))
   ("!=" (token-NEQ))
   ("<=" (token-LTE))
   (">=" (token-GTE))

   ;; Single-char operators
   ("<"  (token-LT))
   (">"  (token-GT))
   ("="  (token-EQ))
   ("+"  (token-PLUS))
   ("-"  (token-MINUS))
   ("*"  (token-TIMES))
   ("/"  (token-DIVIDE))
   ("("  (token-LPAREN))
   (")"  (token-RPAREN))
   ("["  (token-LBRACK))
   ("]"  (token-RBRACK))
   (","  (token-COMMA))

   ((eof) (token-EOF))))

;; ── 5. Tokenise a string and print each token cleanly ──
(define (tokenize-string str)
  (let ([port (open-input-string str)])
    (let loop ([tok (roshni-lexer port)])
      (unless (eq? tok 'EOF)
        ;; tok is either a plain symbol (empty token) or a (token name value) struct
        (cond
          [(symbol? tok)
           (printf "~a\n" tok)]
          [(token? tok)
           (let ([n (token-name  tok)]
                 [v (token-value tok)])
             (if v
                 (printf "(~a ~a)\n" n v)
                 (printf "~a\n"      n)))]
          [else
           (printf "UNKNOWN: ~a\n" tok)])
        (loop (roshni-lexer port))))))

;; ── 6. Test runs ──
(displayln "--- test 1: variable declaration ---")
(tokenize-string "dhara x = 5")

(displayln "--- test 2: function definition ---")
(tokenize-string "jalao fib (n) ->")

(displayln "--- test 3: print string ---")
(tokenize-string "dikha \"hello world\"")

(displayln "--- test 4: for-each loop ---")
(tokenize-string "dohra har numList as x ->")

(displayln "--- test 5: conditional ---")
(tokenize-string "jab x == 5")

(displayln "--- test 6: arithmetic ---")
(tokenize-string "dhara jawab = (3 + 4) * 2")

(displayln "--- test 7: boolean ---")
(tokenize-string "dhara flag = haan")

(displayln "--- test 8: list ---")
(tokenize-string "dhara nums = jama(1, 2, 3)")