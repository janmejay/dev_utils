.PHONY: all install
install: xmobar_launcher prlimit qcsv hash_join
	cp xmobar_launcher ..
	cp prlimit ..
	cp qcsv ..

xmobar_launcher: xmobar_launcher.c
	gcc -o xmobar_launcher xmobar_launcher.c

prlimit: prlimit.c
	gcc -o prlimit prlimit.c

qcsv: qcsv.cc
	g++ -std=c++11 -Wall -g3 -ggdb -o qcsv qcsv.cc -l UTF8Strings-1

hash_join: hash_join.cc
	g++ -std=c++11 -O3 -o hash_join hash_join.cc
