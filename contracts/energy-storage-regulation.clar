;; Energy Storage System Regulation Contract
;; Manages permits for battery storage and backup power systems

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-ALREADY-EXISTS (err u401))
(define-constant ERR-NOT-FOUND (err u402))
(define-constant ERR-INVALID-INPUT (err u403))
(define-constant ERR-SAFETY-VIOLATION (err u404))
(define-constant ERR-CAPACITY-LIMIT-EXCEEDED (err u405))

;; Data Variables
(define-data-var next-storage-id uint u1)
(define-data-var max-residential-capacity uint u50) ;; 50kWh max for residential
(define-data-var max-commercial-capacity uint u1000) ;; 1MWh max for commercial
(define-data-var max-utility-capacity uint u100000) ;; 100MWh max for utility scale

;; Data Maps
(define-map storage-systems
  { storage-id: uint }
  {
    owner-principal: principal,
    system-type: (string-ascii 20), ;; "residential", "commercial", "utility"
    battery-technology: (string-ascii 30), ;; "lithium_ion", "lead_acid", "flow_battery"
    capacity-kwh: uint,
    power-rating-kw: uint,
    installation-address: (string-ascii 200),
    application-date: uint,
    approval-date: (optional uint),
    installation-date: (optional uint),
    commissioning-date: (optional uint),
    status: (string-ascii 20),
    permit-fee: uint,
    is-grid-tied: bool
  }
)

(define-map safety-certifications
  { storage-id: uint }
  {
    fire-safety-rating: uint,
    thermal-management: bool,
    overcharge-protection: bool,
    short-circuit-protection: bool,
    ground-fault-protection: bool,
    emergency-shutdown: bool,
    ventilation-adequate: bool,
    certification-body: (string-ascii 100),
    certification-date: uint,
    expiration-date: uint,
    certified: bool
  }
)

(define-map performance-monitoring
  { storage-id: uint }
  {
    cycles-completed: uint,
    capacity-retention: uint, ;; Percentage of original capacity
    efficiency-rating: uint,
    temperature-range: { min: uint, max: uint },
    maintenance-events: uint,
    fault-events: uint,
    last-maintenance: uint,
    next-maintenance: uint,
    operational-status: (string-ascii 20)
  }
)

(define-map grid-services
  { storage-id: uint }
  {
    frequency-regulation: bool,
    voltage-support: bool,
    peak-shaving: bool,
    load-shifting: bool,
    backup-power: bool,
    islanding-capable: bool,
    response-time-ms: uint,
    service-agreements: (list 5 (string-ascii 100))
  }
)

;; Authorization checks
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-authorized-certifier (certifier principal))
  ;; In a real implementation, this would check against a registry of authorized certification bodies
  (is-contract-owner)
)

;; Get capacity limit based on system type
(define-private (get-capacity-limit (system-type (string-ascii 20)))
  (if (is-eq system-type "residential")
    (var-get max-residential-capacity)
    (if (is-eq system-type "commercial")
      (var-get max-commercial-capacity)
      (var-get max-utility-capacity)
    )
  )
)

;; Submit storage system permit application
(define-public (apply-for-storage-permit
  (system-type (string-ascii 20))
  (battery-technology (string-ascii 30))
  (capacity-kwh uint)
  (power-rating-kw uint)
  (installation-address (string-ascii 200))
  (permit-fee uint)
  (is-grid-tied bool))
  (let
    (
      (storage-id (var-get next-storage-id))
      (current-block block-height)
      (capacity-limit (get-capacity-limit system-type))
    )
    (asserts! (or (is-eq system-type "residential")
                  (or (is-eq system-type "commercial") (is-eq system-type "utility"))) ERR-INVALID-INPUT)
    (asserts! (or (is-eq battery-technology "lithium_ion")
                  (or (is-eq battery-technology "lead_acid") (is-eq battery-technology "flow_battery"))) ERR-INVALID-INPUT)
    (asserts! (> capacity-kwh u0) ERR-INVALID-INPUT)
    (asserts! (<= capacity-kwh capacity-limit) ERR-CAPACITY-LIMIT-EXCEEDED)
    (asserts! (> power-rating-kw u0) ERR-INVALID-INPUT)
    (asserts! (> (len installation-address) u0) ERR-INVALID-INPUT)
    (asserts! (> permit-fee u0) ERR-INVALID-INPUT)

    (map-set storage-systems
      { storage-id: storage-id }
      {
        owner-principal: tx-sender,
        system-type: system-type,
        battery-technology: battery-technology,
        capacity-kwh: capacity-kwh,
        power-rating-kw: power-rating-kw,
        installation-address: installation-address,
        application-date: current-block,
        approval-date: none,
        installation-date: none,
        commissioning-date: none,
        status: "pending-review",
        permit-fee: permit-fee,
        is-grid-tied: is-grid-tied
      }
    )

    (var-set next-storage-id (+ storage-id u1))
    (ok storage-id)
  )
)

