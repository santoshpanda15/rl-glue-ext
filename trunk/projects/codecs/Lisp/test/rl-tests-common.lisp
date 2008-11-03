
;;; Copyright 2008 Gabor Balazs
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the License.
;;; You may obtain a copy of the License at
;;;
;;;     http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions and
;;; limitations under the License.
;;;
;;; $Revision$
;;; $Date$

(in-package #:rl-glue-tests)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Common purpose test functions.

(defun gen-adt-array (make-fn old-arr size elem-gen-fn)
  "Generates and returns an ADT array of SIZE number of TYPE elements 
which are generated by to GEN-FN function."
  (let ((arr (if (= size (length old-arr))
                 old-arr
                 (funcall make-fn size))))
    (dotimes (i size)
      (setf (aref arr i) (funcall elem-gen-fn i)))
    arr))

(defun fill-adt (adt &key ints floats chars)
  "Fills and returns an ADT with the specified number of data."
  (with-accessors ((iarr int-array) (farr float-array) (cstr char-string)) adt
    (when ints
      (setf iarr (gen-adt-array #'(lambda (size)
                                    (make-int-array size))
                                iarr
                                ints
                                #'(lambda (i) i))))
    (when floats
      (setf farr (gen-adt-array #'(lambda (size)
                                    (make-float-array size))
                                farr
                                floats
                                #'(lambda (i)
                                    (/ (coerce i 'double-float) floats)))))
    (when chars
      (setf cstr (gen-adt-array #'(lambda (size)
                                    (make-array size :element-type 'character))
                                cstr
                                chars
                                #'(lambda (i)
                                    (code-char (+ (char-code #\a) i)))))))
  adt)

(defun create-answer-message (step-count input-message)
  "Creates and returns a usual answer message
from the input one used during testing."
  (concatenate 'string
               input-message "|"
               (format nil "~{~a.~}" (loop repeat (mod step-count 3)
                                        collect step-count))
               "|" input-message))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Test experiment.

(defclass test-experiment (experiment)
  ((test-name
    :reader test-name
    :initarg :test-name
    :initform (error "Must specify test name!")
    :documentation "Name of the test.")
   (test-failed
    :accessor test-failed
    :initform 0
    :documentation "Counter of failed tests.")
   (test-count
    :accessor test-count
    :initform 0
    :documentation "Counter of passed tests."))
  (:documentation "Base of test experiments."))

(defmacro check (exp compare expected-form got-form)
  (let ((expected (gensym)) (got (gensym)))
    `(let ((,expected ,expected-form) (,got ,got-form))
       (with-accessors ((test-count test-count) (test-failed test-failed)) ,exp
         (incf test-count)
         (unless (funcall ,compare ,expected ,got)
           (format t "Failed #~a, expected ~a, got ~a~%"
                   test-count ,expected ,got)
           (format t "            ~a <> ~a~%" ',expected-form ',got-form)
           (incf test-failed))))))

(defmacro check-adt-array (exp exp-size array eq-fn gen-fn)
  "Checks an array of an ADT according to the GEN-FN generator function."
  `(progn
     (check ,exp #'= ,exp-size (length ,array))
     (when (plusp (length ,array))
       (loop for i from 0 to (1- (length ,array))
          do (check ,exp ,eq-fn (funcall ,gen-fn i) (aref ,array i))))))

(defmacro check-adt (exp adt exp-ints exp-floats exp-chars)
  "Checks whether the ADT contains the expected number of elements and their 
values are generated according to the fill-adt function."
  `(progn
     (check-adt-array ,exp
                      ,exp-ints
                      (int-array ,adt)
                      #'=
                      #'(lambda (i) i))
     (check-adt-array ,exp
                      ,exp-floats
                      (float-array ,adt)
                      #'=
                      #'(lambda (i) (/ (coerce i 'double-float) ,exp-floats)))
     (check-adt-array ,exp
                      ,exp-chars
                      (char-string ,adt)
                      #'char=
                      #'(lambda (i)
                          (code-char (+ (char-code #\a) i))))
     ,adt))

(defun summarize-stat (exp)
  "Prints a summary and returns the number of failed checks."
  (with-accessors ((test-name test-name)
                   (test-failed test-failed)
                   (test-count test-count)) exp
    (if (plusp test-failed)
        (format t "Failed ~a / ~a checks in ~a~%"
                test-failed test-count test-name)
        (format t "Passed all ~a checks in ~a~%"
                test-count test-name))
    test-failed))
