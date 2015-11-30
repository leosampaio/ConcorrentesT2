CXX = 				mpic++
CUDA_CC =			nvcc
CXXFLAGS = 			-I/usr/local/include -Wall -g -std=c++11 -fopenmp
CUDA_FLAGS =		-std=c++11
LIBS =    			-L/usr/local/lib/ -lopencv_core -lopencv_highgui -lopencv_imgproc
SRCS = 				main.cpp
CUDA_SRC =			cuda.cu
HEADERS = 	
BUILD_DIR =			build
OBJS = 				main.o
NAME =      		smooth
CUDA_NAME =			cudaSmooth
NP = 				4
HOSTFILE = 			hostfile

all: $(OBJS:%=$(BUILD_DIR)/%) cuda
	$(CXX) $^ $(CXXFLAGS) -o $(NAME) $(LIBS)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) -c $(CXXFLAGS) $< -o $@

cuda : $(CUDA_SRC)
	$(CUDA_CC) $< -o $(CUDA_NAME) $(CUDA_FLAGS) $(LIBS)

run:
	./$(NAME) $(ARGS)

run_parallel:
	mpirun -np $(NP) -hostfile $(HOSTFILE) ./$(NAME) $(ARGS)

run_cuda :
	./$(CUDA_NAME) $(ARGS)

clean:
	$(RM) *.o $(NAME) blured_* $(BUILD_DIR)/*

zip:
	@zip -r Concorrente.zip Makefile $(HEADERS) $(SRCS)
