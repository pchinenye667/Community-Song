;; Community Song Ownership Contract
;; A simple NFT contract for collaborative music creation where contributors own shares

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-song-not-found (err u102))
(define-constant err-invalid-shares (err u103))
(define-constant err-already-contributor (err u104))
(define-constant err-insufficient-shares (err u105))

;; Data Variables
(define-data-var last-song-id uint u0)
(define-data-var contract-uri (string-ascii 256) "")

;; Data Maps
(define-map songs
  uint
  {
    title: (string-ascii 128),
    uri: (string-ascii 256),
    total-shares: uint,
    created-at: uint
  }
)

(define-map song-contributors
  {song-id: uint, contributor: principal}
  {shares: uint}
)

(define-map contributor-songs
  {contributor: principal, song-id: uint}
  bool
)

(define-map song-revenue
  uint
  uint
)

;; SIP-009 NFT Functions
(define-non-fungible-token community-song uint)

(define-read-only (get-last-token-id)
  (ok (var-get last-song-id))
)

(define-read-only (get-token-uri (song-id uint))
  (ok (some (get uri (map-get? songs song-id))))
)

(define-read-only (get-owner (song-id uint))
  (ok (nft-get-owner? community-song song-id))
)

(define-public (transfer (song-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (is-eq (unwrap! (nft-get-owner? community-song song-id) err-song-not-found) sender) err-not-token-owner)
    (asserts! (not (is-eq sender recipient)) err-invalid-shares)
    (nft-transfer? community-song song-id sender recipient)
  )
)

;; Core Functions
(define-public (mint-song 
  (title (string-ascii 128))
  (uri (string-ascii 256))
  (contributors (list 50 {contributor: principal, shares: uint}))
)
  (let
    (
      (song-id (+ (var-get last-song-id) u1))
      (total-shares (fold calculate-total-shares contributors u0))
    )
    (asserts! (> (len title) u0) err-invalid-shares)
    (asserts! (> (len uri) u0) err-invalid-shares)
    (asserts! (> total-shares u0) err-invalid-shares)
    (try! (nft-mint? community-song song-id tx-sender))
    (map-set songs song-id {
      title: title,
      uri: uri,
      total-shares: total-shares,
      created-at: block-height
    })
    (fold add-contributor-to-song contributors song-id)
    (var-set last-song-id song-id)
    (ok song-id)
  )
)

(define-private (calculate-total-shares (contributor {contributor: principal, shares: uint}) (acc uint))
  (+ acc (get shares contributor))
)

(define-private (add-contributor-to-song (contributor {contributor: principal, shares: uint}) (song-id uint))
  (begin
    (map-set song-contributors 
      {song-id: song-id, contributor: (get contributor contributor)}
      {shares: (get shares contributor)}
    )
    (map-set contributor-songs
      {contributor: (get contributor contributor), song-id: song-id}
      true
    )
    song-id
  )
)

(define-public (add-revenue (song-id uint) (amount uint))
  (let
    (
      (current-revenue (default-to u0 (map-get? song-revenue song-id)))
    )
    (asserts! (is-some (map-get? songs song-id)) err-song-not-found)
    (asserts! (> amount u0) err-invalid-shares)
    (map-set song-revenue song-id (+ current-revenue amount))
    (ok true)
  )
)

(define-public (claim-revenue (song-id uint))
  (let
    (
      (song-info (unwrap! (map-get? songs song-id) err-song-not-found))
      (contributor-info (unwrap! (map-get? song-contributors {song-id: song-id, contributor: tx-sender}) err-not-token-owner))
      (total-revenue (default-to u0 (map-get? song-revenue song-id)))
      (contributor-share (/ (* total-revenue (get shares contributor-info)) (get total-shares song-info)))
    )
    (asserts! (> contributor-share u0) err-insufficient-shares)
    (asserts! (>= total-revenue contributor-share) err-insufficient-shares)
    (map-set song-revenue song-id (- total-revenue contributor-share))
    (try! (stx-transfer? contributor-share (as-contract tx-sender) tx-sender))
    (ok contributor-share)
  )
)

;; Read-only functions
(define-read-only (get-song-info (song-id uint))
  (map-get? songs song-id)
)

(define-read-only (get-contributor-shares (song-id uint) (contributor principal))
  (map-get? song-contributors {song-id: song-id, contributor: contributor})
)

(define-read-only (get-song-revenue (song-id uint))
  (default-to u0 (map-get? song-revenue song-id))
)

(define-read-only (is-contributor (song-id uint) (contributor principal))
  (default-to false (map-get? contributor-songs {contributor: contributor, song-id: song-id}))
)

(define-read-only (calculate-contributor-revenue (song-id uint) (contributor principal))
  (match (map-get? songs song-id)
    song-info
    (match (map-get? song-contributors {song-id: song-id, contributor: contributor})
      contributor-info
      (let
        (
          (total-revenue (default-to u0 (map-get? song-revenue song-id)))
        )
        (some (/ (* total-revenue (get shares contributor-info)) (get total-shares song-info)))
      )
      none
    )
    none
  )
)