# SystemRDL vs RgGen Gap Analysis

A comparison of SystemRDL 2.0 against RgGen ([wiki](https://github.com/rggen/rggen/wiki/Register-Map-Specifications)). This document organizes each SystemRDL feature by its handling policy in RgGen -- mapped, not supported, or already implemented -- as a reference for SystemRDL input support.

---

## 1. Already Supported in RgGen

SystemRDL concepts for which RgGen already provides equivalent or near-equivalent functionality. SystemRDL input can be mapped directly.

| SystemRDL Concept             | RgGen Equivalent                            | Notes                                                                                                                                       |
| ----------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `regfile` component           | `register_file`                             | Hierarchical grouping                                                                                                                       |
| `external reg`                | `external` register type                    | Single external register                                                                                                                    |
| `encode` (enumeration)        | `label`                                     | Named enumerated values                                                                                                                     |
| `counter` (basic)             | `counter` bit field type                    | RgGen has a counter type (up/down/clear). NOTE: SystemRDL conversion does not support it yet — the front-end (systemrdl elaborator) does not handle `counter`, so it is out of current scope.       |
| `swacc`                       | `rwtrg` / `rotrg` / `wotrg`                 | Read/write trigger outputs (via `swacc=true`). `swmod` has no faithful target → error. See matrix.                                          |
| `singlepulse`                 | `w1trg`                                     | Write-1 pulse. `w0trg` is not generated (singlepulse triggers on write-1). See matrix.                                                      |
| `errextbus`                   | Error input on `rggen_bus_if` (default)     | rggen_bus_if has an error input by default, so an explicit `errextbus` needs no action → ignored.                                           |
| Register arrays               | `size` + `step`                             | Multi-dimensional supported (front-end array flattening applies; see systemrdl_to_rggen_mapping.md)                                         |

---

## 2. Mapping Strategy for SystemRDL Bit Field Types

The detailed and authoritative mapping from SystemRDL field property combinations to RgGen bit
field types now lives in dedicated notes:

- [bit_field_type_matrix.md](bit_field_type_matrix.md) — the full decision matrix (every
  SystemRDL property column vs. each RgGen type), used as the converter's dispatch reference.
- [bit_field_type_mapping.md](bit_field_type_mapping.md) — a per-type migration guide describing
  each RgGen type's distinguishing properties and reference semantics.

Cross-cutting property policies and the full list of properties/structures that are rejected as
errors are in [systemrdl_to_rggen_mapping.md](systemrdl_to_rggen_mapping.md) (field layer).

---

## 3. Implementation Plan

Features for which an implementation plan or handling policy has been defined. Some are tracked as issues for future implementation; others have their handling policy documented in a separate notes file.

| Feature                                                                | Issue                                                | Status         |
| ---------------------------------------------------------------------- | ---------------------------------------------------- | -------------- |
| **Alias register type**                                                | rggen/rggen#287                                      | Filed          |
| **Interrupt support** (trigger extension + block-level aggregation)    | rggen/rggen#290                                      | Filed. NOTE: SystemRDL conversion does not support `intr` yet — front-end does not handle it, so out of current scope. |
| **External + child block reference**                                   | rggen/rggen#291                                      | Filed          |
| **Counter saturate/wrap boundary behavior** (spec-level specification) | rggen/rggen#292                                      | Filed          |
| **User-Defined Properties (UDP)**                                      | See [udp_handling_policy.md](udp_handling_policy.md) | Policy defined |
| **`precedence` property handling**                                     | See [precedence_handling_policy.md](precedence_handling_policy.md); conversion behavior summarized in [systemrdl_to_rggen_mapping.md](systemrdl_to_rggen_mapping.md) | Policy defined |

### Mapping Coverage by Issue

| SystemRDL Feature                       | Corresponding RgGen Extension                                                     |
| --------------------------------------- | --------------------------------------------------------------------------------- |
| `alias` keyword                         | rggen/rggen#287 alias register type                                               |
| `intr` field property + sticky variants | rggen/rggen#290 (existing `w1c` family + trigger + aggregation)                   |
| Trigger mode (level/edge)               | rggen/rggen#290 `trigger` option                                                  |
| Interrupt aggregation (OR output)       | rggen/rggen#290 block-level `interrupt` attribute                                 |
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

| Feature                                  | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Field overlap within a register (10.1 d) | RgGen does not have a mechanism to place multiple fields at overlapping bit positions within a register. The SystemRDL exception for read-only / write-only pairs is rejected (no `rowo`). See [systemrdl_to_rggen_mapping.md](systemrdl_to_rggen_mapping.md).                                                                                                                                                                                                                                                                                                                    |
| Register address not aligned to bus width | RgGen does not support placing a register at an address that is not a multiple of the configured bus width. The constraint `(address % bus_width) == 0` applies to every register, whether its address was assigned via `@` or by automatic allocation. |
| `sharedextbus`                           | Combines multiple external components into a single bus interface. RgGen has no feature to merge external interfaces, so the intent cannot be represented → rejected as error. See [systemrdl_to_rggen_mapping.md](systemrdl_to_rggen_mapping.md). |

### 5.3 Low Usage Frequency

| Feature                                            | Notes                                                                                                   |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `anded` / `ored` / `xored` (field-level reduction) | Rare in practice; no RgGen feature → rejected as error. Interrupt aggregation use case is covered by rggen/rggen#290 |
| `swmod` (as a standalone property)                 | No faithful RgGen target → rejected as error. (`swacc` IS supported: it drives `rwtrg`/`rotrg`/`wotrg`; see [bit_field_type_matrix.md](bit_field_type_matrix.md).) |
| `hwenable` / `hwmask` (bit-level HW write control) | Rare in practice; no RgGen feature → rejected as error. Per-bit control can be expressed by splitting into separate fields with `rwe`/`rwl` |
| `bridge` addrmap (multi-view)                      | Limited real-world use                                                                                  |
| `struct` definition and usage                      | Used only within SystemRDL source (UDP types, component parameters, struct members) and does not survive elaboration. Rare in practical CSR descriptions. |

Note: For `hwenable` / `hwmask`, equivalent semantics can be expressed using `rwe` / `rwl`.

### 5.4 High Parser Implementation Cost

| Feature                                                                                             | Notes                                                                                                                                                                                                                                                     |
| --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Preprocessor (Perl-embedded templates, Verilog-style `` `include `` / `` `define `` / `` `ifdef ``) | Implementing these in the SystemRDL parser carries a high cost, particularly for tracking token positions through template expansion to produce meaningful error messages. The core register modeling concern is far removed from preprocessor semantics. |

---

## 6. Architecturally Unnecessary

SystemRDL properties that exist because SystemRDL is a description language only, and have no role in RgGen's integrated spec + RTL/RAL generation architecture. Some are automatically resolved by RgGen's own mechanisms; others have no corresponding concept and are simply ignored.

| Feature                                              | RgGen Resolution                                                                                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `hdl_path` / `hdl_path_slice` / `hdl_path_gate` etc. | Automatically embedded during RAL generation, based on RgGen's own RTL hierarchy                                                  |
| `donttest` / `dontcompare` / `internal`              | Handled standardly on the RAL generation side                                                                                     |
| `name`                                               | Descriptive display name for documentation; RgGen has no corresponding concept and silently ignores the property                  |

**Input handling**: Silently discard (no warning needed). User-provided HDL paths would not match RgGen's generated RTL hierarchy anyway.
