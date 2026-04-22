#lang racket/base

(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre))

;; ═══════════════════════════════════════════════════════════
;; ROSHNI LEXER — src/lexer.rkt
;;
;; Turns raw source text into a flat stream of tokens.
;; Think of it like a post-office sorter: raw letters (characters)
;; come in, and labelled parcels (tokens) come out.
;;
;; Key design decisions:
;;   • Hyphenated keywords (warna-agar, nai-barabar, …) are
;;     listed FIRST — the lexer uses longest-match, so
;;     "nai-barabar" (12 chars) beats "nai" (3 chars) ✓
;;   • Word operators (jama, tafreeq, …) emit the SAME token
;;     as their symbol counterparts (+, -, …) so the parser
;;     needs zero extra rules for them.
;;   • Comments begin with the word "tanqeed"; everything
;;     after it on that line is ignored.
;; ═══════════════════════════════════════════════════════════


;; ── 1. Value-carrying tokens ──────────────────────────────
;; These carry a Racket value alongside the token type.
(define-tokens value-tokens
  (ID NUMBER FLOAT STRING))

;; ── 2. Empty tokens (keywords + punctuation) ─────────────
;; These carry no extra value — the token type IS the info.
(define-empty-tokens punct-tokens
  (;; Declaration & definition
   RAKHO       ;; rakho   — variable declaration  (was: dhara)
   BANAO       ;; banao   — function definition   (was: jalao)
   BULAO       ;; bulao   — function call          (unchanged)
   DIKHAO      ;; dikhao  — print                 (was: dikha)

   ;; Control flow
   JABTAK      ;; jabtak       — while loop       (was: dohra)
   HAR         ;; har          — for-each loop    (was: dohra har)
   AGAR        ;; agar         — if               (was: jab)
   WARNA       ;; warna        — else             (unchanged)
   WARNA_AGAR  ;; warna-agar   — else-if          (NEW)

   ;; Collections & indexing
   FEHRIST     ;; fehrist — list literal          (was: jama)
   LO          ;; lo      — list index access     (was: nikalo)

   ;; Other keywords
   WAPAS       ;; wapas   — return                (unchanged)
   END         ;; end     — closes a block        (unchanged)
   SAHI        ;; sahi    — true                  (was: haan)
   GHALAT      ;; ghalat  — false                 (was: nahi)
   AS          ;; as      — used in har loop      (unchanged)

   ;; Logical operators (NEW — also available as: aur ya nai)
   AUR         ;; aur     — and
   YA          ;; ya      — or
   NAI_NOT     ;; nai     — not  (unary prefix)

   ;; String concatenation
   JODNA       ;; jodna   — join/concatenate strings (and any value)

   ;; Comparison & equality operators
   ;; (word forms: barabar nai-barabar zyada kam
   ;;              zyada-ya-barabar  kam-ya-barabar
   ;;  emit the SAME tokens as the symbol forms below)
   ARROW EQ EQ2 NEQ
   LT GT LTE GTE

   ;; Arithmetic operators
   ;; (word forms: jama tafreeq zarb taqseem
   ;;  emit the SAME tokens as + - * / below)
   PLUS MINUS TIMES DIVIDE

   ;; Grouping & structure
   LPAREN RPAREN
   LBRACK RBRACK
   COMMA EOF))


;; ── 3. Character-class shorthands ─────────────────────────
(define-lex-abbrevs
  (digit   (:/ "09"))
  (letter  (:or (:/ "az") (:/ "AZ")))
  (id-char (:or letter digit (char-set "_"))))


