;;; sb-asahi-html.el --- shimbun backend for asahi.com (HTML version)

;; Copyright (C) 2001, 2002, 2003 Yuuichi Teranishi  <teranisi@gohome.org>

;; Author: Yuuichi Teranishi  <teranisi@gohome.org>
;; Keywords: news

;; This file is a part of shimbun.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

(require 'shimbun)
(require 'sb-asahi)

(luna-define-class shimbun-asahi-html (shimbun-asahi) ())

(defvar shimbun-asahi-html-content-start
  "<!--[\t\n ]*Start of photo[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE START NAME=\"HONBUN\"[\t\n ]*-->")
(defvar shimbun-asahi-html-content-end
  "<!--[\t\n ]*End of related link[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE END NAME=\"HONBUN\"[\t\n ]*-->")
(defvar shimbun-asahi-html-x-face-alist shimbun-asahi-x-face-alist)

(defvar shimbun-asahi-html-expiration-days shimbun-asahi-expiration-days)

(defun shimbun-asahi-html-make-contents (entity header)
  "Return article contents with a correct date header."
  (let ((case-fold-search t)
	start date)
    (when (and (re-search-forward (shimbun-content-start-internal entity)
				  nil t)
	       (setq start (point))
	       (re-search-forward (shimbun-content-end-internal entity)
				  nil t))
      (delete-region (match-beginning 0) (point-max))
      (delete-region (point-min) start)
      (when (and (member (shimbun-current-group-internal entity)
			 '("science"))
		 (string-match " \\(00:00\\) "
			       (setq date (shimbun-header-date header))))
	(setq start (match-beginning 1))
	(goto-char (point-max))
	(forward-line -1)
	(when (re-search-forward
	       "([01][0-9]/[0-3][0-9] \\([012][0-9]:[0-5][0-9]\\))"
	       nil t)
	  (shimbun-header-set-date header
				   (concat (substring date 0 start)
					   (match-string 1)
					   (substring date (+ start 5))))))
      (goto-char (point-min))
      (insert "<html>\n<head>\n<base href=\""
	      (shimbun-header-xref header) "\">\n</head>\n<body>\n")
      (goto-char (point-max))
      (insert "\n</body>\n</html>\n"))
    (shimbun-make-mime-article entity header)
    (buffer-string)))

(luna-define-method shimbun-make-contents ((shimbun shimbun-asahi-html)
					   header)
  (shimbun-asahi-html-make-contents shimbun header))

(provide 'sb-asahi-html)

;;; sb-asahi-html.el ends here
