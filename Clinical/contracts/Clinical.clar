;; Smart Contract: Medical Research Grant Smart Contract  
;; Description: A decentralised research funding contract on Stacks. The lead researcher sets a grant amount and timeline, stakeholders fund the study, and trial phases are approved only if reviewers vote positively. If the grant isn't fully funded, stakeholders can claim refunds.

;; Constants
(define-constant ERR_NOT_LEAD_RESEARCHER (err u100))
(define-constant ERR_STUDY_ALREADY_INITIATED (err u101))
(define-constant ERR_REVIEWER_NOT_FOUND (err u102))
(define-constant ERR_STUDY_PERIOD_ENDED (err u103))
(define-constant ERR_GRANT_TARGET_UNMET (err u104))
(define-constant ERR_INSUFFICIENT_GRANT_FUNDS (err u105))
(define-constant ERR_INVALID_FUNDING_AMOUNT (err u106))
(define-constant ERR_INVALID_STUDY_PERIOD (err u107))

;; Data Variables
(define-data-var lead-researcher (optional principal) none)
(define-data-var grant-target uint u0)
(define-data-var funds-allocated uint u0)
(define-data-var current-trial uint u0)
(define-data-var positive-reviews uint u0)
(define-data-var negative-reviews uint u0)
(define-data-var total-reviewers uint u0)
(define-data-var study-end-block uint u0)
(define-data-var research-status (string-ascii 20) "not_started")

;; Maps
(define-map reviewer-contributions principal uint)
(define-map trial-phases uint {protocol: (string-utf8 256), budget: uint})

;; Private Functions
(define-private (is-lead-researcher)
  (is-eq (some tx-sender) (var-get lead-researcher))
)

(define-private (is-study-active)
  (and
    (is-eq (var-get research-status) "recruiting")
    (<= stacks-block-height (var-get study-end-block))
  )
)

;; Public Functions
(define-public (initiate-research-study (grant-amount uint) (study-period uint))
  (begin
    (asserts! (is-none (var-get lead-researcher)) ERR_STUDY_ALREADY_INITIATED)
    (asserts! (> grant-amount u0) ERR_INVALID_FUNDING_AMOUNT)
    (asserts! (and (> study-period u0) (<= study-period u52560)) ERR_INVALID_STUDY_PERIOD)
    (var-set lead-researcher (some tx-sender))
    (var-set grant-target grant-amount)
    (var-set study-end-block (+ stacks-block-height study-period))
    (var-set research-status "recruiting")
    (ok true)
  )
)

(define-public (fund-research (amount uint))
  (let (
    (current-funding (default-to u0 (map-get? reviewer-contributions tx-sender)))
  )
    (asserts! (is-study-active) ERR_STUDY_PERIOD_ENDED)
    (asserts! (> amount u0) ERR_INVALID_FUNDING_AMOUNT)
    (asserts! (<= (+ (var-get funds-allocated) amount) (var-get grant-target)) ERR_GRANT_TARGET_UNMET)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set funds-allocated (+ (var-get funds-allocated) amount))
    (map-set reviewer-contributions tx-sender (+ current-funding amount))
    (if (is-eq current-funding u0)
      (var-set total-reviewers (+ (var-get total-reviewers) u1))
      true
    )
    (ok true)
  )
)

(define-public (review-trial-phase (approve bool))
  (let ((funding (default-to u0 (map-get? reviewer-contributions tx-sender))))
    (asserts! (> funding u0) ERR_REVIEWER_NOT_FOUND)
    (asserts! (is-eq (var-get research-status) "peer_review") ERR_NOT_LEAD_RESEARCHER)
    (if approve
      (var-set positive-reviews (+ (var-get positive-reviews) funding))
      (var-set negative-reviews (+ (var-get negative-reviews) funding))
    )
    (ok true)
  )
)

(define-public (start-peer-review)
  (begin
    (asserts! (is-lead-researcher) ERR_NOT_LEAD_RESEARCHER)
    (asserts! (is-eq (var-get research-status) "recruiting") ERR_NOT_LEAD_RESEARCHER)
    (var-set research-status "peer_review")
    (var-set positive-reviews u0)
    (var-set negative-reviews u0)
    (ok true)
  )
)

(define-public (conclude-peer-review)
  (begin
    (asserts! (is-lead-researcher) ERR_NOT_LEAD_RESEARCHER)
    (asserts! (is-eq (var-get research-status) "peer_review") ERR_NOT_LEAD_RESEARCHER)
    (let ((total-reviews (+ (var-get positive-reviews) (var-get negative-reviews))))
      (asserts! (> total-reviews u0) ERR_REVIEWER_NOT_FOUND)
      (if (> (var-get positive-reviews) (var-get negative-reviews))
        (begin
          (var-set current-trial (+ (var-get current-trial) u1))
          (var-set research-status "recruiting")
          (ok true)
        )
        (begin
          (var-set research-status "recruiting")
          (err u408)  ;; ERR_TRIAL_REJECTED
        )
      )
    )
  )
)

(define-public (define-trial-phase (protocol (string-utf8 256)) (budget uint))
  (begin
    (asserts! (is-lead-researcher) ERR_NOT_LEAD_RESEARCHER)
    (asserts! (> budget u0) ERR_INVALID_FUNDING_AMOUNT)
    (asserts! (<= (len protocol) u256) (err u409))  ;; ERR_INVALID_PROTOCOL
    (map-set trial-phases (var-get current-trial) {protocol: protocol, budget: budget})
    (ok true)
  )
)

(define-public (disburse-grant-funds (amount uint))
  (begin
    (asserts! (is-lead-researcher) ERR_NOT_LEAD_RESEARCHER)
    (asserts! (> amount u0) ERR_INVALID_FUNDING_AMOUNT)
    (asserts! (<= amount (var-get funds-allocated)) ERR_INSUFFICIENT_GRANT_FUNDS)
    (as-contract (stx-transfer? amount tx-sender (unwrap! (var-get lead-researcher) ERR_REVIEWER_NOT_FOUND)))
  )
)

(define-public (claim-research-refund)
  (let ((funding (default-to u0 (map-get? reviewer-contributions tx-sender))))
    (asserts! (and
      (> stacks-block-height (var-get study-end-block))
      (< (var-get funds-allocated) (var-get grant-target))
    ) ERR_NOT_LEAD_RESEARCHER)
    (asserts! (> funding u0) ERR_REVIEWER_NOT_FOUND)
    (map-delete reviewer-contributions tx-sender)
    (as-contract (stx-transfer? funding tx-sender tx-sender))
  )
)

;; Read-only Functions
(define-read-only (get-research-overview)
  (ok {
    researcher: (var-get lead-researcher),
    target: (var-get grant-target),
    allocated: (var-get funds-allocated),
    end-block: (var-get study-end-block),
    status: (var-get research-status),
    current-trial: (var-get current-trial)
  })
)

(define-read-only (get-reviewer-contribution (reviewer principal))
  (ok (default-to u0 (map-get? reviewer-contributions reviewer)))
)

(define-read-only (get-trial-details (trial-id uint))
  (map-get? trial-phases trial-id)
)
