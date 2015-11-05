CXX = 				mpic++
CXXFLAGS = 			-I/usr/local/include -O0 -Wall -g 
#LIBS =    			-L/usr/local/lib -lpthread -ldl -lm -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video -lopencv_objdetect
LIBS =    			-L/usr/local/lib/ -lopencv_core -lopencv_highgui -lopencv_imgproc
SRCS = 				main.cpp
HEADERS = 	
BUILD_DIR =			build
OBJS = 				main.o
NAME =      		smooth
NP = 				4
HOSTFILE = 			hostfile

all: $(OBJS:%=$(BUILD_DIR)/%)
	$(CXX) $^ $(CXXFLAGS) -o $(NAME) $(LIBS)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) -c $(CXXFLAGS) $< -o $@

run:
	./$(NAME) $(ARGS)

run_parallel:
	mpirun -np $(NP) -hostfile $(HOSTFILE) ./$(NAME) $(ARGS)

clean:
	$(RM) *.o $(NAME) blured_* $(BUILD_DIR)/*

zip:
	@zip -r Concorrente.zip Makefile $(HEADERS) $(SRCS)
