(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_FUNDS (err u101))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_VOTED (err u103))
(define-constant ERR_VOTING_ENDED (err u104))
(define-constant ERR_PROPOSAL_NOT_PASSED (err u105))
(define-constant ERR_ALREADY_EXECUTED (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))
(define-constant ERR_NOT_MEMBER (err u108))
(define-constant ERR_SHIPMENT_NOT_FOUND (err u109))
(define-constant ERR_INVALID_STATUS (err u110))
(define-constant ERR_ALREADY_VERIFIED (err u111))
(define-constant ERR_INSUFFICIENT_INVENTORY (err u112))
(define-constant ERR_SUPPLIER_NOT_REGISTERED (err u113))
(define-constant ERR_INVALID_QUANTITY (err u114))

(define-data-var next-proposal-id uint u1)
(define-data-var treasury-balance uint u0)
(define-data-var min-membership-stake uint u1000000)
(define-data-var voting-period uint u1440)
(define-data-var next-shipment-id uint u1)
(define-data-var next-supply-item-id uint u1)

(define-map members principal uint)
(define-map proposals uint {
    id: uint,
    proposer: principal,
    recipient: principal,
    amount: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: (string-ascii 20),
    votes-for: uint,
    votes-against: uint,
    start-block: uint,
    end-block: uint,
    executed: bool,
    passed: bool
})
(define-map votes {proposal-id: uint, voter: principal} bool)
(define-map health-workers principal {
    certified: bool,
    specialization: (string-ascii 50),
    training-completed: uint,
    equipment-received: uint
})
(define-map suppliers principal {
    registered: bool,
    name: (string-ascii 100),
    location: (string-ascii 100),
    reputation-score: uint
})
(define-map supply-items uint {
    id: uint,
    name: (string-ascii 100),
    category: (string-ascii 50),
    unit-price: uint,
    supplier: principal,
    created-at: uint
})
(define-map shipments uint {
    id: uint,
    supplier: principal,
    item-id: uint,
    quantity: uint,
    destination: principal,
    status: (string-ascii 20),
    quality-verified: bool,
    shipped-at: uint,
    delivered-at: uint,
    notes: (string-ascii 200)
})
(define-map inventory {item-id: uint, holder: principal} uint)

(define-public (join-dao (stake-amount uint))
    (begin
        (asserts! (>= stake-amount (var-get min-membership-stake)) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) stake-amount))
        (map-set members tx-sender stake-amount)
        (ok true)
    )
)

(define-public (create-proposal 
    (recipient principal)
    (amount uint)
    (title (string-ascii 100))
    (description (string-ascii 500))
    (proposal-type (string-ascii 20))
)
    (let (
        (proposal-id (var-get next-proposal-id))
        (current-block stacks-block-height)
    )
        (asserts! (is-some (map-get? members tx-sender)) ERR_NOT_MEMBER)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= amount (var-get treasury-balance)) ERR_INSUFFICIENT_FUNDS)
        
        (map-set proposals proposal-id {
            id: proposal-id,
            proposer: tx-sender,
            recipient: recipient,
            amount: amount,
            title: title,
            description: description,
            proposal-type: proposal-type,
            votes-for: u0,
            votes-against: u0,
            start-block: current-block,
            end-block: (+ current-block (var-get voting-period)),
            executed: false,
            passed: false
        })
        
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (vote (proposal-id uint) (support bool))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
        (voter-stake (unwrap! (map-get? members tx-sender) ERR_NOT_MEMBER))
        (current-block stacks-block-height)
    )
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_VOTED)
        (asserts! (<= current-block (get end-block proposal)) ERR_VOTING_ENDED)
        
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} support)
        
        (if support
            (map-set proposals proposal-id (merge proposal {votes-for: (+ (get votes-for proposal) voter-stake)}))
            (map-set proposals proposal-id (merge proposal {votes-against: (+ (get votes-against proposal) voter-stake)}))
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
        (current-block stacks-block-height)
        (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
        (passed (and (> total-votes u0) (> (get votes-for proposal) (get votes-against proposal))))
    )
        (asserts! (> current-block (get end-block proposal)) ERR_VOTING_ENDED)
        (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)
        (asserts! passed ERR_PROPOSAL_NOT_PASSED)
        
        (try! (stx-transfer? (get amount proposal) tx-sender (get recipient proposal)))
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
        
        (map-set proposals proposal-id (merge proposal {executed: true, passed: true}))
        
        (if (is-eq (get proposal-type proposal) "certification")
            (unwrap! (update-health-worker-certification (get recipient proposal)) (err u200))
            (if (is-eq (get proposal-type proposal) "training")
                (unwrap! (update-health-worker-training (get recipient proposal)) (err u201))
                (unwrap! (update-health-worker-equipment (get recipient proposal)) (err u202))
            )
        )
        (ok true)
    )
)

