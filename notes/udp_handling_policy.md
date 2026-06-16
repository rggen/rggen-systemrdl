# UDP Handling Policy for rggen-systemrdl

## Background

SystemRDL provides a User-Defined Property (UDP) mechanism (Section 15 of the SystemRDL 2.0 specification) that allows tools and users to extend the language with custom properties beyond the standard set. In practice, UDPs are widely used by various SystemRDL tools to implement features that are not covered by the standard:

- PeakRDL-regblock uses UDPs such as `buffer_writes`, `wbuffer_trigger`, and others to express features like write-buffered registers, read-buffered registers, signed fields, and fixed-point fields.
- Commercial EDA tools define their own UDPs for vendor-specific features such as encrypted registers, TMR registers, and shadow registers.
- Internal company conventions often introduce custom UDPs to capture domain-specific requirements.

Since UDPs are vendor-specific and not portable across tools, any SystemRDL adapter must define a clear policy for how to handle them. This document describes the UDP handling policy adopted by rggen-systemrdl.

## Design Principles

### 1. Core Adapter Handles SystemRDL Standard Only

The core of rggen-systemrdl is responsible for converting only the SystemRDL standard range (properties defined in the language specification). It does not interpret any UDP semantics on its own.

This keeps the core adapter:

- Simple and focused on the standard
- Independent of any vendor-specific UDP definition
- Free from the lock-in problems associated with UDP-based extensions

### 2. UDP Handling via User-Defined Hooks (Plugins)

When the conversion process encounters a node that has any UDP attached, the entire conversion of that node is delegated to a user-defined hook. The hook is responsible for producing the corresponding RgGen data structure for that node.

This delegation model:

- Respects the SystemRDL property model, where UDPs may interact with other properties in arbitrary ways
- Keeps the core adapter's responsibility cleanly separated from UDP semantics
- Allows users to extend support for any UDP without modifying the core
- Makes the lock-in implications of using a UDP explicit and opt-in

Hooks are registered via the plugin mechanism that RgGen already uses for extension, following the existing RgGen conventions for plugin authoring.

### 3. Hierarchy-Independent Judgment

UDP detection and hook delegation are determined independently at each hierarchy level (addrmap, regfile, reg, field, etc.). The presence of a UDP at one level does not change the conversion behavior of other levels.

This is consistent with the SystemRDL scoping rules: a lower component cannot reference properties of its enclosing component, so a UDP at one hierarchy level cannot legitimately alter the semantics of another level.

Concretely:

- If a register has a UDP but its fields do not, the register conversion is delegated to a hook, while the fields are converted by the default mechanism.
- If a field has a UDP but its parent register does not, the register conversion uses the default mechanism, while the field conversion is delegated.
- Each level makes its own decision based only on its own UDPs.

In the rare case where a UDP is intended to affect multiple hierarchy levels, the plugin may need to express claim conditions that look beyond a single node (for example, to claim a field based on a UDP attached to its parent register). Allowing plugins to define such cross-hierarchy claim conditions is technically possible but is considered a low-priority extension: well-designed UDPs respect the SystemRDL scoping rules, and the common case is fully covered by hierarchy-independent judgment.

### 4. Single Active UDP Plugin

Only one UDP plugin may be active at a time. If multiple UDP plugins are loaded simultaneously, rggen-systemrdl rejects the configuration with an error at startup.

This constraint reflects the practical reality that a given SystemRDL codebase typically targets a single tool (such as PeakRDL) or a single internal convention, and therefore needs exactly one UDP plugin. Allowing multiple UDP plugins would introduce the need for conflict resolution between competing claims on the same node, with no clear benefit for any realistic use case.

If a user genuinely needs to combine multiple UDP sets, the recommended approach is to write a combined plugin that handles both sets coherently. This keeps the single-plugin invariant intact while allowing flexibility for unusual situations.

### 5. Strict by Default

The default behavior when a UDP is encountered but no hook is registered to handle it is to raise an error. This prevents silent fallback to ill-defined behavior and forces users to make explicit decisions about UDP support.

A configuration option may allow this behavior to be relaxed (e.g., to warn or ignore unknown UDPs), but the default is strict.

## Conversion Flow

For each node in the elaborated SystemRDL hierarchy, the conversion proceeds as follows:

1. Check whether the node has any UDP attached to it.
2. If no UDP is present, perform the default conversion:
   - Translate standard SystemRDL properties to the corresponding RgGen data structure.
   - Recursively process child nodes using the same procedure.
3. If a UDP is present, look up a registered hook that matches the node:
   - If a matching hook is found, delegate the conversion of this node entirely to the hook.
   - If no matching hook is found, raise an error (in strict mode) or fall back to the configured alternative behavior.

The hook receives:

- The SystemRDL node, with full access to its standard properties, UDP values, and children.
- A conversion context that provides access to the default conversion routine, so the hook can choose to invoke the default conversion for child nodes if desired.

The hook is expected to return a fully constructed RgGen data structure for the node it handled. The hook is responsible for processing child nodes as appropriate, either by invoking the default conversion via the context or by implementing custom handling.

