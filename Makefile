CXX = 				g++
CMPI = 				mpic++
CXXFLAGS = 			-I/usr/local/include -O0 -Wall -g -std=c++11
#LIBS =    			-L/usr/local/lib -lpthread -ldl -lm -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video -lopencv_objdetect
LIBS =    			-L/usr/local/lib -lopencv_core -lopencv_highgui -lopencv_imgproc
SRCS = 				main.cpp mainParallel.cpp
HEADERS = 	
BUILD_DIR =			build
OBJS_SIMPLE = 		main.o
OBJS_PARALLEL = 	mainParallel.o
NAME =      		smooth
NAME_PARALLEL =		$(NAME)Parallel
NP = 				4
HOSTFILE = 			hostfile

all: simple parallel

simple: $(OBJS_SIMPLE:%=$(BUILD_DIR)/%)
	$(CXX) $^ $(CXXFLAGS) $(LIBS) -o $(NAME)

parallel: CXX = $(CMPI)
parallel: CXXFLAGS := $(CXXFLAGS) -fopenmp
parallel: $(OBJS_PARALLEL:%=$(BUILD_DIR)/%)
	$(CXX) $^ $(CXXFLAGS) $(LIBS) -o $(NAME_PARALLEL)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) -c $(CXXFLAGS) $< -o $@

run_parallel:
	mpirun -np $(NP) -hostfile $(HOSTFILE) ./$(NAME_PARALLEL) $(ARGS)

run:
	@./$(NAME) $(ARGS)

clean:
	@rm -f *.elf *.o *.bin *.d *.map
	@rm -f build/*

zip:
	@zip -r Concorrente.zip Makefile $(HEADERS) $(SRCS)
	-rm -f *.elf *.o *.bin *.d *.map
