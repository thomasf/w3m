;;; sb-mailman.el --- shimbun backend class for mailman archiver.

;; Copyright (C) 2002, 2003 NAKAJIMA Mikio <minakaji@namazu.org>
;; Copyright (C) 2002       Katsumi Yamaoka <yamaoka@jpl.org>

;; Authors: NAKAJIMA Mikio  <minakaji@namazu.org>,
;;          Katsumi Yamaoka <yamaoka@jpl.org>
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

;; Mailman is the GNU Mailing List Manager.
;; See http://www.gnu.org/software/mailman/index.html for its detail.

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'shimbun)

(luna-define-class shimbun-mailman (shimbun) ())

(defun shimbun-mailman-make-contents (shimbun header)
  (subst-char-in-region (point-min) (point-max) ?\t ?\  t)
  (shimbun-decode-entities)
  (goto-char (point-min))
  (let ((end (search-forward "<!--beginarticle-->")))
    (goto-char (point-min))
    (search-forward "</HEAD>")
    (when (re-search-forward "<H1>\\([^\n]+\\)\\(\n +\\)?</H1>" end t nil)
      (shimbun-header-set-subject
       header
       (shimbun-mime-encode-string (match-string 1))))
    (when (re-search-forward "<B>\\([^\n]+\\)\\(\n +\\)?</B> *\n +\
<A HREF=\"[^\n]+\n +TITLE=\"[^\n]+\">\\([^\n]+\\)"
			     end t nil)
      (shimbun-header-set-from
       header
       (shimbun-mime-encode-string (concat (match-string 1)
					   " <" (match-string 3) ">")))
      (when (re-search-forward "<I>\\([^\n]+\\)</I>" end t nil)
	(shimbun-header-set-date header (match-string 1)))
      (delete-region (point-min) end)
      (delete-region (search-forward "<!--endarticle-->") (point-max))
      (shimbun-header-insert-and-buffer-string shimbun header nil t))))

(luna-define-method shimbun-make-contents ((shimbun shimbun-mailman) header)
  (shimbun-mailman-make-contents shimbun header))

(defun shimbun-mailman-headers (shimbun range)
  (with-temp-buffer
    (let* ((index-url (shimbun-index-url shimbun))
	   (group (shimbun-current-group-internal shimbun))
	   (suffix (if (string-match "^http://\\([^/]+\\)/" index-url)
		       (match-string 1 index-url)
		     index-url))
	   auxs aux id url subject from headers)
      (shimbun-retrieve-url (concat index-url "/index.html") 'reload)
      (setq case-fold-search t)
      (let ((pages (shimbun-header-index-pages range))
	    (count 0))
	(while (and (if pages (<= (incf count) pages) t)
		    (re-search-forward "<a href=\"\\(20[0-9][0-9]-\
\\(January\\|February\\|March\\|April\\|May\\|June\
\\|July\\|August\\|September\\|October\\|November\\|December\\)\
\\)/date.html\">"
				       nil t))
	  (push (match-string 1) auxs)))
      (setq auxs (nreverse auxs))
      (catch 'stop
	(while auxs
	  (erase-buffer)
	  (shimbun-retrieve-url (concat index-url "/"
					(setq aux (car auxs))
					"/date.html")
				'reload)
	  (subst-char-in-region (point-min) (point-max) ?\t ?\  t)
	  (goto-char (point-max))
	  (while (re-search-backward "<LI><A HREF=\"\\(\\([0-9]+\\)\\.html\\)\
\">\\([^\n]+\\)\n</A><A NAME=\"[0-9]+\">&nbsp;</A>\n<I>\\([^\n]+\\)\n</I>"
				     nil t)
	    (setq id (format "<%06d.%s@%s>"
			     (string-to-number (match-string 2))
			     group
			     suffix))
	    (when (shimbun-search-id shimbun id)
	      (throw 'stop nil))
	    (setq url (concat index-url "/" aux "/" (match-string 1))
		  subject (match-string 3)
		  from (match-string 4))
	    (setq subject (with-temp-buffer
			    (insert subject)
			    (shimbun-decode-entities)
			    (shimbun-remove-markup)
			    (buffer-string)))
	    (push (shimbun-make-header
		   0 (shimbun-mime-encode-string subject)
		   (shimbun-mime-encode-string from)
		   "" id "" 0 0 url)
		  headers))
	  (setq auxs (cdr auxs))))
      headers)))

(luna-define-method shimbun-headers ((shimbun shimbun-mailman) &optional range)
  (shimbun-mailman-headers shimbun range))

(provide 'sb-mailman)

;;; sb-mailman.el ends here
