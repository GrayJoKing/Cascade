#! /opt/rakudo-pkg/bin/perl6

subset Char of Str where *.chars == 1;

my Array[Callable] @code;
my Array[Char] @codeContent;
my Array[Int] %variables is default(my Int @ = []);
my Array[Int] @start;
my Char $buffer;

sub width returns Int {
	return max map +*, @codeContent
}
sub height returns Int {
	return +@codeContent
}

sub getV(Char:D $_) returns Int {
	return %variables{$_} ?? %variables{$_}[*-1] !! /<:N>/ ?? .unival !! .ord
}

sub popV(Char:D $s) returns Int {
	if %variables{$s}:!exists { %variables{$s} = Array[Int].new(ord $s) }
	return %variables{$s} > 0 ?? %variables{$s}.pop !! getV $s
}

sub pushV(Char:D $s, Int:D $n) returns Int {
	if %variables{$s}:!exists { %variables{$s} = Array[Int]($n) }
	else { %variables{$s}.push($n) }
	return $n
}


sub getChar returns Char {
	LEAVE $buffer = Nil;
	return $buffer.defined ?? $buffer !! getc $*IN
}

sub getTempChar returns Char {
	return ($buffer = getChar)//"\0"
}

sub getIntInput returns Int {
	my Bool:D $negative = False;

	$negative = '-'.ord eq getCharInput() while !isEOF() && getTempChar() ~~ !/<:N>/;

	return 0 if isEOF;

	my Int:D $d = unival getChar;
	
	$d = $d*10 + getChar.unival while !isEOF() && getTempChar() ~~ /<:N>/;
	$d = -$d if $negative;
	
	return $d
}

sub getCharInput returns Int {
	return ord getChar//"\0"
}

sub isEOF returns Bool {
	return !$buffer.defined && $*IN.eof
}

sub getCodeFunc(Int:D $x, Int:D $y) returns Callable {				# Get a function at a specific point
	return @code[$y % height;$x % width]
}
sub getCodeChar(Int:D $x, Int:D $y) returns Char {					# Get a character at a specific point
	return @codeContent[$y % height;$x % width]
}

multi sub exec(Int:D $x, Int:D $y) returns Int {					# Execute a function at a specific point
	# say "$x $y ", @codeContent[$y % height;$x % width];
	return getCodeFunc($x, $y)()
}
multi sub exec(Int @x, Int:D $y) returns Array[Int] { 				# Execute a function at a series of x coordinates
	return Array[Int](@x.map:{ exec $_, $y }) 
}

sub parseCode(Int:D $x, Int:D $y, Char:D $c) {
	my &unary	= -> &f {&{f exec $x, $y+1}};						# A unary function that applies a function to the below coordinate
	my &binary  = -> &f {&{f |exec Array[Int]($x-1, $x+1), $y+1}};	# A binary function that applies a function to the two below coordinates
	
	@start.push(Array[Int]([$x, $y])) if $c eq '@';
	
	@code[$y;$x] = $c.&{
		# Arithmetic
		when '+'	{binary &[+]}
		when '-'	{binary &[-]}
		when '*'	{binary &[*]}
		when ':'	{binary {$^b ?? $^a div $b !! die "Division by zero"}}
		when '%'	{binary &[mod]}
		when '('	{unary *-1}
		when ')'	{unary *+1}
		
		# Comparison
		when '~'	{unary !*}
		when '='	{binary &[==]}
		when '<'	{binary &[<]}
		when '>'	{binary &[>]}
		
		# Control Flow
		when '@'	{unary +*}
		when '/'	{&{exec $x-1, $y+1}}
		when '\\'	{&{exec $x+1, $y+1}}
		when '|'	{&{exec $x, $y+1}}
		when '!'	{&{exec $x, $y+2}}
		when '^'	{binary {$^a;$^b}}
		when '$'	{&{exec($x+[-1, 1].pick, $y+1)}}
		
		# Conditionals
		when '?'	{&{exec $x+(exec($x, $y+1)>0)*2-1, $y+1}}
		when '_'	{&{exec($x-1, $y+1) && exec($x+1, $y+1)}}
		
		# IO
		when ','	{&getCharInput}
		when '.'	{unary {die "Attempted to print $_ as character" if !(0 <= $_ <= 0x10FFFF);print .chr;$_}}
		when '&'	{&getIntInput}
		when '#'	{unary {print +$_;$_}}
		when '"'	{&{
			+(while (my $c = getCodeChar $x, $y + ++$) ne '"' {
				print chr getV $c;
			})
		}}
		when ';'	{&isEOF}
		
		# Meta
		when '{'	{binary &ord o &getCodeChar}
		when '}'	{binary {
			@codeContent[$^b % height;$^a % width] = chr exec $x, $y+1;
			parseCode $a, $b, getCodeChar $a, $b;
			ord getCodeChar $^a, $^b
		}}
		when "'"	{&{ord getCodeChar $x, $y+1}}
		
		# Variables
		when /\w/	{&{getV $c}}
		when '['	{&{popV getCodeChar $x, $y+1}}
		when ']'	{&{pushV getCodeChar($x-1, $y+1), exec $x+1, $y+1}}
		default		{&{0}}
	}
}

