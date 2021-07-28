# windu
Convenient window resizing for Emacs

## What is it?
Windu provides a transient minor-mode for quick fine-tuning of window sizes in Emacs, which can be activated using the default keybinding `C-x C-x`.  Once active, `windu-transient-mode` makes the following keybindings available:

### Nudges (incremental window resizing)
| sequence | function | effect |
| -------- | -------- | ------ |
| `<C-left>`  | `'windu-nudge-in-right` | move window's right edge to decrease its width by 1 |
| `<C-right>` | `'windu-nudge-out-right` | move window's right edge to increase its width by 1 |
| `<C-up>` | `'windu-nudge-in-bottom` | move window's bottom edge to decrease its height by 1 |
| `<C-down>` | `'windu-nudge-out-bottom` | move window's bottom edge to increase its height by 1 |
| `<C-S-left>`  | `'windu-nudge-out-left` | move window's left edge to increase its width by 1 |
| `<C-S-right>` | `'windu-nudge-in-left` | move window's left edge to decrease its width by 1 |
| `<C-S-up>` | `'windu-nudge-out-top` | move window's top edge to increase its height by 1 |
| `<C-S-down>` | `'windu-nudge-in-top` | move window's top edge to decrease its height by 1 |

Once activated, `windu-transient-mode` remains active until a non-nudge or non-bring command is encountered.  This permits easy fine-tuning via repeated invocations of a nudge command without requiring the lengthy `C-x C-x` sequence to be entered before each nudge:

* `C-x C-x <C-right> <C-right> <C-right>` will increase the width of the current window by 3 columns.
* `C-x C-x <C-right> <C-right> <C-left>` will increase the width of the current window by 1 column (first it increases the width by 2, then reduces it by 1).

### Orders (specific window resizing)
| sequence | function | effect |
| -------- | -------- | ------ |
| `f` | `'windu-order-fill-best-effort` | set width to the local `fill-column` by first moving window's right, then left edge |
| `w` | `'windu-order-width-best-effort` | prompt for width and set by first moving window's right, then left edge |
| `h` | `'windu-order-height-best-effort` | prompt for height and set by first moving window's bottom, then top edge |
|     | `'windu-order-fill-right` | set width to the local `fill-column` by moving window's right edge |
|     | `'windu-order-fill-left` | set width to the local `fill-column` by moving window's left edge |
|     | `'windu-order-width-right` | prompt for width and set by moving window's right edge |
|     | `'windu-order-width-left` | prompt for width and set by moving window's left edge |
|     | `'windu-order-height-bottom` | prompt for height and set by moving window's bottom edge |
|     | `'windu-order-height-top` | prompt for height and set by moving window's top edge |

**NOTE:** The unbound functions are intended for really fine-tuning your windows, and may be invoked explicitly via `M-x windu-order-width-right` etc.

