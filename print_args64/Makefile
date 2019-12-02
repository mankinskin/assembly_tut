args = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
current_dir=$(notdir $(shell pwd))
binary_name=$(current_dir)

%:
	@:

build:
	@nasm -g -f elf64 $(binary_name).asm
	@ld -m elf_x86_64 -static -o $(binary_name) $(binary_name).o

clean:
	@rm -f $(binary_name) $(binary_name).o

run: build
	@./$(binary_name) $(args)