;; Submit safety certification
(define-public (submit-safety-certification
  (storage-id uint)
  (fire-safety-rating uint)
  (thermal-management bool)
  (overcharge-protection bool)
  (short-circuit-protection bool)
  (ground-fault-protection bool)
  (emergency-shutdown bool)
  (ventilation-adequate bool)
  (certification-body (string-ascii 100)))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
      (current-block block-height)
      (safety-score (+ (if thermal-management u1 u0)
                      (+ (if overcharge-protection u1 u0)
                         (+ (if short-circuit-protection u1 u0)
                            (+ (if ground-fault-protection u1 u0)
                               (+ (if emergency-shutdown u1 u0)
                                  (if ventilation-adequate u1 u0)))))))
      (certification-passed (and (>= fire-safety-rating u3) (>= safety-score u5)))
    )
    (asserts! (is-authorized-certifier tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status system-info) "pending-review") ERR-INVALID-INPUT)
    (asserts! (and (>= fire-safety-rating u1) (<= fire-safety-rating u5)) ERR-INVALID-INPUT)
    (asserts! (> (len certification-body) u0) ERR-INVALID-INPUT)

    (map-set safety-certifications
      { storage-id: storage-id }
      {
        fire-safety-rating: fire-safety-rating,
        thermal-management: thermal-management,
        overcharge-protection: overcharge-protection,
        short-circuit-protection: short-circuit-protection,
        ground-fault-protection: ground-fault-protection,
        emergency-shutdown: emergency-shutdown,
        ventilation-adequate: ventilation-adequate,
        certification-body: certification-body,
        certification-date: current-block,
        expiration-date: (+ current-block u52560), ;; ~1 year
        certified: certification-passed
      }
    )

    ;; Update system status
    (map-set storage-systems
      { storage-id: storage-id }
      (merge system-info {
        status: (if certification-passed "safety-certified" "safety-rejected")
      })
    )

    (ok certification-passed)
  )
)

;; Approve storage system permit (admin only)
(define-public (approve-storage-permit (storage-id uint))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status system-info) "safety-certified") ERR-SAFETY-VIOLATION)

    (map-set storage-systems
      { storage-id: storage-id }
      (merge system-info {
        approval-date: (some current-block),
        status: "approved"
      })
    )
    (ok true)
  )
)

;; Record system installation
(define-public (record-installation (storage-id uint))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (is-eq tx-sender (get owner-principal system-info)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status system-info) "approved") ERR-INVALID-INPUT)

    (map-set storage-systems
      { storage-id: storage-id }
      (merge system-info {
        installation-date: (some current-block),
        status: "installed"
      })
    )

    ;; Initialize performance monitoring
    (map-set performance-monitoring
      { storage-id: storage-id }
      {
        cycles-completed: u0,
        capacity-retention: u100,
        efficiency-rating: u95,
        temperature-range: { min: u20, max: u25 },
        maintenance-events: u0,
        fault-events: u0,
        last-maintenance: current-block,
        next-maintenance: (+ current-block u4380), ;; ~1 month
        operational-status: "installed"
      }
    )

    (ok true)
  )
)

;; Record system commissioning
(define-public (record-commissioning (storage-id uint))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
      (monitoring-info (unwrap! (map-get? performance-monitoring { storage-id: storage-id }) ERR-NOT-FOUND))
      (current-block block-height)
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status system-info) "installed") ERR-INVALID-INPUT)

    (map-set storage-systems
      { storage-id: storage-id }
      (merge system-info {
        commissioning-date: (some current-block),
        status: "operational"
      })
    )

    (map-set performance-monitoring
      { storage-id: storage-id }
      (merge monitoring-info { operational-status: "operational" })
    )

    (ok true)
  )
)

;; Configure grid services
(define-public (configure-grid-services
  (storage-id uint)
  (frequency-regulation bool)
  (voltage-support bool)
  (peak-shaving bool)
  (load-shifting bool)
  (backup-power bool)
  (islanding-capable bool)
  (response-time-ms uint))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner-principal system-info)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-grid-tied system-info) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status system-info) "operational") ERR-INVALID-INPUT)
    (asserts! (> response-time-ms u0) ERR-INVALID-INPUT)

    (map-set grid-services
      { storage-id: storage-id }
      {
        frequency-regulation: frequency-regulation,
        voltage-support: voltage-support,
        peak-shaving: peak-shaving,
        load-shifting: load-shifting,
        backup-power: backup-power,
        islanding-capable: islanding-capable,
        response-time-ms: response-time-ms,
        service-agreements: (list)
      }
    )
    (ok true)
  )
)

;; Update performance metrics
(define-public (update-performance-metrics
  (storage-id uint)
  (cycles-completed uint)
  (capacity-retention uint)
  (efficiency-rating uint)
  (min-temp uint)
  (max-temp uint))
  (let
    (
      (system-info (unwrap! (map-get? storage-systems { storage-id: storage-id }) ERR-NOT-FOUND))
      (monitoring-info (unwrap! (map-get? performance-monitoring { storage-id: storage-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner-principal system-info)) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= capacity-retention u100) (>= capacity-retention u0)) ERR-INVALID-INPUT)
    (asserts! (and (<= efficiency-rating u100) (>= efficiency-rating u0)) ERR-INVALID-INPUT)

    (map-set performance-monitoring
      { storage-id: storage-id }
      (merge monitoring-info {
        cycles-completed: cycles-completed,
        capacity-retention: capacity-retention,
        efficiency-rating: efficiency-rating,
        temperature-range: { min: min-temp, max: max-temp }
      })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-storage-system (storage-id uint))
  (map-get? storage-systems { storage-id: storage-id })
)

(define-read-only (get-safety-certification (storage-id uint))
  (map-get? safety-certifications { storage-id: storage-id })
)

(define-read-only (get-performance-monitoring (storage-id uint))
  (map-get? performance-monitoring { storage-id: storage-id })
)

(define-read-only (get-grid-services (storage-id uint))
  (map-get? grid-services { storage-id: storage-id })
)

(define-read-only (get-capacity-limits)
  {
    residential-max: (var-get max-residential-capacity),
    commercial-max: (var-get max-commercial-capacity),
    utility-max: (var-get max-utility-capacity)
  }
)

(define-read-only (get-next-storage-id)
  (var-get next-storage-id)
)
