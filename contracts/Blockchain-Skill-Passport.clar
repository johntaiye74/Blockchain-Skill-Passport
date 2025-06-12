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
