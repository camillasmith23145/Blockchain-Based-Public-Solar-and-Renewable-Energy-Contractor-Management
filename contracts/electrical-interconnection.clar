;; Electrical Interconnection Management Contract
;; Coordinates connection of renewable energy systems to the power grid

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-ALREADY-EXISTS (err u301))
(define-constant ERR-NOT-FOUND (err u302))
(define-constant ERR-INVALID-INPUT (err u303))
(define-constant ERR-GRID-CAPACITY-EXCEEDED (err u304))
(define-constant ERR-SAFETY-REQUIREMENTS-NOT-MET (err u305))

;; Data Variables
(define-data-var next-interconnection-id uint u1)
(define-data-var total-grid-capacity uint u1000000) ;; 1GW total capacity
(define-data-var used-grid-capacity uint u0)

;; Data Maps
(define-map interconnection-requests
  { interconnection-id: uint }
  {
    applicant-principal: principal,
    system-type: (string-ascii 20),
    capacity-kw: uint,
    voltage-level: uint,
    connection-point: (string-ascii 200),
    application-date: uint,
    study-completion-date: (optional uint),
    approval-date: (optional uint),
    connection-date: (optional uint),
    status: (string-ascii 30),
    estimated-cost: uint,
    actual-cost: (optional uint),
    utility-company: (string-ascii 100)
  }
)

(define-map grid-studies
  { interconnection-id: uint }
  {
    power-flow-analysis: bool,
    short-circuit-analysis: bool,
    stability-analysis: bool,
    protection-coordination: bool,
    voltage-regulation: bool,
    study-engineer: principal,
    study-date: uint,
    recommendations: (string-ascii 500),
    approved: bool
  }
)

(define-map safety-compliance
  { interconnection-id: uint }
  {
    electrical-standards: bool,
    protection-systems: bool,
    grounding-systems: bool,
    isolation-equipment: bool,
    monitoring-systems: bool,
    inspector-principal: principal,
    inspection-date: uint,
    compliance-score: uint,
    passed: bool
  }
)

(define-map grid-connections
  { interconnection-id: uint }
  {
    connection-date: uint,
    actual-capacity: uint,
    meter-number: (string-ascii 50),
    transformer-info: (string-ascii 200),
    protection-settings: (string-ascii 300),
    commissioning-tests: bool,
    operational-status: (string-ascii 20)
  }
)

;; Authorization checks
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-authorized-engineer (engineer principal))
  ;; In a real implementation, this would check against a registry of authorized engineers
  (is-contract-owner)
)

(define-private (is-authorized-inspector (inspector principal))
  ;; In a real implementation, this would check against a registry of authorized inspectors
  (is-contract-owner)
)

;; Submit interconnection request
(define-public (submit-interconnection-request
  (system-type (string-ascii 20))
  (capacity-kw uint)
  (voltage-level uint)
  (connection-point (string-ascii 200))
  (estimated-cost uint)
  (utility-company (string-ascii 100)))
  (let
    (
      (interconnection-id (var-get next-interconnection-id))
      (current-block block-height)
      (available-capacity (- (var-get total-grid-capacity) (var-get used-grid-capacity)))
    )
    (asserts! (> capacity-kw u0) ERR-INVALID-INPUT)
    (asserts! (<= capacity-kw available-capacity) ERR-GRID-CAPACITY-EXCEEDED)
    (asserts! (or (is-eq voltage-level u120) (is-eq voltage-level u240)
                  (is-eq voltage-level u480) (is-eq voltage-level u4160)
                  (is-eq voltage-level u13800)) ERR-INVALID-INPUT)
    (asserts! (> (len connection-point) u0) ERR-INVALID-INPUT)
    (asserts! (> estimated-cost u0) ERR-INVALID-INPUT)
    (asserts! (> (len utility-company) u0) ERR-INVALID-INPUT)

    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      {
        applicant-principal: tx-sender,
        system-type: system-type,
        capacity-kw: capacity-kw,
        voltage-level: voltage-level,
        connection-point: connection-point,
        application-date: current-block,
        study-completion-date: none,
        approval-date: none,
        connection-date: none,
        status: "pending-study",
        estimated-cost: estimated-cost,
        actual-cost: none,
        utility-company: utility-company
      }
    )

    (var-set next-interconnection-id (+ interconnection-id u1))
    (ok interconnection-id)
  )
)

