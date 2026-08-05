# SystemRDL → RgGen Mapping: TODO

Not-yet-supported / deferred items. Confirmed design decisions live in
`systemrdl_to_rggen_mapping.md`.

## Deferred

### SystemRDL `alias` handling (scope decision)
- RgGen `alias` register support is tracked in rggen/rggen#287. The original proposal there
  includes field-level attribute overrides (N:1 decoder-to-bitfield connection, per-field access
  attribute arrays).
- Current stance: full support is not worth the RTL-generation complexity. If implemented at all,
  scope is limited to address multiplexing and register-level r/w switching only. Field-level
  attribute re-assignment will NOT be done.
- Consequence for SystemRDL conversion: SystemRDL `alias` per spec 10.5.1 rule (e) allows
  per-field overrides of `sw`/`onread`/`onwrite`/`rclr`/`rset`/`woclr`/`woset`. Because the
  intended RgGen scope stops at register-level r/w, SystemRDL alias inputs that vary attributes
  per field cannot be fully represented → such inputs are out of scope (not supported / not
  losslessly convertible). Note this is separate from RgGen `indirect`, which is permanently
  not applicable (see mapping notes).

## Open dependencies

### `counter` / `intr` field types
- SystemRDL has `counter` and `intr`, but the front-end does not support them yet → out of
  first-release scope. The RgGen target type is deferred (not decided now); record only as
  "unsupported, front-end does not support them yet".

### `custom` bit_field type (held)
- First release does not use RgGen `custom`. Property combinations that fit no named RgGen type
  are errors in v1. Using `custom` to catch such combinations is possible but the verification
  cost (confirming each combination is faithfully representable) is too high for v1 → future work.


