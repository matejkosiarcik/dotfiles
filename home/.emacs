;; visibility for eww
;;(setq shr-color-visible-luminance-min 70)
(advice-add #'shr-colorize-region :around (defun shr-no-colourise-region (&rest ignore)))
