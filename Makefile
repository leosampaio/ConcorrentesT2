CXX = 				g++
CMPI = 				mpic++
CXXFLAGS = 			-I/usr/local/include/ -O0 -g3 -Wall -g
LIBS =    			-L/usr/local/lib -lpthread -ldl -lm -std=gnu++0x -std=c++0x -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video -lopencv_objdetect
SRCS = 				main.cpp mainParallel.cpp
HEADERS = 	
OBJS_SIMPLE = 	
OBJS_PARALLEL = 
NAME =      		smooth
NP = 				4
HOSTFILE = 			hostfile

all: simple parallel

simple: $(OBJS_SIMPLE) build/main.o
	$(CXX) $(OBJS_SIMPLE) build/main.o $(CXXFLAGS) $(LIBS) -o $(NAME)

parallel: CXX = $(CMPI)
parallel: $(OBJS_PARALLEL) build/mainParallel.o
	$(CXX) $(OBJS_PARALLEL) build/mainParallel.o $(CXXFLAGS) $(LIBS) -o $(NAME)Parallel

build/%.o: %.cpp
	@mkdir -p build
	$(CXX) -c $(CXXFLAGS) $< -o $@

run_parallel:
	mpirun -np $(NP) -hostfile $(HOSTFILE) ./$(NAME)Parallel $(ARGS)

run:
	@./$(NAME) $(ARGS)

clear:
	@rm -f *.elf *.o *.bin *.d *.map
	@rm -f build/*

zip:
	@zip -r Concorrente.zip Makefile $(HEADERS) $(SRCS)
	-rm -f *.elf *.o *.bin *.d *.map