my %*SUB-MAIN-OPTS = :named-anywhere;

multi sub MAIN (Str:D $file where *.IO.f, Bool :e(:$evaluate) = False) {
	
	$*OUT.out-buffer = 0;
	
	my Str:D $content = slurp $file;
	
	die "Program cannot be empty" if !$content;
	
	CATCH {
		default {
			note .message
		}
	}
	
	@codeContent = $content.split("\n").map:{my Char @ is default(" ") = .comb}
	
	for ^@codeContent -> $y {
		@code[$y] = my Callable @ is default(&{0}) = Array[Callable].new();
		for ^width() -> $x {
			parseCode $x, $y, @codeContent[$y;$x]
		}
	}

	if !@start {
		@start.push(Array[Int]([0, 0]));
	}
	for @start {
		(.say if $evaluate) given exec |$_;
	}
}


multi sub MAIN (Str:D $file where *.IO.f, Bool :s(:$structure) = False) {
	my Str:D $content = slurp $file;
	
	die "Program cannot be empty" if !$content;
	CATCH {
		default {
			note .message
		}
	}
	
	@codeContent = $content.split("\n").map:{my Char @ is default(" ") = .comb}
	
	my @seps = [" " xx 2*width()+1] xx height();
	
	for ^@codeContent -> $y {
		for ^width() -> $x {
			my &replace = {
				@seps[$y][$x*2] = @seps[$y][$x*2] eq '\\' ?? 'X' !! '/'
			}
			my &checkSkip = {
				@seps[$y][$x*2+1] eq "⊤" ?? $_ eq "|" ?? '+' !! "⊤" !! $_
			}
			@seps[$y;$x*2+1, $x*2+2] = @codeContent[$y;$x].&{
				when '/' { &replace();&checkSkip(" "), " "}
				when '\\' {&checkSkip(" "), '\\'}
				when '!' {@seps[$y+1][$x*2+1] = "⊤";@seps[$y][$x*2+1] eq "⊤" ?? "I" !! "⊥", ' '}
				when /<[+\-*:%=<>^$_\{[\]]>/ {&replace(); &checkSkip(" "), '\\'}
				when /<[()~@|.#']>/ {&checkSkip('|'), ' '}
				when /<[?}]>/ {&replace(); &checkSkip("|"), '\\'}
				default {&checkSkip(" "), " "}
			}
		}
		@seps[$y][0] = (@seps[$y][*-1] = @seps[$y][0] eq "/" && @seps[$y][*-1] eq "\\" ?? "X" !! sort(@seps[$y;0,*-1])[1]);
	}
	say @seps[*-1].join;
	
	for ^@codeContent -> $y {
		say " "~@codeContent[$y].join(" ");
		say @seps[$y].join;
	}
	
}

