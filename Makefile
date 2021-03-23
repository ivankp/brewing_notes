NAME = brewing

TEX = lualatex -interaction=batchmode -shell-escape
# BIB = bibtex -terse
BIB = biber --nolog -m 99
# -m 99 suppresses cross references that are not directly cited

.ONESHELL:
SHELL = bash

.PHONY: all clean

PDF := $(NAME).pdf
DEP :=

all: $(PDF)

$(PDF): %.pdf: %.tex $(DEP)
	@md5() { md5sum $*.$$1 2> /dev/null; }
	warn=1 # show warnings: 0 = on error, 1 = always
	for (( i=1, n=1; i<=n; ++i )); do
	  md5_aux=$$(md5 aux)
	  md5_bcf=$$(md5 bcf)
	  # run LaTeX
	  if (( i != 1 )) || (( $(words $(filter-out %.bib, $?)) != 0 ))
	  then
	    printf "\e[32;1m$$i\e[0m\n"
	    if ! $(TEX) $* > /dev/null; then
	      (( ++warn ))
	      break
	    fi
	  fi
	  # check if need to run multiple times
	  if (( i == 1 )) && ( # update bibliography
	    (( $(words $(filter %.bib, $?)) != 0 )) || \
	    [ "$$md5_bcf" != "$$(md5 bcf)" ]
	  ); then
	    printf '\e[32;1mbib\e[0m\n'
	    $(BIB) $* | awk '
	      sub(/^WARN/,"\033[33m&\033[0m") || \
	      sub(/^ERROR/,"\033[31m&\033[0m") \
	      { print }
	    '
	    [ "$${PIPESTATUS[0]}" == '0' ] || break
	    (( ++n ))
	  elif [ "$$md5_aux" != "$$(md5 aux)" ]; then # if aux file updated
	    (( ++n ))
	  fi
	done
	if (( warn > 0 )); then
	  awk '
	    sub(/.*Warning:/,"\033[33m&\033[0m") || \
	    sub(/^!.*/,"\033[31m&\033[0m") { p=1 }
	    /^$$/ { p=0 }
	    p # print if p != 0
	  ' $*.log
	fi

clean:
	@rm -fv $(addprefix $(NAME)., \
	  pdf aux log out toc lof lot bbl bcf blg run.xml nav snm)

