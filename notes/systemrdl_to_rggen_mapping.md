# SystemRDL → RgGen Mapping: Design Notes

This document records confirmed design decisions for the SystemRDL front-end to RgGen
register-map conversion. The SystemRDL support is an add-on feature; perfect coverage is a
non-goal. Deferred / not-yet-supported items are tracked separately in `systemrdl_to_rggen_TODO.md`.

## Scope
- Root `addrmap` → RgGen register_block
- `regfile` → RgGen register_file
- `reg` → RgGen register
- `field` → RgGen bit_field
- External `reg`/`regfile` and nested `addrmap` → RgGen `external` region on the enclosing map,
  plus a separately-converted register_block (see "External components" below).

## Layer correspondence

| SystemRDL              | RgGen                          |
| ---------------------- | ------------------------------ |
| root `addrmap`         | register_block                 |
| `regfile`              | register_file                  |
| `reg`                  | register                       |
| `field`                | bit_field                      |
| nested `addrmap`       | `external` region + its own register_block |
| external `reg`/`regfile` | `external` region + its own register_block |

## Array handling & name conversion
- `reg`, `regfile`, and `addrmap` can be arrays. **`field` is never an array**: in a
  field declaration `foo[4]` specifies bit WIDTH (and `foo[7:0]` specifies msb:lsb), NOT an array
  subscript. So the flatten/`__`-subscript handling below does not apply to fields; a field's
  `[...]` maps to bit_assignment `lsb`/`width` instead (see field layer).
- Arrays are flattened into individual elements. No reconstruction back into RgGen
  `size` / `sequence_size`.
- Subscripts are rendered into the name with a double-underscore `__` separator:
  - `foo[0]` → `foo__0`
  - multi-dimensional `foo[1][0]` → `foo__1__0` (all dimensions use `__`, consistently)
- The same `__` separator is used to join hierarchy levels when a nested subtree is carved out as
  its own register_block (see "External components" below): the carved-out block name is the
  ancestor instance names joined with `__` (e.g. regfile `foo[2]` containing external reg `bar`
  → `foo__0__bar`).
- Conversion-time validation: any SystemRDL instance name (all layers, arrayed or not) that
  itself contains `__` is an ERROR. This reserves `__` exclusively as the array-expansion /
  hierarchy-join separator, eliminating name-collision ambiguity at its root (rather than merely
  lowering collision probability).
  - SystemRDL lexical rules (spec 5.1.1) permit `__` in identifiers; this restriction is an
    extra constraint imposed only when using the RgGen-conversion add-on feature.
- Post-conversion duplicate-name detection is delegated to RgGen's existing validation; the
  converter does NOT re-implement duplicate checking.

## addrmap (root) → register_block

| RgGen register_block | SystemRDL addrmap        | Conversion / notes |
| -------------------- | ------------------------ | ------------------ |
| `name`               | instance name (`name`)   | Apply `__` restriction check. Root addrmap is non-arrayed, so no subscript conversion normally. |
| `byte_size`          | addrmap occupied size    | Uses the occupied-size value provided by the gem directly (front-end fix requested; see feedback). The converter does not compute it from child placement. |
| `bus_width`          | —                        | No corresponding concept in SystemRDL. Not mapped; deferred to RgGen config. |
| `protocol`           | —                        | No corresponding concept in SystemRDL. Not mapped; deferred to RgGen config. |
| `comment`            | `desc` property          | Used directly. `display_name` (SystemRDL `name` property) is a short label, not used for comment. |

### addrmap: properties that cause an ERROR
These SystemRDL properties have no corresponding concept in RgGen. If encountered, the converter
errors out rather than silently ignoring them (silent drop would change the design intent).
- `sharedextbus` — combines multiple external components into a single bus interface (creates a
  single set of control signals for the whole addrmap instead of per-component). Only meaningful
  when the addrmap contains external components. This is about external-component bus-interface
  generation, NOT the 13.5 multiple-view/bridge feature. RgGen has no feature to combine external
  interfaces into one, so this is a **permanent ERROR** (independent of the external-scope
  decision): even once external components are supported, RgGen still cannot merge their
  interfaces, so `sharedextbus` remains unsupported.
- bridge / multiple-view related properties (spec 13.5) in general — e.g. `bridge`. No RgGen concept.
- `bigendian` / `littleendian` — ERROR if either is explicitly true. Even `littleendian` is an
  error: although RgGen is also little-endian, its word-placement model for registers spanning
  multiple words differs from SystemRDL 17.3.2 (Byte ordering), so passing `littleendian` through
  by name would misplace words. If neither is specified, pass through using RgGen's default
  (little-endian).
  - Residual caveat: for registers that span multiple words (`regwidth > accesswidth`), the
    word-placement model differs from SystemRDL 17.3.2 (Byte ordering). This difference is a
    confirmed property of the conversion, not a maybe. The converter does NOT detect or correct
    it; instead, the README states this word-ordering difference as a documented limitation of
    the add-on conversion.
