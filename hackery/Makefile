.PHONY: all install
install: xmobar_launcher prlimit qcsv hash_join
	cp xmobar_launcher ..
	cp prlimit ..
	cp qcsv ..
	cp hash_join ..

xmobar_launcher: xmobar_launcher.c Makefile
	gcc -o xmobar_launcher xmobar_launcher.c

prlimit: prlimit.c Makefile
	gcc -o prlimit prlimit.c

qcsv: qcsv.cc Makefile
	g++ -std=c++11 -Wall -Ofast -g -o qcsv qcsv.cc

hash_join: hash_join.cc Makefile
	g++ -std=c++11 -O3 -o hash_join hash_join.cc

touch_utmp: touch_utmp.c Makefile
	gcc -o touch_utmp touch_utmp.c
