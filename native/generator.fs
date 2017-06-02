: generate ( -- )
  S" gen_out.s" w/o CREATE-FILE ABORT" Could not open gen_out.s"
  >R
  asm-buffer   asm-ptr @ asm-buffer -   R@ ( c-addr u fileid )
  write-file ABORT" Failed to write to the output file."
  r> close-file ABORT" Failed to close the output file."
;

generate bye
