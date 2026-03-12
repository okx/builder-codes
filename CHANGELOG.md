# Changes (vs main)

## Overview

4 commits on `hugo/new`. The core change is replacing **user-supplied code input** with **on-chain auto-generation**, and introducing a **permissionless registration** mode.

---

## 1. Contract Changes (`src/BuilderCodes.sol`)

### 1.1 Registration: User Input → On-Chain Auto-Generation

- **Removed** `register(string code, address initialOwner, address initialPayoutAddress)`
- **Added** `register(address initialOwner, address initialPayoutAddress) returns (string memory code)`
  - Code is no longer passed in by the caller
  - Code is generated internally and returned

### 1.2 On-Chain Code Generation Logic

- **`_generateCode(address initialOwner, address initialPayoutAddress)`**
  - Computes hash via `keccak256(initialOwner, initialPayoutAddress, block.number, block.prevrandao, nonce)`
  - On collision, increments nonce and retries up to 50 times (`MAX_CODE_GENERATION_ATTEMPTS`)
  - Reverts with `CodeGenerationFailed()` if all attempts fail

- **`_hashToCode(bytes32 hash)`**
  - Maps each byte of the hash to one of 36 allowed characters (`0-9a-z`)
  - Always produces a 16-character code (`GENERATED_CODE_LENGTH = 16`)

### 1.3 Removed EIP-712 Signature Registration

- **Removed** `registerWithSignature()` function and all related logic
- **Removed** `REGISTRATION_TYPEHASH` constant
- **Removed** `EIP712` inheritance (no longer extends solady's `EIP712`)
- **Removed** `_domainNameAndVersion()` and `_domainNameAndVersionMayChange()`
- **Removed** `AfterRegistrationDeadline` error
- **Removed** `SignatureCheckerLib` and `EIP712` imports

### 1.4 Permissionless Registration Mode

- **Added** `registerRoleEnabled` storage variable (in `RegistryStorage`)
  - `false` (default): anyone can register
  - `true`: only `REGISTER_ROLE` holders can register
- **Added** `setRegisterRoleEnabled(bool enabled)` — owner-only
- **Added** `isRegisterRoleEnabled()` — view function
- **Added** `RegisterRoleToggled(bool enabled)` event

### 1.5 Allowed Characters Change

- **Removed** underscore (`_`) from allowed characters
- `ALLOWED_CHARACTERS`: `"0123456789abcdefghijklmnopqrstuvwxyz_"` → `"0123456789abcdefghijklmnopqrstuvwxyz"`
- `ALLOWED_CHARACTERS_LOOKUP` constant updated accordingly

### 1.6 New Constants

- `MAX_CODE_GENERATION_ATTEMPTS = 50`
- `GENERATED_CODE_LENGTH = 16`

### 1.7 New Errors

- `CodeGenerationFailed()` — reverts when code generation exhausts all retry attempts

### 1.8 Misc

- Author comment changed from `Coinbase` to `Builder Codes`

---

## 2. README.md Changes

- Removed mention of ERC-8021 `ICodesRegistry` interface
- Feature description updated from user-defined codes to auto-generated 16-char codes
- Removed `registerWithSignature()` documentation and all EIP-712 references
- Added **Auto-Generation** section explaining the generation algorithm
- Removed underscore from allowed characters description
- Updated `register()` function signature and flow description
- Updated `REGISTER_ROLE` description to "when role check is enabled"

---

## Stats

**19 files changed, +275 lines, -1048 lines**
