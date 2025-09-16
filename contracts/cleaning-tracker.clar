;; Sweepnet - Cleaning Tracker Contract
;; Purpose: Track cleaning activities, handle verification, and distribute rewards.
;; Note: No cross-contract calls or trait usage.

;; ------------------------------
;; Constants and Errors
;; ------------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-ALREADY-REGISTERED (err u201))
(define-constant ERR-NOT-REGISTERED (err u202))
(define-constant ERR-CLEANING-NOT-FOUND (err u203))
(define-constant ERR-ALREADY-VERIFIED (err u204))
(define-constant ERR-INVALID-PROOF (err u205))
(define-constant ERR-INSUFFICIENT-FUNDS (err u206))
(define-constant ERR-PAUSED (err u207))
(define-constant ERR-TOO-FREQUENT (err u208))
(define-constant ERR-REWARD-CLAIMED (err u209))
(define-constant ERR-INVALID-AMOUNT (err u210))

;; ------------------------------
;; Data Vars
;; ------------------------------
(define-data-var paused bool false)
(define-data-var next-cleaning-id uint u1)
(define-data-var base-reward uint u1000000) ;; 1 STX in micro-STX
(define-data-var total-cleaners uint u0)
(define-data-var total-cleanings uint u0)
(define-data-var min-verification-time uint u144) ;; ~24h in blocks

;; ------------------------------
;; Admin Permissions
;; ------------------------------
(define-map admins principal bool)

(define-read-only (is-admin (who principal))
  (or (is-eq who CONTRACT-OWNER)
      (default-to false (map-get? admins who)))
)

(define-public (add-admin (who principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-set admins who true)
    (ok true)
  )
)

(define-public (remove-admin (who principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-delete admins who)
    (ok true)
  )
)

(define-public (pause)
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set paused true)
    (ok true)
  )
)

(define-public (unpause)
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set paused false)
    (ok true)
  )
)

(define-public (set-base-reward (new-amount uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> new-amount u0) ERR-INVALID-AMOUNT)
    (var-set base-reward new-amount)
    (ok true)
  )
)

;; ------------------------------
;; Cleaner Profiles
;; ------------------------------
(define-map cleaners
  principal
  {
    registered-at: uint,
    total-cleanings: uint,
    total-earned: uint,
    reputation-score: uint, ;; 0-1000 scale
    active: bool,
    last-cleaning: uint
  }
)

(define-public (register-cleaner)
  (begin
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (asserts! (is-none (map-get? cleaners tx-sender)) ERR-ALREADY-REGISTERED)
    (map-set cleaners tx-sender {
      registered-at: burn-block-height,
      total-cleanings: u0,
      total-earned: u0,
      reputation-score: u100, ;; start with decent rep
      active: true,
      last-cleaning: u0
    })
    (var-set total-cleaners (+ (var-get total-cleaners) u1))
    (ok true)
  )
)

(define-public (toggle-cleaner-status)
  (let ((c (unwrap! (map-get? cleaners tx-sender) ERR-NOT-REGISTERED)))
    (map-set cleaners tx-sender (merge c { active: (not (get active c)) }))
    (ok (get active (unwrap! (map-get? cleaners tx-sender) ERR-NOT-REGISTERED)))
  )
)

;; ------------------------------
;; Cleaning Records
;; ------------------------------
(define-map cleaning-records
  uint
  {
    cleaner: principal,
    street-id: uint,
    street-name: (string-ascii 64),
    proof-hash: (buff 32), ;; SHA256 hash of evidence
    submitted-at: uint,
    verified-at: (optional uint),
    verified-by: (optional principal),
    verified: bool,
    reward-amount: uint,
    reward-claimed: bool,
    difficulty-multiplier: uint ;; u100 = 1.0x, u150 = 1.5x etc.
  }
)

;; Map cleaner -> street -> last cleaning time
(define-map cleaner-street-history
  { cleaner: principal, street-id: uint }
  uint
)

;; ------------------------------
;; Submit Cleaning Proof
;; ------------------------------
(define-public (submit-cleaning-proof
  (street-id uint)
  (street-name (string-ascii 64))
  (proof-hash (buff 32))
  (difficulty-multiplier uint)
)
  (let
    (
      (cleaner-profile (unwrap! (map-get? cleaners tx-sender) ERR-NOT-REGISTERED))
      (cleaning-id (var-get next-cleaning-id))
      (last-cleaning-key { cleaner: tx-sender, street-id: street-id })
      (last-cleaning-time (default-to u0 (map-get? cleaner-street-history last-cleaning-key)))
      (reward-amount (calculate-reward difficulty-multiplier (get reputation-score cleaner-profile)))
    )
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (asserts! (get active cleaner-profile) ERR-NOT-AUTHORIZED)
    ;; Prevent too frequent cleanings of same street
    (asserts! (> burn-block-height (+ last-cleaning-time u72)) ERR-TOO-FREQUENT)

    ;; Record cleaning
    (map-set cleaning-records cleaning-id {
      cleaner: tx-sender,
      street-id: street-id,
      street-name: street-name,
      proof-hash: proof-hash,
      submitted-at: burn-block-height,
      verified-at: none,
      verified-by: none,
      verified: false,
      reward-amount: reward-amount,
      reward-claimed: false,
      difficulty-multiplier: difficulty-multiplier
    })

    ;; Update cleaner history
    (map-set cleaner-street-history last-cleaning-key burn-block-height)

    ;; Update stats
    (var-set next-cleaning-id (+ cleaning-id u1))
    (var-set total-cleanings (+ (var-get total-cleanings) u1))

    (ok cleaning-id)
  )
)

