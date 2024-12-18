/** js sequence diagrams
 *  https://bramp.github.io/js-sequence-diagrams/
 *  (c) 2012-2017 Andrew Brampton (bramp.net)
 *  Simplified BSD license.
 */
%lex

%options case-insensitive

%{
	// Pre-lexer code can go here
%}

%x title
%x tildebox

%%

\t"~~~"               { this.begin('tildebox'); return 'tildebox'; }
<tildebox>\t"~~~"     { this.popState(); }
<tildebox>[^\t\r\n]+  { return 'meta'; }
<tildebox>[^\t]+      { return 'addinfo'; }

[\r\n]+           return 'NL';
\s+               /* skip whitespace */
\#[^\r\n]*        /* skip comments */
"participant"     return 'participant';
"left of"         return 'left_of';
"right of"        return 'right_of';
"over"            return 'over';
"note"            return 'note';
"title"           { this.begin('title'); return 'title'; }
<title>[^\r\n]+   { this.popState(); return 'MESSAGE'; }
","               return ',';
[^\->:,\r\n"]+    return 'ACTOR';
\"[^"]+\"         return 'ACTOR';
"--"              return 'DOTLINE';
"-"               return 'LINE';
">>"              return 'OPENARROW';
">"               return 'ARROW';
":"[^\r\n]+       return 'MESSAGE';
<<EOF>>           return 'EOF';
.                 return 'INVALID';

/lex

%start start

%% /* language grammar */

start
	: document 'EOF' { return yy.parser.yy; } /* returning parser.yy is a quirk of jison >0.4.10 */
	;

document
	: /* empty */
	| document line
	;

line
	: statement { }
	| NL
	;

statement
	: 'participant' actor_alias { $2; }
	| signal               { yy.parser.yy.addSignal($1); }
	| note_statement       { yy.parser.yy.addSignal($1); }
	| 'title' message      { yy.parser.yy.setTitle($2);  }
	;

note_statement
	: 'note' placement actor message NL { $$ = new Diagram.Note($3, $2, $4, "", ""); }
	| 'note' 'over' actor_pair message NL { $$ = new Diagram.Note($3, Diagram.PLACEMENT.OVER, $4, "", ""); }
	| 'note' placement actor message NL tildebox addinfo { $$ = new Diagram.Note($3, $2, $4, "", $7); }
	| 'note' 'over' actor_pair message NL tildebox addinfo { $$ = new Diagram.Note($3, Diagram.PLACEMENT.OVER, $4, "", $7); }
	| 'note' placement actor message NL tildebox meta addinfo { $$ = new Diagram.Note($3, $2, $4, $7, $8); }
	| 'note' 'over' actor_pair message NL tildebox meta addinfo { $$ = new Diagram.Note($3, Diagram.PLACEMENT.OVER, $4, $7, $8); }
	;

actor_pair
	: actor             { $$ = $1; }
	| actor ',' actor   { $$ = [$1, $3]; }
	;

placement
	: 'left_of'   { $$ = Diagram.PLACEMENT.LEFTOF; }
	| 'right_of'  { $$ = Diagram.PLACEMENT.RIGHTOF; }
	;

signal
	: actor signaltype actor message NL { $$ = new Diagram.Signal($1, $2, $3, $4, "", ""); }
	| actor signaltype actor message NL tildebox addinfo { $$ = new Diagram.Signal($1, $2, $3, $4, "", $7 ); }
	| actor signaltype actor message NL tildebox meta addinfo { $$ = new Diagram.Signal($1, $2, $3, $4, $7, $8 ); }
	;

actor
	: ACTOR { $$ = yy.parser.yy.getActor(Diagram.unescape($1)); }
	;

actor_alias
	: ACTOR { $$ = yy.parser.yy.getActorWithAlias(Diagram.unescape($1)); }
	;

signaltype
	: linetype arrowtype  { $$ = $1 | ($2 << 2); }
	| linetype            { $$ = $1; }
	;

linetype
	: LINE      { $$ = Diagram.LINETYPE.SOLID; }
	| DOTLINE   { $$ = Diagram.LINETYPE.DOTTED; }
	;

arrowtype
	: ARROW     { $$ = Diagram.ARROWTYPE.FILLED; }
	| OPENARROW { $$ = Diagram.ARROWTYPE.OPEN; }
	;

message
	: MESSAGE { $$ = Diagram.unescape($1.substring(1)); }
	;


%%
