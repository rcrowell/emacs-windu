;;; windu.el --- directional incremental window-resize routines
;;
;; Author: Rob Crowell (robccrowell@gmail.com)
;;

;; User configurable variables:

;; For customize ...
(defgroup windu nil
  "Convenient resizing of windows in a single frame."
  :prefix "windu-"
  :version "21.1"
  :group 'windows
  :group 'convenience)

(defcustom windu-nudge-x 1
  "How many columns to resize a window when adjusting its left or right edge."
  :type 'number
  :group 'windu)

(defcustom windu-nudge-y 1
  "How many lines to resize a window when adjusting its top or bottom edge."
  :type 'number
  :group 'windu)

(defcustom windu-fill-column nil
  "How wide to make split windows; defaults to `fill-column`."
  :type 'number
  :group 'windu)

(defcustom windu-fill-column-padding 1
  "How many columns to add to `fill-column` as padding."
  :type 'number
  :group 'windu)

;;; Code:
(define-minor-mode windu-transient-mode
  "Nudge windows to make them larger or smaller."
  :lighter " windu"
  :keymap (let ((map (make-sparse-keymap)))
            ;; Nudges
            (define-key map (kbd "<C-left>") 'windu-nudge-in-right)
            (define-key map (kbd "<C-right>") 'windu-nudge-out-right)
            (define-key map (kbd "<C-up>") 'windu-nudge-in-bottom)
            (define-key map (kbd "<C-down>") 'windu-nudge-out-bottom)
            (define-key map (kbd "<C-S-left>") 'windu-nudge-out-left)
            (define-key map (kbd "<C-S-right>") 'windu-nudge-in-left)
            (define-key map (kbd "<C-S-up>") 'windu-nudge-out-top)
            (define-key map (kbd "<C-S-down>") 'windu-nudge-in-top)
            ;; Orders
            (define-key map (kbd "f") 'windu-order-fill-best-effort)
            (define-key map (kbd "w") 'windu-order-width-best-effort)
            (define-key map (kbd "h") 'windu-order-height-best-effort)
            ;; Splits / Group Orders
            (define-key map (kbd "2") 'windu-split-window-below)
            (define-key map (kbd "3") 'windu-split-window-right)
            (define-key map (kbd "r") 'windu-split-window-right-only)
            (define-key map (kbd "l") 'windu-split-window-left-only)
            (define-key map (kbd "+") 'windu-order-fill-many-windows)
            ;; Swaps / Brings
            (define-key map (kbd ",") 'windu-swap-left)
            (define-key map (kbd ".") 'windu-swap-right)
            (define-key map (kbd "<") 'windu-swap-top)
            (define-key map (kbd ">") 'windu-swap-bottom)
            (define-key map (kbd "C-,") 'windu-bring-left)
            (define-key map (kbd "C-.") 'windu-bring-right)
            (define-key map (kbd "C-<") 'windu-bring-top)
            (define-key map (kbd "C->") 'windu-bring-bottom)
            ;; Window Deletion
            (define-key map (kbd "0") 'windu-delete-window)
            (define-key map (kbd "1") 'windu-delete-other-windows)
            (define-key map (kbd ")") 'windu-un-delete-window)
            (define-key map (kbd "!") 'windu-un-delete-other-windows)
            ;; Save/Local Window Configuration (for US keyboard users)
            (define-key map (kbd "6") 'windu-set-save-quick-A)
            (define-key map (kbd "7") 'windu-set-save-quick-B)
            (define-key map (kbd "8") 'windu-set-save-quick-C)
            (define-key map (kbd "9") 'windu-set-save-quick-D)
            (define-key map (kbd "^") 'windu-load-quick-A)
            (define-key map (kbd "&") 'windu-load-quick-B)
            (define-key map (kbd "*") 'windu-load-quick-C)
            (define-key map (kbd "(") 'windu-load-quick-D)
            ;; Info
            (define-key map (kbd "i") 'windu-echo-size)
            map)
  (add-hook 'post-command-hook 'windu--post-command-handler))

(defun windu--post-command-handler ()
  "Deactivate `windu-transient-mode` after non-nudge actions."
  (let ((this-command-name (symbol-name this-command)))
    (cond ((not (or (eq 'windu-transient-activate this-command)
                    (eq (string-match "windu-nudge-" this-command-name) 0)
                    (eq (string-match "windu-bring-" this-command-name) 0)))
           (windu-transient-abort)))))

(defun windu-fill-width (&optional window width)
  (let ((local-fill-column (buffer-local-value 'fill-column (window-buffer window))))
    (cond (width
           width)
          (t
           (+ (or windu-fill-column local-fill-column 79) windu-fill-column-padding)))))

(defun windu-nudge-left (&optional delta window)
  "Resize WINDOW by DELTA via moving its left edge."
  (let ((other-window (window-in-direction 'left window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window on the left of this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge other-window (- delta) t)))))

(defun windu-nudge-right (&optional delta window)
  "Resize WINDOW by DELTA via moving its right edge."
  (let ((other-window (window-in-direction 'right window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window on the right of this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge window delta t)))))

(defun windu-nudge-top (&optional delta window)
  "Resize WINDOW by DELTA via moving its top edge."
  (let ((other-window (window-in-direction 'above window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window above this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge other-window (- delta))))))

(defun windu-nudge-bottom (&optional delta window)
  "Resize WINDOW by DELTA via moving its bottom edge."
  (let ((other-window (window-in-direction 'below window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window below this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge window delta)))))

(defun windu-set-width-left (width &optional window)
  "Set WINDOW width to WIDTH by moving its left edge."
  (let ((delta (- width (window-total-width window))))
    (windu-nudge-left delta window)))

(defun windu-set-width-right (width &optional window)
  "Set WINDOW width to WIDTH by moving its right edge."
  (let ((delta (- width (window-total-width window))))
    (windu-nudge-right delta window)))

(defun windu-set-height-top (height &optional window)
  "Set WINDOW height to HEIGHT by moving its top edge."
  (let ((delta (- height (window-total-height window))))
    (windu-nudge-top delta window)))

(defun windu-set-height-bottom (height &optional window)
  "Set WINDOW height to HEIGHT by moving its bottom edge."
  (let ((delta (- height (window-total-height window))))
    (windu-nudge-bottom delta window)))

(defun windu-fill-windows-right(&optional window width)
  (cond ((not (null window))
         (ignore-errors
           (windu-set-width-right (windu-fill-width window width) window)
           (windu-fill-windows-right (window-in-direction 'right window) width)))))

(defun windu-echo-sizes (&optional window other-window dir)
  "Message the size of 1 or 2 windows, WINDOW and OTHER-WINDOW."
  (cond ((null other-window)
         (message "Current window is %dx%d"
                  (window-total-width window) (window-total-height window)))
        (t
         (message "Current window is %dx%d; %s window is %dx%d"
                  (window-total-width window) (window-total-height window)
                  (or (symbol-name dir) "other")
                  (window-total-width other-window) (window-total-height other-window)))))

(defun windu-swap-buffers (other &optional window)
  "Swap buffers between the OTHER window and WINDOW."
  (let ((this-buf (window-buffer window))
        (other-buf (window-buffer other)))
    (set-window-buffer window other-buf)
    (set-window-buffer other this-buf)))

(defun windu-swap-buffers-in-direction (direction &optional window)
  "Swap buffers between the window in DIRECTION and WINDOW."
  (let ((other-window (window-in-direction direction window)))
    (cond ((null other-window)
           (user-error "No window %s of this one" direction))
          (t
           (windu-swap-buffers other-window window)
           other-window))))

;;; window configuration hotkeys

(defvar windu-autosave-delete-window nil)
(defvar windu-autosave-delete-other-windows nil)
(defvar windu-save-quick-A nil)
(defvar windu-save-quick-B nil)
(defvar windu-save-quick-C nil)
(defvar windu-save-quick-D nil)

(defun windu-set-window-configuration (name)
  "Save the current window configuration into NAME."
  (set name (current-window-configuration))
  (message "Window configuration saved"))

(defun windu-load-window-configuration (name)
  "Load the window configuration corresponding to NAME."
  (if name (progn (set-window-configuration name)
                  (message "Window configuration loaded"))
    (message "Saved configuration not found")))

;;; user-callable interactive wrapper functions
(defun windu-transient-activate ()
  "Begins a new nudge action."
  (interactive)
  (message "Entering windu mode (windu-fill-width is %d)" (windu-fill-width))
  (windu-transient-mode 1))

(defun windu-transient-abort ()
  "Disable the current nudge action."
  (interactive)
  (windu-transient-mode 0))

(defun windu-echo-size ()
  "Print the current window size in the echo area."
  (interactive)
  (windu-echo-sizes))

(defun windu-nudge-out-left (&optional arg)
  "Increase current window size by ARG via pushing its left edge out."
  (interactive "p")
  (windu-nudge-left (* windu-nudge-x arg))
  (windu-echo-sizes))

(defun windu-nudge-out-right (&optional arg)
  "Increase current window size by ARG via pushing its right edge out."
  (interactive "p")
  (windu-nudge-right (* windu-nudge-x arg))
  (windu-echo-size))

(defun windu-nudge-out-top (&optional arg)
  "Increase current window size by ARG via pushing its top edge out."
  (interactive "p")
  (windu-nudge-top (* windu-nudge-y arg))
  (windu-echo-size))

(defun windu-nudge-out-bottom (&optional arg)
  "Increase current window size by ARG via pushing its bottom edge out."
  (interactive "p")
  (windu-nudge-bottom (* windu-nudge-y arg))
  (windu-echo-size))

(defun windu-nudge-in-left (&optional arg)
  "Decrease current window size by ARG via pulling its left edge in."
  (interactive "p")
  (windu-nudge-left (- (* windu-nudge-x arg)))
  (windu-echo-size))

(defun windu-nudge-in-right (&optional arg)
  "Decrease current window size by ARG via pulling its right edge in."
  (interactive "p")
  (windu-nudge-right (- (* windu-nudge-x arg)))
  (windu-echo-size))

(defun windu-nudge-in-top (&optional arg)
  "Decrease current window size by ARG via pulling its top edge in."
  (interactive "p")
  (windu-nudge-top (- (* windu-nudge-y arg)))
  (windu-echo-size))

(defun windu-nudge-in-bottom (&optional arg)
  "Decrease current window size by ARG via pulling its bottom edge in."
  (interactive "p")
  (windu-nudge-bottom (- (* windu-nudge-y arg)))
  (windu-echo-size))

(defun windu-order-width-left (width)
  "Set current window width to WIDTH by moving its left edge."
  (interactive "nSet width: ")
  (windu-set-width-left (windu-fill-width nil width))
  (windu-echo-size))

(defun windu-order-width-right (width)
  "Set current window width to WIDTH by moving its right edge."
  (interactive "nSet width: ")
  (windu-set-width-right (windu-fill-width nil width))
  (windu-echo-size))

(defun windu-order-height-top (height)
  "Set current window height to HEIGHT by moving its top edge."
  (interactive "nSet height: ")
  (windu-set-height-top height)
  (windu-echo-size))

(defun windu-order-height-bottom (height)
  "Set current window height to HEIGHT by moving its bottom edge."
  (interactive "nSet height: ")
  (windu-set-height-bottom height)
  (windu-echo-size))

(defun windu-order-width-best-effort (width)
  "Set current window width to WIDTH by first moving its right edge, then its left."
  (interactive "nSet width: ")
  (let ((width (windu-fill-width nil width)))
    (cond ((window-in-direction 'right)
           (windu-set-width-right width)))
    (cond ((and (< (window-total-width nil) width) (window-in-direction 'left))
           (windu-set-width-left width)))
    (windu-echo-size)))

(defun windu-order-height-best-effort (height)
  "Set current window height to HEIGHT by first moving its bottom edge, then its top."
  (interactive "nSet height: ")
  (cond ((window-in-direction 'below)
         (windu-set-height-bottom height)))
  (cond ((and (< (window-total-height nil) height) (window-in-direction 'above))
         (windu-set-height-top height)))
  (windu-echo-size))

(defun windu-order-fill-left ()
  "Set current window width to `fill-column` by moving its left edge."
  (interactive)
  (windu-order-width-left (windu-fill-width)))

(defun windu-order-fill-right ()
  "Set current window width to `fill-column` by moving its right edge."
  (interactive)
  (windu-order-width-right (windu-fill-width)))

(defun windu-order-fill-best-effort ()
  "Set current window width to `fill-column` by first moving its right edge, then its left."
  (interactive)
  (windu-order-width-best-effort (windu-fill-width)))

(defun windu-order-fill-many-windows ()
  "Set every window to `fill-column` starting with the window at (0, 0)."
  (interactive)
  (balance-windows)
  (windu-fill-windows-right (window-at 0 0)))

(defun windu-split-window-left-only ()
  "Split current window side-by-side, moving the left edge as needed.
After the split, both windows aim to have `windu-fill-column` width."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'left)))
    (cond ((not (null other-window))
           (windu-set-width-left (* 2 width))))
    (let ((new-window (split-window nil (- width) 'right)))
      (windu-echo-sizes nil other-window 'right))))

(defun windu-split-window-right-only ()
  "Split current window side-by-side, moving the right edge as needed.
After the split, both windows aim to have `windu-fill-column` width."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'right)))
    (cond ((not (null other-window))
           (windu-set-width-right (* 2 width))))
    (let ((new-window (split-window nil width 'right)))
      (windu-echo-sizes nil new-window 'right))))

(defun windu-split-window-right ()
  "Split current window side-by-side, moving the right and left edges as needed.
After the split, both windows aim to have `windu-fill-column` width."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'right)))
    (cond ((not (null other-window))
           (windu-set-width-right (* 2 width))))
    (let ((new-window (split-window nil nil 'right)))
      (windu-order-width-right width)
      (windu-echo-sizes nil new-window 'right))))

(defun windu-split-window-below ()
  "Extend `split-window-below` by echoing the current window sizes afterward."
  (interactive)
  (let ((new-window (split-window-below)))
    (windu-echo-sizes nil new-window 'below)))

(defun windu-swap-left ()
  "Swap the buffer in the current window with the one on the left."
  (interactive)
  (windu-swap-buffers-in-direction 'left))

(defun windu-swap-right ()
  "Swap the buffer in the current window with the one on the right."
  (interactive)
  (windu-swap-buffers-in-direction 'right))

(defun windu-swap-top ()
  "Swap the buffer in the current window with the one on the top."
  (interactive)
  (windu-swap-buffers-in-direction 'above))

(defun windu-swap-bottom ()
  "Swap the buffer in the current window with the one on the bottom."
  (interactive)
  (windu-swap-buffers-in-direction 'below))

(defun windu-bring-left ()
  "Select the window on the left, and bring the current buffer along."
  (interactive)
  (select-window (windu-swap-buffers-in-direction 'left)))

(defun windu-bring-right ()
  "Select the window on the right, and bring the current buffer along."
  (interactive)
  (select-window (windu-swap-buffers-in-direction 'right)))

(defun windu-bring-top ()
  "Select the window on the top, and bring the current buffer along."
  (interactive)
  (select-window (windu-swap-buffers-in-direction 'above)))

(defun windu-bring-bottom ()
  "Select the window on the bottom, and bring the current buffer along."
  (interactive)
  (select-window (windu-swap-buffers-in-direction 'below)))

;;; window deletion interactive wrapper functions
(defun windu-delete-window ()
  "Extend `delete-window` by saving the current window configuration first."
  (interactive)
  (windu-set-window-configuration 'windu-autosave-delete-window)
  (delete-window)
  (message "Undo via (windu-un-delete-window)"))

(defun windu-delete-other-windows ()
  "Extend `delete-other-windows` by saving the current window configuration first."
  (interactive)
  (windu-set-window-configuration 'windu-autosave-delete-other-windows)
  (delete-other-windows)
  (message "Undo via (windu-un-delete-other-windows)"))

(defun windu-un-delete-window ()
  "Restore the window configuration saved via `windu-delete-window`, if any."
  (interactive)
  (windu-load-window-configuration windu-autosave-delete-window)
  (message "Window configuration loaded"))

(defun windu-un-delete-other-windows ()
  "Restore the window configuration saved via `windu-delete-other-windows`, if any."
  (interactive)
  (windu-load-window-configuration windu-autosave-delete-other-windows)
  (message "Window configuration loaded"))

;;; window configuration end-user interactive wrapper functions
(defun windu-set-save-quick-A ()
  "Save the current window configuration to 'windu-save-quick-A."
  (interactive)
  (windu-set-window-configuration 'windu-save-quick-A))

(defun windu-set-save-quick-B ()
  "Save the current window configuration to 'windu-save-quick-B."
  (interactive)
  (windu-set-window-configuration 'windu-save-quick-B))

(defun windu-set-save-quick-C ()
  "Save the current window configuration to 'windu-save-quick-C."
  (interactive)
  (windu-set-window-configuration 'windu-save-quick-C))

(defun windu-set-save-quick-D ()
  "Save the current window configuration to 'windu-save-quick-D."
  (interactive)
  (windu-set-window-configuration 'windu-save-quick-D))

(defun windu-load-quick-A ()
  "Load the window configuration stored in 'windu-save-quick-A, if one exists."
  (interactive)
  (windu-load-window-configuration windu-save-quick-A)
  (message "Window configuration loaded"))

(defun windu-load-quick-B ()
  "Load the window configuration stored in 'windu-save-quick-B, if one exists."
  (interactive)
  (windu-load-window-configuration windu-save-quick-B)
  (message "Window configuration loaded"))

(defun windu-load-quick-C ()
  "Load the window configuration stored in 'windu-save-quick-C, if one exists."
  (interactive)
  (windu-load-window-configuration windu-save-quick-C)
  (message "Window configuration loaded"))

(defun windu-load-quick-D ()
  "Load the window configuration stored in 'windu-save-quick-D, if one exists."
  (interactive)
  (windu-load-window-configuration windu-save-quick-D)
  (message "Window configuration loaded"))

;;; convenience keybinding setup functions

(defun windu-setup-transient-keybindings (&optional mode-prefix)
  "Set up keybinding for `windu-transient-mode` on MODE-PREFIX; defaults to 'C-x C-x'."
  (interactive)
  (let ((mode-prefix (or mode-prefix "C-x C-x")))
    (global-set-key (kbd mode-prefix) 'windu-transient-activate)))

(defun windu-setup-windmove-keybindings ()
  "Set up keybindings to mirror windmove: '<C-S-up>' etc."
  (interactive)
  ;; windmove-like bring commands
  (global-set-key (kbd "<C-S-left>") 'windu-bring-left)
  (global-set-key (kbd "<C-S-right>") 'windu-bring-right)
  (global-set-key (kbd "<C-S-up>") 'windu-bring-top)
  (global-set-key (kbd "<C-S-down>") 'windu-bring-bottom))

(defun windu-setup-global-keybindings ()
  "Set up global wrappers for window manipulation at their usual keybindings."
  ;; wrap 'delete-window, 'delete-other-windows
  (global-set-key (kbd "C-x 0") 'windu-delete-window)
  (global-set-key (kbd "C-x 1") 'windu-delete-other-windows)
  (global-set-key (kbd "C-x )") 'windu-un-delete-window)
  (global-set-key (kbd "C-x !") 'windu-un-delete-other-windows)
  ;; wrap 'split-window-below, 'split-window-right, 'balance-windows
  (global-set-key (kbd "C-x 2") 'windu-split-window-below)
  (global-set-key (kbd "C-x 3") 'windu-split-window-right)
  (global-set-key (kbd "C-x +") 'windu-order-fill-many-windows)
)

(provide 'windu)

;;; windu.el ends here
