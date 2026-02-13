;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emacs Starter Pack + Theme Switcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Package system setup
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")
                         ("org"   . "https://orgmode.org/elpa/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Ensure use-package
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Activate shell scripts in Org Babel
(org-babel-do-load-languages 'org-babel-load-languages '((shell . t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI / Basic Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Enable line numbers globally
(global-display-line-numbers-mode t)

;; Set default font
(set-face-attribute 'default nil
                    :family "JetBrainsMono Nerd Font"
                    :weight 'regular
                    :height 110)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; which-key – keybinding hints
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package which-key
  :diminish
  :config
  (which-key-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; org-roam - backlinked knowledgebase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/org-roam"))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode))
  ;; If using org-roam-protocol
  ;; (require 'org-roam-protocol))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion Suite – vertico, orderless, marginalia, consult
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package vertico
;;   :init (vertico-mode))

;; (use-package orderless
;;   :init (setq completion-styles '(orderless)
;;               completion-category-defaults nil
;;               completion-category-overrides '((file (styles partial-completion)))))

;; (use-package marginalia
;;   :init (marginalia-mode))

;; (use-package consult
;;   :bind (("C-s" . consult-line)
;;          ("C-x b" . consult-buffer)
;;          ("M-y" . consult-yank-pop)
;;          ("M-g g" . consult-goto-line)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; magit – Git interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package magit
  :bind ("C-x g" . magit-status))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; projectile – project management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package projectile
;;   :diminish
;;   :config (projectile-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; company – auto-completion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package company
;;   :diminish
;;   :config
;;   (setq company-idle-delay 0.2
;;         company-minimum-prefix-length 1)
;;   (global-company-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; flycheck – on-the-fly linting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package flycheck
;;   :init (global-flycheck-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yasnippet – code snippets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package yasnippet
;;   :config (yas-global-mode 1))
;; (use-package yasnippet-snippets)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; org-mode – notes, tasks, outlining
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org
  :mode ("\\.org\\'" . org-mode)
  :config
  (setq org-hide-emphasis-markers t
        org-startup-indented t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Doom UI packages – themes, modeline, icons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package doom-themes
  :config (load-theme 'doom-one t))

(use-package all-the-icons
  :if (display-graphic-p))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 20)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Theme Switcher – Top 20 themes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package dracula-theme)
(use-package solarized-theme)
(use-package gruvbox-theme)
(use-package monokai-theme)
(use-package nord-theme)
(use-package modus-themes)
(use-package zenburn-theme)
(use-package catppuccin-theme)
(use-package leuven-theme)
(use-package tango-plus-theme)
(use-package ef-themes)
(use-package ayu-theme)
(use-package material-theme)
(use-package gruber-darker-theme)
(use-package spacemacs-theme)
(use-package ample-theme)
(use-package hc-zenburn-theme)

;; Quick theme switcher with hydra
(use-package hydra)

(defhydra hydra-themes (:hint nil)
  "
Themes:
_d_:doom-one   _n_:nord        _c_:catppuccin  
_g_:gruvbox    _z_:zenburn     _s_:solarized   _m_:monokai
_a_:ayu        _M_:modus       _l_:leuven      _f_:ef-themes
_h_:hc-zenburn _p_:spacemacs   _r_:dracula     _y_:gruber-darker
_A_:ample
"
  ("d" (load-theme 'doom-one t))
  ("n" (load-theme 'nord t))
  ("c" (load-theme 'catppuccin t))
  ("g" (load-theme 'gruvbox-dark-medium t))
  ("z" (load-theme 'zenburn t))
  ("s" (load-theme 'solarized-dark t))
  ("m" (load-theme 'monokai t))
  ("a" (load-theme 'ayu-dark t))
  ("M" (load-theme 'modus-vivendi t))
  ("l" (load-theme 'leuven t))
  ("f" (load-theme 'ef-dark t))
  ("h" (load-theme 'hc-zenburn t))
  ("p" (load-theme 'spacemacs-dark t))
e  ("r" (load-theme 'dracula t))
  ("y" (load-theme 'gruber-darker t))
  ("A" (load-theme 'ample t))
  ("q" nil "quit"))

(global-set-key (kbd "C-c T") 'hydra-themes/body)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(all-the-icons ample-theme ayu-theme catppuccin-theme csv-mode
		   doom-modeline doom-themes dracula-theme ef-themes
		   exec-path-from-shell fireplace gptel
		   gruber-darker-theme gruvbox-theme hc-zenburn-theme
		   hydra leuven-theme magit material-theme
		   modus-themes monokai-theme nord-theme nov org-roam
		   solarized-theme spacemacs-theme tango-plus-theme
		   timu-macos-theme writegood-mode zenburn-theme)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
