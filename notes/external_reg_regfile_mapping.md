# External reg / regfile → RgGen: Deferred Design Notes

This document records the conversion approach that was worked out for external `reg`/`regfile`,
so it is available when the feature is picked up later. The key point is that RgGen cannot
generate at reg/regfile granularity, so the contents must be wrapped in a register_block. (This
is unlike a nested addrmap, which is itself an RTL generation unit and maps directly to a
register_block without wrapping — see `systemrdl_to_rggen_mapping.md`.)

Note: the RgGen "External + child block reference" extension (rggen/rggen#291) is NOT a
prerequisite for this. #291 lets the user name the child register_block and avoid entering its
size by hand, but external reg/regfile can also be converted without it by computing the region
size in the converter (the same size-calculation approach used for `mem`).

## Trigger

Each of the following is an independent implementation boundary handled the same way:
- an external `reg` (`Reg#external` = true),
- an external `regfile` (`RegFile#external` = true).

## Two outputs

Each such subtree produces TWO outputs:
1. On the enclosing map, reserve its address region as an RgGen `external` register. Its `address`
   and `size` come from the model (`address`/`size`).
2. Synthesize a NEW register_block that wraps the reg/regfile, and place the reg/regfile inside
   it. Unlike a nested addrmap (which is itself a register_block and goes through the normal
   conversion flow), a reg/regfile cannot itself become a register_block — RgGen cannot generate
   at reg/regfile granularity — so an enclosing register_block hierarchy has to be created for it.
   The synthesized block is what lets RgGen actually generate the contents.

## Rules for the synthesized wrapping register_block

- Name: the ancestor instance names joined with `__` (e.g. regfile `foo[2]` containing external
  reg `bar` → `foo__0__bar`). Array subscripts also use `__`, so the separator is uniform.
- Addresses inside the synthesized block are re-based to a 0 offset (it is an independent block).
- `bridge` is NOT part of the trigger; it only indicates whether the external boundary involves
  bus/protocol conversion.
