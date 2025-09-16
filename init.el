;; Initialize package sources
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Refresh package list if not already done
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package for cleaner package management
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t) ; Automatically install packages

;; Enable a minimal theme
(use-package modus-themes
  :ensure t
  :config
  (load-theme 'modus-vivendi t))

;; Disable default splash screen and startup message
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  ;; Customize dashboard content
  (setq dashboard-items '((recents . 5)
			  (projects . 5)
			  (agenda . 5)))
  (setq dashboard-center-content t)
  (setq dashboard-show-shortcut t)
  (setq dashboard-banner-logo-title "Welcome to the intricacies of my mind.")
  (setq dashboard-startup-banner 'logo)
  ;; Footer
  (setq dashboard-footer-messages '("Happy coding and beyond"))
  :hook
  (emacs-startup-hook . dashboard-open))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; Disable modes
(menu-bar-mode -1)
(tool-bar-mode -1)

;; Fullscreen on startup
(add-to-list 'default-frame-alist '(fullscreen . maximized))