;; Complete grid impact study
(define-public (complete-grid-study
  (interconnection-id uint)
  (power-flow-analysis bool)
  (short-circuit-analysis bool)
  (stability-analysis bool)
  (protection-coordination bool)
  (voltage-regulation bool)
  (recommendations (string-ascii 500)))
  (let
    (
      (request-info (unwrap! (map-get? interconnection-requests { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
      (current-block block-height)
      (all-studies-passed (and power-flow-analysis (and short-circuit-analysis (and stability-analysis (and protection-coordination voltage-regulation)))))
    )
    (asserts! (is-authorized-engineer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-info) "pending-study") ERR-INVALID-INPUT)

    (map-set grid-studies
      { interconnection-id: interconnection-id }
      {
        power-flow-analysis: power-flow-analysis,
        short-circuit-analysis: short-circuit-analysis,
        stability-analysis: stability-analysis,
        protection-coordination: protection-coordination,
        voltage-regulation: voltage-regulation,
        study-engineer: tx-sender,
        study-date: current-block,
        recommendations: recommendations,
        approved: all-studies-passed
      }
    )

    ;; Update request status
    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      (merge request-info {
        study-completion-date: (some current-block),
        status: (if all-studies-passed "study-approved" "study-rejected")
      })
    )

    (ok all-studies-passed)
  )
)

;; Conduct safety compliance inspection
(define-public (conduct-safety-inspection
  (interconnection-id uint)
  (electrical-standards bool)
  (protection-systems bool)
  (grounding-systems bool)
  (isolation-equipment bool)
  (monitoring-systems bool))
  (let
    (
      (request-info (unwrap! (map-get? interconnection-requests { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
      (current-block block-height)
      (compliance-count (+ (if electrical-standards u1 u0)
                          (+ (if protection-systems u1 u0)
                             (+ (if grounding-systems u1 u0)
                                (+ (if isolation-equipment u1 u0)
                                   (if monitoring-systems u1 u0))))))
      (compliance-score (* compliance-count u20)) ;; Score out of 100
      (inspection-passed (>= compliance-score u80))
    )
    (asserts! (is-authorized-inspector tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-info) "study-approved") ERR-INVALID-INPUT)

    (map-set safety-compliance
      { interconnection-id: interconnection-id }
      {
        electrical-standards: electrical-standards,
        protection-systems: protection-systems,
        grounding-systems: grounding-systems,
        isolation-equipment: isolation-equipment,
        monitoring-systems: monitoring-systems,
        inspector-principal: tx-sender,
        inspection-date: current-block,
        compliance-score: compliance-score,
        passed: inspection-passed
      }
    )

    ;; Update request status
    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      (merge request-info {
        status: (if inspection-passed "safety-approved" "safety-rejected")
      })
    )

    (ok inspection-passed)
  )
)

;; Approve interconnection (admin only)
(define-public (approve-interconnection (interconnection-id uint))
  (let
    (
      (request-info (unwrap! (map-get? interconnection-requests { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-info) "safety-approved") ERR-SAFETY-REQUIREMENTS-NOT-MET)

    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      (merge request-info {
        approval-date: (some current-block),
        status: "approved"
      })
    )
    (ok true)
  )
)

;; Record grid connection
(define-public (record-grid-connection
  (interconnection-id uint)
  (actual-capacity uint)
  (meter-number (string-ascii 50))
  (transformer-info (string-ascii 200))
  (protection-settings (string-ascii 300))
  (actual-cost uint))
  (let
    (
      (request-info (unwrap! (map-get? interconnection-requests { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (is-eq tx-sender (get applicant-principal request-info)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-info) "approved") ERR-INVALID-INPUT)
    (asserts! (> actual-capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len meter-number) u0) ERR-INVALID-INPUT)
    (asserts! (> actual-cost u0) ERR-INVALID-INPUT)

    (map-set grid-connections
      { interconnection-id: interconnection-id }
      {
        connection-date: current-block,
        actual-capacity: actual-capacity,
        meter-number: meter-number,
        transformer-info: transformer-info,
        protection-settings: protection-settings,
        commissioning-tests: false,
        operational-status: "connected"
      }
    )

    ;; Update request with connection info
    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      (merge request-info {
        connection-date: (some current-block),
        actual-cost: (some actual-cost),
        status: "connected"
      })
    )

    ;; Update used grid capacity
    (var-set used-grid-capacity (+ (var-get used-grid-capacity) actual-capacity))

    (ok true)
  )
)

;; Complete commissioning tests
(define-public (complete-commissioning-tests (interconnection-id uint))
  (let
    (
      (request-info (unwrap! (map-get? interconnection-requests { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
      (connection-info (unwrap! (map-get? grid-connections { interconnection-id: interconnection-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-authorized-engineer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request-info) "connected") ERR-INVALID-INPUT)

    (map-set grid-connections
      { interconnection-id: interconnection-id }
      (merge connection-info {
        commissioning-tests: true,
        operational-status: "operational"
      })
    )

    (map-set interconnection-requests
      { interconnection-id: interconnection-id }
      (merge request-info { status: "operational" })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-interconnection-request (interconnection-id uint))
  (map-get? interconnection-requests { interconnection-id: interconnection-id })
)

(define-read-only (get-grid-study (interconnection-id uint))
  (map-get? grid-studies { interconnection-id: interconnection-id })
)

(define-read-only (get-safety-compliance (interconnection-id uint))
  (map-get? safety-compliance { interconnection-id: interconnection-id })
)

(define-read-only (get-grid-connection (interconnection-id uint))
  (map-get? grid-connections { interconnection-id: interconnection-id })
)

(define-read-only (get-grid-capacity-info)
  {
    total-capacity: (var-get total-grid-capacity),
    used-capacity: (var-get used-grid-capacity),
    available-capacity: (- (var-get total-grid-capacity) (var-get used-grid-capacity))
  }
)

(define-read-only (get-next-interconnection-id)
  (var-get next-interconnection-id)
)
