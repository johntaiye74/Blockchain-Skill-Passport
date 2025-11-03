(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_SKILL_NOT_FOUND (err u101))
(define-constant ERR_ISSUER_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_INPUT (err u104))

(define-map skill-passports
  { user: principal }
  {
    total-skills: uint,
    created-at: uint,
    updated-at: uint
  }
)

(define-map skills
  { user: principal, skill-id: uint }
  {
    skill-name: (string-ascii 100),
    category: (string-ascii 50),
    level: (string-ascii 20),
    issuer: principal,
    issuer-name: (string-ascii 100),
    issued-at: uint,
    verified: bool,
    description: (string-ascii 500)
  }
)

(define-map verified-issuers
  { issuer: principal }
  {
    name: (string-ascii 100),
    issuer-type: (string-ascii 50),
    verified-at: uint,
    active: bool
  }
)

(define-map user-skill-counter
  { user: principal }
  { counter: uint }
)

(define-data-var next-skill-id uint u1)

(define-public (register-issuer (name (string-ascii 100)) (issuer-type (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len issuer-type) u0) ERR_INVALID_INPUT)
    (ok (map-set verified-issuers
      { issuer: tx-sender }
      {
        name: name,
        issuer-type: issuer-type,
        verified-at: stacks-block-height,
        active: true
      }
    ))
  )
)

(define-public (add-verified-issuer (issuer principal) (name (string-ascii 100)) (issuer-type (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len issuer-type) u0) ERR_INVALID_INPUT)
    (ok (map-set verified-issuers
      { issuer: issuer }
      {
        name: name,
        issuer-type: issuer-type,
        verified-at: stacks-block-height,
        active: true
      }
    ))
  )
)

(define-public (create-passport)
  (let ((existing-passport (map-get? skill-passports { user: tx-sender })))
    (asserts! (is-none existing-passport) ERR_ALREADY_EXISTS)
    (ok (map-set skill-passports
      { user: tx-sender }
      {
        total-skills: u0,
        created-at: stacks-block-height,
        updated-at: stacks-block-height
      }
    ))
  )
)

(define-public (issue-skill 
  (recipient principal)
  (skill-name (string-ascii 100))
  (category (string-ascii 50))
  (level (string-ascii 20))
  (description (string-ascii 500))
)
  (let (
    (issuer-info (map-get? verified-issuers { issuer: tx-sender }))
    (current-counter (default-to u0 (get counter (map-get? user-skill-counter { user: recipient }))))
    (skill-id (+ current-counter u1))
    (passport (map-get? skill-passports { user: recipient }))
  )
    (asserts! (is-some issuer-info) ERR_ISSUER_NOT_FOUND)
    (asserts! (get active (unwrap-panic issuer-info)) ERR_UNAUTHORIZED)
    (asserts! (> (len skill-name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len category) u0) ERR_INVALID_INPUT)
    (asserts! (> (len level) u0) ERR_INVALID_INPUT)
    
    (if (is-none passport)
      (map-set skill-passports
        { user: recipient }
        {
          total-skills: u1,
          created-at: stacks-block-height,
          updated-at: stacks-block-height
        }
      )
      (map-set skill-passports
        { user: recipient }
        {
          total-skills: (+ (get total-skills (unwrap-panic passport)) u1),
          created-at: (get created-at (unwrap-panic passport)),
          updated-at: stacks-block-height
        }
      )
    )
    
    (map-set user-skill-counter
      { user: recipient }
      { counter: skill-id }
    )
    
    (ok (map-set skills
      { user: recipient, skill-id: skill-id }
      {
        skill-name: skill-name,
        category: category,
        level: level,
        issuer: tx-sender,
        issuer-name: (get name (unwrap-panic issuer-info)),
        issued-at: stacks-block-height,
        verified: true,
        description: description
      }
    ))
  )
)

