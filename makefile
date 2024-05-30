# Compiler
CC = g++
LEX = flex
YACC = bison

# Compiler flags
CFLAGS = -Wall -Wextra -g

# Source files
SRCS = lex.yy.c parser.tab.c

# Object files
OBJS = $(SRCS:.c=.o)

# Executable name
TARGET = main

# Default target
all: $(TARGET)

# Compile source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Link object files into executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

# Generate parser and lexer
parser.tab.c parser.tab.h: parser.y
	$(YACC) -d $<
	
lex.yy.c: lexer.l parser.tab.h
	$(LEX) $<

# Clean up object files and executable
clean:
	rm -f $(OBJS) $(TARGET) parser.tab.c parser.tab.h lex.yy.c