(define-public (register-health-worker (specialization (string-ascii 50)))
    (begin
        (map-set health-workers tx-sender {
            certified: false,
            specialization: specialization,
            training-completed: u0,
            equipment-received: u0
        })
        (ok true)
    )
)

(define-public (add-funds (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) amount))
        (ok true)
    )
)

(define-public (update-voting-period (new-period uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set voting-period new-period)
        (ok true)
    )
)

(define-public (update-min-stake (new-stake uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set min-membership-stake new-stake)
        (ok true)
    )
)

(define-private (update-health-worker-certification (worker principal))
    (let (
        (current-data (default-to {certified: false, specialization: "", training-completed: u0, equipment-received: u0} 
                                 (map-get? health-workers worker)))
    )
        (map-set health-workers worker (merge current-data {certified: true}))
        (ok true)
    )
)

(define-private (update-health-worker-training (worker principal))
    (let (
        (current-data (default-to {certified: false, specialization: "", training-completed: u0, equipment-received: u0} 
                                 (map-get? health-workers worker)))
    )
        (map-set health-workers worker (merge current-data {training-completed: (+ (get training-completed current-data) u1)}))
        (ok true)
    )
)

(define-private (update-health-worker-equipment (worker principal))
    (let (
        (current-data (default-to {certified: false, specialization: "", training-completed: u0, equipment-received: u0} 
                                 (map-get? health-workers worker)))
    )
        (map-set health-workers worker (merge current-data {equipment-received: (+ (get equipment-received current-data) u1)}))
        (ok true)
    )
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-member-stake (member principal))
    (map-get? members member)
)

(define-read-only (get-health-worker (worker principal))
    (map-get? health-workers worker)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (get-voting-period)
    (var-get voting-period)
)

(define-read-only (get-min-membership-stake)
    (var-get min-membership-stake)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-next-proposal-id)
    (var-get next-proposal-id)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes {proposal-id: proposal-id, voter: voter}))
)

