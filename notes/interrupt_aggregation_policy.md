# Interrupt Aggregation and Port Generation Policy

This document records the implementation policy for how interrupt outputs are aggregated and exposed at module boundaries in generated RTL. The SystemRDL specification fixes register-level aggregation but is silent on how the resulting `intr`/`halt` outputs are surfaced at the boundary of `addrmap` modules. The choices below are implementation decisions and not behavior mandated by the specification.

## Scope

The decisions here govern the backend (RTL generator). The elaborator's responsibility is to produce the elaborated model in which `intr` fields, their `enable`/`mask` (and `haltenable`/`haltmask`) bindings, and the `next` connections among interrupt registers are all preserved. The behavior described below is how the backend then translates that model into module ports and aggregation logic.

## Register-Level Aggregation (Specification-Mandated)

SystemRDL 10.8 specifies that a register containing one or more `intr` fields implicitly has an `intr` register property representing the inclusive OR of all interrupt bits in the register after any field `enable`/`mask` logic. If `haltenable`/`haltmask` is specified on at least one field, the register also has a `halt` property representing the OR of those bits after haltenable/haltmask. The `intr` property is always present on an interrupt register (10.8.1 b); the `halt` property is present only when haltenable or haltmask exists (10.8.1 c). These are register-level outputs in the SystemRDL sense: they exist as values that the language permits to be referenced on the right-hand side of an assignment.

This document does not modify the register-level aggregation rule; it follows the specification.

## Boundary Port Exposure (Implementation Policy)

SystemRDL does not specify how a register's `intr`/`halt` output is realized at an `addrmap` module's HDL boundary. The specification merely makes the aggregated value a referenceable property; whether and how it becomes an external port is left to the implementation.

### Decision

For every register that has an `intr` output (and likewise for `halt`), the enclosing `addrmap` module exposes that register's `intr` output as a port on the module boundary. The same applies to `halt`. Aggregation stops at the register level; the `addrmap` module does not perform additional OR-reduction across multiple registers.

When an `addrmap` is instantiated inside another `addrmap`, the child `addrmap` is treated as an external component (per 13.4.1 c-4: "addrmap instances are always considered external"). The child module's per-register `intr`/`halt` ports appear on the parent's interface to the child instance. Aggregation across registers, or across child `addrmap` instances, is performed by user-written aggregation registers in the parent (the pattern shown in the specification's 17.2 example).

### Rationale

This policy keeps the backend's behavior close to what the specification actually says, without adding implementation-defined aggregation rules:

- The specification defines aggregation only at the register level. Per-register boundary exposure preserves that granularity; aggregating further at the `addrmap` level would introduce an `intr`/`halt` semantics that the specification does not describe.
- Typical CSR designs have only a small number of interrupt registers per `addrmap`, so the per-register port count is manageable in practice and does not produce unwieldy module interfaces.
- Per-register ports allow multiple categories of interrupts (e.g. priority levels, error vs. event, distinct CPU targets) to be exposed independently. An `addrmap`-level aggregated port would be limited to a single `intr` and a single `halt`, constraining the designer to that one categorization.
- Hierarchical aggregation through nested `addrmap`s is consistent with how SystemRDL itself handles cross-block interrupt aggregation: by user-written aggregation registers connecting lower-level `intr` outputs via `next`. The boundary behavior chosen here lines up with that pattern: each register's `intr` is available as a port; aggregation across registers (whether within an `addrmap` or across `addrmap`s) is the user's responsibility, expressed via aggregation registers and `next` references.

### Status

The register-level aggregation (10.8) is specification-mandated and is followed. The boundary exposure policy -- per-register ports, no `addrmap`-level aggregation -- is an implementation choice that the specification does not constrain. Other tools may make different choices (for example, exposing only the top-level aggregated output, or providing both per-register and `addrmap`-level outputs). Behavior may therefore differ across tools at the boundary, even when the SystemRDL input is the same.

If a use case requires `addrmap`-level aggregation in addition to per-register exposure, this policy can be extended without contradicting the specification, because the specification does not forbid additional `addrmap`-level outputs; it simply does not require them.

## Final Interrupt Pin to the Outside

The SystemRDL specification does not describe how a chip-level interrupt pin is produced from the per-register `intr` outputs. Within a SystemRDL design, the only mechanism for combining interrupts across registers is the user-written aggregation register (see 17.2 example).

Under this policy, the final external interrupt pin is the `intr` port of a register that aggregates the relevant lower-level `intr` signals via `next`. When that register is contained directly in the top-level `addrmap`, its `intr` port appears on the top-level module's boundary and constitutes the chip-level interrupt output. There is no separate "top-level interrupt pin" mechanism; the final pin is simply a register-level `intr` port on the top module, just like any other register's `intr` port.

## Comparison with Other Implementations

PeakRDL-regblock follows the same register-level boundary policy described above (per-register `intr`/`halt` outputs at the module boundary; no `addrmap`-level aggregation). This is the most direct reading of the specification and tends to be the convergent choice across implementations that prioritize specification fidelity.

Implementations that perform `addrmap`-level aggregation, or that expose only a single top-level interrupt port, exist in some tools as a generation option, but they go beyond what the specification describes.
