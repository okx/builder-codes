# Changelog

### Added
- **`registerAuto(address initialPayoutAddress)`** — New external function that registers a builder code with an auto-generated code (no user-provided code needed), NFT is minted to `msg.sender`
  - Code is generated on-chain via `keccak256(msg.sender, initialPayoutAddress, block.number, block.prevrandao, nonce)`
  - On collision, increments nonce and retries up to 50 times (`MAX_CODE_GENERATION_ATTEMPTS`)
  - Reverts with `CodeGenerationFailed()` if all attempts fail
  - Returns the auto-generated 16-character code
- **`_generateCode(address, address)`** — Internal function to generate unique builder codes on-chain
- **`_hashToCode(bytes32)`** — Internal function that maps hash bytes to allowed characters (`0-9a-z`), producing a 16-character code
- **`MAX_CODE_GENERATION_ATTEMPTS`** constant (`50`)
- **`GENERATED_CODE_LENGTH`** constant (`16`)
- **`CodeGenerationFailed()`** custom error
- Unit tests for `registerAuto` covering success cases, collision handling, and revert cases
- **`setAutoRegistration(bool enabled)`** — Owner-only function to toggle auto registration on/off
- **`autoRegistrationEnabled()`** — View function to query current auto registration state
- **`AutoRegistrationToggled(bool enabled)`** event — Emitted when auto registration is toggled
- **`AutoRegistrationDisabled()`** custom error — Thrown when `registerAuto` is called while disabled
- **`autoRegistrationEnabled`** field in `RegistryStorage` (default: `false`)

### Changed
- **`ALLOWED_CHARACTERS`** — Removed underscore (`_`) to prevent codes starting with `_` which affects readability
  - Old: `"0123456789abcdefghijklmnopqrstuvwxyz_"` (37 chars)
  - New: `"0123456789abcdefghijklmnopqrstuvwxyz"` (36 chars)
- **`ALLOWED_CHARACTERS_LOOKUP`** — Updated to match new allowed characters set
- **`registerAuto`** is open to anyone (no `REGISTER_ROLE` restriction), but requires auto registration to be enabled by owner
- **`registerAuto`** — Gated by `autoRegistrationEnabled` toggle (default off, owner controls via `setAutoRegistration`)
- **`registerAuto`** — Removed `initialOwner` parameter; NFT is now always minted to `msg.sender`