\ Exception word list
\ See chapter 9.

VARIABLE (exception-handler)
0 (exception-handler) !

: CATCH ( xt -- exception# | 0 )
  sp@ >R
  (exception-handler) @ >R \ Save the previous handler and data stack.
  rp@ (exception-handler) !
  execute
  R> (exception-handler) ! \ Restore the old handler.
  R> drop      \ Discard saved stack pointer.
  0 \ Signal no exception.
;

: THROW ( ixn exception# -- jxm exception# )
  ?dup IF \ 0 THROW is a no-op.
    (exception-handler) @ rp!
    R> (exception-handler) ! \ Previous handler.
    R> swap >R \ Save the exception number on return stack.
    sp! drop R> ( exc# )
    \ We'll return to the caller of CATCH now because of the stack mangling.
  THEN
;

\ Hat-tip to the Standard as presented on
\ http://forth-standard.org/standard/exception for these implementations.
