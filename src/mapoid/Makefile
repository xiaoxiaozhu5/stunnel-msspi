all: mapoid.o libmapoid.a

mapoid.o:
	g++ -Wall -Wl,--no-as-needed -std=c++11 -g -O2 -fPIC -Werror -Wno-unused-function -I../msspi/third_party/cprocsp/include mapoid.cpp -c -o mapoid.o

libmapoid.a: mapoid.o
	ar cr libmapoid.a mapoid.o