(define-read-only (is-proposal-active (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (and (<= stacks-block-height (get end-block proposal)) (not (get executed proposal)))
        false
    )
)

(define-public (register-supplier (name (string-ascii 100)) (location (string-ascii 100)))
    (begin
        (map-set suppliers tx-sender {
            registered: true,
            name: name,
            location: location,
            reputation-score: u100
        })
        (ok true)
    )
)

(define-public (create-supply-item 
    (name (string-ascii 100))
    (category (string-ascii 50))
    (unit-price uint)
)
    (let (
        (item-id (var-get next-supply-item-id))
        (supplier-data (unwrap! (map-get? suppliers tx-sender) ERR_SUPPLIER_NOT_REGISTERED))
    )
        (asserts! (> unit-price u0) ERR_INVALID_AMOUNT)
        (map-set supply-items item-id {
            id: item-id,
            name: name,
            category: category,
            unit-price: unit-price,
            supplier: tx-sender,
            created-at: stacks-block-height
        })
        (var-set next-supply-item-id (+ item-id u1))
        (ok item-id)
    )
)

(define-public (create-shipment 
    (item-id uint)
    (quantity uint)
    (destination principal)
    (notes (string-ascii 200))
)
    (let (
        (shipment-id (var-get next-shipment-id))
        (item (unwrap! (map-get? supply-items item-id) ERR_SHIPMENT_NOT_FOUND))
        (supplier-data (unwrap! (map-get? suppliers tx-sender) ERR_SUPPLIER_NOT_REGISTERED))
    )
        (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
        (asserts! (is-eq tx-sender (get supplier item)) ERR_UNAUTHORIZED)
        (map-set shipments shipment-id {
            id: shipment-id,
            supplier: tx-sender,
            item-id: item-id,
            quantity: quantity,
            destination: destination,
            status: "shipped",
            quality-verified: false,
            shipped-at: stacks-block-height,
            delivered-at: u0,
            notes: notes
        })
        (var-set next-shipment-id (+ shipment-id u1))
        (ok shipment-id)
    )
)

(define-public (update-shipment-status (shipment-id uint) (new-status (string-ascii 20)))
    (let (
        (shipment (unwrap! (map-get? shipments shipment-id) ERR_SHIPMENT_NOT_FOUND))
    )
        (asserts! (or (is-eq tx-sender (get supplier shipment)) 
                     (is-eq tx-sender (get destination shipment))) ERR_UNAUTHORIZED)
        (map-set shipments shipment-id (merge shipment {
            status: new-status,
            delivered-at: (if (is-eq new-status "delivered") stacks-block-height (get delivered-at shipment))
        }))
        (if (is-eq new-status "delivered")
            (try! (update-inventory-on-delivery shipment-id))
            true
        )
        (ok true)
    )
)

(define-public (verify-quality (shipment-id uint) (verified bool))
    (let (
        (shipment (unwrap! (map-get? shipments shipment-id) ERR_SHIPMENT_NOT_FOUND))
        (verifier-member (unwrap! (map-get? members tx-sender) ERR_NOT_MEMBER))
    )
        (asserts! (not (get quality-verified shipment)) ERR_ALREADY_VERIFIED)
        (map-set shipments shipment-id (merge shipment {quality-verified: verified}))
        (if verified
            (try! (update-supplier-reputation (get supplier shipment) true))
            (try! (update-supplier-reputation (get supplier shipment) false))
        )
        (ok true)
    )
)

(define-public (transfer-inventory 
    (item-id uint)
    (quantity uint)
    (to principal)
)
    (let (
        (current-inventory (default-to u0 (map-get? inventory {item-id: item-id, holder: tx-sender})))
    )
        (asserts! (>= current-inventory quantity) ERR_INSUFFICIENT_INVENTORY)
        (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
        (map-set inventory {item-id: item-id, holder: tx-sender} (- current-inventory quantity))
        (map-set inventory {item-id: item-id, holder: to} 
                 (+ (default-to u0 (map-get? inventory {item-id: item-id, holder: to})) quantity))
        (ok true)
    )
)

(define-public (request-emergency-supplies 
    (item-id uint)
    (quantity uint)
    (justification (string-ascii 200))
)
    (let (
        (worker-data (unwrap! (map-get? health-workers tx-sender) ERR_UNAUTHORIZED))
        (item (unwrap! (map-get? supply-items item-id) ERR_SHIPMENT_NOT_FOUND))
    )
        (asserts! (get certified worker-data) ERR_UNAUTHORIZED)
        (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
        (create-proposal 
            tx-sender 
            (* (get unit-price item) quantity)
            "Emergency Supply Request"
            justification
            "emergency-supply"
        )
    )
)

(define-private (update-inventory-on-delivery (shipment-id uint))
    (let (
        (shipment (unwrap! (map-get? shipments shipment-id) ERR_SHIPMENT_NOT_FOUND))
        (destination (get destination shipment))
        (item-id (get item-id shipment))
        (quantity (get quantity shipment))
    )
        (map-set inventory {item-id: item-id, holder: destination}
                 (+ (default-to u0 (map-get? inventory {item-id: item-id, holder: destination})) quantity))
        (ok true)
    )
)

(define-private (update-supplier-reputation (supplier principal) (positive bool))
    (let (
        (supplier-data (unwrap! (map-get? suppliers supplier) ERR_SUPPLIER_NOT_REGISTERED))
        (current-score (get reputation-score supplier-data))
    )
        (map-set suppliers supplier (merge supplier-data {
            reputation-score: (if positive 
                                 (+ current-score u10)
                                 (if (>= current-score u10) (- current-score u10) u0))
        }))
        (ok true)
    )
)

(define-read-only (get-supplier (supplier principal))
    (map-get? suppliers supplier)
)

(define-read-only (get-supply-item (item-id uint))
    (map-get? supply-items item-id)
)

(define-read-only (get-shipment (shipment-id uint))
    (map-get? shipments shipment-id)
)

(define-read-only (get-inventory (item-id uint) (holder principal))
    (default-to u0 (map-get? inventory {item-id: item-id, holder: holder}))
)

(define-read-only (get-next-shipment-id)
    (var-get next-shipment-id)
)

(define-read-only (get-next-supply-item-id)
    (var-get next-supply-item-id)
)