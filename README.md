# Cascade

This language is inspired by other esoteric languages like [Flobnar](https://github.com/Reconcyl/flobnar) and [Pyramid Scheme](https://github.com/ConorOBrien-Foxx/Pyramid-Scheme) as well as other 2D languages. A **Cascade** program can be executed by the command `perl6 Cascade.p6 file` where `file` contains your program.

**Cascade** has a tree-like structure, where one character commands propogate downwards from the starting point of the `@` characters (or the top left corner if there are no `@`s). Commands can be thought of as functions with 0 to 3 arguments, which are taken from the evaluated values of the characters below them.

For example, the unary function `#` prints a value as a number. The program below will simply print the number `1`:

~~~
 @
 #
 1
~~~

Similarly, binary functions such as `+` or `-` take two values from below them:

~~~
 @
 #    This prints 2
 +
1 1
~~~

When a execution goes beyond the boundaries of the program it will wrap around, which is the only way to travel upwards in **Cascade**, and therefore to have any sort of looping. For example, the below program is exactly the same as the above one, merely shifted down two and to the right one:

~~~
  +
11
  @
  #
~~~

The shifting of a program only affects the starting point(s), which are ordered from top to bottom, left to right. Characters that are not filled in (such as after the `11` above) will be filled in with spaces implicitly.

### Control Flow:

There are a few instructions that help with control flow, since branches of the tree will overlap frequently. Most of the are self explanatory, for example `/|\` all behave the way you would expect:

~~~
 @
 \
  |   Wiggly snake!
  /
 /
|
\
 #
 1
~~~

There is also `^`, which executes the left side, then discards that and returns the result of the right side. Or `!`, which skips the next instruction and executes one below it:

~~~
 @
 #
 ^   Prints 12
# !
1
  2
~~~

For conditional flow and branching, there are the instructions `$`, `?`, and `_`. `$` will choose between returning the left or right randomly. `?` checks the value of the instruction directly below them and goes right if it is positive, or left otherwise. `_` executes the right *only if* the left is not zero.

~~~
 @
 .   Prints a or b depends on the random value
 ?
a|b
 $ 
0 1

  @
  _  Either prints a or nothing
 $ .
1 0a
~~~

### Variables:

Variables are any numeric characters or letters, and by default have the value that makes sense. For example, `1` has a value of `1`, and `a` has a value of `97` (the ordinal value of `a`). 

~~~
 @
 ^   Prints 1a
# .
1 a
~~~

But secretly, each variable is actually a stack of values, and using a variable is peeking at the top of the stack. You can actually push/pop values from a variable with the commands `[]`.

~~~
  @
  ^     This actually prints 0, since we push 0 to the variable 1 before printing
 ] \
1 0 #
    1
~~~

### Instruction List

| Group | Character(s) | Name | Action |
|-|-|-|-|
| Control Flow | | | |
|              | `@`  | Start     | Returns center. Execution starts here. If there are multiple `@`s, then run them all in sequence, going from top to bottom, left to right. If there are none, start at the top left cell |
|              | `/`  | Left      | Returns left                      |
|              | `\`  | Right     | Returns right                     |
|              | `\|` | Center    | Returns center                     |
|              | `!`  | Skip      | Returns two below by skipping the one between |
|              | `^`  | Both      | Execute left, but return right    |
| Branching | | | |
|           | `?` | Choice | If center is positive, return right, otherwise left |
|           | `_` | Check  | If left is zero, return zero, otherwise right      |
|           | `$` | Random | Return left or right randomly                      |
| Comparison | | | |
|            | `<` | Less    | Return 1 if left is less than right, otherwise 0    |
|            | `>` | Greater | Return 1 if left is greater than right, otherwise 0 |
|            | `=` | Equal   | Return 1 if left is equal to right, otherwise 0     |
|            | `~` | Not     | Return 1 if center is 0, else 0     |
| Arithmetic | | | |
|            | `+` | Addition       | Returns the sum of the left and right  |
|            | `-` | Subtraction    | Returns left minus right               |
|            | `*` | Multiplication | Returns left multiplied by right       |
|            | `:` | Division       | Returns left divided by right          |
|            | `%` | Modulo         | Returns left modulo right (with sign of right) |
|            | `(` | Decrement      | Returns center - 1                      |
|            | `)` | Increment      | Returns center + 1                      |
| Input/Output | | | |
|              | `,` | Char Input    | Returns the ordinal value of the next character of input. Returns `-1` if there is no input left |
|              | `.` | Char Output   | Converts center to a character and prints it, and then returns the number |
|              | `&` | Number Input  | Searches for the next (possibly negative) number. If no number number is encountered before EOF, returns `-1` |
|              | `#` | Number Output | Prints and returns center |
|              | `"` | String Output | Prints each variable below it until it encounters another `"` |
|              | `;` | EOF           | Returns 1 if there is no more input left, otherwise 0 |
| Meta | | | |
|      | numeric | Variables | Returns the top of the stack for that variable, otherwise the numeric value of the character |
|      | letters | Variables | Returns the top of the stack for that variable, otherwise the ordinal value of that character |
|      | `[`     | Pop       | Pop from the variable at the character below this one and return |
|      | `]`     | Push      | Push to the character at left the value of right, then return right |
|      | `{`     | Get       | Returns the ordinal value of the character at the position (left, right) |
|      | `}`     | Put       | Replaces the character at the position (left, right) with center         |
|      | `'`     | Char      | Return the character below it   |
|      | space   | No-op     | Returns 0. Other non-variable characters will also be no-ops |


### Notes:

* Variables don't necessarily have to be ASCII
  * They can even be the same character as instructions, if the command is getting the variable by character
* The get/put commands wrap around the boundary of the program
* This language isn't intended to be a Turing Tarpit (something hard to even *program* in), but it *is* meant to be interesting to golf in (finding the shortest program to execute a task), since this results in overlapping logic in a lot of places.