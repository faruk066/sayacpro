# Lessons Learned

## 1. M-Bus E5 (ACK) Handling in Industrial Settings
**Pattern to avoid:** Treating standard M-Bus handshake signals (like E5 / ACK) as strict requirements to proceed.
**Rule:** When implementing industrial communication protocols, ALWAYS assume target devices (like Calmet meters) might drop the ACK frame due to sleep states or hardware constraints. Do not use `return false;`, `continue;`, or any abort mechanism based on a missing ACK unless explicitly requested. Always force the actual command (e.g., Read `7B`) and rely solely on the data response timeout as the final failure condition.

## 2. `audioplayers` Package Version Compatibility
**Pattern to avoid:** Using advanced or version-specific enum members like `PlayerMode.media` or `PlayerMode.lowLatency` without verifying the project's specific package version.
**Rule:** When using `audioplayers`, keep the `play()` calls as simple as possible (avoid the `mode` parameter) unless a specific mode is strictly required by the user or the implementation logic. This prevents "Member not found" compilation errors due to package version mismatches.
