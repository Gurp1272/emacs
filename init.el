;;; init.el --- Elixir IDE + AI in Emacs -*- lexical-binding: t -*-

;;; Commentary:
;;
;; Layout of this file:
;;   1. Package system + use-package
;;   2. Core editor defaults
;;   3. Look & feel (theme, font, modeline, dashboard, icons)
;;   4. Discoverability (which-key, helpful, cheatsheet on C-c ?)
;;   5. Minibuffer completion (vertico / consult / embark)
;;   6. Editing helpers (Prelude picks: crux, avy, expand-region, ...)
;;   7. Project, files, tree sidebar (treemacs), symbol tree (imenu-list)
;;   8. Git (magit, diff-hl)
;;   9. Completion + diagnostics (company, flycheck)
;;  10. LSP (lsp-mode + lsp-ui) and header-line breadcrumb
;;  11. Elixir (tree-sitter, ElixirLS, exunit, iex, mix, dap)
;;  12. AI (claude-code.el driving the Claude Code CLI)
;;  13. Remote projects over SSH (TRAMP)
;;  14. Leader keymaps under C-c
;;
;; Keybinding scheme: everything custom lives under `C-c <letter>'.
;; Press `C-c' and wait for which-key, or press `C-c ?' for a cheatsheet.
;;
;;   C-c a  AI (Claude Code, local or over SSH)   C-c j  jump (avy, xref)
;;   C-c b  buffers                      C-c l  LSP (lsp-mode's own map)
;;   C-c d  debug (dap)                  C-c m  Elixir / mix (Elixir buffers only)
;;   C-c e  edit                         C-c p  project (C-c p R opens one over SSH)
;;   C-c f  files                        C-c s  search
;;   C-c g  git                          C-c t  toggles
;;   C-c h  help                         C-c w  windows

;;; Code:

;;; ---------------------------------------------------------------------------
;;; 1. Package system
;;; ---------------------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(setq package-archive-priorities '(("melpa" . 10) ("gnu" . 5) ("nongnu" . 5)))
(setq package-native-compile t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-compute-statistics nil)

;; Keep customize's noise out of this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; Inherit PATH & friends from the login shell so asdf shims, mix, claude are found.
(use-package exec-path-from-shell
  :if (or (daemonp) (memq window-system '(pgtk x mac ns)))
  :config
  (dolist (var '("PATH" "MANPATH" "ASDF_DIR" "ASDF_DATA_DIR" "MIX_HOME" "HEX_HOME"
                 "ERL_AFLAGS" "LANG" "LC_ALL"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;;; ---------------------------------------------------------------------------
;;; 2. Core editor defaults
;;; ---------------------------------------------------------------------------

(use-package emacs
  :ensure nil
  :init
  (setq inhibit-startup-screen t
        initial-scratch-message nil
        ring-bell-function #'ignore
        use-short-answers t
        confirm-kill-processes nil
        require-final-newline t
        sentence-end-double-space nil
        create-lockfiles nil
        load-prefer-newer t
        scroll-conservatively 101
        scroll-margin 3
        mouse-wheel-progressive-speed nil
        enable-recursive-minibuffers t
        read-process-output-max (* 4 1024 1024)) ; LSP sends big payloads
  (setq-default indent-tabs-mode nil
                tab-width 2
                fill-column 98            ; Elixir formatter's line length
                truncate-lines t)
  ;; Put backups and auto-saves out of the way.
  (let ((backups (expand-file-name "backups/" user-emacs-directory))
        (autosaves (expand-file-name "auto-saves/" user-emacs-directory)))
    (make-directory backups t)
    (make-directory autosaves t)
    (setq backup-directory-alist `(("." . ,backups))
          auto-save-file-name-transforms `((".*" ,autosaves t))
          backup-by-copying t
          delete-old-versions t
          kept-new-versions 6
          version-control t))
  :config
  (column-number-mode 1)
  (global-auto-revert-mode 1)
  (delete-selection-mode 1)
  (electric-pair-mode 1)
  (show-paren-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (winner-mode 1)                       ; C-c w u undoes window changes
  (pixel-scroll-precision-mode 1)
  (global-so-long-mode 1)
  (add-hook 'prog-mode-hook #'display-line-numbers-mode)
  (add-hook 'text-mode-hook #'display-line-numbers-mode)
  (add-hook 'prog-mode-hook #'hl-line-mode)
  (add-hook 'before-save-hook #'delete-trailing-whitespace)
  ;; Undo/redo without the old "undo the undo" dance.
  :bind (("C-?" . undo-redo)
         ("C-x k" . kill-current-buffer)))

(use-package recentf
  :ensure nil
  :init (setq recentf-max-saved-items 200
              recentf-exclude '("/elpa/" "/tmp/" "\\.gz\\'" "/_build/" "/deps/"))
  :config (recentf-mode 1))

;; Restore normal GC after startup (lsp-mode recommends a high-ish value).
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 100 1024 1024))))

;; Tree-sitter grammars.  Emacs 30 ships elixir-ts-mode and heex-ts-mode but
;; not the grammars; install them once, automatically (needs git and a C compiler).
(use-package treesit
  :ensure nil
  :init
  (setq treesit-language-source-alist
        '((elixir "https://github.com/elixir-lang/tree-sitter-elixir")
          (heex   "https://github.com/phoenixframework/tree-sitter-heex")))
  (setq treesit-font-lock-level 4)
  :config
  ;; Fedora ships libtree-sitter-elixir/heex in /usr/lib64, so this is a no-op there.
  (dolist (lang (mapcar #'car treesit-language-source-alist))
    (unless (treesit-language-available-p lang)
      (message "Installing tree-sitter grammar for %s..." lang)
      (condition-case err
          (treesit-install-language-grammar lang)
        (error (message "Could not install %s grammar: %s" lang err))))))

;;; ---------------------------------------------------------------------------
;;; 3. Look & feel
;;; ---------------------------------------------------------------------------

(defun my/first-available-font (fonts)
  "Return the first font family in FONTS that is installed."
  (seq-find (lambda (f) (find-font (font-spec :family f))) fonts))

(defun my/apply-font ()
  "Use JetBrains Mono (installed under ~/.local/share/fonts) with fallbacks."
  (when-let* ((font (my/first-available-font
                     '("JetBrains Mono" "JetBrainsMono Nerd Font" "DejaVu Sans Mono"))))
    (set-face-attribute 'default nil :family font :height 120)))
(my/apply-font)
;; `find-font' only works once a graphical frame exists, so re-run for daemon clients.
(add-hook 'server-after-make-frame-hook #'my/apply-font)

(use-package spacemacs-theme
  :init (setq my/dark-theme 'spacemacs-dark
              my/light-theme 'spacemacs-light)
  :config
  (load-theme my/dark-theme t))

(defun my/toggle-theme ()
  "Switch between the dark and light theme."
  (interactive)
  (let ((next (if (memq my/dark-theme custom-enabled-themes)
                  my/light-theme my/dark-theme)))
    (mapc #'disable-theme custom-enabled-themes)
    (load-theme next t)
    (message "Theme: %s" next)))

(use-package nerd-icons)                ; uses the Symbols Nerd Font you have installed
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))
(use-package nerd-icons-ibuffer
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :init
  (setq doom-modeline-buffer-file-name-style 'truncate-with-project
        doom-modeline-lsp t
        doom-modeline-vcs-max-length 30
        doom-modeline-height 28))

(use-package dashboard
  :init
  (setq dashboard-startup-banner 'logo
        dashboard-banner-logo-title
        "Waves of possibility ripple through the universe, only collapse completely when observed in crystalline clarity."
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons
        dashboard-set-file-icons t
        dashboard-set-heading-icons t
        dashboard-projects-backend 'project-el
        dashboard-items '((recents . 8) (projects . 5))
        dashboard-footer-messages
        '("Press C-c ? for the keybinding cheatsheet.  Press C-c and wait to browse."
          "C-c a a toggles Claude Code.  C-c a m opens the full Claude menu."
          "F8 toggles the file tree, F9 the symbol tree."))
  :config
  (dashboard-setup-startup-hook))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

;;; ---------------------------------------------------------------------------
;;; 4. Discoverability
;;; ---------------------------------------------------------------------------

;; which-key: press a prefix, pause, and see what's available.
(use-package which-key
  :ensure nil                           ; built into Emacs 30
  :init
  (setq which-key-idle-delay 0.4
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha
        which-key-max-description-length 40
        which-key-add-column-padding 1
        which-key-show-early-on-C-h t
        which-key-separator " → ")
  :config
  (which-key-mode 1)
  (which-key-setup-side-window-bottom))

;; helpful: much better C-h f / C-h v / C-h k.
(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-command]  . helpful-command)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key]      . helpful-key)
         ([remap describe-symbol]   . helpful-symbol)
         ("C-h ." . helpful-at-point)))

;; Cheatsheet: a generated overview of every `C-c <letter>' group in the
;; current buffer, including mode-specific ones (LSP, Elixir).
(defvar my/leader-groups
  '(("C-c a" . "AI: Claude Code")
    ("C-c b" . "Buffers")
    ("C-c d" . "Debug (dap)")
    ("C-c e" . "Edit")
    ("C-c f" . "Files")
    ("C-c g" . "Git")
    ("C-c h" . "Help")
    ("C-c j" . "Jump")
    ("C-c l" . "LSP")
    ("C-c m" . "Elixir / mix")
    ("C-c p" . "Project")
    ("C-c s" . "Search")
    ("C-c t" . "Toggles")
    ("C-c w" . "Windows"))
  "Leader prefixes shown by `my/cheatsheet'.")

(defvar my/global-key-notes
  '(("C-c ?"   . "this cheatsheet")
    ("M-x"     . "run any command by name (fuzzy)")
    ("C-h B"   . "embark: everything you can do at point")
    ("C-h m"   . "help for the current major mode")
    ("C-h ."   . "help for symbol at point")
    ("C-x b"   . "switch buffer (consult)")
    ("C-x g"   . "magit status")
    ("M-o"     . "jump to window (ace-window)")
    ("M-."     . "go to definition   M-, go back")
    ("C-="     . "expand region")
    ("C-."     . "embark act on thing at point")
    ("C-x u"   . "visual undo tree")
    ("M-s l"   . "search lines in buffer   M-s g grep project")
    ("M-g g"   . "go to line   M-g i go to symbol")
    ("<f6>"    . "toggle Claude Code")
    ("C-c p R" . "open a project over SSH   C-c a h runs Claude there")
    ("<f8>"    . "toggle file tree")
    ("<f9>"    . "toggle symbol tree"))
  "Global keys worth remembering, shown by `my/cheatsheet'.")

(defun my/cheatsheet--doc (cmd)
  "First line of CMD's docstring, or empty."
  (let ((doc (and (fboundp cmd) (documentation cmd t))))
    (if doc (car (split-string doc "\n")) "")))

(defun my/cheatsheet ()
  "Show a cheatsheet of the leader keymaps active in this buffer."
  (interactive)
  (let ((buf (current-buffer)))
    (with-help-window "*Keybinding Cheatsheet*"
      (with-current-buffer standard-output
        (insert (propertize "Keybinding cheatsheet\n" 'face 'bold)
                "Press a prefix and pause: which-key lists what follows.\n\n"
                (propertize "Global\n" 'face 'bold))
        (dolist (note my/global-key-notes)
          (insert (format "  %-10s %s\n" (car note) (cdr note))))
        (dolist (group my/leader-groups)
          (let ((map (with-current-buffer buf (key-binding (kbd (car group)) t))))
            (when (keymapp map)
              (insert (format "\n%s   %s\n" (propertize (car group) 'face 'bold)
                              (cdr group)))
              (let (rows)
                (map-keymap
                 (lambda (ev def)
                   (when (and def (not (eq def 'undefined)))
                     (push (list (single-key-description ev)
                                 (cond ((symbolp def) (symbol-name def))
                                       ((keymapp def) "(prefix)")
                                       (t "(lambda)"))
                                 (if (symbolp def) (my/cheatsheet--doc def) ""))
                           rows)))
                 map)
                (dolist (row (sort rows (lambda (a b) (string< (car a) (car b)))))
                  (insert (format "  %-6s %-38s %s\n"
                                  (nth 0 row) (nth 1 row)
                                  (truncate-string-to-width (nth 2 row) 60 nil nil "…"))))))))))))

;;; ---------------------------------------------------------------------------
;;; 5. Minibuffer completion
;;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x r b" . consult-bookmark)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g o"   . consult-outline)
         ("M-g m"   . consult-mark)
         ("M-g e"   . consult-compile-error)
         ("M-s l"   . consult-line)
         ("M-s L"   . consult-line-multi)
         ("M-s g"   . my/consult-grep-project)
         ("M-s f"   . consult-find)
         ("C-x C-r" . consult-recent-file))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref
        consult-narrow-key "<")
  (defun my/consult-grep-project ()
    "Grep the current project with ripgrep when available, else grep."
    (interactive)
    (if (executable-find "rg")
        (consult-ripgrep)
      (consult-grep))))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :init (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; ---------------------------------------------------------------------------
;;; 6. Editing helpers (Prelude picks)
;;; ---------------------------------------------------------------------------

(use-package crux
  :bind (("C-a"        . crux-move-beginning-of-line)
         ("S-<return>" . crux-smart-open-line)
         ("C-S-<return>" . crux-smart-open-line-above)
         ("C-k"        . crux-smart-kill-line)
         ("C-^"        . crux-top-join-line)))

(use-package avy
  :bind (("C-:" . avy-goto-char-timer)
         ("M-g l" . avy-goto-line))
  :custom (avy-timeout-seconds 0.3))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-scope 'frame)
  (aw-dispatch-always nil))

(use-package expand-region
  :bind ("C-=" . er/expand-region))

(use-package anzu                       ; match counts in the modeline, live replace preview
  :config (global-anzu-mode 1)
  :bind (([remap query-replace] . anzu-query-replace)
         ([remap query-replace-regexp] . anzu-query-replace-regexp)))

(use-package move-text
  :bind (("M-<up>"   . move-text-up)
         ("M-<down>" . move-text-down)))

(use-package vundo
  :bind ("C-x u" . vundo)
  :custom (vundo-glyph-alist vundo-unicode-symbols))

(use-package editorconfig
  :config (editorconfig-mode 1))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode)
  :config (yas-reload-all))
(use-package yasnippet-snippets :after yasnippet)

(use-package markdown-mode
  :mode ("\\.md\\'" . gfm-mode))
(use-package yaml-mode :mode "\\.ya?ml\\'")
(use-package dockerfile-mode :mode "Dockerfile\\'")

;;; ---------------------------------------------------------------------------
;;; 7. Project, files, sidebar, symbol tree
;;; ---------------------------------------------------------------------------

(use-package project
  :ensure nil
  :custom
  (project-vc-ignores '("_build/" "deps/" ".elixir_ls/" "node_modules/" "priv/static/"))
  (project-switch-commands
   '((project-find-file "Find file" ?f)
     (my/consult-grep-project "Grep" ?g)
     (project-dired "Dired" ?d)
     (magit-project-status "Magit" ?m)
     (project-eshell "Eshell" ?e))))

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t))

;; treemacs: the IDE-style file explorer on the left.
(use-package treemacs
  :defer t
  :init
  (setq treemacs-width 34
        treemacs-follow-after-init t
        treemacs-is-never-other-window t
        treemacs-indentation 2
        treemacs-collapse-dirs 3
        treemacs-show-hidden-files t
        treemacs-file-event-delay 1000
        treemacs-silent-refresh t
        treemacs-sorting 'alphabetic-asc)
  :config
  (treemacs-follow-mode 1)              ; highlight the file you are editing
  (treemacs-project-follow-mode 1)      ; show the project of the current buffer
  (treemacs-filewatch-mode 1)
  (treemacs-fringe-indicator-mode 'always)
  (treemacs-git-mode (if treemacs-python-executable 'deferred 'simple))
  (treemacs-git-commit-diff-mode 1)
  (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1)))
  (dolist (pattern '("_build" "deps" ".elixir_ls" "node_modules" ".git"))
    (add-to-list 'treemacs-ignored-file-predicates
                 (let ((p pattern))
                   (lambda (file _) (string= file p))))))

(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))
(use-package treemacs-magit :after (treemacs magit))

(defun my/treemacs-toggle ()
  "Cycle treemacs: hidden -> shown and focused -> (if focused) hidden.
When treemacs is visible but another window is selected, just focus it."
  (interactive)
  (cond
   ((not (eq (treemacs-current-visibility) 'visible))
    (treemacs-add-and-display-current-project-exclusively)
    (treemacs-select-window))
   ((treemacs-is-treemacs-window-selected?)
    (delete-window (treemacs-get-local-window)))
   (t (treemacs-select-window))))

;; imenu-list: the symbol / function tree on the right, follows point.
(use-package imenu-list
  :custom
  (imenu-list-position 'right)
  (imenu-list-size 0.22)
  (imenu-list-focus-after-activation nil)
  (imenu-list-auto-resize nil)
  (imenu-list-idle-update-delay 0.5)
  :config
  (add-hook 'imenu-list-major-mode-hook (lambda () (display-line-numbers-mode -1))))

(defun my/copy-file-path ()
  "Copy the current buffer's file path (relative to the project) to the kill ring."
  (interactive)
  (if-let* ((file buffer-file-name)
            (root (and (project-current) (project-root (project-current))))
            (rel (file-relative-name file root)))
      (progn (kill-new rel) (message "Copied: %s" rel))
    (if buffer-file-name
        (progn (kill-new buffer-file-name) (message "Copied: %s" buffer-file-name))
      (user-error "Buffer is not visiting a file"))))

(defun my/open-init-file ()
  "Open this init.el."
  (interactive)
  (find-file user-init-file))

;;; ---------------------------------------------------------------------------
;;; 8. Git
;;; ---------------------------------------------------------------------------

(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-diff-refine-hunk t)
  (magit-save-repository-buffers 'dontask))

(use-package diff-hl                    ; changed lines in the fringe
  :hook ((magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

;;; ---------------------------------------------------------------------------
;;; 9. Completion + diagnostics
;;; ---------------------------------------------------------------------------

(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 1)
  (company-tooltip-align-annotations t)
  (company-tooltip-limit 12)
  (company-selection-wrap-around t)
  (company-format-margin-function #'company-text-icons-margin)
  :bind (:map company-active-map
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous)
              ("<tab>" . company-complete-selection)))

(use-package flycheck
  :hook (prog-mode . flycheck-mode)
  :custom
  (flycheck-display-errors-delay 0.3)
  (flycheck-indication-mode 'right-fringe))

(use-package consult-flycheck :after (consult flycheck))

;;; ---------------------------------------------------------------------------
;;; 10. LSP
;;; ---------------------------------------------------------------------------

(defun my/header-line-path ()
  "Project-relative file path for the header line (used when LSP is off)."
  (cond
   ((and buffer-file-name (project-current))
    (let ((root (project-root (project-current))))
      (concat (propertize (file-name-nondirectory (directory-file-name root)) 'face 'bold)
              "  ›  " (file-relative-name buffer-file-name root))))
   (buffer-file-name (abbreviate-file-name buffer-file-name))
   (t (buffer-name))))

(defun my/enable-header-line-path ()
  "Show the file path at the top of file-visiting buffers.
lsp-mode replaces this with its breadcrumb (path + symbols) when it starts."
  (setq header-line-format '(" " (:eval (my/header-line-path)))))
(add-hook 'find-file-hook #'my/enable-header-line-path)

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")       ; must be set before lsp-mode loads
  :hook ((lsp-mode . lsp-enable-which-key-integration)
         (lsp-mode . lsp-lens-mode))
  :custom
  ;; Header line: project › path › symbol › symbol
  (lsp-headerline-breadcrumb-enable t)
  (lsp-headerline-breadcrumb-segments '(project file symbols))
  (lsp-headerline-breadcrumb-enable-diagnostics nil)
  ;; General behaviour
  (lsp-idle-delay 0.3)
  (lsp-log-io nil)
  (lsp-enable-snippet t)
  (lsp-enable-symbol-highlighting t)
  (lsp-enable-on-type-formatting nil)
  (lsp-signature-auto-activate '(:on-trigger-char :on-server-request))
  (lsp-signature-render-documentation nil)
  (lsp-completion-show-detail t)
  (lsp-completion-show-kind t)
  (lsp-modeline-code-actions-enable t)
  (lsp-modeline-diagnostics-enable t)
  (lsp-lens-enable t)
  (lsp-file-watch-threshold 3000)
  ;; ElixirLS
  (lsp-elixir-server-command (list (expand-file-name "~/.elixir-ls/release/language_server.sh")))
  (lsp-elixir-suggest-specs t)
  (lsp-elixir-enable-test-lenses t)     ; "Run test" buttons above tests
  (lsp-elixir-fetch-deps nil)
  :config
  (dolist (dir '("[/\\\\]_build\\'" "[/\\\\]deps\\'" "[/\\\\]\\.elixir_ls\\'"
                 "[/\\\\]priv[/\\\\]static\\'" "[/\\\\]node_modules\\'"))
    (add-to-list 'lsp-file-watch-ignored-directories dir))
  ;; Over TRAMP, lsp-mode would list every project directory through ssh and
  ;; then start one remote inotifywait per directory, freezing Emacs for a
  ;; long time.  Skip watchers for remote folders; the server still learns
  ;; about edits through didSave.
  (defun my/lsp-skip-remote-watches (orig dir &rest args)
    (if (file-remote-p dir)
        (progn (lsp-log "Skipping file watchers for remote folder %s" dir)
               (or (nth 3 args) (make-lsp-watch :root-directory dir)))
      (apply orig dir args)))
  (advice-add 'lsp-watch-root-folder :around #'my/lsp-skip-remote-watches))

(use-package lsp-ui
  :after lsp-mode
  :custom
  (lsp-ui-doc-enable t)
  (lsp-ui-doc-position 'at-point)
  (lsp-ui-doc-show-with-cursor nil)     ; use C-c l h g (glance) or mouse hover
  (lsp-ui-doc-show-with-mouse t)
  (lsp-ui-doc-delay 0.5)
  (lsp-ui-doc-max-height 20)
  (lsp-ui-sideline-enable t)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-sideline-show-hover nil)
  (lsp-ui-peek-enable t)
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references]  . lsp-ui-peek-find-references)))

(use-package lsp-treemacs
  :after (lsp-mode treemacs)
  :config (lsp-treemacs-sync-mode 1))

(use-package consult-lsp :after (consult lsp-mode))

;;; ---------------------------------------------------------------------------
;;; 11. Elixir
;;; ---------------------------------------------------------------------------

(use-package elixir-ts-mode
  :ensure nil                           ; built into Emacs 30
  :mode (("\\.exs?\\'" . elixir-ts-mode)
         ("mix\\.lock\\'" . elixir-ts-mode))
  :hook ((elixir-ts-mode . lsp-deferred)
         (elixir-ts-mode . my/elixir-format-on-save))
  :config
  (defun my/elixir-format-on-save ()
    "Format Elixir buffers with ElixirLS before saving."
    (add-hook 'before-save-hook
              (lambda () (when (bound-and-true-p lsp-mode) (lsp-format-buffer)))
              nil t)))

(use-package heex-ts-mode
  :ensure nil                           ; built into Emacs 30
  :mode "\\.[hl]?eex\\'"
  :hook ((heex-ts-mode . lsp-deferred)
         (heex-ts-mode . my/elixir-format-on-save)))

;; ExUnit test runner: C-c m a/f/s/r
(use-package exunit
  :hook (elixir-ts-mode . exunit-mode))

;; IEx REPL: C-c m i starts `iex -S mix' for the project.
(use-package inf-elixir
  :commands (inf-elixir inf-elixir-project inf-elixir-send-line
                        inf-elixir-send-region inf-elixir-send-buffer))

;; Mix helpers run in a compilation buffer at the project root.
(defun my/mix-root ()
  "Directory containing the nearest mix.exs, or the project root."
  (or (locate-dominating-file default-directory "mix.exs")
      (and (project-current) (project-root (project-current)))
      default-directory))

(defun my/mix (task)
  "Run `mix TASK' in a compilation buffer."
  (interactive (list (read-string "mix " nil 'my/mix-history)))
  (let ((default-directory (my/mix-root)))
    (compile (concat "mix " task))))

(defun my/mix-phx-server ()
  "Run `mix phx.server' in an interactive compilation buffer."
  (interactive)
  (let ((default-directory (my/mix-root)))
    (compilation-start "mix phx.server" t (lambda (_) "*mix phx.server*"))))

(use-package compile
  :ensure nil
  :custom
  (compilation-scroll-output 'first-error)
  (compilation-ask-about-save nil)
  :hook (compilation-filter . ansi-color-compilation-filter))

;; Debugging through ElixirLS's debug adapter.
(use-package dap-mode
  :after lsp-mode
  :commands (dap-debug dap-hydra dap-breakpoint-toggle)
  :custom
  (dap-auto-configure-features '(sessions locals breakpoints expressions repl))
  :config
  (require 'dap-elixir)
  (setq dap-elixir-debug-program (list (expand-file-name "~/.elixir-ls/release/debug_adapter.sh"))))

;;; ---------------------------------------------------------------------------
;;; 12. AI
;;; ---------------------------------------------------------------------------

;; claude-code.el runs your `claude' CLI (Claude Code Max login) in a terminal
;; inside Emacs and lets you send regions, errors, and commands to it.
(use-package inheritenv)               ; dependency of claude-code
(use-package eat)                      ; terminal backend (pure elisp, no compile step)

(use-package claude-code
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :commands (claude-code claude-code-toggle claude-code-send-command
                         claude-code-send-region claude-code-fix-error-at-point
                         claude-code-transient claude-code-command-map)
  :custom
  (claude-code-terminal-backend 'eat)
  (claude-code-program "claude")
  (claude-code-newline-keybinding-style 'newline-on-shift-return)
  (claude-code-enable-notifications t)
  :config
  (claude-code-mode 1)
  (add-to-list 'savehist-additional-variables 'claude-code-command-history))

;;; ---------------------------------------------------------------------------
;;; 13. Remote projects over SSH (TRAMP)
;;; ---------------------------------------------------------------------------
;;
;; `C-c p R' opens a project on another machine.  Pick a saved project from
;; `my/remote-projects' or type `user@host' and a directory.  Everything below
;; then works on the remote box: find-file, grep, magit, compile, exunit, iex,
;; ElixirLS (looked up on the remote host, see `my/remote-elixir-ls-candidates')
;; and `C-c a h' for Claude Code over SSH.

(use-package tramp
  :ensure nil
  :custom
  (tramp-default-method "ssh")
  (tramp-verbose 1)                     ; raise to 6 when debugging a connection
  (tramp-connection-timeout 30)
  (tramp-use-connection-share t)        ; one ssh ControlMaster per host, reused
  (remote-file-name-inhibit-cache 60)
  (remote-file-name-inhibit-locks t)
  (enable-remote-dir-locals t)
  (vc-handled-backends '(Git))          ; don't probe other VCS backends over ssh
  :config
  ;; Use the remote user's own PATH (asdf shims, ~/.local/bin, ...) so mix,
  ;; elixir and claude are found on the other side.
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(defcustom my/remote-projects
  '(;; ("my-app" . "/ssh:isaac@server.example.com:~/code/my_app/")
    )
  "Saved remote projects: (NAME . TRAMP-DIRECTORY).  Offered by `my/ssh-project'."
  :type '(alist :key-type string :value-type string)
  :group 'convenience)

(defcustom my/remote-elixir-ls-candidates
  '("~/.local/share/elixir-ls/language_server.sh" ; ElixirLS installer default
    "~/.local/share/elixir-ls/launch.sh"          ; same install, inner script
    "~/.elixir-ls/release/language_server.sh"     ; source build
    "elixir-ls"                                   ; anything on the remote PATH
    "language_server.sh")
  "Where to look for ElixirLS on a remote host, first match wins.
Entries with a `~' or `/' are paths expanded in the remote user's home;
bare names are searched on the remote PATH.  Don't copy launch scripts
elsewhere: they find the release relative to their own location.
Whatever is found is run with ELS_MODE=language_server, which launch.sh
needs and language_server.sh would set itself."
  :type '(repeat string)
  :group 'convenience)

(defun my/remote-elixir-ls-resolve ()
  "Return the remote-side path of the first ElixirLS candidate that exists.
Must be called with a remote `default-directory'.  Returns nil if none exist."
  (let ((prefix (file-remote-p default-directory)))
    (seq-some
     (lambda (cand)
       (if (string-match-p "[~/]" cand)
           ;; `expand-file-name' on a remote name expands `~' on the remote
           ;; host (a bare "~/x" would expand to the *local* home).
           (let ((remote (expand-file-name (concat prefix cand))))
             (and (file-executable-p remote) (file-local-name remote)))
         (when-let* ((found (executable-find cand t)))
           (file-local-name found))))
     my/remote-elixir-ls-candidates)))

(defun my/remote-elixir-ls-command ()
  "Command list that starts ElixirLS on the current remote host."
  (if-let* ((script (my/remote-elixir-ls-resolve)))
      (list "env" "ELS_MODE=language_server" script)
    (user-error "ElixirLS not found on remote host; see `my/remote-elixir-ls-candidates'")))

(defun my/remote-elixir-ls-present-p ()
  "Non-nil when some ElixirLS candidate exists on the current remote host."
  (let ((found (my/remote-elixir-ls-resolve)))
    (if found
        (lsp-log "Remote ElixirLS: using %s" found)
      (lsp-log "Remote ElixirLS: none of %S found on %s"
               my/remote-elixir-ls-candidates (file-remote-p default-directory)))
    (and found t)))

(defun my/ssh-read-remote-dir ()
  "Ask for a remote directory: a saved project name, or user@host plus a path."
  (let* ((choice (completing-read "Remote project (name or user@host): "
                                  (mapcar #'car my/remote-projects)))
         (saved (cdr (assoc choice my/remote-projects))))
    (file-name-as-directory
     (or saved
         (let ((host (if (string-prefix-p "/" choice) choice (concat "/ssh:" choice ":"))))
           (read-directory-name (format "Directory on %s: " choice) host host))))))

(defun my/ssh-project (dir)
  "Open the remote project at DIR (prompts) and offer the usual project actions."
  (interactive (list (my/ssh-read-remote-dir)))
  (let ((default-directory dir))
    (when-let* ((proj (project-current nil dir)))
      (project-remember-project proj))
    (project-switch-project dir)))

(defun my/ssh-shell (&optional dir)
  "Open a terminal (eat) on the machine that owns DIR, or the current buffer's host.
Prompts for a remote directory when the current buffer is local.  Returns the buffer."
  (interactive)
  (let ((default-directory (or dir
                               (and (file-remote-p default-directory) default-directory)
                               (my/ssh-read-remote-dir))))
    ;; Ask for bash explicitly: the remote box may not have the local zsh.
    (eat (if (file-remote-p default-directory) "/bin/bash" nil) t)))

(defun my/ssh-claude (&optional dir)
  "Run the Claude Code CLI on a remote host, inside an eat terminal.
Uses DIR, the current remote buffer's directory, or prompts for one.
The remote machine needs `claude' installed and logged in."
  (interactive)
  (let ((buf (my/ssh-shell dir)))
    (run-at-time 1.5 nil
                 (lambda ()
                   (with-current-buffer buf
                     (when (bound-and-true-p eat-terminal)
                       (eat-term-send-string eat-terminal "claude\r")))))))

;; ElixirLS over TRAMP: same client as the local one, started on the remote host.
(with-eval-after-load 'lsp-elixir
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection #'my/remote-elixir-ls-command
                                          #'my/remote-elixir-ls-present-p)
    :activation-fn (lsp-activate-on "elixir")
    :priority -1
    :remote? t
    :server-id 'elixir-ls-remote
    :action-handlers (ht ("elixir.lens.test.run" 'lsp-elixir--run-test)))))

;;; ---------------------------------------------------------------------------
;;; 14. Leader keymaps (C-c <letter>)
;;; ---------------------------------------------------------------------------

(defvar-keymap my/ai-map
  :doc "AI: Claude Code"
  "a" #'claude-code-toggle
  "c" #'claude-code
  "C" #'claude-code-continue
  "r" #'claude-code-send-region
  "e" #'claude-code-fix-error-at-point
  "s" #'claude-code-send-command
  "x" #'claude-code-send-command-with-context
  "o" #'claude-code-send-buffer-file
  "n" #'claude-code-send-escape
  "y" #'claude-code-send-return
  "k" #'claude-code-kill
  "m" #'claude-code-transient
  "h" #'my/ssh-claude
  "/" #'claude-code-slash-commands
  "b" #'claude-code-switch-to-buffer
  "i" #'claude-code-new-instance
  "R" #'claude-code-resume
  "M" #'claude-code-cycle-mode
  "z" #'claude-code-toggle-read-only-mode
  "1" #'claude-code-send-1
  "2" #'claude-code-send-2
  "3" #'claude-code-send-3)

(defvar-keymap my/buffer-map
  :doc "Buffers"
  "b" #'consult-buffer
  "B" #'consult-project-buffer
  "k" #'kill-current-buffer
  "K" #'crux-kill-other-buffers
  "i" #'ibuffer
  "n" #'next-buffer
  "p" #'previous-buffer
  "l" #'mode-line-other-buffer
  "r" #'revert-buffer-quick
  "s" #'scratch-buffer)

(defvar-keymap my/debug-map
  :doc "Debug (dap-mode)"
  "d" #'dap-debug
  "h" #'dap-hydra
  "b" #'dap-breakpoint-toggle
  "c" #'dap-continue
  "n" #'dap-next
  "i" #'dap-step-in
  "o" #'dap-step-out
  "q" #'dap-disconnect
  "l" #'dap-ui-locals
  "r" #'dap-ui-repl)

(defvar-keymap my/edit-map
  :doc "Edit"
  "d" #'crux-duplicate-current-line-or-region
  "D" #'crux-duplicate-and-comment-current-line-or-region
  "k" #'crux-kill-whole-line
  "c" #'crux-cleanup-buffer-or-region
  "u" #'upcase-dwim
  "l" #'downcase-dwim
  "j" #'crux-top-join-line
  ";" #'comment-line
  "r" #'anzu-query-replace
  "R" #'anzu-query-replace-regexp
  "s" #'sort-lines
  "a" #'align-regexp
  "i" #'indent-region)

(defvar-keymap my/file-map
  :doc "Files"
  "f" #'find-file
  "F" #'find-file-other-window
  "r" #'consult-recent-file
  "s" #'save-buffer
  "S" #'save-some-buffers
  "R" #'crux-rename-file-and-buffer
  "D" #'crux-delete-file-and-buffer
  "c" #'my/copy-file-path
  "d" #'dired-jump
  "t" #'my/treemacs-toggle
  "p" #'project-find-file
  "i" #'my/open-init-file)

(defvar-keymap my/git-map
  :doc "Git"
  "g" #'magit-status
  "f" #'magit-file-dispatch
  "l" #'magit-log-current
  "L" #'magit-log-buffer-file
  "b" #'magit-blame-addition
  "d" #'magit-diff-buffer-file
  "c" #'magit-commit
  "p" #'magit-push
  "P" #'magit-pull
  "n" #'diff-hl-next-hunk
  "N" #'diff-hl-previous-hunk
  "r" #'diff-hl-revert-hunk
  "s" #'diff-hl-show-hunk)

(defvar-keymap my/help-map
  :doc "Help"
  "?" #'my/cheatsheet
  "h" #'which-key-show-top-level
  "m" #'which-key-show-major-mode
  "M" #'describe-mode
  "k" #'helpful-key
  "f" #'helpful-callable
  "v" #'helpful-variable
  "s" #'helpful-symbol
  "." #'helpful-at-point
  "b" #'embark-bindings
  "p" #'describe-package
  "i" #'info)

(defvar-keymap my/jump-map
  :doc "Jump"
  "j" #'avy-goto-char-timer
  "w" #'avy-goto-word-1
  "l" #'avy-goto-line
  "d" #'xref-find-definitions
  "D" #'xref-find-definitions-other-window
  "r" #'xref-find-references
  "b" #'xref-go-back
  "f" #'xref-go-forward
  "i" #'consult-imenu
  "m" #'consult-mark
  "e" #'consult-flycheck)

(defvar-keymap my/project-map
  :doc "Project"
  "p" #'project-switch-project
  "f" #'project-find-file
  "F" #'project-or-external-find-file
  "b" #'consult-project-buffer
  "d" #'project-dired
  "g" #'my/consult-grep-project
  "r" #'project-query-replace-regexp
  "k" #'project-kill-buffers
  "c" #'project-compile
  "e" #'project-eshell
  "s" #'project-shell
  "!" #'project-shell-command
  "t" #'treemacs-add-and-display-current-project-exclusively
  "m" #'magit-project-status
  "R" #'my/ssh-project
  "S" #'my/ssh-shell
  "X" #'tramp-cleanup-all-connections)

(defvar-keymap my/search-map
  :doc "Search"
  "s" #'consult-line
  "S" #'consult-line-multi
  "g" #'my/consult-grep-project
  "G" #'consult-git-grep
  "f" #'consult-find
  "i" #'consult-imenu
  "I" #'consult-imenu-multi
  "o" #'consult-outline
  "m" #'consult-mark
  "e" #'consult-flycheck
  "l" #'consult-lsp-symbols
  "d" #'consult-lsp-diagnostics
  "r" #'anzu-query-replace)

(defvar-keymap my/toggle-map
  :doc "Toggles"
  "t" #'my/treemacs-toggle
  "i" #'imenu-list-smart-toggle
  "l" #'display-line-numbers-mode
  "w" #'whitespace-mode
  "v" #'visual-line-mode
  "T" #'toggle-truncate-lines
  "f" #'flycheck-list-errors
  "d" #'my/toggle-theme
  "h" #'hl-line-mode
  "r" #'read-only-mode
  "L" #'lsp-lens-mode
  "s" #'lsp-ui-sideline-mode
  "D" #'lsp-ui-doc-mode
  "z" #'text-scale-adjust)

(defvar-keymap my/window-map
  :doc "Windows"
  "w" #'ace-window
  "s" #'split-window-below
  "v" #'split-window-right
  "d" #'delete-window
  "D" #'ace-delete-window
  "o" #'delete-other-windows
  "x" #'ace-swap-window
  "u" #'winner-undo
  "r" #'winner-redo
  "b" #'balance-windows
  "m" #'toggle-frame-maximized
  "f" #'toggle-frame-fullscreen
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right)

;; Elixir-only prefix, active in Elixir and HEEx buffers.
(defvar-keymap my/elixir-map
  :doc "Elixir / mix"
  "a" #'exunit-verify-all
  "f" #'exunit-verify
  "s" #'exunit-verify-single
  "r" #'exunit-rerun
  "T" #'exunit-toggle-file-and-test
  "t" #'exunit-toggle-file-and-test-other-window
  "i" #'inf-elixir-project
  "I" #'inf-elixir
  "l" #'inf-elixir-send-line
  "R" #'inf-elixir-send-region
  "b" #'inf-elixir-send-buffer
  "m" #'my/mix
  "c" (lambda () (interactive) (my/mix "compile"))
  "d" (lambda () (interactive) (my/mix "deps.get"))
  "p" #'my/mix-phx-server
  "F" #'lsp-format-buffer
  "o" #'lsp-organize-imports
  "=" #'lsp-format-buffer)

(with-eval-after-load 'elixir-ts-mode
  (keymap-set elixir-ts-mode-map "C-c m" my/elixir-map))
(with-eval-after-load 'heex-ts-mode
  (keymap-set heex-ts-mode-map "C-c m" my/elixir-map))

(dolist (binding `(("C-c a" . ,my/ai-map)
                   ("C-c b" . ,my/buffer-map)
                   ("C-c d" . ,my/debug-map)
                   ("C-c e" . ,my/edit-map)
                   ("C-c f" . ,my/file-map)
                   ("C-c g" . ,my/git-map)
                   ("C-c h" . ,my/help-map)
                   ("C-c j" . ,my/jump-map)
                   ("C-c p" . ,my/project-map)
                   ("C-c s" . ,my/search-map)
                   ("C-c t" . ,my/toggle-map)
                   ("C-c w" . ,my/window-map)))
  (keymap-global-set (car binding) (cdr binding)))

(keymap-global-set "C-c ?" #'my/cheatsheet)
(keymap-global-set "<f6>" #'claude-code-toggle)
(keymap-global-set "<f8>" #'my/treemacs-toggle)
(keymap-global-set "<f9>" #'imenu-list-smart-toggle)

;; Group names shown by which-key when you press C-c.
(with-eval-after-load 'which-key
  (dolist (group my/leader-groups)
    (which-key-add-key-based-replacements (car group) (cdr group)))
  (which-key-add-key-based-replacements
    "C-c ?" "cheatsheet"
    "C-c m c" "mix compile"
    "C-c m d" "mix deps.get"))

;;; init.el ends here
