# bit_field type decision matrix (SystemRDL properties → RgGen type)

One consolidated table. Left columns are SystemRDL input properties (what the converter reads to
decide the type). The right column is the resulting RgGen type. Types that can take a reference
are split into multiple rows so each row's property combination is unambiguous.

Legend:
- Empty cell = property must NOT be set (if set, the field maps to a different type or errors).
- A value (e.g. `rw`, `rclr`, `true`, `ref`) = required value in that cell.
- In a signal/reference cell (`next`, swwe, swwel, hwclr, hwset, we): `true` = external input;
  `ref` = reference to another field instance. (`next` takes only `ref`, not `true`.)
- `r/na` = either r or na.
- `rw/w` = hw writes the value; read side (rw vs w) is NOT distinguished (the hw output port is
  generated either way; whether user logic observes it is the user's concern).

| RgGen type | sw   | hw    | next | onread | onwrite | hwset | hwclr | swwe | swwel | we   | swacc | singlepulse |
| ---------- | ---- | ----- | ---- | ------ | ------- | ----- | ----- | ---- | ----- | ---- | ----- | ----------- |
| `rw`       | rw   | r/na  |      |        |         |       |       |      |       |      |       |             |
| `ro` (ext)  | r | rw/w |    |     |         |       |       |      |       |      |       |             |
| `ro` (ref)  | r | r/na | ref |    |         |       |       |      |       |      |       |             | 
| `rof`      | r    | na    |      |        |         |       |       |      |       |      |       |             |
| `wo`       | w    | r     |      |        |         |       |       |      |       |      |       |             |
| `rohw` (ext) | r  | rw/w  |      |        |         |       |       |      |       | true |       |             |
| `rohw` (ref) | r  | rw/w  |      |        |         |       |       |      |       | ref  |       |             |
| `rwhw` (ext) | rw | rw/w  |      |        |         |       |       |      |       | true |       |             |
| `rwhw` (ref) | rw | rw/w  |      |        |         |       |       |      |       | ref  |       |             |
| `rc`       | r    | r/na  |      | rclr   |         | true  |       |      |       |      |       |             |
| `rs`       | r    | r/na  |      | rset   |         |       | true  |      |       |      |       |             |
| `wrc`      | rw   | r/na  |      | rclr   |         |       |       |      |       |      |       |             |
| `wrs`      | rw   | r/na  |      | rset   |         |       |       |      |       |      |       |             |
| `w0c`      | rw   | r/na  |      |        | wzc     | true  |       |      |       |      |       |             |
| `w1c`      | rw   | r/na  |      |        | woclr   | true  |       |      |       |      |       |             |
| `w0s`      | rw   | r/na  |      |        | wzs     |       | true  |      |       |      |       |             |
| `w1s`      | rw   | r/na  |      |        | woset   |       | true  |      |       |      |       |             |
| `w0t`      | rw   | r/na  |      |        | wzt     |       |       |      |       |      |       |             |
| `w1t`      | rw   | r/na  |      |        | wot     |       |       |      |       |      |       |             |
| `wc`       | rw   | r/na  |      |        | wclr    | true  |       |      |       |      |       |             |
| `ws`       | rw   | r/na  |      |        | wset    |       | true  |      |       |      |       |             |
| `woc`      | w    | r     |      |        | wclr    | true  |       |      |       |      |       |             |
| `wos`      | w    | r     |      |        | wset    |       | true  |      |       |      |       |             |
| `w0crs`    | rw   | r/na  |      | rset   | wzc     |       |       |      |       |      |       |             |
| `w1crs`    | rw   | r/na  |      | rset   | woclr   |       |       |      |       |      |       |             |
| `wcrs`     | rw   | r/na  |      | rset   | wclr    |       |       |      |       |      |       |             |
| `w0src`    | rw   | r/na  |      | rclr   | wzs     |       |       |      |       |      |       |             |
| `w1src`    | rw   | r/na  |      | rclr   | woset   |       |       |      |       |      |       |             |
| `wsrc`     | rw   | r/na  |      | rclr   | wset    |       |       |      |       |      |       |             |
| `rwl` (ext) | rw  | r/na  |      |        |         |       |       |      | true  |      |       |             |
| `rwl` (ref) | rw  | r/na  |      |        |         |       |       |      | ref   |      |       |             |
| `rwe` (ext) | rw  | r/na  |      |        |         |       |       | true |       |      |       |             |
| `rwe` (ref) | rw  | r/na  |      |        |         |       |       | ref  |       |      |       |             |
| `rwc` (ext) | rw  | r/na  |      |        |         |       | true  |      |       |      |       |             |
| `rwc` (ref) | rw  | r/na  |      |        |         |       | ref   |      |       |      |       |             |
| `rws` (ext) | rw  | r/na  |      |        |         | true  |       |      |       |      |       |             |
| `rws` (ref) | rw  | r/na  |      |        |         | ref   |       |      |       |      |       |             |
| `rwtrg`    | rw   | r/na  |      |        |         |       |       |      |       |      | true  |             |
| `rotrg` (ext) | r  | rw/w  |      |        |         |       |       |      |       |      | true  |             |
| `rotrg` (ref) | r  | r/na  | ref  |        |         |       |       |      |       |      | true  |             |
| `wotrg`    | w    | r     |      |        |         |       |       |      |       |      | true  |             |
| `w1trg`    | rw   | r/na  |      |        |         |       |       |      |       |      |       | true        |
| `w1`       | rw1  | r/na  |      |        |         |       |       |      |       |      |       |             |
| `wo1`      | w1   | r     |      |        |         |       |       |      |       |      |       |             |

## General error rules (apply to all types)
- `hw = rw1` or `hw = w1` (write-once on the hardware side) — RgGen has no corresponding concept.
  ERROR for every type. (The hw column values in the table above are limited to r / na / rw / w;
  rw1/w1 on hw are always rejected.)

## Not generated / not supported (no row above)
- `w0trg`, `row0trg`, `row1trg` — not expressible in SystemRDL.
- `rowo`, `rowotrg` — not supported; bit-field overlap is an error.
- `counter`, `intr` — front-end does not support them yet.
- `reserved`, `indirect` — no SystemRDL equivalent.
- `custom` — held for v1.

## Reference (RgGen output) per type
- `ro` (ref) / `rotrg` (ref): reference = the `next` target field.
- `rwl`/`rwe`/`rwc`/`rws` (ref rows): reference = the swwel/swwe/hwclr/hwset target field.
- `rohw`/`rwhw` (ref rows): reference = the `we` target field (valid signal source).
- `rc`/`w0c`/`w1c`/`wc`: RgGen reference means a data mask; NOT settable from SystemRDL → no reference.
- All other types: no reference.
