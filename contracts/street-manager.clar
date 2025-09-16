;; Sweepnet - Street Manager Contract
;; Purpose: Manage street segments, schedules, and admin controls.
;; Note: No cross-contract calls or trait usage.

;; ------------------------------
;; Constants and Errors
;; ------------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-STREET-EXISTS (err u101))
(define-constant ERR-STREET-NOT-FOUND (err u102))
(define-constant ERR-INVALID-NAME (err u103))
(define-constant ERR-INVALID-COORDS (err u104))
(define-constant ERR-INVALID-FREQUENCY (err u105))
(define-constant ERR-PAUSED (err u106))
(define-constant ERR-NO-UPDATE (err u107))

;; ------------------------------
;; Data Vars
;; ------------------------------
(define-data-var paused bool false)
(define-data-var next-street-id uint u1)
(define-data-var total-streets uint u0)
(define-data-var admin-count uint u1) ;; includes owner by default

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
    (var-set admin-count (+ (var-get admin-count) u1))
    (ok true)
  )
)

(define-public (remove-admin (who principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-delete admins who)
    (var-set admin-count (if (> (var-get admin-count) u0)
                             (- (var-get admin-count) u1)
                             u0))
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

(define-read-only (is-paused)
  (var-get paused)
)

;; ------------------------------
;; Street Data
;; ------------------------------
;; Coordinates in micro-degrees (int), e.g. 37.7749 => 37774900
(define-map streets
  uint
  {
    name: (string-ascii 64),
    latitude: int,
    longitude: int,
    difficulty: uint,        ;; u1 (easy) .. u10 (hard)
    required-frequency: uint,;; cleanings per 30-day epoch
    active: bool,
    created-at: uint,
    updated-at: uint,
    total-cleanings: uint
  }
)

(define-map street-names (string-ascii 64) uint)

;; ------------------------------
;; Helpers
;; ------------------------------
(define-private (validate-coords (lat int) (lon int))
  (ok (and (and (>= lat -90000000) (<= lat 90000000))
           (and (>= lon -180000000) (<= lon 180000000))))
)

(define-private (validate-name (nm (string-ascii 64)))
  (let ((l (len nm)))
    (ok (and (> l u0) (<= l u64)))
  )
)

(define-private (validate-frequency (freq uint))
  (ok (and (> freq u0) (<= freq u60)))
)

;; ------------------------------
;; Public Street Management
;; ------------------------------
(define-public (register-street
  (name (string-ascii 64))
  (latitude int)
  (longitude int)
  (difficulty uint)
  (required-frequency uint)
)
  (let
    (
      (pid (var-get next-street-id))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (asserts! (unwrap! (validate-name name) ERR-INVALID-NAME) ERR-INVALID-NAME)
    (asserts! (unwrap! (validate-coords latitude longitude) ERR-INVALID-COORDS) ERR-INVALID-COORDS)
    (asserts! (unwrap! (validate-frequency required-frequency) ERR-INVALID-FREQUENCY) ERR-INVALID-FREQUENCY)
    (asserts! (is-none (map-get? street-names name)) ERR-STREET-EXISTS)

    (map-set streets pid {
      name: name,
      latitude: latitude,
      longitude: longitude,
      difficulty: (if (> difficulty u0) difficulty u1),
      required-frequency: required-frequency,
      active: true,
      created-at: burn-block-height,
      updated-at: burn-block-height,
      total-cleanings: u0
    })

    (map-set street-names name pid)
    (var-set next-street-id (+ pid u1))
    (var-set total-streets (+ (var-get total-streets) u1))
    (ok pid)
  )
)

(define-public (update-street
  (id uint)
  (new-name (optional (string-ascii 64)))
  (new-lat (optional int))
  (new-lon (optional int))
  (new-difficulty (optional uint))
  (new-frequency (optional uint))
)
  (let ((s (unwrap! (map-get? streets id) ERR-STREET-NOT-FOUND)))
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get paused)) ERR-PAUSED)

    (let
      (
        (nm (match new-name n (begin (asserts! (unwrap! (validate-name n) ERR-INVALID-NAME) ERR-INVALID-NAME) n) (get name s)))
        (lt (match new-lat v (begin (asserts! (unwrap! (validate-coords v (get longitude s)) ERR-INVALID-COORDS) ERR-INVALID-COORDS) v) (get latitude s)))
        (ln (match new-lon v (begin (asserts! (unwrap! (validate-coords (get latitude s) v) ERR-INVALID-COORDS) ERR-INVALID-COORDS) v) (get longitude s)))
        (df (match new-difficulty v (if (> v u0) v u1) (get difficulty s)))
        (rf (match new-frequency v (begin (asserts! (unwrap! (validate-frequency v) ERR-INVALID-FREQUENCY) ERR-INVALID-FREQUENCY) v) (get required-frequency s)))
      )
      (map-set streets id {
        name: nm,
        latitude: lt,
        longitude: ln,
        difficulty: df,
        required-frequency: rf,
        active: (get active s),
        created-at: (get created-at s),
        updated-at: burn-block-height,
        total-cleanings: (get total-cleanings s)
      })
      (ok true)
    )
  )
)

(define-public (toggle-street (id uint))
  (let ((s (unwrap! (map-get? streets id) ERR-STREET-NOT-FOUND)))
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (map-set streets id (merge s { active: (not (get active s)), updated-at: burn-block-height }))
    (ok (get active (unwrap! (map-get? streets id) ERR-STREET-NOT-FOUND)))
  )
)

;; Incremental cleaning counter for reporting; not tied to rewards here
(define-public (record-cleaning (id uint))
  (let ((s (unwrap! (map-get? streets id) ERR-STREET-NOT-FOUND)))
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (map-set streets id (merge s {
      total-cleanings: (+ (get total-cleanings s) u1),
      updated-at: burn-block-height
    }))
    (ok true)
  )
)

;; ------------------------------
;; Read-only
;; ------------------------------
(define-read-only (get-street (id uint))
  (map-get? streets id)
)

(define-read-only (get-street-id-by-name (name (string-ascii 64)))
  (map-get? street-names name)
)

(define-read-only (list-stats)
  {
    total-streets: (var-get total-streets),
    next-id: (var-get next-street-id),
    paused: (var-get paused),
    admin-count: (var-get admin-count)
  }
)

(define-read-only (preview-updated-street
  (id uint)
  (new-name (optional (string-ascii 64)))
  (new-lat (optional int))
  (new-lon (optional int))
  (new-difficulty (optional uint))
  (new-frequency (optional uint))
)
  (let ((s (unwrap! (map-get? streets id) ERR-STREET-NOT-FOUND)))
    (ok {
      name: (match new-name n n (get name s)),
      latitude: (match new-lat v v (get latitude s)),
      longitude: (match new-lon v v (get longitude s)),
      difficulty: (match new-difficulty v (if (> v u0) v u1) (get difficulty s)),
      required-frequency: (match new-frequency v v (get required-frequency s)),
      active: (get active s)
    })
  )
)