(define-public (self-report-skill
  (skill-name (string-ascii 100))
  (category (string-ascii 50))
  (level (string-ascii 20))
  (description (string-ascii 500))
)
  (let (
    (current-counter (default-to u0 (get counter (map-get? user-skill-counter { user: tx-sender }))))
    (skill-id (+ current-counter u1))
    (passport (map-get? skill-passports { user: tx-sender }))
  )
    (asserts! (> (len skill-name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len category) u0) ERR_INVALID_INPUT)
    (asserts! (> (len level) u0) ERR_INVALID_INPUT)
    
    (if (is-none passport)
      (map-set skill-passports
        { user: tx-sender }
        {
          total-skills: u1,
          created-at: stacks-block-height,
          updated-at: stacks-block-height
        }
      )
      (map-set skill-passports
        { user: tx-sender }
        {
          total-skills: (+ (get total-skills (unwrap-panic passport)) u1),
          created-at: (get created-at (unwrap-panic passport)),
          updated-at: stacks-block-height
        }
      )
    )
    
    (map-set user-skill-counter
      { user: tx-sender }
      { counter: skill-id }
    )
    
    (ok (map-set skills
      { user: tx-sender, skill-id: skill-id }
      {
        skill-name: skill-name,
        category: category,
        level: level,
        issuer: tx-sender,
        issuer-name: "Self-Reported",
        issued-at: stacks-block-height,
        verified: false,
        description: description
      }
    ))
  )
)

(define-read-only (get-passport (user principal))
  (map-get? skill-passports { user: user })
)

(define-read-only (get-skill (user principal) (skill-id uint))
  (map-get? skills { user: user, skill-id: skill-id })
)

(define-read-only (get-issuer-info (issuer principal))
  (map-get? verified-issuers { issuer: issuer })
)

(define-read-only (get-user-skill-count (user principal))
  (default-to u0 (get counter (map-get? user-skill-counter { user: user })))
)

(define-read-only (is-verified-issuer (issuer principal))
  (match (map-get? verified-issuers { issuer: issuer })
    issuer-data (get active issuer-data)
    false
  )
)

(define-read-only (get-skill-by-category (user principal) (skill-id uint) (target-category (string-ascii 50)))
  (match (map-get? skills { user: user, skill-id: skill-id })
    skill-data 
      (if (is-eq (get category skill-data) target-category)
        (some skill-data)
        none
      )
    none
  )
)

(define-read-only (count-verified-skills (user principal))
  (let ((skill-count (get-user-skill-count user)))
    (fold count-verified-skills-iter (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) { user: user, count: u0 })
  )
)

(define-private (count-verified-skills-iter (skill-id uint) (data { user: principal, count: uint }))
  (match (map-get? skills { user: (get user data), skill-id: skill-id })
    skill-data
      (if (get verified skill-data)
        { user: (get user data), count: (+ (get count data) u1) }
        data
      )
    data
  )
)

(define-map skill-endorsements
  { user: principal, skill-id: uint, endorser: principal }
  {
    endorsed-at: uint,
    endorser-reputation: uint
  }
)

(define-map endorsement-counts
  { user: principal, skill-id: uint }
  { count: uint }
)

(define-map user-endorsement-given
  { endorser: principal, target-user: principal, skill-id: uint }
  { endorsed: bool }
)

(define-public (endorse-skill (target-user principal) (skill-id uint))
  (let (
    (skill-data (map-get? skills { user: target-user, skill-id: skill-id }))
    (existing-endorsement (map-get? user-endorsement-given { endorser: tx-sender, target-user: target-user, skill-id: skill-id }))
    (current-count (default-to u0 (get count (map-get? endorsement-counts { user: target-user, skill-id: skill-id }))))
    (endorser-reputation (get-user-skill-count tx-sender))
  )
    (asserts! (is-some skill-data) ERR_SKILL_NOT_FOUND)
    (asserts! (not (is-eq tx-sender target-user)) ERR_INVALID_INPUT)
    (asserts! (is-none existing-endorsement) ERR_ALREADY_EXISTS)
    
    (map-set skill-endorsements
      { user: target-user, skill-id: skill-id, endorser: tx-sender }
      {
        endorsed-at: stacks-block-height,
        endorser-reputation: endorser-reputation
      }
    )
    
    (map-set endorsement-counts
      { user: target-user, skill-id: skill-id }
      { count: (+ current-count u1) }
    )
    
    (ok (map-set user-endorsement-given
      { endorser: tx-sender, target-user: target-user, skill-id: skill-id }
      { endorsed: true }
    ))
  )
)

