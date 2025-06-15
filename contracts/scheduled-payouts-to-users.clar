(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_USER_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_CLAIMED (err u103))
(define-constant ERR_TOO_EARLY (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_POOL_EMPTY (err u106))
(define-constant ERR_USER_EXISTS (err u107))

(define-constant BLOCKS_PER_WEEK u1008)

(define-data-var total-pool uint u0)
(define-data-var current-week uint u0)
(define-data-var pool-start-block uint u0)
(define-data-var total-users uint u0)

(define-map users 
  { user: principal }
  { 
    share-percentage: uint,
    last-claimed-week: uint,
    total-claimed: uint,
    active: bool
  }
)

(define-map weekly-pools
  { week: uint }
  {
    total-amount: uint,
    distributed: uint,
    start-block: uint
  }
)

(define-map user-weekly-claims
  { user: principal, week: uint }
  { claimed: bool, amount: uint }
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)

(define-read-only (get-total-pool)
  (var-get total-pool)
)

(define-read-only (get-current-week)
  (var-get current-week)
)

(define-read-only (get-total-users)
  (var-get total-users)
)

(define-read-only (get-user-info (user principal))
  (map-get? users { user: user })
)

(define-read-only (get-weekly-pool (week uint))
  (map-get? weekly-pools { week: week })
)

(define-read-only (get-user-claim-status (user principal) (week uint))
  (map-get? user-weekly-claims { user: user, week: week })
)

(define-read-only (calculate-current-week)
  (let ((start-block (var-get pool-start-block)))
    (if (> start-block u0)
      (/ (- stacks-block-height start-block) BLOCKS_PER_WEEK)
      u0
    )
  )
)

(define-read-only (is-week-claimable (week uint))
  (>= (calculate-current-week) (+ week u1))
)

(define-read-only (calculate-user-payout (user principal) (week uint))
  (let (
    (user-data (unwrap! (map-get? users { user: user }) (err u0)))
    (weekly-data (unwrap! (map-get? weekly-pools { week: week }) (err u0)))
    (share-pct (get share-percentage user-data))
    (pool-amount (get total-amount weekly-data))
  )
    (ok (/ (* pool-amount share-pct) u100))
  )
)

(define-read-only (get-claimable-weeks (user principal))
  (let (
    (user-data (unwrap! (map-get? users { user: user }) (err u0)))
    (last-claimed (get last-claimed-week user-data))
    (current-week-calc (calculate-current-week))
  )
    (ok {
      last-claimed: last-claimed,
      current-claimable: (if (> current-week-calc u0) (- current-week-calc u1) u0),
      weeks-available: (if (> current-week-calc last-claimed) (- current-week-calc last-claimed u1) u0)
    })
  )
)

(define-public (initialize-pool)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (var-get pool-start-block) u0) (err u108))
    (var-set pool-start-block stacks-block-height)
    (var-set current-week u0)
    (ok true)
  )
)

(define-public (add-user (user principal) (share-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (> share-percentage u0) (<= share-percentage u100)) ERR_INVALID_AMOUNT)
    (asserts! (is-none (map-get? users { user: user })) ERR_USER_EXISTS)
    (map-set users 
      { user: user }
      {
        share-percentage: share-percentage,
        last-claimed-week: u0,
        total-claimed: u0,
        active: true
      }
    )
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

(define-public (update-user-share (user principal) (new-share-percentage uint))
  (let ((user-data (unwrap! (map-get? users { user: user }) ERR_USER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (> new-share-percentage u0) (<= new-share-percentage u100)) ERR_INVALID_AMOUNT)
    (map-set users 
      { user: user }
      (merge user-data { share-percentage: new-share-percentage })
    )
    (ok true)
  )
)

(define-public (deactivate-user (user principal))
  (let ((user-data (unwrap! (map-get? users { user: user }) ERR_USER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set users 
      { user: user }
      (merge user-data { active: false })
    )
    (ok true)
  )
)

(define-public (fund-weekly-pool (amount uint))
  (let ((current-week-calc (calculate-current-week)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> (var-get pool-start-block) u0) (err u109))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (let ((existing-pool (default-to 
      { total-amount: u0, distributed: u0, start-block: (+ (var-get pool-start-block) (* current-week-calc BLOCKS_PER_WEEK)) }
      (map-get? weekly-pools { week: current-week-calc })
    )))
      (map-set weekly-pools 
        { week: current-week-calc }
        (merge existing-pool { total-amount: (+ (get total-amount existing-pool) amount) })
      )
      (var-set total-pool (+ (var-get total-pool) amount))
      (var-set current-week current-week-calc)
      (ok true)
    )
  )
)

(define-public (claim-payout (week uint))
  (let (
    (user-data (unwrap! (map-get? users { user: tx-sender }) ERR_USER_NOT_FOUND))
    (weekly-data (unwrap! (map-get? weekly-pools { week: week }) ERR_POOL_EMPTY))
    (payout-amount (unwrap! (calculate-user-payout tx-sender week) ERR_INVALID_AMOUNT))
  )
    (asserts! (get active user-data) ERR_UNAUTHORIZED)
    (asserts! (is-week-claimable week) ERR_TOO_EARLY)
    (asserts! (is-none (map-get? user-weekly-claims { user: tx-sender, week: week })) ERR_ALREADY_CLAIMED)
    (asserts! (>= (get total-amount weekly-data) (+ (get distributed weekly-data) payout-amount)) ERR_INSUFFICIENT_BALANCE)
    (try! (as-contract (stx-transfer? payout-amount tx-sender tx-sender)))
    (map-set user-weekly-claims
      { user: tx-sender, week: week }
      { claimed: true, amount: payout-amount }
    )
    (map-set weekly-pools
      { week: week }
      (merge weekly-data { distributed: (+ (get distributed weekly-data) payout-amount) })
    )
    (map-set users
      { user: tx-sender }
      (merge user-data { 
        last-claimed-week: week,
        total-claimed: (+ (get total-claimed user-data) payout-amount)
      })
    )
    (ok payout-amount)
  )
)

(define-public (claim-multiple-weeks (weeks (list 10 uint)))
  (let ((results (map claim-payout weeks)))
    (ok results)
  )
)

(define-public (emergency-withdraw)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((balance (stx-get-balance (as-contract tx-sender))))
      (try! (as-contract (stx-transfer? balance tx-sender CONTRACT_OWNER)))
      (ok balance)
    )
  )
)