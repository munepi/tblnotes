# tablenotes Package

**LaTeX: Footnotes in tables as table notes or page footnotes**

A `\footnote` inside a `tabular` gives its mark, but its text is lost: the footnote insertion is trapped in the box of the table.

The tablenotes package collects the footnotes of the outermost `tabular`, `tabular*` or `longtable`, together with their marks, while the table is typeset, and puts them

* `mode=table` (default): below the table, in the width of the table, as *table notes* (the footnotes of a minipage), marked with the `mpfootnote` counter (or a counter of your own) and numbered afresh for each table; or
* `mode=page`: at the bottom of the page, as ordinary footnotes numbered along with the footnotes of the body text.

The ordinary `\footnote`, `\footnote[<number>]`, `\footnotemark` and `\footnotetext` are used in the table. Tables inside a `minipage` or a `tcolorbox` are left as they are. With hyperref, each footnote mark links to its own footnote text.

* **Supported formats/engines:** pdfLaTeX, XeLaTeX, LuaLaTeX (with or without LuaTeX-ja), pLaTeX, upLaTeX (+ dvipdfmx)

## Files

| File | Description |
|---|---|
| `tablenotes.sty` | The package |
| `tablenotes.tex` / `.pdf` | Documentation |
| `test-*.tex` | Test suite (see below) |

## Requirements

* Tested with TeX Live 2026 (LaTeX2e 2026-11-01, longtable 4.28)

## Installation

Copy `tablenotes.sty` to your local TeX tree:
`$TEXMF/tex/latex/tablenotes/`

## Usage

```latex
\usepackage[mode=table, counter=mpfootnote]{tablenotes}

\begin{table}[ht]
  \centering
  \caption{A table with table notes}
  \begin{tabular}{ll}
    Item\footnote{A table note, below the table.} & Value \\
  \end{tabular}
\end{table}

\tablenotessetup{mode=page}  % also locally, e.g. inside a table environment
```

| Option | Default | Meaning |
|---|---|---|
| `mode` | `table` | `table`: below the table, in its width; `page`: at the bottom of the page; `off`: nothing is done |
| `counter` | `mpfootnote` | The counter of the table notes (`mode=table`) |
| `reset` | `true` | Reset the counter of the table notes for each table |
| `rule` | `false` | Put `\footnoterule` above the table notes |
| `skip` | (that of a minipage) | The space between the table and the table notes |
| `width` | (empty: the width of the table) | The width of the table notes; their left edge is that of the table |

## Errors, warnings and limitations

* threeparttable (and threeparttablex, which loads it) and tablefootnote cannot be loaded with tablenotes, before or after it (error). Note that threeparttable defines an environment named `tablenotes`; this package does not define `\tablenotes`.
* `mode=page`: the footnote insertions in a float are lost, so the footnotes of a table in a float are put right after the float environment, in the text. If the float moves to another page, they are not on the page of the float, and the package warns (no warning for `[H]` of the float package).
* The table notes of a `longtable` are put below the last row (below the last foot, if any), as a single block that is not broken across pages.
* By default the notes are set in the width of the table (the width of its box, including the `\tabcolsep` at both ends unless `@{}` removes it): those of a very narrow table are narrow, too; give `width` for them.
* `tabularx`, `xltabular`, `tabulary`, tabularray and nicematrix are not supported. Vertical writing (tate) and tagged PDF are outside the scope of this version.

## Testing

`make test` compiles every test twice with pdfLaTeX, XeLaTeX, LuaLaTeX, pLaTeX and upLaTeX (+ dvipdfmx), and checks the log:

* `TN-RESULT OK`: every footnote text is typeset exactly once, with its own mark (and, with hyperref, the anchor of its mark), on the expected page, in the table notes (in the expected width), as a page footnote or as a footnote of a box (recorded at shipout to the `.aux` file and checked when it is read back at `\end{document}`; see `test-common.tex`).
* `test-hyperref-*`: no warning on a duplicate or missing destination in the log or in the output of the engine and (x)dvipdfmx.
* `test-page-*`: exactly one tablenotes warning (a float that moves); the other tests: none.
* `test-errors`: the expected error message.

| Test | Engines | What it covers |
|---|---|---|
| `test-basic.tex` | pdflatex, xelatex, lualatex (article, ltjsarticle), platex, uplatex | `mode=table`: tables in the text and in a float, `[t]/[c]/[b]`, `\footnote[9]`, `\footnotemark`/`\footnotetext`, nested tables, `tabular*`, `counter`, `reset`, `width`, `mode=off` |
| `test-page.tex` | same | `mode=page`: tables in the text, in a float `[H]` and in a float that moves |
| `test-longtable.tex` | same | `longtable` over pages with a head and a foot, `[l]`, p columns, `width`, both modes |
| `test-minipage.tex` | same | tables in a `minipage`, a `tcolorbox`, and a `tcolorbox` with `page footnote` (tcbpagefootnote) |
| `test-hyperref.tex` | pdflatex, xelatex, lualatex, platex, uplatex | the four tests above with hyperref |
| `test-japanese.tex` | lualatex (ltjbook), platex (jbook), uplatex (ujbook) | a Japanese document |
| `test-errors.tex` | pdflatex | the error messages (incompatible packages, unknown counter) |

`test-common.tex` holds the helpers shared by the tests.

## Repository

* <https://github.com/munepi/tablenotes>
* Bug reports: <https://github.com/munepi/tablenotes/issues>

## License

This package is licensed under the conditions of the [LaTeX Project Public License](https://www.latex-project.org/lppl.txt), either version 1.3c of this license or any later version.

Copyright (c) 2026 Munehiro Yamamoto