(define-read-only (get-skill-endorsement-count (user principal) (skill-id uint))
  (default-to u0 (get count (map-get? endorsement-counts { user: user, skill-id: skill-id })))
)

(define-read-only (has-endorsed-skill (endorser principal) (target-user principal) (skill-id uint))
  (is-some (map-get? user-endorsement-given { endorser: endorser, target-user: target-user, skill-id: skill-id }))
)

(define-read-only (get-endorsement-details (user principal) (skill-id uint) (endorser principal))
  (map-get? skill-endorsements { user: user, skill-id: skill-id, endorser: endorser })
)

(define-constant DEFAULT_SKILL_VALIDITY u144000)

(define-map skill-expiry
  { user: principal, skill-id: uint }
  {
    expires-at: uint,
    renewable: bool,
    renewal-count: uint
  }
)

(define-map expired-skills
  { user: principal }
  { count: uint }
)

(define-public (set-skill-expiry (target-user principal) (skill-id uint) (validity-blocks uint))
  (let (
    (skill-data (map-get? skills { user: target-user, skill-id: skill-id }))
    (issuer-info (map-get? verified-issuers { issuer: tx-sender }))
  )
    (asserts! (is-some skill-data) ERR_SKILL_NOT_FOUND)
    (asserts! (is-some issuer-info) ERR_ISSUER_NOT_FOUND)
    (asserts! (get active (unwrap-panic issuer-info)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get issuer (unwrap-panic skill-data)) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (> validity-blocks u0) ERR_INVALID_INPUT)
    
    (ok (map-set skill-expiry
      { user: target-user, skill-id: skill-id }
      {
        expires-at: (+ stacks-block-height validity-blocks),
        renewable: true,
        renewal-count: u0
      }
    ))
  )
)

(define-public (renew-skill (target-user principal) (skill-id uint) (additional-validity uint))
  (let (
    (skill-data (map-get? skills { user: target-user, skill-id: skill-id }))
    (expiry-data (map-get? skill-expiry { user: target-user, skill-id: skill-id }))
    (issuer-info (map-get? verified-issuers { issuer: tx-sender }))
  )
    (asserts! (is-some skill-data) ERR_SKILL_NOT_FOUND)
    (asserts! (is-some expiry-data) ERR_SKILL_NOT_FOUND)
    (asserts! (is-some issuer-info) ERR_ISSUER_NOT_FOUND)
    (asserts! (get active (unwrap-panic issuer-info)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get issuer (unwrap-panic skill-data)) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (get renewable (unwrap-panic expiry-data)) ERR_UNAUTHORIZED)
    (asserts! (> additional-validity u0) ERR_INVALID_INPUT)
    
    (ok (map-set skill-expiry
      { user: target-user, skill-id: skill-id }
      {
        expires-at: (+ stacks-block-height additional-validity),
        renewable: true,
        renewal-count: (+ (get renewal-count (unwrap-panic expiry-data)) u1)
      }
    ))
  )
)

(define-read-only (is-skill-expired (user principal) (skill-id uint))
  (match (map-get? skill-expiry { user: user, skill-id: skill-id })
    expiry-data (>= stacks-block-height (get expires-at expiry-data))
    false
  )
)

