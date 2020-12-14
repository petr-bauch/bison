/* Simplified -*- C++ -*- Type and Expression Grammar.  */

%glr-parser
%skeleton "glr2.cc"
%header
%locations
%debug

/* Nice error messages with details. */
%define parse.error detailed

%code requires
{
  #include "ast.hh"
}

%define api.value.type {Node}

%code
{

#include <cassert>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#if __cplusplus < 201103L
# define nullptr 0
#endif

  static yy::parser::semantic_type stmtMerge (const yy::parser::semantic_type& x0, const yy::parser::semantic_type& x1);

  static int yylex (yy::parser::semantic_type* val, yy::parser::location_type* loc);
}

%expect-rr 1

%token
  TYPENAME "typename"
  ID "identifier"

%right '='
%left '+'

%%

prog : %empty
     | prog stmt   { std::cout << @2 << ": " << $2 << '\n'; }
     ;

stmt : expr ';'  %merge <stmtMerge>     { $$ = $1; }
     | decl      %merge <stmtMerge>
     | error ';'        { $$ = Nterm ("<error>"); }
     | '@'              { $$ = $1; YYACCEPT; }
     ;

expr : ID
     | TYPENAME '(' expr ')'
                        { $$ = Nterm ("<cast>", $3, $1); }
     | expr '+' expr    { $$ = Nterm ("+", $1, $3); }
     | expr '=' expr    { $$ = Nterm ("=", $1, $3); }
     ;

decl : TYPENAME declarator ';'
                        { $$ = Nterm ("<declare>", $1, $2); }
     | TYPENAME declarator '=' expr ';'
                        { $$ = Nterm ("<init-declare>", $1, $2, $4); }
     ;

declarator
     : ID
     | '(' declarator ')' { $$ = $2; }
     ;

%%
/* A C error reporting function.  */
void yy::parser::error (const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}

static int yylex (yy::parser::semantic_type* lvalp, yy::parser::location_type* llocp)
{
  static int lineNum = 1;
  static int colNum = 0;

  while (1)
    {
      int c;
      assert (!feof (stdin));
      c = getchar ();
      switch (c)
        {
        case EOF:
          return 0;
        case '\t':
          colNum = (colNum + 7) & ~7;
          break;
        case ' ': case '\f':
          colNum += 1;
          break;
        case '\n':
          lineNum += 1;
          colNum = 0;
          break;
        default:
          {
            int tok;
            llocp->begin.line = llocp->end.line = lineNum;
            llocp->begin.column = colNum;
            if (isalpha (c))
              {
                std::string form;
                do
                  {
                    form += static_cast<char> (c);
                    colNum += 1;
                    c = getchar ();
                  }
                while (isalnum (c) || c == '_');

                ungetc (c, stdin);
                tok
                  = isupper (static_cast <unsigned char> (form[0]))
                  ? yy::parser::token::TYPENAME
                  : yy::parser::token::ID;
                *lvalp = Term (form);
              }
            else
              {
                colNum += 1;
                tok = c;
                lvalp = nullptr;
              }
            llocp->end.column = colNum-1;
            return tok;
          }
        }
    }
}

static yy::parser::semantic_type
stmtMerge (const yy::parser::semantic_type& x0, const yy::parser::semantic_type& x1)
{
  return Nterm ("<OR>", x0, x1);
}

int
main (int argc, char **argv)
{
  yy::parser parse;
  // Enable parse traces on option -p.
  if (1 < argc && strcmp (argv[1], "-p") == 0)
    parse.set_debug_level (1);
  return !!parse ();
}
