all:
	Rscript -e "library(knitr); knit2html('databases.Rmd')"

clean:
	rm -f databases.{md,html}
