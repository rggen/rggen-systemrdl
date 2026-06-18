# Precedence Handling Policy

This document records how RgGen handles the SystemRDL `precedence` property, which is silent on the spec's part regarding its compatibility with implementations that fix software/hardware precedence rather than making it per-field configurable.

## Background

SystemRDL defines the `precedence` field property (clause 9.10) to control which side wins when software and hardware attempt to write the same field on the same cycle:

- `precedence = sw` (the default) -- software takes precedence over hardware.
- `precedence = hw` -- hardware takes precedence over software.

RgGen, by contrast, fixes hardware-side precedence in all field types. The rationale is that software writes are inherently retryable by the host -- the host can read the field back and re-issue the write if it sees the value did not stick -- whereas hardware writes typically signal a time-sensitive event (an error capture, a completion notification, a state transition) that has no comparable retry mechanism. Granting hardware precedence is therefore the safer default: the side that cannot easily recover from being overwritten is the side that wins.

This creates a mismatch between the SystemRDL default (`sw`) and RgGen's fixed behavior (`hw`). A SystemRDL file that omits `precedence` is, by the spec's default, requesting software precedence -- the opposite of what RgGen will actually produce. Silently accepting such input would invert the field's semantics without notice.

A further complication: by the time SystemRDL elaboration completes, the origin of a property value -- whether it was written explicitly by the user or filled in from the default -- is generally lost. The elaborated model only carries the final value. RgGen therefore cannot distinguish "the user wrote `precedence = sw`" from "the user omitted `precedence` and the default of `sw` was applied"; both reach the backend as `precedence = sw`.

This rules out any policy that depends on telling explicit and defaulted values apart. The handling must work purely from the effective value as it appears in the elaborated model.

## Solution: A `precedence` Ignore Mode

RgGen introduces a configuration flag, the `precedence` ignore mode, that selects between two behaviors. The flag is set at the project level via RgGen configuration; it is not a SystemRDL property and cannot be changed per-field or per-register.

### Ignore Mode On

The `precedence` property is treated as something RgGen does not implement. The elaborated value of `precedence` on each field is simply not consulted by the RtL generator; every field is generated with hardware precedence regardless of what its `precedence` value happens to be.

No diagnostic is emitted. A SystemRDL file may contain `precedence = sw`, `precedence = hw`, or omit the property entirely; in all cases the generated RTL is the same.

This mode silently sets aside whatever the SystemRDL source requests via `precedence`. It is therefore not the default: making the silent override the default would build a hidden inversion of semantics into the standard behavior. Users select this mode explicitly when they accept that trade-off in exchange for being able to process SystemRDL files that omit `precedence` without further annotation.

### Ignore Mode Off (Default)

The elaborated value of `precedence` is checked on every field. If it is `sw`, the field is rejected as an error; if it is `hw`, it is accepted.

Because elaboration cannot distinguish an explicit value from a defaulted one, this mode rejects every field whose `precedence` is `sw` for any reason, including fields where the user simply omitted the property. As a practical consequence, the SystemRDL source must set `precedence = hw` explicitly on every field that should be accepted -- typically via `default precedence = hw;` at the addrmap or register scope, which sets the scope-wide default rather than requiring per-field annotation.

This mode is the default. The reason is that any disagreement between the SystemRDL request and RgGen's actual behavior is surfaced as an explicit error rather than being silently overridden. A SystemRDL file is processed only when its `precedence` settings are consistent with the hardware-precedence model that RgGen produces; otherwise the user is required to acknowledge the mismatch, either by adding `default precedence = hw;` (matching RgGen's behavior at the source level) or by explicitly selecting ignore mode on (accepting the override). The default refuses to perform a silent semantic inversion.