- `rsvdset` / `rsvdsetX` — control the read value of reserved / unassigned regions (whether
  unassigned bits read as 1, or as X/undefined). RgGen has no mechanism to specify the read value
  of unassigned regions, so there is nowhere to map these. ERROR if set.

### addrmap: properties that are IGNORED (safe to drop)
- `errextbus` — indicates the (external) addrmap instance has an error input. RgGen's
  `rggen_bus_if` has an error input by default, so RgGen always satisfies the `errextbus`
  behavior. Ignoring the property therefore does not lose design intent (unlike the error-listed
  properties above).
- `accesswidth` — IGNORED. RgGen derives access width from its `bus_width` (RgGen config, not
  mapped from SystemRDL). Safe to ignore: if `accesswidth` disagrees with `bus_width`, the
  resulting addresses violate RgGen's `address % bus_width == 0` rule and are caught by the later
  address check.

## reg → register

| RgGen register   | SystemRDL reg           | Conversion / notes |
| ---------------- | ----------------------- | ------------------ |
| `name`           | instance name (`name`)  | Apply `__` restriction check; arrayed regs are flattened with `__` subscript conversion into individual registers. |
| `offset_address` | `address` property      | Direct copy. Both RgGen `offset_address` and SystemRDL `address` are offsets from the block start, so they coincide and `address` is used as-is. |
| `size`           | (basically unused)      | Arrays are flattened, so repetition `size` is not used. First release: single element. |
| `type`           | (fixed `default`)       | Normal regs map to `default`. See register-type notes below. |
| `comment`        | `desc` property         | Used directly. |

### register-type notes
- `default` — normal reg. Supported (fixed for first release).
- `external` — an external `reg` (`Reg#external` = true) is carved out into an `external` region
  plus its own register_block; see the "External components" section. (SystemRDL `mem` would also
  land here but is not yet in scope.)
- `indirect` — **permanently not applicable.** RgGen `indirect` multiplexes multiple registers
  at one address, selected by index bit fields. SystemRDL has NO indirect-access mechanism, and
  SystemRDL `alias` is a DIFFERENT concept (a second name/address onto the same storage, not
  index-based multiplexing). `indirect` can therefore never be produced by the conversion.
- `reserved` / `maskable` / `rw` — SystemRDL-side trigger for these is TBD; not used in first release.

### reg: properties that cause an ERROR
These SystemRDL reg properties have no corresponding concept in RgGen. If encountered, the
converter errors out rather than silently ignoring them.
- `shared` — shared component (spec 13.5, bridges / multiple-view address maps). RgGen has a
  single-address-space-per-block model with no multiple-view/shared-storage concept, so there is
  nowhere to map this. Even once the front-end supports it, the converter must error.

### reg: properties that are IGNORED (safe to drop)
- `errextbus` — indicates the (external) regfile has an error input. Same rationale as the
  addrmap `errextbus`: RgGen's `rggen_bus_if` has an error input by default, so ignoring it loses
  no design intent.
- `accesswidth` — IGNORED (same rationale as addrmap: bus_width is RgGen config; a mismatch is
  caught by the later `address % bus_width == 0` check).

## regfile → register_file

| RgGen register_file | SystemRDL regfile        | Conversion / notes |
| ------------------- | ------------------------ | ------------------ |
| `name`              | instance name (`name`)   | Apply `__` restriction check; arrayed regfiles are flattened with `__` subscript conversion. |
| `offset_address`    | `address` property       | Direct copy (offset from the parent). |
| `size`              | (not used)               | Arrays are flattened, so repetition `size` is not used. |
| `comment`           | `desc` property          | Used directly. |

### regfile: properties handled like addrmap/reg
- `sharedextbus` — ERROR (no RgGen feature to merge external interfaces; same as addrmap).
- `errextbus` — IGNORED (rggen_bus_if has an error input by default; same as addrmap/reg).
- `accesswidth` — IGNORED (same as addrmap/reg; bus_width is RgGen config, mismatch caught by the address check).
- `external` — an external regfile is carved out; see the "External components" section below.

## field → bit_field

Bit positions are resolved by the front-end during elaboration, so the model's `msb` / `lsb`
give the final positions.

