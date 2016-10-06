\ Collections classes and interfaces, a la Java's collections (but without some
\ dumb parts).
\ Support iterators, pleasant FP-style operations over them, and more.

\ REQUIRE objects.fs

interface
  selector iter@ ( iterator -- x ) \ Returns the value at the current location.
  selector iter! ( x iterator -- ) \ Writes the given value at the current pos.
  selector iter+ ( iterator -- )   \ Advances the iterator.
  selector iter? ( iterator -- ? ) \ True when there are more elements.
end-interface iterator

interface
  selector >iterator ( iterable -- iterator ) \ Returns a new iterator.
end-interface iterable

interface
  \ Returns the current length of the list
  selector length ( object -- u )
  \ Ensures the list is big enough to handle u entries.
  \ Never shrinks the list, only grows it.
  selector ensure-capacity ( u object -- )

  \ Reads element at index u from the list. (0-based)
  selector list@ ( u object -- x )
  \ Stores x at index u from the list (0-based)
  selector list! ( x u object -- )

  \ Pushes a new element onto the front of a list.
  selector unshift ( x object -- )
  \ Pops an element off the front of the list, returning it.
  selector shift   ( object -- x )

  \ Pushes a new element onto the back of a list.
  selector list-push ( x object -- )
  \ Pops an element off the back of the list list, returning it.
  selector list-pop ( object -- x )

  \ Inserts an element at index u.
  \ If the list is not big enough, it grows accordingly, placing 0s in the extra
  \ places.
  \ If the list is already long enough to have an element at index u,
  \ all the elements at u and later are pushed back one, so that the former u
  \ is now at u+1.
  selector insert    ( x u object -- )

  \ Removes the element at index u.
  \ If the list is shorter than u+1, do nothing.
  \ If the list does contain an element at u, it is removed.
  \ The element at u+1 is moved down to u, and so on.
  \ The removed element is returned.
  selector remove    ( u object -- x )

  \ Cleans up a list so it can be freed safely.
  selector destroy   ( object -- )
end-interface list


\ Error values
73189 CONSTANT list-out-of-range

\ Linked list node class, for use below.
object class
  cell% field (ll-value)
  cell% field (ll-next)

  m: ( x node -- )
      this (ll-value) !
    0 this (ll-next)  !
  ;m overrides construct
end-class (ll-node)


object class
  iterator implementation
  cell% inst-var node

  m: ( node iter -- ) node ! ;m overrides construct
  m: ( iter -- x ) node @ (ll-value) @ ;m overrides iter@
  m: ( x iter -- ) node @ (ll-value) ! ;m overrides iter!
  m: ( iter -- ) node @ (ll-next) @ node ! ;m overrides iter+
  m: ( iter -- ? ) node @ 0<> ;m overrides iter?
end-class list-iterator