(define-read-only (get-skill-expiry (user principal) (skill-id uint))
  (map-get? skill-expiry { user: user, skill-id: skill-id })
)

(define-read-only (get-active-skills-count (user principal))
  (let ((total-skills (get-user-skill-count user)))
    (fold count-active-skills-iter (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) { user: user, count: u0 })
  )
)

(define-private (count-active-skills-iter (skill-id uint) (data { user: principal, count: uint }))
  (if (not (is-skill-expired (get user data) skill-id))
    { user: (get user data), count: (+ (get count data) u1) }
    data
  )
)

(define-map user-badges
  { user: principal }
  {
    first-skill: bool,
    first-verified: bool,
    category-expert: bool,
    skill-collector: bool,
    endorsement-leader: bool,
    renewal-champion: bool
  }
)

(define-map badge-earned-at
  { user: principal, badge-type: (string-ascii 20) }
  { earned-at: uint }
)

(define-private (check-and-award-badges (user principal))
  (let (
    (skill-count (get-user-skill-count user))
    (verified-result (count-verified-skills user))
    (verified-count (get count verified-result))
    (current-badges (default-to 
      { first-skill: false, first-verified: false, category-expert: false, 
        skill-collector: false, endorsement-leader: false, renewal-champion: false }
      (map-get? user-badges { user: user })))
  )
    (begin
      (if (and (>= skill-count u1) (not (get first-skill current-badges)))
        (begin
          (map-set badge-earned-at { user: user, badge-type: "first-skill" } { earned-at: stacks-block-height })
          (map-set user-badges { user: user } (merge current-badges { first-skill: true }))
        )
        false
      )
      
      (if (and (>= verified-count u1) (not (get first-verified current-badges)))
        (begin
          (map-set badge-earned-at { user: user, badge-type: "first-verified" } { earned-at: stacks-block-height })
          (map-set user-badges { user: user } (merge current-badges { first-verified: true }))
        )
        false
      )
      
      (if (and (>= skill-count u10) (not (get skill-collector current-badges)))
        (begin
          (map-set badge-earned-at { user: user, badge-type: "skill-collector" } { earned-at: stacks-block-height })
          (map-set user-badges { user: user } (merge current-badges { skill-collector: true }))
        )
        false
      )
      
      (if (and (>= verified-count u5) (not (get category-expert current-badges)))
        (begin
          (map-set badge-earned-at { user: user, badge-type: "category-expert" } { earned-at: stacks-block-height })
          (map-set user-badges { user: user } (merge current-badges { category-expert: true }))
        )
        false
      )
      
      true
    )
  )
)

(define-read-only (get-user-badges (user principal))
  (map-get? user-badges { user: user })
)

(define-read-only (get-badge-earned-at (user principal) (badge-type (string-ascii 20)))
  (map-get? badge-earned-at { user: user, badge-type: badge-type })
)

(define-read-only (has-badge (user principal) (badge-type (string-ascii 20)))
  (match (map-get? user-badges { user: user })
    user-badge-data
      (if (is-eq badge-type "first-skill")
        (get first-skill user-badge-data)
        (if (is-eq badge-type "first-verified")
          (get first-verified user-badge-data)
          (if (is-eq badge-type "category-expert")
            (get category-expert user-badge-data)
            (if (is-eq badge-type "skill-collector")
              (get skill-collector user-badge-data)
              (if (is-eq badge-type "endorsement-leader")
                (get endorsement-leader user-badge-data)
                (if (is-eq badge-type "renewal-champion")
                  (get renewal-champion user-badge-data)
                  false
                )
              )
            )
          )
        )
      )
    false
  )
)


(define-map skill-bounties
  { user: principal, skill-id: uint }
  { bounty-amount: uint, active: bool }
)

(define-map issuer-global-bounties
  { issuer: principal, skill-name: (string-ascii 100) }
  { bounty-amount: uint, active: bool }
)

