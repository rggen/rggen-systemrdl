# SystemRDL → RgGen Mapping: Design Notes

This document records confirmed design decisions for the SystemRDL front-end to RgGen
register-map conversion. The SystemRDL support is an add-on feature; perfect coverage is a
non-goal. Deferred / not-yet-supported items are tracked separately in `systemrdl_to_rggen_TODO.md`.

## Scope
- Root `addrmap` → RgGen register_block
- `regfile` → RgGen register_file
- `reg` → RgGen register
- `field` → RgGen bit_field
- Nested `addrmap` → RgGen `external` region on the enclosing map; the addrmap is also converted
  to its own register_block through the normal flow (see "External components" below).
- External `reg`/`regfile` → ERROR in the first release (deferred; see "External components").
- `mem` → RgGen `external` register (region reservation only; see "mem" below).

## Layer correspondence

| SystemRDL              | RgGen                          |
| ---------------------- | ------------------------------ |
| root `addrmap`         | register_block                 |
| `regfile`              | register_file                  |
| `reg`                  | register                       |
| `field`                | bit_field                      |
| nested `addrmap`       | `external` region + its own register_block |
| external `reg`/`regfile` | ERROR (first release; deferred)          |
| `mem`                  | `external` register (region reservation only) |

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
- Conversion-time validation: any SystemRDL instance name (all layers, arrayed or not) that
  itself contains `__` is an ERROR. This reserves `__` exclusively as the array-expansion
  separator, eliminating name-collision ambiguity at its root (rather than merely
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
- `msb0` — ERROR if set (true). `msb0` reverses bit numbering so that `regwidth-1` is the least
  significant bit (spec 13.4.1), the opposite of the default `lsb0` mode. RgGen assumes `lsb0`
  numbering; under `msb0` the field `lsb`/`msb` positions would be interpreted in reverse and
  would be misplaced, so the mode cannot be represented. (`lsb0` is the default and needs no
  action; it is not an error. `msb0` and `lsb0` are mutually exclusive per spec 13.4.1.)
  Inference of `msb0` from the first field's explicit bit indices (spec 13.4.2) is unsupported by
  the front-end, so only an explicitly set `msb0` property reaches the converter.

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
- `external` — an external `reg` (`Reg#external` = true) is NOT supported in the first release →
  ERROR. See the "External components" section (deferred design in `external_reg_regfile_mapping.md`).
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
- `external` — an external regfile is NOT supported in the first release → ERROR. See the
  "External components" section (deferred design in `external_reg_regfile_mapping.md`).

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

## External components

### Nested addrmap → external region

A nested (non-root) `addrmap` instance represents an independent implementation boundary.
(`AddrMap` has no `external` property; external/internal does not apply to an addrmap itself, so
the trigger is structural: any addrmap below the root counts.)

For a nested addrmap, the only thing this conversion does is reserve its address region on the
enclosing map as an RgGen `external` register (its `address`/`size` come from the model).

The addrmap's own contents do NOT need a special carve-out step here: an addrmap is itself an RTL
generation unit with its own definition, so running that definition through the normal
register_block conversion (the same path used for the root addrmap) produces its register_block.

`bridge` is NOT part of the trigger; it only indicates whether the external boundary involves
bus/protocol conversion.

### External reg / external regfile → ERROR (first release)

An external `reg` (`Reg#external` = true) and an external `regfile` (`RegFile#external` = true)
are NOT supported in the first release and are ERRORs. Silently dropping them would lose design
intent, so the converter errors out rather than ignoring the external boundary.

The conversion scheme worked out for them — reserve the region on the enclosing map and wrap the
contents in a separately-converted register_block (RgGen cannot generate at reg/regfile
granularity, so the wrapping is required) — is recorded separately in
`external_reg_regfile_mapping.md` for when the feature is picked up later.


## mem → external register

A SystemRDL `mem` is mapped to an RgGen `external` register. `external` is exactly the RgGen
construct intended for this purpose: it reserves an address region whose contents are provided by
a user implementation. The memory contents are therefore not generated by RgGen (and not by the
converter); the converter only reserves the region.

Because the contents are a user implementation, a `mem` is NOT handled like the "External
components" above: it produces no carved-out register_block, only the region reservation on the
enclosing map.

| RgGen external | SystemRDL mem          | Conversion / notes |
| -------------- | ---------------------- | ------------------ |
| `name`         | instance name (`name`) | Apply `__` restriction check; arrayed mems are flattened with `__` subscript conversion. |
| `offset_address` | `address` property   | Direct copy (offset from the parent), same as reg/regfile. |
| `size`         | model `size` (byte size), converted | Element count in `bus_width` units; see below. |
| `comment`      | `desc` property        | Used directly. |

### mem: size calculation
RgGen's `external` `size` is an element count expressed in `bus_width` units (how many
`bus_width`-wide accesses the region occupies), NOT a byte size. The front-end already provides
the mem's occupied byte size as the model's `size`, so the converter does not compute it from
`memwidth`/`mementries`; it only converts that byte size into `bus_width` units:

```
size = byte_size / (bus_width / 8)
```

where `byte_size` is the model's `size` (the front-end computes it from `entry_width` — `memwidth`
rounded up to a power-of-two number of bits — times `mementries`).

- `bus_width` is an RgGen config value, not taken from SystemRDL (same policy as `accesswidth`,
  which is IGNORED elsewhere).
- If `byte_size` is not an integer multiple of `bus_width / 8`, the region cannot be expressed as
  a whole number of `bus_width`-wide elements → ERROR.

