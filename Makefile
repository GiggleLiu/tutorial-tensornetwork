JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update()'

pluto:
	$(JL) -e "using Pluto; Pluto.run(notebook=\"examples/$${case}/main.jl\")"

pdf:
	typst compile notes/tnet.typ notes/tnet.pdf
	@echo "Notebook is ready in notes/tnet.pdf"

.PHONY: init update pluto pdf