(define-map skill-referrals
  { referrer: principal, referee: principal, skill-name: (string-ascii 100) }
  { claimed: bool, bounty-paid: uint, referred-at: uint }
)

(define-map user-referral-earnings
  { user: principal }
  { total-earned: uint, total-referrals: uint }
)

(define-public (set-skill-bounty (skill-id uint) (bounty-amount uint))
  (let ((skill-data (map-get? skills { user: tx-sender, skill-id: skill-id })))
    (asserts! (is-some skill-data) ERR_SKILL_NOT_FOUND)
    (asserts! (> bounty-amount u0) ERR_INVALID_INPUT)
    (ok (map-set skill-bounties
      { user: tx-sender, skill-id: skill-id }
      { bounty-amount: bounty-amount, active: true }
    ))
  )
)

(define-public (set-issuer-bounty (skill-name (string-ascii 100)) (bounty-amount uint))
  (let ((issuer-info (map-get? verified-issuers { issuer: tx-sender })))
    (asserts! (is-some issuer-info) ERR_ISSUER_NOT_FOUND)
    (asserts! (get active (unwrap-panic issuer-info)) ERR_UNAUTHORIZED)
    (asserts! (> bounty-amount u0) ERR_INVALID_INPUT)
    (ok (map-set issuer-global-bounties
      { issuer: tx-sender, skill-name: skill-name }
      { bounty-amount: bounty-amount, active: true }
    ))
  )
)

(define-public (claim-referral-bounty (referrer principal) (skill-name (string-ascii 100)) (referee-skill-id uint))
  (let (
    (referee-skill (map-get? skills { user: tx-sender, skill-id: referee-skill-id }))
    (referral-data (map-get? skill-referrals { referrer: referrer, referee: tx-sender, skill-name: skill-name }))
    (issuer-bounty (map-get? issuer-global-bounties { issuer: (get issuer (unwrap! referee-skill ERR_SKILL_NOT_FOUND)), skill-name: skill-name }))
    (bounty-amt (if (is-some issuer-bounty) (get bounty-amount (unwrap-panic issuer-bounty)) u0))
    (current-earnings (default-to { total-earned: u0, total-referrals: u0 } (map-get? user-referral-earnings { user: referrer })))
  )
    (asserts! (is-some referee-skill) ERR_SKILL_NOT_FOUND)
    (asserts! (get verified (unwrap-panic referee-skill)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get skill-name (unwrap-panic referee-skill)) skill-name) ERR_INVALID_INPUT)
    (asserts! (is-none referral-data) ERR_ALREADY_EXISTS)
    (asserts! (> bounty-amt u0) ERR_INVALID_INPUT)
    (map-set skill-referrals
      { referrer: referrer, referee: tx-sender, skill-name: skill-name }
      { claimed: true, bounty-paid: bounty-amt, referred-at: stacks-block-height }
    )
    (ok (map-set user-referral-earnings
      { user: referrer }
      { total-earned: (+ (get total-earned current-earnings) bounty-amt), total-referrals: (+ (get total-referrals current-earnings) u1) }
    ))
  )
)

(define-read-only (get-referral-earnings (user principal))
  (default-to { total-earned: u0, total-referrals: u0 } (map-get? user-referral-earnings { user: user }))
)

(define-read-only (get-skill-bounty (user principal) (skill-id uint))
  (map-get? skill-bounties { user: user, skill-id: skill-id })
)

(define-read-only (get-issuer-bounty (issuer principal) (skill-name (string-ascii 100)))
  (map-get? issuer-global-bounties { issuer: issuer, skill-name: skill-name })
)

(define-map skill-challenges
  { challenge-id: uint }
  {
    challenger: principal,
    target-user: principal,
    skill-id: uint,
    challenge-text: (string-ascii 300),
    created-at: uint,
    status: (string-ascii 20),
    proof-submitted: bool,
    votes-for: uint,
    votes-against: uint,
    resolved-at: uint
  }
)

