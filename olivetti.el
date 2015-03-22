;;; olivetti.el --- Minor mode for a nice writing environment

;; Copyright (C) 2014  Paul Rankin

;; Author: Paul Rankin <paul@tilk.co>
;; Keywords: wp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Olivetti
;; ========

;; Olivetti is a simple Emacs minor mode for a nice writing environment.

;; Features
;; --------

;; - set a desired text body width to automatically resize window margins
;;   to keep the text comfortably in the middle of the window
;; - text body width can be the number of characters (an integer) or a
;;   fraction of the window width (a float between 0.0 and 1.0)
;; - optionally hide the modeline for distraction-free writing

;; Olivetti actually duplicates a subset of features already present in
;; [Writeroom-mode][], but Olivetti keeps all features buffer-local.

;; [writeroom-mode]: https://github.com/joostkremers/writeroom-mode "Writeroom-mode"

;; Requirements
;; ------------

;; - Emacs 24.1 (not tested on earlier versions, only tested on Mac OS X
;;   and Linux, not tested on Windows).

;; Installation
;; ------------

;; Olivetti is available through [MELPA][] and [MELPA-stable][]. I
;; encourage installing the stable version.

;; [melpa]: http://melpa.milkbox.net "MELPA"
;; [melpa-stable]: http://melpa-stable.milkbox.net "MELPA"
;; [latest release]: https://github.com/rnkn/olivetti/releases/latest "Olivetti latest release"

;; History
;; -------

;; See [Releases][].

;; [releases]: https://github.com/rnkn/olivetti/releases "Olivetti releases"

;;; Code:

(defgroup olivetti ()
  "Minor mode for a nice writing environment"
  :prefix "olivetti-"
  :group 'wp)

;;; Customizable Variables =====================================================

(defcustom olivetti-mode-hook
  '(turn-on-visual-line-mode)
  "Mode hook for `olivetti-mode', run after mode is turned on."
  :type 'hook
  :group 'olivetti)

(defcustom olivetti-body-width 66
  "Text body width to which to adjust relative margin width.

If an integer, set text body width to that integer in columns; if
a floating point between 0.0 and 1.0, set text body width to
that fraction of the total window width.

An integer is best if you want text body width to remain
constant, while a floating point is best if you want text body
width to change with window width.

The floating point can anything between 0.0 and 1.0 (exclusive),
but it's better to use a value between about 0.33 and 0.9 for
best effect.

This option does not affect file contents."
  :type '(choice (integer 80) (float 0.5))
  :group 'olivetti)
(make-variable-buffer-local 'olivetti-body-width)

(defcustom olivetti-minimum-body-width
  40
  "Minimum width in columns that text body width may be set."
  :type 'integer
  :group 'olivetti)

(defcustom olivetti-hide-mode-line nil
  "Hide the mode line.
Can cause display issues in console mode."
  :type 'boolean
  :group 'olivetti)

;;; Functions ==================================================================

(defun olivetti-set-mode-line (&optional arg)
  "Set the mode line formating appropriately.
If ARG is 'toggle, toggle the value of `olivetti-hide-mode-line',
then rerun. If ARG is 'exit, kill `mode-line-format' then rerun.
If ARG is nil and `olivetti-hide-mode-line' is non-nil, hide the
mode line. Finally redraw the frame."
  (cond ((equal arg 'toggle)
         (setq olivetti-hide-mode-line
               (null olivetti-hide-mode-line))
         (olivetti-set-mode-line))
        ((or (equal arg 'exit)
             (null olivetti-hide-mode-line))
         (kill-local-variable 'mode-line-format))
        (olivetti-hide-mode-line
         (setq-local mode-line-format nil)))
  (redraw-frame (selected-frame)))

(defun olivetti-safe-width (n)
  "Parse N to a safe value for `olivetti-body-width'."
  (let ((window-width (- (window-total-width)
                         (% (window-total-width) 2)))
        (min-width (+ olivetti-minimum-body-width
                      (% olivetti-minimum-body-width 2))))
    (cond ((integerp n)
           (let ((width (min n window-width)))
             (max width min-width)))
          ((floatp n)
           (let ((min-width
                  (string-to-number (format "%0.2f"
                                            (/ (float min-width)
                                               window-width))))
                 (width
                  (string-to-number (format "%0.2f"
                                            (min n 1.0)))))
             (max width min-width)))
          ((message "`olivetti-body-width' must be an integer or a float")
           (setq olivetti-body-width
                 (car (get 'olivetti-body-width 'standard-value)))))))


(defun olivetti-set-environment ()
  "Set text body width to `olivetti-body-width' with relative margins."
  (let* ((n olivetti-body-width)
         (width
          (cond ((integerp n) n)
                ((and (floatp n)
                      (< n 1)
                      (> n 0))
                 (* (window-total-width) n)))))
    (if width
        (let ((margin
               (round (/ (- (window-total-width) width) 2))))
          (set-window-margins (selected-window) margin margin))
      (message "`olivetti-body-width' must be an integer or a float between 0 and 1"))))

(defun olivetti-toggle-hide-modeline ()
  "Toggle the visibility of the modeline.
Toggles the value of `olivetti-hide-mode-line' and runs
`olivetti-set-mode-line'."
  (interactive)
  (olivetti-set-mode-line 'toggle))

;; Mode Definition =============================================================

;;;###autoload
(defun turn-on-olivetti-mode ()
  "Turn on `olivetti-mode' unconditionally."
  (interactive)
  (olivetti-mode 1))

;;;###autoload
(define-minor-mode olivetti-mode
  "Olivetti provides a nice writing environment.

Window margins are set to relative widths to accomodate a text
body width set in `olivetti-body-width'.

When `olivetti-hide-mode-line' is non-nil, the mode line is also
hidden."
  :init-value nil
  :lighter " Olv"
  (if olivetti-mode
      (progn
        (if olivetti-hide-mode-line
            (olivetti-set-mode-line))
        (add-hook 'window-configuration-change-hook
                  'olivetti-set-environment nil t)
        (add-hook 'after-setting-font-hook
                  'olivetti-set-environment nil t)
        (olivetti-set-environment))
    (olivetti-set-mode-line 'exit)
    (set-window-margins nil nil)
    (remove-hook 'window-configuration-change-hook
                 'olivetti-set-environment t)
    (remove-hook 'after-setting-font-hook
                 'olivetti-set-environment t)))

(provide 'olivetti)
;;; olivetti.el ends here
