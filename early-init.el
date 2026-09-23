;;; early-init.el --- Runs before package.el and the first frame -*- lexical-binding: t -*-

;;; Commentary:
;; Keep this file tiny.  Everything that matters lives in init.el.

;;; Code:

;; Faster startup: raise the GC threshold now, init.el lowers it again later.
(setq gc-cons-threshold most-positive-fixnum)

;; Don't let package.el initialise twice; init.el calls `package-initialize'.
(setq package-enable-at-startup nil)

;; Turn off UI chrome before the first frame is drawn to avoid flicker.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . maximized) default-frame-alist)

;; Silence native-compilation warnings popping up in a buffer.
(setq native-comp-async-report-warnings-errors 'silent)

;; Don't resize the frame when the font or mode-line changes.
(setq frame-inhibit-implied-resize t)

;;; early-init.el ends here