;; ── 4. The lexer ──────────────────────────────────────────
(define roshni-lexer
  (lexer

   ;; ── Whitespace (skip silently) ────────────────────────
   ((:+ (:or " " "\t" "\n" "\r"))
    (roshni-lexer input-port))

   ;; ── Comments ─────────────────────────────────────────
   ;; tanqeed starts a comment; rest of line is ignored
   ;; e.g.  tanqeed yeh ek comment hai
   ((:seq "tanqeed" (:* (:~ "\n")))
    (roshni-lexer input-port))

   ;; ── Hyphenated compound keywords ─────────────────────
   ;; MUST appear before the simple keyword rules.
   ;; Longest-match guarantees "nai-barabar" (12 chars) beats
   ;; "nai" (3 chars) when the input contains the full word.
   ("warna-agar"         (token-WARNA_AGAR))   ;; else-if
   ("nai-barabar"        (token-NEQ))           ;; !=
   ("zyada-ya-barabar"   (token-GTE))           ;; >=
   ("kam-ya-barabar"     (token-LTE))           ;; <=

   ;; ── Keywords ─────────────────────────────────────────
   ("rakho"    (token-RAKHO))
   ("banao"    (token-BANAO))
   ("bulao"    (token-BULAO))
   ("dikhao"   (token-DIKHAO))
   ("jabtak"   (token-JABTAK))
   ("har"      (token-HAR))
   ("agar"     (token-AGAR))
   ("warna"    (token-WARNA))
   ("fehrist"  (token-FEHRIST))
   ("lo"       (token-LO))
   ("wapas"    (token-WAPAS))
   ("end"      (token-END))
   ("sahi"     (token-SAHI))
   ("ghalat"   (token-GHALAT))
   ("as"       (token-AS))

   ;; ── Logical operator keywords ─────────────────────────
   ("aur"      (token-AUR))
   ("ya"       (token-YA))
   ("nai"      (token-NAI_NOT))

   ;; String concatenation keyword
   ("jodna"    (token-JODNA))   ;; جوڑنا — joins any two values as strings   ;; unary NOT (not to be confused
                                  ;; with ghalat which is the value false)

   ;; ── Word arithmetic operators ─────────────────────────
   ;; These emit the SAME token as their symbol counterparts,
   ;; so  "3 jama 4"  and  "3 + 4"  are 100% identical to the parser.
   ("jama"     (token-PLUS))      ;; addition    جمع
   ("tafreeq"  (token-MINUS))     ;; subtraction تفریق
   ("zarb"     (token-TIMES))     ;; multiply    ضرب
   ("taqseem"  (token-DIVIDE))    ;; divide      تقسیم

   ;; ── Word comparison operators ─────────────────────────
   ;; Same idea — emit the same tokens as < > == !=
   ("barabar"  (token-EQ2))       ;; ==  برابر
   ("zyada"    (token-GT))        ;; >   زیادہ
   ("kam"      (token-LT))        ;; <   کم

   ;; ── Identifiers ──────────────────────────────────────
   ;; Must come AFTER all keyword rules; longest-match handles
   ;; the case where a keyword is a prefix of an identifier.
   ((:seq letter (:* id-char))
    (token-ID lexeme))

   ;; ── Number literals ───────────────────────────────────
   ;; Float rule must precede integer rule (longer match wins).
   ((:seq (:+ digit) "." (:+ digit))
    (token-FLOAT (string->number lexeme)))
   ((:+ digit)
    (token-NUMBER (string->number lexeme)))

   ;; ── String literals ───────────────────────────────────
   ((:seq "\"" (:* (:~ "\"")) "\"")
    (token-STRING (substring lexeme 1 (- (string-length lexeme) 1))))

   ;; ── Multi-character symbol operators ─────────────────
   ;; Must precede single-char rules so "->" beats "-" + ">".
   ("->"  (token-ARROW))
   ("=="  (token-EQ2))
   ("!="  (token-NEQ))
   ("<="  (token-LTE))
   (">="  (token-GTE))

   ;; ── Single-character symbol operators ────────────────
   ("<"   (token-LT))
   (">"   (token-GT))
   ("="   (token-EQ))
   ("+"   (token-PLUS))
   ("-"   (token-MINUS))
   ("*"   (token-TIMES))
   ("/"   (token-DIVIDE))
   ("("   (token-LPAREN))
   (")"   (token-RPAREN))
   ("["   (token-LBRACK))
   ("]"   (token-RBRACK))
   (","   (token-COMMA))

   ;; ── End of file ───────────────────────────────────────
   ((eof) (token-EOF))))

(provide roshni-lexer value-tokens punct-tokens)