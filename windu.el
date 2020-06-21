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
            (define-key map (kbd "<C-left>") 'windu-nudge-out-left)
            (define-key map (kbd "<C-right>") 'windu-nudge-out-right)
            (define-key map (kbd "<C-up>") 'windu-nudge-out-top)
            (define-key map (kbd "<C-down>") 'windu-nudge-out-bottom)
            (define-key map (kbd "<C-S-left>") 'windu-nudge-in-right)
            (define-key map (kbd "<C-S-right>") 'windu-nudge-in-left)
            (define-key map (kbd "<C-S-up>") 'windu-nudge-in-bottom)
            (define-key map (kbd "<C-S-down>") 'windu-nudge-in-top)
            (define-key map (kbd "i") 'windu-echo-size)
            (define-key map (kbd "w") 'windu-set-width-right)
            (define-key map (kbd "W") 'windu-set-width-left)
            (define-key map (kbd "h") 'windu-set-height-bottom)
            (define-key map (kbd "H") 'windu-set-height-top)
            (define-key map (kbd "f") 'windu-fill-column-right)
            (define-key map (kbd "F") 'windu-fill-column-left)
            (define-key map (kbd "+") 'windu-fill-many-windows)
            (define-key map (kbd "3") 'windu-split-window-best-effort)
            (define-key map (kbd "r") 'windu-split-window-right)
            (define-key map (kbd "l") 'windu-split-window-left)
            map)
  (add-hook 'post-command-hook 'windu--post-command-handler))

(defun windu--post-command-handler ()
  "Deactivate `windu-transient-mode` after non-nudge actions."
  (let ((this-command-name (symbol-name this-command)))
    (cond ((not (or (eq 'windu-transient-activate this-command)
                    (eq (string-match "windu-nudge-" this-command-name) 0)))
           (windu-transient-abort)))))

(defun windu-fill-width (&optional window width)
  (let ((local-fill-column (buffer-local-value 'fill-column (window-buffer window))))
    (cond (width
           width)
          (t
           (+ (or windu-fill-column local-fill-column 79) windu-fill-column-padding)))))

(defun windu-do-nudge-left (&optional delta window)
  "Resize WINDOW by DELTA via moving its left edge."
  (let ((other-window (window-in-direction 'left window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window on the left of this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge other-window (- delta) t)))))

(defun windu-do-nudge-right (&optional delta window)
  "Resize WINDOW by DELTA via moving its right edge."
  (let ((other-window (window-in-direction 'right window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window on the right of this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge window delta t)))))

(defun windu-do-nudge-top (&optional delta window)
  "Resize WINDOW by DELTA via moving its top edge."
  (let ((other-window (window-in-direction 'above window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window above this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge other-window (- delta))))))

(defun windu-do-nudge-bottom (&optional delta window)
  "Resize WINDOW by DELTA via moving its bottom edge."
  (let ((other-window (window-in-direction 'below window))
        (delta (or delta 1)))
    (cond ((null other-window)
           (user-error "No window below this one"))
          ((not (eq delta 0))
           (adjust-window-trailing-edge window delta)))))

(defun windu-do-set-width-left (width &optional window)
  "Set WINDOW width to WIDTH by moving its left edge."
  (let ((delta (- width (window-total-width window))))
    (windu-do-nudge-left delta window)))

(defun windu-do-set-width-right (width &optional window)
  "Set WINDOW width to WIDTH by moving its right edge."
  (let ((delta (- width (window-total-width window))))
    (windu-do-nudge-right delta window)))

(defun windu-do-set-height-top (height &optional window)
  "Set WINDOW height to HEIGHT by moving its top edge."
  (let ((delta (- height (window-total-height window))))
    (windu-do-nudge-top delta window)))

(defun windu-do-set-height-bottom (height &optional window)
  "Set WINDOW height to HEIGHT by moving its bottom edge."
  (let ((delta (- height (window-total-height window))))
    (windu-do-nudge-bottom delta window)))

(defun windu-fill-windows-right(&optional window width)
  (cond ((not (null window))
         (ignore-errors
           (windu-do-set-width-right (windu-fill-width window width) window)
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

;;; end-user interactive wrapper functions

(defun windu-transient-activate ()
  "Begins a new nudge action."
  (interactive)
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
  (windu-do-nudge-left (* windu-nudge-x arg))
  (windu-echo-size))

(defun windu-nudge-out-right (&optional arg)
  "Increase current window size by ARG via pushing its right edge out."
  (interactive "p")
  (windu-do-nudge-right (* windu-nudge-x arg))
  (windu-echo-size))

(defun windu-nudge-out-top (&optional arg)
  "Increase current window size by ARG via pushing its top edge out."
  (interactive "p")
  (windu-do-nudge-top (* windu-nudge-y arg))
  (windu-echo-size))

(defun windu-nudge-out-bottom (&optional arg)
  "Increase current window size by ARG via pushing its bottom edge out."
  (interactive "p")
  (windu-do-nudge-bottom (* windu-nudge-y arg))
  (windu-echo-size))

(defun windu-nudge-in-left (&optional arg)
  "Decrease current window size by ARG via pulling its left edge in."
  (interactive "p")
  (windu-do-nudge-left (- (* windu-nudge-x arg)))
  (windu-echo-size))

(defun windu-nudge-in-right (&optional arg)
  "Decrease current window size by ARG via pulling its right edge in."
  (interactive "p")
  (windu-do-nudge-right (- (* windu-nudge-x arg)))
  (windu-echo-size))

(defun windu-nudge-in-top (&optional arg)
  "Decrease current window size by ARG via pulling its top edge in."
  (interactive "p")
  (windu-do-nudge-top (- (* windu-nudge-y arg)))
  (windu-echo-size))

(defun windu-nudge-in-bottom (&optional arg)
  "Decrease current window size by ARG via pulling its bottom edge in."
  (interactive "p")
  (windu-do-nudge-bottom (- (* windu-nudge-y arg)))
  (windu-echo-size))

(defun windu-set-width-left (width)
  "Set current window width to WIDTH by moving its left edge."
  (interactive "nSet width: ")
  (windu-do-set-width-left (windu-fill-width nil width))
  (windu-echo-size))

(defun windu-set-width-right (width)
  "Set current window width to WIDTH by moving its right edge."
  (interactive "nSet width: ")
  (windu-do-set-width-right (windu-fill-width nil width))
  (windu-echo-size))

(defun windu-fill-column-left ()
  "Set current window width to `fill-column`."
  (interactive)
  (windu-do-set-width-left (windu-fill-width))
  (windu-echo-size))

(defun windu-fill-column-right ()
  "Set current window width to `fill-column`."
  (interactive)
  (windu-do-set-width-right (windu-fill-width))
  (windu-echo-size))

(defun windu-fill-many-windows ()
  "Set every window to `fill-column` starting with the window at (0, 0)."
  (interactive)
  (balance-windows)
  (windu-fill-windows-right (window-at 0 0)))

(defun windu-split-window-left ()
  "Split current window side-by-side, moving the left edge as needed.
After the split, both windows aim to have `windu-fill-column` width."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'left)))
    (cond ((not (null other-window))
           (windu-do-set-width-left (* 2 width))))
    (let ((new-window (split-window nil (- width) 'right)))
      (windu-echo-sizes nil other-window 'right))))

(defun windu-split-window-right ()
  "Split current window side-by-side, moving the right edge as needed.
After the split, both windows aim to have `windu-fill-column` width."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'right)))
    (cond ((not (null other-window))
           (windu-do-set-width-right (* 2 width))))
    (let ((new-window (split-window nil width 'right)))
      (windu-echo-sizes nil new-window 'right))))

(defun windu-split-window-best-effort ()
  "Things."
  (interactive)
  (let ((width (windu-fill-width))
        (other-window (window-in-direction 'right)))
    (cond ((not (null other-window))
           (windu-do-set-width-right (* 2 width))))
    (cond ((< (window-total-width) (* 2 width))
           (let ((new-window (split-window nil nil 'right)))
             (windu-fill-column-right)
             (windu-echo-sizes nil new-window 'right)))
          (t
           (let ((new-window (split-window nil width 'right)))
             (windu-echo-sizes nil new-window 'right))))))

(defun windu-default-keybindings ()
  "Set up keybinding for `windu-transient-mode`."
  (interactive)
  (global-set-key (kbd "C-x C-_") 'windu-transient-activate))

(provide 'windu)

;;; windu.el ends here
