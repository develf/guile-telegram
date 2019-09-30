;;; Guile Telegram API

(define-module (telegram)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 popen)
  #:use-module (oop goops)
  #:use-module (json)
  #:export (<telegram-bot>
            get-me
            get-updates
            send-message

            response:okay?
            response:result
            message:chat-id
            message:text))


;;; Constants

(define %telegram-api-url "https://api.telegram.org")
(define %curl-opt         "--silent")
;; (define %curl-opt         "-v")


;; The main class
(define-class <telegram-bot> ()
  (token #:init-value #f #:init-keyword #:token #:getter get-token)
  (name  #:init-value #f #:init-keyword #:name  #:getter get-name)
  (proxy #:init-value #f #:init-keyword #:proxy #:getter get-proxy))


;; Send a message MESSAGE to the bot API.
(define-method (api-request (self <telegram-bot>) (message <string>))
  (open-input-pipe
   (string-append (format #f "curl -X GET ~a --proxy ~a '~a/bot~a/~a'"
                          %curl-opt
                          (get-proxy self)
                          %telegram-api-url
                          (get-token self)
                          message))))


;;; Helper procedures
(define-method (read-all port)
  (let loop ((line  (read-line port))
             (result ""))
    (if (eof-object? line)
        result
        (loop (read-line port) (string-append result line)))))

;; API Methods.

(define-method (get-me (self <telegram-bot>))
  (let ((p (api-request self "getMe")))
    (json-string->scm (read-all p))))

(define-method (get-updates (self <telegram-bot>))
  (let ((p (api-request self "getUpdates")))
    (json-string->scm (read-all p))))

(define (%make-option name value)
  (if value
      (format #f "&~a=~a" name (if (boolean? value)
                                   "true"
                                   value))
      ""))


(define* (send-message self chat-id message
                       #:key parse-mode disable-web-page-preview? disable-notification?
                       reply-to-message-id reply-markup)
  (let ((p (api-request self
                        (string-append (format #f "sendMessage?chat_id=~a&text=~a"
                                               chat-id message)
                                       (%make-option "parse_mode" parse-mode)
                                       (%make-option "disable_web_page_preview" disable-web-page-preview?)
                                       (%make-option "disable_notification"     disable-notification?)
                                       (%make-option "reply_to_message_id"      reply-to-message-id)
                                       (%make-option "reply_markup"             reply-markup)))))
    (json-string->scm (read-all p))))


;;; Response parsers.

(define (response:okay? response)
  (hash-ref response "ok"))

(define (response:result response)
  (hash-ref response "result"))

(define (message:chat-id message)
  (hash-ref (hash-ref message "chat") "id"))

(define (message:text message)
  (hash-ref message "text"))

;;; telegram.scm ends here.

