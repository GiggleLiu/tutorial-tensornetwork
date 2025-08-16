JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update()'

notebook:
	$(JL) -e "using IJulia; notebook(dir=\"examples/$${case}\", detached=true)"

.PHONY: init update notebook