| RgGen bit_field                  | SystemRDL field         | Conversion / notes |
| -------------------------------- | ----------------------- | ------------------ |
| `name`                           | instance name (`name`)  | Apply `__` restriction check. No subscript conversion (fields are not arrays). |
| `bit_assignment` `lsb`           | `lsb`                   | Direct copy (front-end-assigned). |
| `bit_assignment` `width`         | field width (model accessor) | Use a `width` accessor on the model (front-end fix requested; see feedback) rather than computing `msb - lsb + 1` on the converter side. |
| `bit_assignment` `sequence_size` / `step` | —              | Not used; fields are not arrays. |
| `initial_value`                  | `reset` property        | Maps the reset value (constant only). If `reset` is absent, `initial_value` is left unset — the converter does NOT substitute 0; RgGen's own validation errors if a type that requires an initial value has none. A `reset` given as a reference (to another field) is unsupported → ERROR. A user-defined `resetsignal` is unsupported → ERROR. See field error list below. |
| `type`                           | (sw/hw/onread/onwrite/hwset/hwclr/swwe/swwel/we/swacc/singlepulse/… combination) | Main conversion. See `bit_field_type_mapping.md` for the full RgGen-type ← SystemRDL-property table and the cross-cutting property policies. |
| `reference`                      | instance reference (e.g. `next`, swwe/swwel/hwclr/hwset target) | Only SystemRDL **instance** references map to RgGen `reference`. **Property** references → ERROR. Mask-purpose references (`rc`/`w0c`/`w1c`/`wc`) are not specifiable from SystemRDL. See `bit_field_type_mapping.md`. |
| `comment`                        | `desc` property         | Used directly. |

### field: properties / values that cause an ERROR
- `reset` given as a **reference** (to another field's value) rather than a constant — RgGen
  `initial_value` accepts a constant value only and has no dynamic/reference reset, so a
  reference reset cannot be represented. ERROR.
- `resetsignal` (user-defined reset signal) — RgGen does not support user-defined reset signals,
  so specifying `resetsignal` is unsupported. ERROR.
- Properties/values with no corresponding RgGen feature — ERROR if used: `wel`, `swmod`, `anded`,
  `ored`, `xored`, `hwenable`, `hwmask`, `paritycheck`, `ruser` (onread=ruser),
  `wuser` (onwrite=wuser), and `hw = rw1` / `hw = w1` (hardware-side write-once).
- Property reference used anywhere — ERROR. SystemRDL references come in two kinds: instance
  references and property references (e.g. `other->prop`). RgGen supports instance references
  only. (Applies wherever a reference is used: `ro`/next, rwl/rwe swwe/swwel, rwc/rws hwclr/hwset,
  etc.)
- Combinations that fit no named RgGen type — ERROR in the first release (`custom` is not used
  yet; see `bit_field_type_mapping.md`).
- Bit-field overlap — two or more fields at the same bit position in a register (SystemRDL allows
  this when read/write are mutually exclusive) — ERROR. RgGen has no merged read-only+write-only
  field (`rowo` is not supported).

### field: precedence handling
Handled per a project-level "precedence ignore mode" flag (see rggen/rggen-systemrdl
`notes/precedence_handling_policy.md`). RgGen fixes hardware precedence; the SystemRDL default is
`sw`. The flag is set via RgGen configuration, not per-field/per-register.
- Ignore mode OFF (default): field with effective `precedence=sw` → ERROR; `precedence=hw` →
  accepted. (Elaboration cannot tell an explicit value from a defaulted one, so `sw` is rejected
  regardless; users set `default precedence = hw;` at a scope.)
- Ignore mode ON: `precedence` is not consulted; all fields generated with hw precedence, no
  diagnostic.

## External components (external reg / external regfile / nested addrmap)

Three kinds of subtree represent an independent implementation boundary and are all handled the
same way:
- an external `reg` (`Reg#external` = true),
- an external `regfile` (`RegFile#external` = true),
- a nested (non-root) `addrmap` instance. (`AddrMap` has no `external` property; external/internal
  does not apply to an addrmap itself, so the trigger here is structural: any addrmap below the
  root counts.)

Each such subtree produces TWO outputs:
1. On the enclosing map, reserve its address region as an RgGen `external` register. Its `address`
   and `size` come from the model (`address`/`size`).
2. Separately, convert the subtree as its OWN register_block, by running the normal register_block
   conversion with the subtree as the entry point. This is what lets RgGen actually generate the
   contents — RgGen cannot generate at reg/regfile granularity, so the contents must be wrapped in
   a register_block.

Rules for the carved-out register_block:
- Name: the ancestor instance names joined with `__` (e.g. regfile `foo[2]` containing external
  reg `bar` → `foo__0__bar`). Array subscripts also use `__`, so the separator is uniform.
- Addresses inside the carved-out block are re-based to a 0 offset (it is an independent map).
- `bridge` is NOT part of the trigger; it only indicates whether the external boundary involves
  bus/protocol conversion.

