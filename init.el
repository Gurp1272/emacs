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
(setq gc-cons-threshold 3500000)

;; Disable modes
(menu-bar-mode -1)
(tool-bar-mode -1)

;; Fullscreen on startup
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; doom-modeline
;;(use-package doom-modeline
;;  :ensure t
;;  :hook (after-init . doom-modeline-mode))

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
 '(package-selected-packages
   '(company dashboard doom-modeline flycheck helm-lsp lsp-treemacs
	     lsp-ui magit modus-themes nano-modeline
	     rainbow-delimiters tree-sitter-langs tsc)))
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

;; which-key
;;(use-package which-key
;;  :ensure t
;;  :init
;;  (which-key-mode 1)
;;  :config
;;  (setq which-key-idle-delay 0.3))

;; company
(use-package company
  :ensure t
  :hook (csharp-mode . company-mode)
  :config
  (setq company-idle-delay 0.2
	company-minimum-prefix-length 1))

;; flycheck
(use-package flycheck
  :ensure t
  :hook (csharp-mode . flycheck-mode))

;; tree-sitter
;; (add-to-list 'tree-sitter-major-mode-language-alist '(csharp-ts-mode . csharp))
;; (use-package treesit
;;  :ensure nil ; built in
;; ;; :hook (csharp-ts-mode . tree-sitter-mode)
;;  :config
;;  (setq treesit-language-source-alist
;;        '((c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp")))
;;  (add-to-list 'major-mode-remap-alist '(csharp-mode . csharp-ts-mode))
;;  (add-hook 'csharp-ts-mode-hook #'treesit-font-lock-enable)
;;  (add-hook 'csharp-ts-mode-hook #'treesit-major-mode-setup))
;; (add-to-list 'treesit-extra-load-path "/home/isaac/.emacs.d/elpa/tree-sitter-langs-20250922.704/bin"))

;; tree-sitter-langs
;;(use-package tree-sitter-langs
;;  :ensure t
;;  :config
;;  (tree-sitter-langs-install-grammars))

;; (use-package lsp-ui :commands lsp-ui-mode)

;; (use-package which-key
;;   :config
;;   (which-key-mode))

;; rainbow-delimiters
;;(use-package rainbow-delimiters
;;  :ensure t)

;; (use-package lsp-mode
;; ;;  :ensure t
;;   :commands (lsp lsp-deferred)
;;   :hook (
;; 	 (csharp-mode . lsp-deferred)
;; 	 (lsp-mode    . lsp-enable-which-key-integration))
;;   :init
;;   (setq lsp-csharp-server-path (or (executable-find "csharp-ls") "/home/isaac/.dotnet/tools/csharp-ls"))
;;   :config
;;   (lsp-register-client
;;    (make-lsp-client
;;     :new-connection (lsp-stdio-connection (lambda () (list lsp-csharp-server-path)))
;;     :major-modes '(csharp-mode)
;;     :server-id 'csharp-ls
;;     :priority 1))
;;   (setq lsp-auto-guess-root t
;;         ;;lsp-log-io t                 ; Enable detailed logging
;;         ;;lsp-print-performance t      ; Log performance metrics
;;         lsp-csharp-server-install-dir nil ; Disable auto-install
;;         lsp-keep-workspace-alive nil ; Restart server if it crashes
;;         lsp-client-reconnect t       ; Attempt to reconnect
;;         lsp-diagnostic-clean-after-change t))



;; (use-package lsp-ui
;;   :ensure t
;;   :after lsp-mode
;;   :commands lsp-ui-mode
;;   :config
;;   (setq lsp-ui-doc-enable t
;;         lsp-ui-doc-position 'at-point
;;         lsp-ui-sideline-enable t
;; 	lsp-ui-sideline-show-hover t
;; 	lsp-ui-flycheck-enable t))

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-l")
  (setq lsp-csharp-server-path (or (executable-find "csharp-ls") "/home/isaac/.dotnet/tools/csharp-ls"))
  :hook (
	 (csharp-mode . lsp-deferred)
	 (lsp-mode    . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-ui :commands lsp-ui-mode)
(use-package helm-lsp :commands helm-lsp-workspace-symbols)
(use-package lsp-treemacs :commands lsp-treemacs-errors-list)
(use-package which-key
  :config
  (which-key-mode))

(use-package csharp-mode
  :ensure t
  :mode "\\.cs\\'"
  :hook (
	 (csharp-mode . lsp-deferred)
	 (csharp-mode . font-lock-mode)
	 (csharp-mode . electric-pair-local-mode)
	 (csharp-mode . (lambda () (font-lock-ensure))))
  :config (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-mode) t))
