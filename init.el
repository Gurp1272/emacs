(defun my-append-env-var (var-name value)
  "Append VALUE to the beginning of current value of env variable VAR-NAME."
  (setenv var-name (if (getenv var-name)
                       (format "%s:%s" value (getenv var-name))
                     value)))

(let ((gccjitpath "/opt/homebrew/lib/gcc/15:/opt/homebrew/lib"))
  (mapc (lambda (var-name) (my-append-env-var var-name gccjitpath))
        '("LIBRARY_PATH" "LD_LIBRARY_PATH" "PATH")))

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

(use-package emacs
  :init
  (load-theme 'modus-vivendi)
  ;; disable modes
  (when scroll-bar-mode
    (scroll-bar-mode -1))
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (fido-vertical-mode)
  :custom
  (treesit-language-source-alist
   '((ruby "https://github.com/tree-sitter/tree-sitter-ruby"))))

;; Fullscreen on startup
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Enable a minimal theme
;;(use-package modus-themes
;;  :ensure t
;;  :config
;;  (load-theme 'modus-vivendi t))

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
 '(custom-safe-themes
   '("77f281064ea1c8b14938866e21c4e51e4168e05db98863bd7430f1352cab294a"
     default))
 '(package-selected-packages '(dashboard elixir-mode modus-themes nano-modeline)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; which key
(use-package which-key
  :ensure t
  :commands (which-key-mode)
  :init
  (which-key-mode))

;; nano mode-line
(use-package nano-modeline
  :ensure t
  :init
  (nano-modeline-prog-mode t)
  :custom
  (nano-modeline-position 'nano-modeline-footer)
  :hook
  (prog-mode     . nano-modeline-prog-mode)
  (text-mode     . nano-modeline-text-mode))

;; Ruby mode
(use-package ruby-ts-mode
  :mode "\\.rb\\'"
  :mode "Rakefile\\'"
  :mode "Gemfile\\'")

;; Elixir mode
(use-package elixir-mode
  :ensure t
  :hook
  (elixir-mode . eglot-ensure) ; Start LSP automatically in Elixir files
  :config
  (add-to-list 'exec-path "~/.elixir-ls") ; Adjust path to elixir-ls if needed
)

;; Eglot for LSP support
(use-package eglot
  :hook (prog-mode . eglot-ensure))



