# bit_field type mapping (RgGen type ← SystemRDL field properties)

Confirmed mapping from SystemRDL field property combinations to RgGen bit_field types.
Reference: RgGen RTL templates at
rggen/rggen-systemverilog `lib/rggen/systemverilog/rtl/bit_field/type`.

## Baseline conventions
- `sw` reaching the converter is one of rw / r / w / rw1 / w1 (sw=na and all invalid sw/hw combos
  in Table 12 are errored by the front-end; see systemrdl notes/implicit_constraints.md).
- SystemRDL "Error – meaningless" combos and SW-write-loss combos (sw∈{w,rw} & hw∈{w,rw} without
  we/wel) are errored by the front-end; the converter assumes inputs already passed those checks.
- HW-update principle: RgGen `rw`/`ro`/`wo` (plain storage) have NO hardware update path, so for
  those, hw ∈ {r, na}. Fields where HW writes the value (hw=rw/w) map to HW-input-capable types
  (`rohw`, `row1trg`, ...) or are unrepresentable — never to plain rw/ro/wo.
- "Other properties not allowed" on a type means: if any property outside that type's listed set
  is present, the field does NOT map to that type (→ another type, or error if none fits).

## Type table
The combinations below list the distinguishing properties per type. Full per-property conditions
(including which properties must be absent) are in `bit_field_type_matrix.md`; they are not
repeated here.

### Basic access (no side effects)
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `rw`   | sw=rw, hw∈{r,na} | Plain storage. |
| `ro` (ext) | sw=r, hw drives value (hw=rw/w) | Value comes from hardware. |
| `ro` (ref) | sw=r, hw=r/na, `next` = another field | Value comes from the referenced field (`reference` = the `next` target). |
| `rof`  | sw=r, hw=na | Returns fixed `initial_value` (constant). hw=na only (not r). |
| `wo`   | sw=w, hw=r | Write-only storage. |
| `rohw` | sw=r, hw∈{rw,w}, `we` required (true or another field) | HW value taken in under `we` (valid). |
| `rwhw` | sw=rw, hw∈{rw,w}, `we` required (true or another field) | read/write version of `rohw`; HW value taken in under `we` (valid). `we` avoids the SW-write-loss error. |
| `rowo` | — NOT SUPPORTED | Would require merging two fields (sw=r + sw=w) at the same bit position. Bit-field overlap is an ERROR (see below). |

### Read side-effect
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `rc`   | sw=r, onread=rclr, hwset=true | `reference`(mask) NOT specifiable (SystemRDL has no mask). |
| `rs`   | sw=r, onread=rset, hwclr=true | `rs` takes NO reference. |
| `wrc`  | sw=rw, hw∈{r,na}, onread=rclr | |
| `wrs`  | sw=rw, hw∈{r,na}, onread=rset | |

### Write side-effect: clear / set / toggle
Polarity: SystemRDL woclr/woset (write-ONE) → RgGen w1c/w1s; wzc/wzs (write-ZERO) → w0c/w0s;
wot/wzt (toggle) → w1t/w0t. clear-family needs hwset=true; set-family needs hwclr=true;
toggle-family takes neither.
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `w0c`  | sw=rw, hw∈{r,na}, onwrite=wzc,  hwset=true | mask NOT specifiable. |
| `w1c`  | sw=rw, hw∈{r,na}, onwrite=woclr, hwset=true | mask NOT specifiable. |
| `w0s`  | sw=rw, hw∈{r,na}, onwrite=wzs,  hwclr=true | |
| `w1s`  | sw=rw, hw∈{r,na}, onwrite=woset, hwclr=true | |
| `w0t`  | sw=rw, hw∈{r,na}, onwrite=wzt  | |
| `w1t`  | sw=rw, hw∈{r,na}, onwrite=wot  | |
| `wc`   | sw=rw, hw∈{r,na}, onwrite=wclr, hwset=true | mask NOT specifiable. |
| `ws`   | sw=rw, hw∈{r,na}, onwrite=wset, hwclr=true | |
| `woc`  | sw=w, hw=r, onwrite=wclr, hwset=true | write-only version of wc. |
| `wos`  | sw=w, hw=r, onwrite=wset, hwclr=true | write-only version of ws. |

### Write + read combined (all: sw=rw, hw∈{r,na})
| RgGen type | SystemRDL combination |
| ---------- | --------------------- |
| `w0crs` | onwrite=wzc,  onread=rset |
| `w1crs` | onwrite=woclr, onread=rset |
| `wcrs`  | onwrite=wclr, onread=rset |
| `w0src` | onwrite=wzs,  onread=rclr |
| `w1src` | onwrite=woset, onread=rclr |
| `wsrc`  | onwrite=wset, onread=rclr |

### Read/write with control signal (signal = true → external input; = other field → reference)
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `rwl`  | sw=rw, swwel (=true or other field) | lock, active-low. |
| `rwe`  | sw=rw, swwe  (=true or other field) | enable, active-high. |
| `rwc`  | sw=rw, hw∈{r,na}, hwclr (=true or other field) | clear. |
| `rws`  | sw=rw, hw∈{r,na}, hwset (=true or other field) | set. |

### Trigger output
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `rwtrg`  | `rw` combination + swacc=true  | |
| `rotrg`  | `ro` combination + swacc=true  | |
| `wotrg`  | `wo` combination + swacc=true  | |
| `rowotrg`| — NOT GENERATED | `rowo` is not supported (bit-field overlap is an error). |
| `w1trg`  | sw=rw, hw∈{r,na}, singlepulse=true | width=1/reset=0 etc. guaranteed by front-end. |
| `w0trg`  | — NOT GENERATED | singlepulse requires write-1, so write-0 trigger has no SystemRDL source. |
| `row0trg`| — NOT GENERATED | follows w0trg. |
| `row1trg`| — NOT GENERATED | would need sw=rw + hw=rw/w + singlepulse, but sw=rw/w means value write in SystemRDL, so this combination is not expressible. (Also likely errored by front-end SW-write-loss.) |

### Write once
| RgGen type | SystemRDL combination | Notes |
| ---------- | --------------------- | ----- |
| `w1`  | sw=rw1, hw∈{r,na} | |
| `wo1` | sw=w1, hw=r | |

### Special / not generated
| RgGen type | Status |
| ---------- | ------ |
| `counter`  | Front-end does NOT support SystemRDL `counter` yet → out of first-release scope (target type deferred; see TODO). |
| `reserved` | SystemRDL has no equivalent concept → never generated from SystemRDL. |
| `custom`   | First release: NOT used (held/deferred). Combinations that fit no named type are errors; using `custom` to catch them is future work (verification cost too high for v1). |

## Mask reference
RgGen types whose `reference` means a read/write data mask (`rc`, `w0c`, `w1c`, `wc`) cannot
receive that mask from SystemRDL (no mask concept in SystemRDL) → such fields are reference-less.
