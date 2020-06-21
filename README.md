# windu
Convenient window resizing for Emacs

## What is it?
Windu provides a transient minor-mode for quick fine-tuning of window sizes in Emacs, which can be activated using the default keybinding `C-x C-/`.  Once active, `windu-transient-mode` makes the following keybindings available:

### Nudges (incremental window resizing)
| sequence | function | effect |
| -------- | -------- | ------ |
| `<C-left>`  | `'windu-nudge-out-left` | move window's left edge to increase its width by 1 |
| `<C-right>` | `'windu-nudge-out-right` | move window's right edge to increase its width by 1 |
| `<C-up>` | `'windu-nudge-out-top` | move window's top edge to increase its height by 1 |
| `<C-down>` | `'windu-nudge-out-bottom` | move window's bottom edge to increase its height by 1 |
| `<C-S-left>`  | `'windu-nudge-in-left` | move window's left edge to decrease its width by 1 |
| `<C-S-right>` | `'windu-nudge-in-right` | move window's right edge to decrease its width by 1 |
| `<C-S-up>` | `'windu-nudge-in-top` | move window's top edge to decrease its height by 1 |
| `<C-S-down>` | `'windu-nudge-in-bottom` | move window's bottom edge to decrease its height by 1 |

Once activated, `windu-transient-mode` remains active until a non-nudge command is encountered.  This permits easy fine-tuning via repeated invocations of a nudge command without requiring the lengthy `C-x C-/` sequence to be entered before each nudge:

* `C-x C-/ <C-right> <C-right> <C-right>` will increase the width of the current window by 3 columns.
* `C-x C-/ <C-right> <C-right> <C-S-left>` will increase the width of the current window by 2 columns.

### Orders (specific window resizing)
| sequence | function | effect |
| -------- | -------- | ------ |
| `w` | `'windu-set-width-right` | prompt for width and set by moving window's right edge |
| `W` | `'windu-set-width-left` | prompt for width and set by moving window's left edge |
| `h` | `'windu-set-height-bottom` | prompt for height and set by moving window's bottom edge |
| `H` | `'windu-set-height-top` | prompt for height and set by moving window's top edge |
| `f` | `'windu-fill-column-right` | set width to the local `fill-column` by moving window's right edge |
| `F` | `'windu-fill-column-left` | set width to the local `fill-column` by moving window's left edge |

[`fill-column`](https://www.gnu.org/software/emacs/manual/html_node/emacs/Fill-Commands.html) is a standard Emacs variable related to maximum line width.  Its value is local and can be set on a per-buffer basis, and can furthermore be customized for each major-mode though hooks.  This would allow the same `windu-fill-column-right` keybinding to set a python-mode buffer to 80 columns and a javascript-mode buffer to 120:

    (add-hook 'python-mode-hook (lambda () (set-fill-column 80)))
    (add-hook 'java-mode-hook (lambda () (set-fill-column 120)))

`windu-fill-column` acts as a global override for `fill-column` for all windu orders and splits. Its value can be set using the Emacs built-in customization system, accessed via `M-x customize-variable`.

### Splits
| sequence | function | effect |
| -------- | -------- | ------ |
| `3` | `'windu-split-window-best-effort` | split side-by-side and and order each window to width `fill-column` |
| `r` | `'windu-split-window-right` | split side-by-side and order each window to width `fill-column` by moving its right edge; fail if too small |
| `l` | `'windu-split-window-left` | split side-by-side and order each window to width `fill-column` by moving its left edge; fail if too small |
| `+` | `'windu-fill-many-windows` | set as window widths to `fill-column` as possible, starting from the left and moving along the top |

The `windu-split-` commands mimic the Emacs built-in `C-x 3` keybinding, but order the split windows to have width `fill-column` (or the global override `windu-fill-column`, if set) after splitting. If there is insufficient width available on the requested left or right side, `windu-split-window-right` and `windu-split-window-left` fail with an error message; `windu-split-window-best-effort` will try its best.

You can remap the built-in `C-x 3` and `C-x +` keybindings to their windu equivalents globally in your `.emacs` config file:

    (global-set-key (kbd "C-x 3") 'windu-split-window-best-effort)
    (global-set-key (kbd "C-x +") 'windu-fill-many-windows)

### Informational
| sequence | function | effect |
| -------- | -------- | ------ |
| `i` | `'windu-echo-size` | display window's current size in the minibuffer |

## Installation

Place `windu.el` in your emacs load path (often somewhere under `~/.emacs.d/`) and then enable it in your `.emacs` config:

    (require 'windu)
    (windu-default-keybindings)

Then reload your config via `M-x eval-buffer` or simply restart Emacs :)