TNVER := $(shell awk '/ProvidesExplPackage\{tblnotes\}/{getline; split($$0, a, "[{}]"); print a[4]}' tblnotes.sty)

DOCS := tblnotes.pdf

.PHONY: ctanzip
ctanzip: tblnotes.zip ## Archive for CTAN upload
tblnotes.zip: clean $(DOCS)
	git archive --format=tar --prefix=tblnotes/ HEAD | gtar -x
	## remove unpacked files
	cd tblnotes/ && \
		rm -f .gitignore Makefile ctan.toml
	## then, now just make archive
	zip -9 -r tblnotes.zip tblnotes/*
	rm -rf tblnotes
	@echo finished

.PHONY: tblnotes.pdf
tblnotes.pdf: tblnotes.tex tblnotes.sty
	pdflatex -interaction=nonstopmode -halt-on-error $<
	pdflatex -interaction=nonstopmode -halt-on-error $<
	pdflatex -interaction=nonstopmode -halt-on-error $<

## Run the test suite ($(TNVER)):
##  * every test compiles without errors (each is run twice, since
##    longtable saves its column widths in the .aux file)
##  * TN-RESULT OK and no TN-* NG: every footnote text is typeset once,
##    with its own mark (and anchor), where it is expected (see
##    test-common.tex)
##  * test-page-* and test-hyperref-page-*: exactly one tblnotes
##    warning (a float that moves); the others: none
##  * test-hyperref-*: no warning on a duplicate or missing destination
##    in the log or in the output of the engine and (x)dvipdfmx
##  * test-errors-*: the expected error message
##  * test-tagging-*: tagged PDF with lualatex and pdflatex, run three
##    times; no error, no warning of tagpdf (but the one that
##    unicode-math is not loaded) or tblnotes, and in the structure
##    tree (show-pdf-tags --xml) every footnotemark and footnote refer
##    to each other (test-tagging.awk); as many of them as the
##    TAGS-FOOTNOTES line of test-tagging.tex says
## A test is "<engine>:<jobname>:<input>".  The output of the engine and
## of (x)dvipdfmx is kept in <jobname>.term.
ENGINES := pdflatex xelatex lualatex platex uplatex
CLS_platex := jarticle
CLS_uplatex := ujarticle

define tests_for
$(foreach e,$(ENGINES),$(e):test-$(1)-$(e):'$(if $(CLS_$(e)),\def\CLS{$(CLS_$(e))})\input test-$(1)') \
lualatex:test-$(1)-ltjsarticle-lualatex:'\def\CLS{ltjsarticle}\input test-$(1)'
endef
define hyperref_for
$(foreach e,$(ENGINES),$(e):test-hyperref-$(1)-$(e):'$(if $(CLS_$(e)),\def\CLS{$(CLS_$(e))})\def\TNfile{test-$(1)}\input test-hyperref')
endef

TESTS := \
  $(call tests_for,basic) \
  $(call tests_for,page) \
  $(call tests_for,longtable) \
  $(call tests_for,minipage) \
  $(call hyperref_for,basic) \
  $(call hyperref_for,page) \
  $(call hyperref_for,longtable) \
  $(call hyperref_for,minipage) \
  lualatex:test-japanese-lualatex:'\input test-japanese' \
  platex:test-japanese-platex:'\def\CLS{jbook}\input test-japanese' \
  uplatex:test-japanese-uplatex:'\def\CLS{ujbook}\input test-japanese'

TAGGING_ENGINES := lualatex pdflatex

## "<case>:<error message>" of test-errors.tex (pdflatex)
ERRORS := \
  tpt-before:"Package 'threeparttable' cannot" \
  tpt-after:"Package 'threeparttable' cannot" \
  tptx-after:"Package 'threeparttable' cannot" \
  tfn-before:"Package 'tablefootnote' cannot" \
  tfn-after:"Package 'tablefootnote' cannot" \
  counter:"Counter 'nosuchcounter' is not defined"

.PHONY: test
test:
	@set -e; \
	for t in $(TESTS); do \
	  eng=$${t%%:*}; rest=$${t#*:}; job=$${rest%%:*}; in=$${rest#*:}; \
	  echo "== $$eng $$job"; \
	  rm -f $$job.aux $$job.dvi $$job.xdv; \
	  opt=; if [ $$eng = xelatex ]; then opt=-no-pdf; fi; \
	  $$eng $$opt -interaction=nonstopmode -jobname=$$job "$$in" >$$job.term 2>&1 || true; \
	  $$eng $$opt -interaction=nonstopmode -jobname=$$job "$$in" >$$job.term 2>&1 || true; \
	  if [ -f $$job.dvi ]; then dvipdfmx $$job.dvi >>$$job.term 2>&1; fi; \
	  if [ -f $$job.xdv ]; then xdvipdfmx $$job.xdv >>$$job.term 2>&1; fi; \
	  if grep -q '^!' $$job.log; then echo "NG: error in $$job.log"; exit 1; fi; \
	  if grep -q '^TN-.* NG' $$job.log; then grep '^TN-.* NG' $$job.log; exit 1; fi; \
	  grep -q '^TN-RESULT OK' $$job.log || \
	    { echo "NG: no TN-RESULT OK in $$job.log"; exit 1; }; \
	  nwarn=`grep -c 'tblnotes Warning' $$job.log || true`; \
	  case $$job in test-page-*|test-hyperref-page-*) want=1;; *) want=0;; esac; \
	  [ $$nwarn -eq $$want ] || \
	    { echo "NG: $$nwarn tblnotes warning(s) in $$job.log, want $$want"; exit 1; }; \
	  case $$job in test-hyperref-*) \
	    if cat $$job.log $$job.term | \
	      grep -i 'duplicate\|already defined\|does not exist\|unreferenced destination'; then \
	      echo "NG: destination warning in $$job.log or $$job.term"; exit 1; fi;; \
	  esac; \
	done; \
	for e in $(ERRORS); do \
	  c=$${e%%:*}; msg=$${e#*:}; job=test-errors-$$c; \
	  echo "== pdflatex $$job"; \
	  pdflatex -interaction=nonstopmode -jobname=$$job "\def\CASE{$$c}\input test-errors" >$$job.term 2>&1 || true; \
	  grep -q "^! Package tblnotes Error: .*$$msg" $$job.log || \
	    { echo "NG: no expected error in $$job.log"; exit 1; }; \
	done; \
	want=`sed -n 's/^%% TAGS-FOOTNOTES: *//p' test-tagging.tex`; \
	for eng in $(TAGGING_ENGINES); do \
	  job=test-tagging-$$eng; \
	  echo "== $$eng $$job"; \
	  rm -f $$job.aux; \
	  for i in 1 2 3; do \
	    $$eng -interaction=nonstopmode -jobname=$$job test-tagging >$$job.term 2>&1 || true; \
	  done; \
	  if grep -q '^!' $$job.log; then echo "NG: error in $$job.log"; exit 1; fi; \
	  if grep 'Warning' $$job.log | grep -v 'unicode-math'; then \
	    echo "NG: warning in $$job.log"; exit 1; fi; \
	  show-pdf-tags --xml $$job.pdf >$$job.xml 2>>$$job.term || \
	    { echo "NG: show-pdf-tags failed on $$job.pdf"; exit 1; }; \
	  awk -v want=$$want -f test-tagging.awk $$job.xml || exit 1; \
	done; \
	echo "All tests passed ($(TNVER))"

.PHONY: clean
clean: ## Clean this repository
	rm -rf tblnotes.zip tblnotes
	rm -f *.aux *.log *.out *.toc *.dvi *.xdv *.synctex.gz *.term
	rm -f test-*.pdf test-*.xml
	find . -type f -name "*~" -delete