[`fill-column`](https://www.gnu.org/software/emacs/manual/html_node/emacs/Fill-Commands.html) is a standard Emacs variable related to maximum line width.  Its value is buffer-local and can be set on a per-buffer basis, and can furthermore be customized for each major-mode though hooks.  This would allow the same `windu-order-fill-` keybindings to set a python-mode buffer to 80 columns and a java-mode buffer to 120:

```elisp
(add-hook 'python-mode-hook (lambda () (set-fill-column 80)))
(add-hook 'java-mode-hook (lambda () (set-fill-column 120)))
```

`windu-fill-column` acts as a global override for `fill-column` for all windu orders and splits. Its value can be set using the Emacs built-in customization system, accessed via `M-x customize-variable`.

### Splits
| sequence | function | effect |
| -------- | -------- | ------ |
| `2` | `'windu-split-window-below` | split above-below and echo window sizes |
| `3` | `'windu-split-window-right` | split side-by-side and order each window to width `fill-column` by first moving its right, then left edge |
| `r` | `'windu-split-window-right` | split side-by-side and order each window to width `fill-column` by moving its right edge; fail if too small |
| `l` | `'windu-split-window-left` | split side-by-side and order each window to width `fill-column` by moving its left edge; fail if too small |
| `+` | `'windu-order-fill-many-windows` | order as many window widths to `fill-column` as possible, starting from the left and moving along the top |

The `windu-split-window-right` command mimics the Emacs built-in `C-x 3` keybinding, but orders the split windows to have width `fill-column` (or the global override `windu-fill-column`, if set) after splitting. If there is insufficient width available on the requested left or right side, `windu-split-window-right` and `windu-split-window-left` fail with an error message; `windu-split-window-right` will try its best.

The `windu-order-fill-many-windows` command mimics the Emacs built-in `C-x +` keybinding, but orders windows to their local `fill-column` width. It is currently fairly primitive, and simply orders each window along the top row to set its width via `windu-order-width-right`.

You can remap the built-in `C-x 2`, `C-x 3`, and `C-x +` keybindings to their windu equivalents globally via `(windu-setup-global-keybindings)`, or explicitly in your `.emacs` config file:

```elisp
(global-set-key (kbd "C-x 2") 'windu-split-window-below)
(global-set-key (kbd "C-x 3") 'windu-split-window-right)
(global-set-key (kbd "C-x +") 'windu-order-fill-many-windows)
```

### Swaps
| sequence | function | effect |
| -------- | -------- | ------ |
| `,` | `'windu-swap-left` | move the current window's buffer to the window on the left, and move that window's buffer to the current window |
| `.` | `'windu-swap-right` | move the current window's buffer to the window on the right, and move that window's buffer to the current window |
| `<` | `'windu-swap-top` | move the current window's buffer to the window on the top, and move that window's buffer to the current window |
| `>` | `'windu-swap-bottom` | move the current window's buffer to the window on the bottom, and move that window's buffer to the current window |
| `C-,` | `'windu-bring-left` | select the window on the left, and bring the current buffer with you |
| `C-.` | `'windu-bring-right` | select the window on the right, and bring the current buffer with you |
| `C-<` | `'windu-bring-top` | select the window on the top, and bring the current buffer with you |
| `C->` | `'windu-bring-bottom` | select the window on the bottom, and bring the current buffer with you |

The `'windu-swap-` commands switch the buffer in the active window with the buffer in a window left, right, above, or below the current window.  Focus remains in the current window.

The `'windu-bring-` commands, on the other hand, switch buffers like `'windu-swap-` but move focus to the other window as well. Multiple bring commands can be chained together without requiring the lengthy `C-x C-x` sequence to be entered before each bring:

* `C-x C-x C->` will result in the simultaneous evaluation of:

        window0.buffer = window1.buffer
        window1.buffer = window0.buffer

    Additionally, window1 will become the current window.
* `C-x C-x C-> C->` will result in the simultaneous evaluation of:

        window0.buffer = window1.buffer
        window1.buffer = window2.buffer
        window2.buffer = window0.buffer

    Additionally, window2 will become the current window.

You can make the `'windu-bring-` commands available globally through convenient keybindings that mimic [`windmove`](https://github.com/emacs-mirror/emacs/blob/master/lisp/windmove.el) via `(windu-setup-windmove-keybindings)`, or explicitly in your `.emacs` config file:

```elisp
(global-set-key (kbd "<C-S-left>") 'windu-bring-left)
(global-set-key (kbd "<C-S-right>") 'windu-bring-right)
(global-set-key (kbd "<C-S-up>") 'windu-bring-top)
(global-set-key (kbd "<C-S-down>") 'windu-bring-bottom)
```

### Informational
| sequence | function | effect |
| -------- | -------- | ------ |
| `i` | `'windu-echo-size` | display window's current size in the minibuffer |

Window size information is displayed automatically by many `windu-` commands.

## Installation

Place `windu.el` in your emacs load path (often somewhere under `~/.emacs.d/`) and then enable it in your `.emacs` config:

```elisp
;; Use default keybinding "C-x C-x"
(require 'windu)
(windu-setup-transient-keybindings)
```

### More Keybindings

Several helper functions may be called in `~/.emacs` to enable typical keybindings:

```elisp
(require 'windu)
;; Enable windu transient mode on the default "C-x C-x" prefix.
(windu-setup-transient-keybindings)
;; Enable windu "windmove-like" bring keybindings on <C-S-left> etc.
(windu-setup-windmove-keybindings)
;; Enable global keybindings for split/balance/delete commands.
(windu-setup-global-keybindings)
```

Keybindings can instead be customized by explicitly enabling them in `~/.emacs`:

```elisp
(require 'windu)
;; Enable transient mode on a custom prefix "M-w".
(windu-setup-transient-keybindings (kbd "M-w"))
;; Enable windmove-like bring commands.
(global-set-key (kbd "<C-S-left>") 'windu-bring-left)
(global-set-key (kbd "<C-S-right>") 'windu-bring-right)
(global-set-key (kbd "<C-S-up>") 'windu-bring-top)
(global-set-key (kbd "<C-S-down>") 'windu-bring-bottom))
;; Wrap 'delete-window, 'delete-other-windows.
(global-set-key (kbd "C-x 0") 'windu-delete-window)
(global-set-key (kbd "C-x 1") 'windu-delete-other-windows)
(global-set-key (kbd "C-x )") 'windu-un-delete-window)
(global-set-key (kbd "C-x !") 'windu-un-delete-other-windows)
;; Wrap 'split-window-below, 'split-window-right, 'balance-windows.
(global-set-key (kbd "C-x 2") 'windu-split-window-below)
(global-set-key (kbd "C-x 3") 'windu-split-window-right)
(global-set-key (kbd "C-x +") 'windu-order-fill-many-windows)
```