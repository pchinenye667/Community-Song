📜 README: Community Song Ownership Contract
Overview

The Community Song Ownership Contract is a Clarity smart contract that enables collaborative music creation and revenue sharing using NFTs.
Each song is minted as a non-fungible token (NFT) representing ownership of the song. Contributors to the song are assigned shares that determine how much of the song’s revenue they can claim.

This contract follows the SIP-009 standard for NFT implementation on the Stacks blockchain.

🎵 Key Features

NFT-based Song Representation:
Each song is minted as a unique NFT (community-song) that represents ownership of that song.

Collaborative Ownership:
Multiple contributors can hold shares in a song, stored in the song-contributors map.

Revenue Distribution:
Songs can accumulate STX revenue which contributors can claim based on their share percentage.

Transparent Record Keeping:
Every song’s metadata (title, URI, creation date) and ownership details are stored on-chain for public visibility.

🧩 Core Data Structures

Data Variables

last-song-id: Tracks the most recent song NFT ID.

contract-uri: Optional metadata URI for the overall contract.

Data Maps

songs: Stores each song’s metadata — title, URI, total shares, and creation block.

song-contributors: Maps contributors to their assigned shares for a specific song.

contributor-songs: Tracks whether a contributor is linked to a given song.

song-revenue: Stores the total unclaimed revenue for each song.

⚙️ Core Functions
1. mint-song

Purpose: Mint a new song NFT and assign contributors with shares.
Parameters:

title: ASCII string (max 128 chars)

uri: Metadata link (e.g., IPFS or cloud URL)

contributors: List of up to 50 {contributor: principal, shares: uint} pairs

Returns: ok(song-id)
Errors:

err-invalid-shares — Empty title, URI, or invalid shares

err-already-contributor — If contributor is already registered (if implemented later)

2. transfer

Purpose: Transfer ownership of a song NFT from one user to another.
Checks:

Caller must be the current owner.

Cannot transfer to self.

Song must exist.

Returns: (ok true) or relevant error.

3. add-revenue

Purpose: Add STX revenue to a song’s revenue pool.
Parameters:

song-id

amount (in microSTX)

Returns: (ok true)
Errors:

err-song-not-found

err-invalid-shares (if amount is u0)

4. claim-revenue

Purpose: Allows contributors to claim their proportional share of a song’s revenue.
Mechanism:

Calculates contributor’s share = (total-revenue * contributor-shares) / total-shares.

Transfers that share of STX to the contributor.

Deducts claimed amount from song’s total revenue.

Errors:

err-not-token-owner — Not a contributor.

err-insufficient-shares — No revenue or invalid shares.

err-song-not-found — Song ID doesn’t exist.

5. Read-Only Helpers

get-song-info(song-id) → Returns metadata for a song.

get-contributor-shares(song-id, contributor) → Returns share info.

get-song-revenue(song-id) → Returns total accumulated STX revenue.

is-contributor(song-id, contributor) → Checks if a user contributed.

calculate-contributor-revenue(song-id, contributor) → Estimates potential claimable revenue.

🧠 Example Flow

Mint a Song

(contract-call? .community-song-ownership mint-song
  "Harmony of Stars"
  "ipfs://Qm12345"
  (list {contributor: 'SP123...', shares: u70} {contributor: 'SP456...', shares: u30})
)


→ Returns (ok u1) — song minted with ID 1.

Add Revenue

(contract-call? .community-song-ownership add-revenue u1 u1000000)


→ Adds 1 STX in revenue to song 1.

Claim Revenue

(contract-call? .community-song-ownership claim-revenue u1)


→ Contributor claims proportional share of available revenue.

🔒 Error Codes Reference
Code	Constant	Meaning
u100	err-owner-only	Restricted to contract owner
u101	err-not-token-owner	Caller not authorized
u102	err-song-not-found	Invalid song ID
u103	err-invalid-shares	Invalid input or 0 shares
u104	err-already-contributor	Contributor already exists
u105	err-insufficient-shares	No available revenue to claim
💡 Design Notes

The contract ensures transparent ownership and fair share distribution.

Uses stx-transfer? for direct payout in STX.

Limits contributor list to 50 for gas efficiency.

Future extensions may include:

Removing or updating contributor shares.

Token-based governance for songs.

Integration with decentralized music platforms.

🧾 License

MIT License — Free to use, modify, and distribute with attribution.