CFLAGS := -O0
CC := gcc

main: main.o
	$(CC) -o main main.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

main.s: main.o
	objdump --source -d -M intel main.o > main.$(CC).s

clean:
	rm -rf main *.o *.s
