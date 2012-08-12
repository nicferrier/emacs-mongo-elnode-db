;;; mongo-elnode.el --- elnode adapter for mongo-el

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: hypermedia, data

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Connect Elnode apps to your Mongo DB.

;;; Code:

(require 'elnode-db)
(require 'mongo)
(require 'bson)

(defun elnode-db-mongo (reference)
  "Make a db Mongo database

REFERENCE comes from the call to `elnode-db-make' and MUST
include:

 `:host' key with a hostname

 `:collection' key with a collection name

See `mongo-open-database' for more keys that will be passed to
mongo."
  (let* ((host (plist-get (cdr reference) :host))
         (collection (plist-get (cdr reference) :collection))
         (db (list
              :db (make-hash-table :test 'equal)
              :get 'elnode-db-mongo-get
              :put 'elnode-db-mongo-put
              :map 'elnode-db-mongo-map
              :collection collection
              :host host)))
    ;; Return the database
    db))

(defun elnode-db-mongo--do-query (query db)
  "A general querying tool."
  (let* ((host (plist-get db :host))
         (result
          (mongo-with-open-database
              (database :host host)
            (mongo-do-request
             (make-mongo-message-query
              :flags 0
              :number-to-skip 0
              :number-to-return 0
              :full-collection-name (plist-get db :collection)
              :query query)
             :database database)))
         (docres (mongo-message-reply-documents result)))
    docres))

(defun elnode-db-mongo-get (key db)
  "Read record identified by KEY from the mongo DB.

Not often a terribly useful function with mongo because it just
looks up on the id."
  (let ((res (elnode-db-mongo--do-query
              (list
               (cons
                "_id"
                (bson-oid-of-hex-string key)))
              db)))
    (car res)))

(defun elnode-db-mongo-put (key value db)
  "Put the VALUE into the DB at KEY."
  (error "updating mongo not supported yet"))

(defun elnode-db-mongo-map (func db &optional query)
  "Map the FUNC over the records in the DB.

Optionally only match QUERY."
  (mapcar func (elnode-db-mongo--do-query query db)))

(ert-deftest elnode-db-mongo-marmalade-get ()
  (let ((mdb
         (elnode-db-make
          '(mongo
            :host "localhost"
            :collection "marmalade.packages"))))
    (should
     (elnode-db-mongo-get "4f65e980cd6108da68000252" mdb))))

;; Put the mongo db into the list of Elnode dbs
(puthash 'mongo 'elnode-db-mongo elnode-db--types)

(provide 'mongo-elnode)

;;; mongo-elnode.el ends here