## Plugin Architecture

UDP handlers are organized as plugins, separate from the rggen-systemrdl core. This means:

- The core adapter ships without any built-in UDP knowledge.
- Support for specific UDPs (e.g., PeakRDL UDPs, vendor-specific UDPs, internal company UDPs) is provided by independent plugins.
- Users can install only the UDP plugins they need, and the dependencies between rggen-systemrdl and any specific UDP definition are made explicit.

Each plugin declares:

- Which UDPs it handles (by name and optionally by combination)
- The conditions under which it applies (e.g., component type, presence of related UDPs)
- The conversion logic that produces RgGen data structures

This structure allows the community to contribute UDP support for various tools and conventions without burdening the core adapter with vendor-specific code.

## Plugin Registration

Plugins register UDP hooks following the conventions of the RgGen plugin system. A hook registration declares:

- A matching condition that determines when the hook applies to a node
- A conversion routine that produces the RgGen data structure for that node

The exact API is determined at implementation time, but the general shape follows RgGen's existing plugin patterns.

## Behavior on Unknown UDPs

When a UDP is encountered but no plugin provides a matching hook, the configured behavior applies:

- **error** (default): Raise an error indicating that the UDP is not supported, with location information from the SystemRDL source.
- **warn**: Emit a warning and proceed without applying the UDP's semantics. The default conversion is used as if the UDP were absent.
- **ignore**: Silently proceed without applying the UDP's semantics.

The `warn` and `ignore` modes are provided for cases such as bulk migration from existing SystemRDL codebases, where a complete UDP handler set may not yet be available. They should be used with awareness that the resulting RgGen data may not reflect the original intent.

## Rationale for the "Whole-Node Delegation" Choice

When a UDP is present at a given node, the adapter delegates the entire conversion of that node, rather than performing a partial conversion and asking the hook to augment it. This choice is motivated by the way SystemRDL is structured:

- SystemRDL defines behavior through combinations of properties, and UDPs may participate in those combinations in arbitrary ways.
- A UDP may change how standard properties at the same level should be interpreted (e.g., `buffer_writes` changes how SW writes to the register are realized).
- A partial conversion would force the hook to reconcile a half-formed result with the UDP's semantics, leading to complex and error-prone hook implementations.

By delegating the whole node, the hook has full control and is responsible for producing a coherent result. If the hook wishes to use the default conversion as a starting point, it may do so explicitly by invoking the conversion context.

## Implications and Trade-offs

### Lock-In Awareness

A SystemRDL file that uses UDPs is, in effect, tool-specific. By making UDP handling explicit through plugins and requiring opt-in, this policy makes the lock-in implications visible to the user. Users adopting a UDP-based feature are also adopting the plugin (and its maintenance burden) needed to interpret that UDP.

This is preferable to silent compatibility shims that hide the lock-in.

### Migration Path

For users migrating SystemRDL files that use vendor-specific UDPs (e.g., PeakRDL UDPs) to rggen-systemrdl:

1. They can either install a community-provided plugin that supports those UDPs, or
2. They can write their own plugin to interpret their UDPs in the way they prefer, or
3. They can modify the SystemRDL source to remove UDP usage and rewrite the equivalent behavior using RgGen's native facilities.

The third option is encouraged as the long-term path, since it removes the SystemRDL-induced lock-in entirely.

### No Built-In UDP Knowledge in the Core

rggen-systemrdl itself does not ship with any UDP definitions or handlers. This is intentional:

- Bundling specific vendor UDP support would implicitly endorse those vendors' design choices.
- It would also tie the core to the maintenance lifecycle of those vendors' tools.
- The plugin model lets each community of users maintain the UDP handlers they need, independently from the core's release schedule.

## Open Questions

The following aspects are deferred to implementation and may be revisited as the adapter evolves:

- The exact shape of the plugin registration API
- Whether plugins can introduce new RgGen types or are limited to existing ones
- The precise interface through which hooks invoke the default conversion on child nodes

The following extension is acknowledged but considered low priority:

- Allowing plugins to define claim conditions that span multiple hierarchy levels (for example, claiming a field based on a UDP attached to its parent register). This would extend the adapter's reach to UDPs that intentionally violate SystemRDL's scoping conventions, but the common case is fully covered by hierarchy-independent judgment, so this is not a near-term priority.

## Summary

| Aspect | Decision |
| --- | --- |
| Core adapter scope | SystemRDL standard range only |
| UDP handling | Delegated to user-defined hooks via plugins |
| Delegation granularity | Whole-node delegation when a UDP is present |
| Hierarchy treatment | Independent judgment at each level |
| Number of active UDP plugins | One at a time; multiple loaded plugins cause a startup error |
| Default behavior on unknown UDP | Error (strict by default) |
| UDP definitions in core | None; all UDP support is plugin-provided |
| Cross-hierarchy claim by plugins | Low-priority extension; not in scope for initial implementation |

This policy keeps the rggen-systemrdl core simple, principled, and aligned with RgGen's overall design philosophy of explicit type-based safety, while leaving the door open for the community to provide UDP support through the plugin mechanism.
