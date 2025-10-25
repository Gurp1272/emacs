;; Library path for libtree-sitter on macOS
(when (memq window-system '(mac ns))
  (setenv "DYLD_LIBRARY_PATH" (concat "/opt/homebrew/Cellar/tree-sitter/0.25.10/lib:" (getenv "DYLD_LIBRARY_PATHg200g")))
  (add-to-list 'treesit-extra-load-path "/opt/homebrew/Cellar/tree-sitter/0.25.10/lib"))

;; Set environment for csharp-ls
(when (memq window-system '(mac ns)) ; macOS GUI
  (setenv "PATH" (concat (getenv "PATH") ":/opt/homebrew/bin:/Users/isaac/.dotnet/tools"))
  (add-to-list 'exec-path "/opt/homebrew/bin")
  (add-to-list 'exec-path "/Users/isaac/.dotnet/tools")
  (setenv "DOTNET_ROOT" "/opt/homebrew/opt/dotnet/libexec"))
(when (not (memq window-system '(mac ns))) ; Linux or Terminal
  (setenv "PATH" (concat (getenv "PATH") ":/home/isaac/.dotnet/tools"))
  (add-to-list 'exec-path "/home/isaac/.dotnet/tools"))

;; Ensure .NET tools are in PATH for csharp-ls
(setenv "PATH" (concat (getenv "PATH") ":/Users/isaac/.dotnet/tools:/home/isaac/.dotnet/tools"))
(add-to-list 'exec-path "/Users/isaac/.dotnet/tools")
(add-to-list 'exec-path "/home/isaac/.dotnet/tools")

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
 '(package-selected-packages nil))
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

;; ;; tree-sitter
;; (use-package treesit
;;   :ensure nil ;; built in to emacs 30.2
;;   :config
;;   ;; Define the C# grammar source
;;   (setq treesit-language-source-alist
;; 	'((c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp" "master" "src")))
;;   ;; Map csharp-mode to csharp-ts-mode
;;   (add-to-list 'major-mode-remap-alist '(csharp-mode . csharp-ts-mode))
;;   ;; Auto install C# grammar if missing
;;   (unless (treesit-language-available-p 'c-sharp)
;;     (treesit-install-language-grammar 'c-sharp))
;;   ;; Enable tree-sitter features for csharp-ts-mode
;;   :hook
;;   (csharp-ts-mode . (lambda ()
;; 		      (treesit-parser-create 'c-sharp)
;; 		      (treesit-major-mode-setup))))

;; ;; Map .cs files to csharp-ts-mode
;; (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-ts-mode))

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


;; rainbow-delimiters
;;(use-package rainbow-delimiters
;;  :ensure t)

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-l")
  (setq lsp-csharp-server-path (or (executable-find "csharp-ls") "/home/isaac/.dotnet/tools/csharp-ls" "/Users/isaac/.dotnet/tools/csharp-ls"))
  ;; disable omnisharp explicitly
  (setq lsp-disabled-clients '(omnisharp))
  :hook (
	 (csharp-mode . lsp-deferred)
	 (lsp-mode    . lsp-enable-which-key-integration))
  :commands lsp
  :config
  (setq lsp-enable-snippet nil) ; Disable snippets to avoid YASnippet warning
  (setq lsp-log-io t) ; Enable detailed LSP logging
  (setq lsp-print-performance t) ; Log performance metrics
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection (lambda () lsp-csharp-server-path))
    :major-modes '(csharp-mode)
    :server-id 'csharp-ls
    :priority 1))) ; High priority to ensure csharp-ls is used

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

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode))

;; Install and configure DAP mode
(use-package dap-mode
  :ensure t
  :after lsp-mode ; Optional: If using LSP for C# (recommended for IntelliSense)
  :hook
  (dap-session-created . my-dap-ui-setup) ;; Run layout setup on session start
  (dap-terminated . (lambda () (delete-other-windows)))
  :config
  ;; Enable core DAP features
;;  (dap-mode 1)
  (dap-ui-mode 1)
;;  (dap-tooltip-mode 1)

  ;; Optional: Auto-configre (uncomment if desired)
  (setq dap-auto-configure-features '(sessions locals tooltip))

  ;; Customize DAP UI window layout
  (defun my-dap-ui-setup ()
    "Set up DAP UI windows for debugging."
    (interactive)
    ;; Open debugging buffers in a specific layout
    (delete-other-windows) ; Clear existing windows
    (let ((main-window (selected-window)))
      ;; Split main window horizontally for code (70%) and stack/locals (30%)
      (select-window (split-window-horizontally (- (window-width) (/ (window-width) 3))))
      ;; Show call stack and locals in the right pane
      (dap-ui-locals)
      (dap-ui-stack-frames)
      ;; Split the right pain vertically for breakpoints
      (select-window (split-window-vertically))
      (dap-ui-breakpoints)
      ;; Return to the main code window
      (select-window main-window)))

  ;; Automatically trigger UI setup when a debug session starts
;;  (add-hook 'dap-session-created . #'my-dap-ui-setup) ;; Run layout setup on session start
;;  (add-hook 'dap-terminated . (lambda () (delete-other-windows))) ;; Cleanup when the session ends

  ;; Keybindings (customizen as needed)
  (global-set-key (kbd "C-c d b") 'dap-breakpoint-toggle)
  (global-set-key (kbd "C-c d c") 'dap-continue)
  (global-set-key (kbd "C-c d n") 'dap-next)
  (global-set-key (kbd "C-c d s") 'dap-step-in)
  (global-set-key (kbd "C-c d o") 'dap-step-out)
  (global-set-key (kbd "C-c d h") 'dap-hydra)
  (global-set-key (kbd "C-c d r") 'dap-restart)
  ;; Load netcore support
  (require 'dap-netcore)
  ;; Set path to installed netcoredbg
  (setq dap-netcore--debugger-cmd "/usr/local/bin/netcoredbg")
  ;; Debug templates for .NET
  (dap-register-debug-template "NetCore Launch (Console)"
			       (list :type "coreclr"
				     :request "launch"
				     :name "NetCore Launch (Console)"
				     :dap-compilation "dotnet build"
				     :program (concat "${workspaceFolder}/bin/Debug/net9.0/${workspaceFolderBasename}.dll")
				     :cwd "${workspaceFolder}"
				     :stopAtEntry t
				     :console "integratedTerminal"
				     :env (list :append '("ASPNETCORE_ENVIRONMENT" . "Development"))))
  (dap-register-debug-template "NetCore Attach (Console)"
			       (list :type "coreclr"
				     :request "attach"
				     :name "NetCore Attach (Console)"
				     :processId (lambda () (read-number "PID to attach: "))))
  (dap-register-debug-template "NetCore Debug MSTest"
			       (list :type "coreclr"
				     :request "launch"
				     :name "NetCore Debug MSTest"
				     :mode "launch"
				     :dap-compilation "dotnet build"
				     :program (concat (project-root (project-current t)) "bin/Debug/net9.0/" (file-name-base (project-root (project-current t))) ".dll")
				     :cwd (project-root (project-current t))
				     :console "integratedTerminal"
				     :args (lambda () (list "--no-build" "--filter" (read-string "Test filter (e.g., FullyQualifiedName=Namespace.TestClass.TestMethod): ")))
				     :env (list :append '("ASPNETCORE_ENVIRONMENT" . "Development")))))


;; dotnet test project without debugging
(defun dotnet-test-project ()
  "Run 'dotnet test' in the current project root detected by project.el."
  (interactive)
  (let ((default-directory (or (project-root (project-current t))
			       default-direcory)))
    (compile "dotnet test --no-build --verbosity normal")))

;; bind dotnet-test-project to key
(global-set-key (kbd "C-c t") 'dotnet-test-project)

;; editor config
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))
