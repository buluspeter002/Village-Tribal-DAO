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
(define-constant ERR_INVALID_ACTIVITY (err u200))
(define-constant ERR_STREAK_RESET (err u201))

(define-constant ERR_SKILL_NOT_FOUND (err u300))
(define-constant ERR_CANNOT_VERIFY_OWN_SKILL (err u301))
(define-constant ERR_ALREADY_VERIFIED (err u302))
(define-constant ERR_VERIFICATION_STAKE_TOO_LOW (err u303))

(define-data-var skill-counter uint u0)
(define-data-var min-verification-stake uint u100000)

(define-data-var season-counter uint u1)
(define-data-var season-blocks uint u1008)

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


(define-map member-activity
  principal
  {
    total-votes: uint,
    total-proposals: uint,
    voting-streak: uint,
    last-vote-block: uint,
    reputation-score: uint,
    season-votes: uint,
    season-proposals: uint
  }
)

(define-map season-leaderboard
  { season: uint, rank: uint }
  { member: principal, score: uint }
)

(define-public (track-vote-activity (member principal))
  (let (
    (current-activity (default-to 
      { total-votes: u0, total-proposals: u0, voting-streak: u0, 
        last-vote-block: u0, reputation-score: u0, season-votes: u0, season-proposals: u0 }
      (map-get? member-activity member)
    ))
    (blocks-since-last (- stacks-block-height (get last-vote-block current-activity)))
    (streak-broken (> blocks-since-last u1008))
    (new-streak (if streak-broken u1 (+ (get voting-streak current-activity) u1)))
  )
    (asserts! (is-some (map-get? members member)) ERR_NOT_MEMBER)
    (map-set member-activity member {
      total-votes: (+ (get total-votes current-activity) u1),
      total-proposals: (get total-proposals current-activity),
      voting-streak: new-streak,
      last-vote-block: stacks-block-height,
      reputation-score: (calculate-reputation-score member),
      season-votes: (+ (get season-votes current-activity) u1),
      season-proposals: (get season-proposals current-activity)
    })
    (ok true)
  )
)

(define-public (track-proposal-activity (member principal))
  (let (
    (current-activity (default-to 
      { total-votes: u0, total-proposals: u0, voting-streak: u0, 
        last-vote-block: u0, reputation-score: u0, season-votes: u0, season-proposals: u0 }
      (map-get? member-activity member)
    ))
  )
    (asserts! (is-some (map-get? members member)) ERR_NOT_MEMBER)
    (map-set member-activity member {
      total-votes: (get total-votes current-activity),
      total-proposals: (+ (get total-proposals current-activity) u1),
      voting-streak: (get voting-streak current-activity),
      last-vote-block: (get last-vote-block current-activity),
      reputation-score: (calculate-reputation-score member),
      season-votes: (get season-votes current-activity),
      season-proposals: (+ (get season-proposals current-activity) u1)
    })
    (ok true)
  )
)

(define-private (calculate-reputation-score (member principal))
  (let (
    (activity (default-to 
      { total-votes: u0, total-proposals: u0, voting-streak: u0, 
        last-vote-block: u0, reputation-score: u0, season-votes: u0, season-proposals: u0 }
      (map-get? member-activity member)
    ))
    (base-score (+ (* (get total-votes activity) u10) (* (get total-proposals activity) u25)))
    (streak-bonus (* (get voting-streak activity) u5))
  )
    (+ base-score streak-bonus)
  )
)

(define-read-only (get-member-activity (member principal))
  (map-get? member-activity member)
)

(define-read-only (get-member-reputation (member principal))
  (match (map-get? member-activity member)
    activity (some (get reputation-score activity))
    none
  )
)

(define-read-only (get-top-contributors (limit uint))
  (let ((current-season (var-get season-counter)))
    (map get-leaderboard-entry (list u1 u2 u3 u4 u5))
  )
)

(define-private (get-leaderboard-entry (rank uint))
  (map-get? season-leaderboard { season: (var-get season-counter), rank: rank })
)


(define-map member-skills
  { member: principal, skill-id: uint }
  { skill-name: (string-ascii 50), experience-level: uint, verified: bool }
)

(define-map skill-verifications
  { skill-owner: principal, skill-id: uint, verifier: principal }
  { stake-amount: uint, verification-block: uint }
)

(define-map skills-index
  uint
  { skill-name: (string-ascii 50), creator: principal, total-verifications: uint }
)

(define-public (declare-skill (skill-name (string-ascii 50)) (experience-level uint))
  (let ((skill-id (+ (var-get skill-counter) u1)))
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (asserts! (<= experience-level u10) (err u304))
    (map-set member-skills 
      { member: tx-sender, skill-id: skill-id }
      { skill-name: skill-name, experience-level: experience-level, verified: false }
    )
    (map-set skills-index skill-id 
      { skill-name: skill-name, creator: tx-sender, total-verifications: u0 }
    )
    (var-set skill-counter skill-id)
    (ok skill-id)
  )
)

(define-public (verify-member-skill (skill-owner principal) (skill-id uint) (stake-amount uint))
  (let (
    (skill-key { member: skill-owner, skill-id: skill-id })
    (verification-key { skill-owner: skill-owner, skill-id: skill-id, verifier: tx-sender })
    (skill (unwrap! (map-get? member-skills skill-key) ERR_SKILL_NOT_FOUND))
  )
    (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
    (asserts! (not (is-eq tx-sender skill-owner)) ERR_CANNOT_VERIFY_OWN_SKILL)
    (asserts! (is-none (map-get? skill-verifications verification-key)) ERR_ALREADY_VERIFIED)
    (asserts! (>= stake-amount (var-get min-verification-stake)) ERR_VERIFICATION_STAKE_TOO_LOW)
    
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    (map-set skill-verifications verification-key
      { stake-amount: stake-amount, verification-block: stacks-block-height }
    )
    
    (let ((skill-index (unwrap! (map-get? skills-index skill-id) ERR_SKILL_NOT_FOUND)))
      (map-set skills-index skill-id
        (merge skill-index { total-verifications: (+ (get total-verifications skill-index) u1) })
      )
    )
    
    (if (>= (get total-verifications (unwrap! (map-get? skills-index skill-id) ERR_SKILL_NOT_FOUND)) u3)
      (map-set member-skills skill-key (merge skill { verified: true }))
      true
    )
    (ok true)
  )
)

(define-read-only (get-member-skills (member principal))
  (map-get? member-skills { member: member, skill-id: u1 })
)

(define-read-only (find-skilled-members (skill-name (string-ascii 50)))
  (map-get? skills-index u1)
)

(define-read-only (get-skill-verification-count (skill-owner principal) (skill-id uint))
  (match (map-get? skills-index skill-id)
    skill-info (some (get total-verifications skill-info))
    none
  )
)