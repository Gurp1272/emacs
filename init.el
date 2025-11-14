;; Library path for libtree-sitter on macOS
(when (memq window-system '(mac ns))
  (setenv "DYLD_LIBRARY_PATH" (concat "/opt/homebrew/Cellar/tree-sitter/0.25.10/lib:" (getenv "DYLD_LIBRARY_PATHg200g")))
  (add-to-list 'treesit-extra-load-path "/opt/homebrew/Cellar/tree-sitter/0.25.10/lib"))

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

;; threshold
(setq gc-cons-threshold 100000000)

;; so emacs will inherit shell path variables
(use-package exec-path-from-shell
  :ensure t
  :config
  (exec-path-from-shell-initialize))

;; Disable modes
(menu-bar-mode -1)
(tool-bar-mode -1)

;; Fullscreen on startup
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; numbered lines
(global-display-line-numbers-mode t)

;; doom-modeline
(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))

;; Enable a minimal theme
(use-package darkokai-theme
  :ensure t
  :config
  (load-theme 'darkokai t))

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
  (setq dashboard-banner-logo-title "Waves of possibility ripple through the universe, only collapse completely when observed in crystalline clarity.")
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
 '(package-selected-packages
   '(company dap-mode darkokai-theme dashboard doom-modeline elixir-mode
	     exec-path-from-shell flycheck flycheck-eglot helm-lsp
	     lsp-ui magit modus-themes nano-modeline
	     rainbow-delimiters treesit-auto tsc yasnippet)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; magit
(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
	 ("C-x M-g" . magit-dispatch)) ;; Opens Magit command menu
  :config
  (setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (setq magit-diff-refine-hunk t) ;; show word-level diff highlights
  (setq magit-save-repository-buffers 'dontask) ;; auto-save buffers before git operations
  :hook
  (magit-status-mode . (lambda () (visual-line-mode 1)))) ;; enable visual-line-mode in magit buffers

;; ----- Company ----- ;;
(use-package company
  :ensure t
  :hook (elixir-ts-mode . company-mode)
  :config
  (setq company-idle-delay 0.2
	company-minimum-prefix-length 2))


;; ----- Eglot Config ----- ;;
(use-package eglot
  :hook ((elixir-ts-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
	       '((elixir-mode elixir-ts-mode heex-ts-mode)
		 . ("/home/isaac/.elixir-ls/release/language_server.sh"))))

;; ----- Flycheck ----- ;;
(use-package flycheck
  :ensure t
  :hook (elixir-ts-mode . flycheck-mode)
  :config
  (use-package flycheck-eglot
    :ensure t
    :after flycheck eglot
    :config
    (global-flycheck-eglot-mode 1)))

;; ----- HEEX ----- ;;
(use-package heex-ts-mode
  :ensure t
  :mode ("\\.heex\\'"))

(use-package which-key
  :config
  (which-key-mode))

;; ----- Elixir ----- ;;
(add-to-list 'auto-mode-alist '("\\.ex\\'" . elixir-ts-mode))
(add-to-list 'auto-mode-alist '("\\.exs\\'" . elixir-ts-mode))

(use-package elixir-mode
  :ensure t
  :mode (("\\.ex\\'"    . elixir-ts-mode)
	 ("\\.exs\\'"   . elixir-ts-mode)))

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode))

;; editor config
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))