\ Helper for finding nodes by index.
\ The index must be within the range of the list!
: (list-search) ( u node -- prev-node this-node )
  over 1 = IF
    nip ( node )
    dup (ll-next) @ ( prev this )
    EXIT
  ELSE
    >r 1- r> (ll-next) @ ( u-1 node' )
    recurse
  THEN
;


\ A linked list implementation of the list interface.
object class
  list implementation
  iterable implementation

  cell% inst-var head
  cell% inst-var tail
  cell% inst-var size

  m: ( list -- ) 0 head ! 0 tail ! 0 size ! ;m overrides construct

  m: ( list -- u ) size @ ;m overrides length
  m: ( u list -- ) drop ;m overrides ensure-capacity \ No-op for linked lists.

  \ Creates u new nodes with value 0 and appends them to the list.
  selector (append-nodes) ( u list -- )
  m: ( u list -- )
    dup size +! \ Update the size.
    tail @ swap 0 ?DO ( old )
      0 (ll-node) heap-new ( old new )
      dup >r
      swap (ll-next) ! ( R: new )
      r>
    LOOP
    tail ! \ Set the tail.
  ;m overrides (append-nodes)


  \ Three cases for list@:
  \ - 0 means the head, just return it.
  \ - length-1 means the tail, just return that.
  \ - Otherwise we use (list-search).
  \ Throws if the value is out of range.
  m: ( u list -- x )
    dup size @ >=   IF list-out-of-range throw THEN \ Out of range
    dup 0=          IF drop head @ (ll-value) @ EXITM THEN \ Special case: head
    dup size @ 1- = IF drop tail @ (ll-value) @ EXITM THEN \ Special case: tail
    \ Otherwise, run the search.
    head @ (list-search) ( prev curr )
    nip (ll-value) @ ( value )
  ;m overrides list@

  \ Four cases for list!:
  \ - 0 means the head, just set it.
  \ - length - 1 means the tail, just set it.
  \ - 0 <= index < size means we have such a node. use (list-search) and set it.
  \ - index >= size means we need to grow to fit. Create index - size extra
  \   nodes and then set it.
  m: ( x u list -- )
    \ Special case: index 0 is the head.
    dup 0= IF drop head @ (ll-value) ! EXITM THEN
    size @ ( x u size )
    \ Special case: Index length - 1 means the tail.
    2dup 1- = IF 2drop tail @ (ll-value) ! EXITM THEN

    \ Now it's either < size or >= size.
    over > ( x u inside? ) IF
      head @ (list-search) nip ( x cur )
      (ll-value) !
    ELSE \ Need to extend the list.
      size @ - 1+ ( x extras )
      this (append-nodes) ( x ) \ Tail is now the updated node. Size is updated too.
      tail @ (ll-value) ! ( ) \ Update the new tail's value.
    THEN
  ;m overrides list!


  \ The push and pop ones are pretty straightforward for linked lists.
  m: ( x list -- )
    (ll-node) heap-new ( new )
    head @ over (ll-next) ! ( new )
    tail @ 0= IF dup tail ! THEN \ Special case: set the tail if it's empty.
    head !
    1 size +!
  ;m overrides unshift

  \ Empties out all nodes and frees them.
  m: ( list -- )
    head @
    BEGIN dup WHILE dup (ll-next) @ swap free drop REPEAT
    0 head ! 0 tail ! 0 size !
  ;m method empty


  m: ( list -- x )
    size @ 1 = IF head @ (ll-value) @ this empty THEN
    head @
    dup (ll-next) @ head !
    dup (ll-value) @ ( node x )
    swap free drop ( x )
    -1 size +!
  ;m overrides shift

  m: ( x list -- )
    \ Special case: if the list is empty, make it non-empty.
    size @ 0= IF (ll-node) heap-new dup tail ! head ! 1 size ! EXITM THEN
    (ll-node) heap-new ( new )
    dup tail @ (ll-next) ! ( new )
    tail ! ( )
    1 size +!
  ;m overrides list-push

  m: ( list -- x )
    size @ 1 = IF
      head @ (ll-value) @ ( x )
      head @ free drop
      0 head ! 0 tail ! 0 size !
      EXITM
    THEN
    size @ 1- head @ (list-search) ( prev tail )
    >r 0 over (ll-next) ! tail ! ( R: old-tail )
    r@ (ll-value) @ ( x  R: old-tail )
    r> free drop ( x )
    -1 size +!
  ;m overrides list-pop

  \ Insert is straightforward. If the index is outside the list, just call list!
  \ If u is inside the list, (list-search) it and insert an extra node.
  m: ( x u list -- )
    \ Special case: u=0 is an unshift.
    dup 0= IF drop this unshift EXITM THEN
    dup size @ < IF \ Inside the list, so find the nodes.
      head @ (list-search) ( x prev old )
      rot (ll-node) heap-new ( prev old new )
      dup >r ( prev old new   R: new )
      (ll-next) ! ( prev   R: new )
      r> swap (ll-next) ! ( )
      1 size +!
    ELSE \ Outside the list. list! can handle this.
      this list!
    THEN
  ;m overrides insert

  \ Remove is also straightforward. If the index is outside, do nothing.
  \ Otherwise, look it up and move it.
  \ Special cases for head and tail are needed.
  m: ( u list -- )
    dup size @ >= IF drop EXITM THEN \ Bail if it's too short.
    dup 0= IF drop this shift EXITM THEN \ Punt to shift if its index 0.
    dup size @ 1- = IF drop this list-pop EXITM THEN \ And to pop if u == size-1
    \ If we're still here, it's the simple case.
    head @ (list-search) ( prev curr )
    dup >r
    (ll-next) @ swap (ll-next) ! ( R: curr )
    r> free drop
    -1 size +!
  ;m overrides remove

  \ Destroy deletes all the nodes.
  m: ( list -- ) this empty ;m overrides destroy

  \ Returns an iterator for a list.
  m: ( list -- iterator ) head @ list-iterator heap-new ;m overrides >iterator
end-class linked-list



\ Generic iterator operations: each, update (map), fold

\ Runs xt for each value in the iterator.
\ The xt must have stack effect ( x -- ).
: iter-each ( xt iterator -- )
  >r
  BEGIN r@ iter? WHILE
    r@ iter@ over execute
    r@ iter+
  REPEAT
  r> 2drop
;
: each ( xt iterable -- ) >iterator iter-each ;

\ Runs xt for each value in the iterator, writing back the new values.
\ The xt must have stack effect ( x1-- x2 )
: iter-update ( xt iterator -- )
  >r
  BEGIN r@ iter? WHILE
    r@ iter@ over execute r@ iter!
    r@ iter+
  REPEAT
  r> 2drop
;
: update ( xt iterator -- ) >iterator iter-update ;

\ Runs xt for each value in the iterator, computing a final value.
\ The xt must have stack effect ( x1 x2 -- x3 ), where x1 is the old final
\ value, x3 is the new final value, and x2 is the next iterator element.
\ NB: In functional programming terms, this is a left-fold with a default.
: iter-fold ( xt x iterator -- x )
  >r
  BEGIN r@ iter? WHILE ( xt x )
    over r@ iter@ swap ( xt x y xt ) execute ( xt x' )
    r@ iter+
  REPEAT
  swap r> 2drop ( x )
;
: fold ( xt x iterable -- x ) >iterator iter-fold ;

