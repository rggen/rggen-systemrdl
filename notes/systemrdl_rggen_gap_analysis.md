# SystemRDL vs RgGen Gap Analysis

A comparison of SystemRDL 2.0 against RgGen ([wiki](https://github.com/rggen/rggen/wiki/Register-Map-Specifications)). This document organizes each SystemRDL feature by its handling policy in RgGen -- mapped, not supported, or already implemented -- as a reference for SystemRDL input support.

---

## 1. Already Supported in RgGen

SystemRDL concepts for which RgGen already provides equivalent or near-equivalent functionality. SystemRDL input can be mapped directly.

| SystemRDL Concept             | RgGen Equivalent                            | Notes                                                                                     |
| ----------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `regfile` component           | `register_file`                             | Hierarchical grouping                                                                     |
| `external reg`                | `external` register type                    | Single external register                                                                  |
| `encode` (enumeration)        | `label`                                     | Named enumerated values                                                                   |
| `counter` (basic)             | `counter` bit field type                    | Supports up/down/clear                                                                    |
| `swacc`/`swmod` (approximate) | `rwtrg` / `rotrg` / `wotrg`                 | Read/write trigger outputs                                                                |
| `singlepulse` (approximate)   | `w0trg` / `w1trg`                           | Pulse-like trigger outputs                                                                |
| `errextbus`                   | External bus interface `i_xxx_status` input | Error response from external implementation propagates through the existing status signal |
| Register arrays               | `size` + `step`                             | Multi-dimensional supported                                                               |
| Register overlap (10.1 h)     | Overlaid register pair                      | RgGen supports two registers at the same address when one is read-only and the other is write-only (or write-once-only) |

---

## 2. Mapping Strategy for SystemRDL Bit Field Types

Guidelines for mapping SystemRDL's `sw` / `hw` / `onread` / `onwrite` combinations to RgGen bit field types.

### Base Types

| SystemRDL (sw, hw, onread/onwrite) | RgGen Type                                              |
| ---------------------------------- | ------------------------------------------------------- |
| sw=rw, hw=r                        | `rw`                                                    |
| sw=r, hw=rw                        | `ro` (or `rohw` if dynamic HW update)                   |
| sw=r, hw=r, constant               | `rof` (fixed via `initial_value`)                       |
| sw=w, hw=r                         | `wo`                                                    |
| sw=rw, hw=rw + valid               | `rwhw`                                                  |
| sw=r, hw=w + valid                 | `rohw`                                                  |
| onwrite=woclr                      | `w0c`                                                   |
| onwrite=woset                      | `w0s`                                                   |
| onwrite=wzc                        | `w1c`                                                   |
| onwrite=wzs                        | `w1s`                                                   |
| onwrite=wclr                       | `wc` / `woc`                                            |
| onwrite=wset                       | `ws` / `wos`                                            |
| onwrite=wzt                        | `w0t` / `w1t`                                           |
| onread=rclr                        | `rc`                                                    |
| onread=rset                        | `rs`                                                    |
| sw=rw + write-once                 | `w1` / `wo1`                                            |
| Combined (W1C+RS, etc.)            | `w0crs` / `w1crs` / `wcrs` / `w0src` / `w1src` / `wsrc` |

### Modifiers

| SystemRDL Property                    | RgGen Equivalent                         |
| ------------------------------------- | ---------------------------------------- |
| `we` / `wel` (SW write enable / lock) | `rwe` / `rwl`                            |
| `hwclr` / `hwset`                     | `rwc` / `rws`                            |
| `next` (input source reference)       | Option on `ro` type; the referenced field/signal supplies the field value |
| `reset` value                         | `initial_value`                          |
| `reference`                           | `reference` (purpose determined by type) |

---

## 3. To Be Implemented

Features present in SystemRDL but missing from RgGen, with clear implementation value.

| Feature                                                                | Issue                                             | Status |
| ---------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| **Alias register type**                                                | [#287](https://github.com/rggen/rggen/issues/287) | Filed  |
| **Interrupt support** (trigger extension + block-level aggregation)    | [#290](https://github.com/rggen/rggen/issues/290) | Filed  |
| **External + child block reference**                                   | [#291](https://github.com/rggen/rggen/issues/291) | Filed  |
| **Counter saturate/wrap boundary behavior** (spec-level specification) | [#292](https://github.com/rggen/rggen/issues/292) | Filed  |
| **User-Defined Properties (UDP)**                                      | See [udp_handling_policy.md](udp_handling_policy.md) | Policy defined |

### Mapping Coverage by Issue

| SystemRDL Feature                       | Corresponding RgGen Extension                                                     |
| --------------------------------------- | --------------------------------------------------------------------------------- |
| `alias` keyword                         | #287 alias register type                                                          |
| `intr` field property + sticky variants | #290 (existing `w1c` family + trigger + aggregation)                              |
| Trigger mode (level/edge)               | #290 `trigger` option                                                             |
| Interrupt aggregation (OR output)       | #290 block-level `interrupt` attribute                                            |
| `external regfile { ... }`              | External + child block reference                                                  |
| `mem` component                         | External + child block reference (mementries x memwidth normalized to byte_size)  |
| `incrsaturate` / `decrsaturate`         | Counter saturate/wrap boundary behavior (this feature)                            |

---

## 4. Resolved on the SystemRDL Parser / Elaborator Side

Language constructs that exist in SystemRDL but are resolved at elaboration time. By the time data reaches the RgGen internal model, these are already materialized, so RgGen DSL does not need equivalent mechanisms.

| SystemRDL Feature                                                                                             | Resolution Strategy                                  |
| ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `default` keyword scope inheritance                                                                           | Expanded to each field during elaboration            |
| Dynamic property assignment (`inst->prop = value;`)                                                           | Final values resolved during elaboration             |
| Parameterized components (`#(WIDTH = 8)`)                                                                     | Instantiated with concrete values during elaboration |
| Addressing (`@` explicit address, `%=` alignment, `alignment` property, compact / regalign / fullalign modes) | Concrete addresses finalized during elaboration      |
| Mixed anonymous/named definitions                                                                             | Uniquified during elaboration                        |

---

## 5. Not Supported

Features that exist in SystemRDL but are deliberately not supported in RgGen. **All items in this section are rejected with an explicit error during SystemRDL input processing.**

### 5.1 Out of Scope (Beyond CSR Tool Responsibility)

| Feature                                                     | Reason                                                                                                                                                                                                                                                                                                           |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `signal` component                                          | RgGen does not have a first-class signal concept. HW access properties (`we`, `wel`, `hwclr`, `hwset`, `swwe`, `swwel`, etc.) can be expressed via the boolean form (auto-generated external ports) or field references (internal control), covering practical use cases without an explicit signal declaration. |
| Reset signals (`resetsignal`, `field_reset`, `cpuif_reset`) | Uniformly rejected. RgGen targets a single reset domain (`i_rst_n`); supporting signal-based reset specifications would entail multiple reset domains and the associated RDC (Reset Domain Crossing) analysis, which is beyond CSR tool scope. Only constant reset values via `initial_value` are supported.     |
| Counter `overflow` / `underflow` output                     | HW-to-HW event signals, outside CSR domain                                                                                                                                                                                                                                                                       |
| Counter `incrthreshold` / `decrthreshold`                   | Same as above                                                                                                                                                                                                                                                                                                    |
| `constraint` block                                          | Verification-specific syntax with limited demand                                                                                                                                                                                                                                                                 |

### 5.2 No Corresponding Feature

| Feature                                  | Notes                                                                                                                                                                          |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Field overlap within a register (10.1 d) | RgGen does not have a mechanism to place multiple fields at overlapping bit positions within a register. The SystemRDL exception for read-only / write-only pairs is rejected. |
| `precedence` (10.6.1 b, 9.10)            | RgGen fixes hardware-side precedence in all field types (software writes are inherently retryable by the host, so hardware precedence is the safer default). The SystemRDL default of `precedence = sw` (9.10 a-1) is the opposite of RgGen's behavior, so accepting a field without an explicit `precedence` would silently invert the semantics. The user is therefore required to make the intent explicit by setting `precedence = hw` -- typically via `default precedence = hw;` at the addrmap or register scope. Any effective value of `sw` (whether by omission or by explicit `precedence = sw`) is an error. |

### 5.3 Low Usage Frequency

| Feature                                            | Notes                                                                                                                                                                                                                                                                                                           |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `anded` / `ored` / `xored` (field-level reduction) | Rare in practice; interrupt aggregation use case is covered by #290                                                                                                                                                                                                                                             |
| `swacc` / `swmod` (as standalone properties)       | Approximate functionality covered by `rwtrg`/`rotrg`/`wotrg`; demand for orthogonal combinations is low                                                                                                                                                                                                         |
| `hwenable` / `hwmask` (bit-level HW write control) | Rare in practice; per-bit control can be expressed by splitting into separate fields with `rwe`/`rwl`                                                                                                                                                                                                           |
| `bridge` addrmap (multi-view)                      | Limited real-world use                                                                                                                                                                                                                                                                                          |

Note: For `hwenable` / `hwmask`, equivalent semantics can be expressed using `rwe` / `rwl`.

### 5.4 High Parser Implementation Cost

| Feature                                                                                             | Notes                                                                                                                                                                                                                                                     |
| --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Preprocessor (Perl-embedded templates, Verilog-style `` `include `` / `` `define `` / `` `ifdef ``) | Implementing these in the SystemRDL parser carries a high cost, particularly for tracking token positions through template expansion to produce meaningful error messages. The core register modeling concern is far removed from preprocessor semantics. |

---

## 6. Architecturally Unnecessary

SystemRDL properties that exist because SystemRDL is a description language only, but which are automatically resolved by RgGen's integrated spec + RTL/RAL generation architecture.

| Feature                                              | RgGen Resolution                                                                                                                 |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `hdl_path` / `hdl_path_slice` / `hdl_path_gate` etc. | Automatically embedded during RAL generation, based on RgGen's own RTL hierarchy                                                 |
| `donttest` / `dontcompare` / `internal`              | Handled standardly on the RAL generation side                                                                                    |
| `sharedextbus`                                       | How external modules are wired up is left to the user; the property has no meaningful interpretation in RgGen's generation model |

**Input handling**: Silently discard (no warning needed). User-provided HDL paths would not match RgGen's generated RTL hierarchy anyway.