(define-map challenge-proofs
  { challenge-id: uint }
  { proof-text: (string-ascii 500), submitted-at: uint }
)

(define-map challenge-votes
  { challenge-id: uint, voter: principal }
  { vote-for: bool, voted-at: uint }
)

(define-map skill-credibility
  { user: principal, skill-id: uint }
  { score: uint, challenges-won: uint, challenges-lost: uint }
)

(define-data-var challenge-counter uint u0)

(define-public (create-challenge (target-user principal) (skill-id uint) (challenge-text (string-ascii 300)))
  (let (
    (skill-data (map-get? skills { user: target-user, skill-id: skill-id }))
    (new-challenge-id (+ (var-get challenge-counter) u1))
  )
    (asserts! (is-some skill-data) ERR_SKILL_NOT_FOUND)
    (asserts! (not (is-eq tx-sender target-user)) ERR_INVALID_INPUT)
    (asserts! (> (len challenge-text) u0) ERR_INVALID_INPUT)
    (var-set challenge-counter new-challenge-id)
    (ok (map-set skill-challenges
      { challenge-id: new-challenge-id }
      {
        challenger: tx-sender,
        target-user: target-user,
        skill-id: skill-id,
        challenge-text: challenge-text,
        created-at: stacks-block-height,
        status: "pending",
        proof-submitted: false,
        votes-for: u0,
        votes-against: u0,
        resolved-at: u0
      }
    ))
  )
)

(define-public (submit-proof (challenge-id uint) (proof-text (string-ascii 500)))
  (let ((challenge (map-get? skill-challenges { challenge-id: challenge-id })))
    (asserts! (is-some challenge) ERR_SKILL_NOT_FOUND)
    (asserts! (is-eq tx-sender (get target-user (unwrap-panic challenge))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status (unwrap-panic challenge)) "pending") ERR_INVALID_INPUT)
    (asserts! (> (len proof-text) u0) ERR_INVALID_INPUT)
    (map-set challenge-proofs { challenge-id: challenge-id } { proof-text: proof-text, submitted-at: stacks-block-height })
    (ok (map-set skill-challenges { challenge-id: challenge-id } (merge (unwrap-panic challenge) { proof-submitted: true, status: "voting" })))
  )
)

(define-public (vote-on-challenge (challenge-id uint) (vote-for bool))
  (let (
    (challenge (map-get? skill-challenges { challenge-id: challenge-id }))
    (existing-vote (map-get? challenge-votes { challenge-id: challenge-id, voter: tx-sender }))
  )
    (asserts! (is-some challenge) ERR_SKILL_NOT_FOUND)
    (asserts! (is-eq (get status (unwrap-panic challenge)) "voting") ERR_INVALID_INPUT)
    (asserts! (is-none existing-vote) ERR_ALREADY_EXISTS)
    (map-set challenge-votes { challenge-id: challenge-id, voter: tx-sender } { vote-for: vote-for, voted-at: stacks-block-height })
    (ok (map-set skill-challenges
      { challenge-id: challenge-id }
      (merge (unwrap-panic challenge) 
        {
          votes-for: (if vote-for (+ (get votes-for (unwrap-panic challenge)) u1) (get votes-for (unwrap-panic challenge))),
          votes-against: (if (not vote-for) (+ (get votes-against (unwrap-panic challenge)) u1) (get votes-against (unwrap-panic challenge)))
        }
      )
    ))
  )
)

(define-read-only (get-challenge (challenge-id uint))
  (map-get? skill-challenges { challenge-id: challenge-id })
)

(define-read-only (get-challenge-proof (challenge-id uint))
  (map-get? challenge-proofs { challenge-id: challenge-id })
)

(define-read-only (get-skill-credibility (user principal) (skill-id uint))
  (default-to { score: u100, challenges-won: u0, challenges-lost: u0 } (map-get? skill-credibility { user: user, skill-id: skill-id }))
)