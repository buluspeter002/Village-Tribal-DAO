(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_VOTING_ACTIVE (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_NOT_MEMBER (err u106))
(define-constant ERR_ALREADY_MEMBER (err u107))
(define-constant ERR_PROPOSAL_NOT_PASSED (err u108))

(define-data-var proposal-counter uint u0)
(define-data-var village-treasury uint u0)

(define-map members principal bool)
(define-map member-voting-power principal uint)

(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    amount: uint,
    recipient: principal,
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    voting-end-block: uint,
    executed: bool,
    proposal-type: (string-ascii 20)
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint }
)

(define-public (join-village)
  (begin
    (asserts! (is-none (map-get? members tx-sender)) ERR_ALREADY_MEMBER)
    (map-set members tx-sender true)
    (map-set member-voting-power tx-sender u1)
    (ok true)
  )
)

(define-public (contribute-to-treasury (amount uint))
  (begin
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set village-treasury (+ (var-get village-treasury) amount))
    (let ((current-power (default-to u1 (map-get? member-voting-power tx-sender))))
      (map-set member-voting-power tx-sender (+ current-power u1))
    )
    (ok true)
  )
)

(define-public (create-proposal 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (amount uint)
  (recipient principal)
  (proposal-type (string-ascii 20))
)
  (let ((proposal-id (+ (var-get proposal-counter) u1)))
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (map-set proposals proposal-id {
      title: title,
      description: description,
      amount: amount,
      recipient: recipient,
      proposer: tx-sender,
      votes-for: u0,
      votes-against: u0,
      voting-end-block: (+ stacks-block-height u144),
      executed: false,
      proposal-type: proposal-type
    })
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (voter-power (default-to u1 (map-get? member-voting-power tx-sender)))
    (vote-key { proposal-id: proposal-id, voter: tx-sender })
  )
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (asserts! (is-none (map-get? votes vote-key)) ERR_ALREADY_VOTED)
    (asserts! (< stacks-block-height (get voting-end-block proposal)) ERR_VOTING_ENDED)
    
    (map-set votes vote-key { vote: vote-for, voting-power: voter-power })
    
    (if vote-for
      (map-set proposals proposal-id 
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-power) }))
      (map-set proposals proposal-id 
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-power) }))
    )
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (>= stacks-block-height (get voting-end-block proposal)) ERR_VOTING_ACTIVE)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_NOT_PASSED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_PROPOSAL_NOT_PASSED)
    
    (if (is-eq (get proposal-type proposal) "budget")
      (begin
        (asserts! (>= (var-get village-treasury) (get amount proposal)) ERR_INSUFFICIENT_FUNDS)
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        (var-set village-treasury (- (var-get village-treasury) (get amount proposal)))
      )
      true
    )
    
    (map-set proposals proposal-id (merge proposal { executed: true }))
    (ok true)
  )
)

(define-public (delegate-voting-power (delegate principal) (amount uint))
  (let ((current-power (default-to u1 (map-get? member-voting-power tx-sender))))
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (asserts! (is-some (map-get? members delegate)) ERR_NOT_MEMBER)
    (asserts! (>= current-power amount) ERR_INSUFFICIENT_FUNDS)
    
    (map-set member-voting-power tx-sender (- current-power amount))
    (let ((delegate-power (default-to u1 (map-get? member-voting-power delegate))))
      (map-set member-voting-power delegate (+ delegate-power amount))
    )
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-member-info (member principal))
  {
    is-member: (default-to false (map-get? members member)),
    voting-power: (default-to u0 (map-get? member-voting-power member))
  }
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-treasury-balance)
  (var-get village-treasury)
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (get-proposal-status (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (let (
      (voting-ended (>= stacks-block-height (get voting-end-block proposal)))
      (passed (> (get votes-for proposal) (get votes-against proposal)))
    )
      (some {
        voting-ended: voting-ended,
        passed: passed,
        executed: (get executed proposal),
        votes-for: (get votes-for proposal),
        votes-against: (get votes-against proposal)
      })
    )
    none
  )
)

(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ok true)
  )
)

(define-public (update-member-status (member principal) (status bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set members member status)
    (ok true)
  )
)