;; ------------------------------
;; Verification
;; ------------------------------
(define-public (verify-cleaning (cleaning-id uint) (approve bool))
  (let ((record (unwrap! (map-get? cleaning-records cleaning-id) ERR-CLEANING-NOT-FOUND)))
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get verified record)) ERR-ALREADY-VERIFIED)

    (if approve
      ;; Approve cleaning
      (let
        (
          (cleaner-profile (unwrap! (map-get? cleaners (get cleaner record)) ERR-NOT-REGISTERED))
        )
        ;; Update cleaning record
        (map-set cleaning-records cleaning-id (merge record {
          verified-at: (some burn-block-height),
          verified-by: (some tx-sender),
          verified: true
        }))

        ;; Update cleaner stats
        (map-set cleaners (get cleaner record) (merge cleaner-profile {
          total-cleanings: (+ (get total-cleanings cleaner-profile) u1),
          last-cleaning: burn-block-height,
          reputation-score: (if (< (+ (get reputation-score cleaner-profile) u10) u1000)
                               (+ (get reputation-score cleaner-profile) u10)
                               u1000)
        }))

        (ok true)
      )
      ;; Reject cleaning
      (let
        (
          (cleaner-profile (unwrap! (map-get? cleaners (get cleaner record)) ERR-NOT-REGISTERED))
        )
        ;; Mark as verified but rejected (no reward)
        (map-set cleaning-records cleaning-id (merge record {
          verified-at: (some burn-block-height),
          verified-by: (some tx-sender),
          verified: true,
          reward-amount: u0
        }))

        ;; Slightly decrease reputation
        (map-set cleaners (get cleaner record) (merge cleaner-profile {
          reputation-score: (if (> (get reputation-score cleaner-profile) u5)
                               (- (get reputation-score cleaner-profile) u5)
                               u0)
        }))

        (ok false)
      )
    )
  )
)

;; ------------------------------
;; Reward Claiming
;; ------------------------------
(define-public (claim-reward (cleaning-id uint))
  (let ((record (unwrap! (map-get? cleaning-records cleaning-id) ERR-CLEANING-NOT-FOUND)))
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (asserts! (is-eq tx-sender (get cleaner record)) ERR-NOT-AUTHORIZED)
    (asserts! (get verified record) ERR-CLEANING-NOT-FOUND)
    (asserts! (not (get reward-claimed record)) ERR-REWARD-CLAIMED)
    (asserts! (> (get reward-amount record) u0) ERR-INVALID-AMOUNT)

    ;; Transfer reward
    (try! (as-contract (stx-transfer? (get reward-amount record) tx-sender (get cleaner record))))

    ;; Mark as claimed
    (map-set cleaning-records cleaning-id (merge record { reward-claimed: true }))

    ;; Update cleaner earnings
    (let ((cleaner-profile (unwrap! (map-get? cleaners (get cleaner record)) ERR-NOT-REGISTERED)))
      (map-set cleaners (get cleaner record) (merge cleaner-profile {
        total-earned: (+ (get total-earned cleaner-profile) (get reward-amount record))
      }))
    )

    (ok (get reward-amount record))
  )
)

;; ------------------------------
;; Helper Functions
;; ------------------------------
(define-private (calculate-reward (difficulty-mult uint) (reputation uint))
  (let
    (
      (base (var-get base-reward))
      (difficulty-bonus (/ (* base difficulty-mult) u100))
      (reputation-bonus (/ (* base reputation) u1000))
    )
    (+ difficulty-bonus reputation-bonus)
  )
)

;; Fund contract with STX for rewards
(define-public (fund-contract (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok amount)
  )
)

;; Emergency withdraw (admin only)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
    (ok amount)
  )
)

;; ------------------------------
;; Read-only Functions
;; ------------------------------
(define-read-only (get-cleaner-profile (cleaner principal))
  (map-get? cleaners cleaner)
)

(define-read-only (get-cleaning-record (id uint))
  (map-get? cleaning-records id)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-system-stats)
  {
    total-cleaners: (var-get total-cleaners),
    total-cleanings: (var-get total-cleanings),
    base-reward: (var-get base-reward),
    paused: (var-get paused),
    contract-balance: (get-contract-balance),
    next-cleaning-id: (var-get next-cleaning-id)
  }
)

(define-read-only (get-cleaner-street-last-cleaning (cleaner principal) (street-id uint))
  (map-get? cleaner-street-history { cleaner: cleaner, street-id: street-id })
)

(define-read-only (calculate-estimated-reward (difficulty-mult uint) (cleaner principal))
  (match (map-get? cleaners cleaner)
    profile (ok (calculate-reward difficulty-mult (get reputation-score profile)))
    ERR-NOT-REGISTERED
  )
)


