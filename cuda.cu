#include <cstdio>
#include <cstdlib>
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>
#include <string>
#include <cstring>
#include <unistd.h>

using namespace std;
using namespace cv;

/// Constants
#define KERNEL_SIZE 5

/// Funcion Prototypes
void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel);

__global__ void scalar_convolution_oldschool(unsigned char* source_image,
    unsigned char* destiny_image,
    float* kernel,
    int k, 
    int w, int h, int channels);

int main( int argc, char** argv ) {

    // auxiliars
    Mat source_image, destiny_image, destiny_imageAux;
	unsigned char *source_image_raw, *destiny_image_raw;
    bool black_and_white = false, visual = false;
    bool dont_save_image = false, opencv_std = false;

    // validade the input
    if (argc < 3) {
        cerr <<
        "usage: ./smooth image_path numThreads [--black-and-white] [--opencv-std] \n\
                                    [--visual] [--dont-save-image] [--parallel]"
        << endl;
        return -1;
    }

    // check the optional values
	for (int i = 3; i < argc; i++) {
		if (string(argv[i]) == "--black-and-white") {
			black_and_white = true;
		}
		else if (string(argv[i]) == "--visual") {
			visual = true;
		}
		else if (string(argv[i]) == "--dont-save-image") {
			dont_save_image = true;
		}
	}

    // load the image and validate
    string image_path(argv[1]);
	int numThreads = atoi (argv[2]);
	if (numThreads <= 0) {
		cerr << "Poxa, número de Threads tem que ser positivo!" << endl;
		return -1;
	}

	if (!black_and_white) {
		source_image = imread(image_path, CV_LOAD_IMAGE_COLOR);
	} else {
		source_image = imread(image_path, CV_LOAD_IMAGE_GRAYSCALE);
	}

    if (!source_image.data) {
        cerr << "Abort! Couldn't load image!" << endl;
        return -1;
    }

    destiny_image = Mat::zeros(source_image.size (), source_image.type());
    destiny_imageAux = Mat::zeros(source_image.size (), source_image.type());

    if (opencv_std) {
        blur(source_image, destiny_image, Size(KERNEL_SIZE, KERNEL_SIZE));
    } else {

        // creates the kernel for a uniform filter
        Mat kernel = Mat::ones(KERNEL_SIZE, KERNEL_SIZE, CV_32F)/
            (float)(KERNEL_SIZE*KERNEL_SIZE);
		float *kernel_raw;


		// preparação para chamar o kernel CUDA
		size_t total_memory = source_image.total () * source_image.channels () * sizeof (unsigned char);
		size_t kernel_memory = kernel.total () * sizeof (float);
		/*cout << "Tamanho de memória total: " << total_memory << endl;*/
		/*cout << "Memória do Kernel: " << kernel_memory << " = " << kernel.total () << " * " << sizeof (float) << endl;*/

		if (cudaMalloc (&source_image_raw, total_memory))	cerr << "Eita, cudaMalloc (source)  falhou =/" << endl;
		if (cudaMalloc (&destiny_image_raw, total_memory))	cerr << "Eita, cudaMalloc (destiny) falhou =/" << endl;
		if (cudaMalloc (&kernel_raw, kernel_memory))		cerr << "Eita, cudaMalloc (kernel)  falhou =/" << endl;

		cudaMemcpy (source_image_raw, source_image.data, total_memory, cudaMemcpyHostToDevice);
		cudaMemcpy (kernel_raw, kernel.data, kernel_memory, cudaMemcpyHostToDevice);

		// roda o normal
		/*scalar_convolution (source_image, destiny_imageAux, kernel);*/

		// e roda o kernel na GPU
		scalar_convolution_oldschool <<<1, numThreads>>> (
			source_image_raw, destiny_image_raw,
			kernel_raw, KERNEL_SIZE,
			source_image.cols, source_image.rows, source_image.channels ()
		);

		cudaMemcpy (destiny_image.data, destiny_image_raw, total_memory, cudaMemcpyDeviceToHost);

		cudaFree (source_image_raw);
		cudaFree (destiny_image_raw);
		cudaFree (kernel_raw);
    }

	if (visual) {
		imshow("Original Image", source_image);
		imshow("Blured Image", destiny_image);
		waitKey(0);
	}

	if (!dont_save_image) {
		string new_file_name = "blured_" + image_path;
		imwrite(new_file_name, destiny_image);
	}

    return 0;
}

void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel) {

	int k = kernel.rows;
	int half_k = k / 2;
	int w = source_image.cols, h = source_image.rows;

    // performs convolution
    // for each pixel, either 1 channel (BW) or 3 channel (colored) images
	for (int channel = 0; channel < source_image.channels (); channel++) {
		for (int y = half_k; y < h - half_k; ++y) {
			for (int x = half_k; x < w - half_k; ++x) {

				float total = 0;

				// multiply the kernel values by all neighboors
				for (int i = -half_k; i <= half_k; ++i) {
					for (int j = -half_k; j <= half_k; ++j) {
						auto kernel_value = kernel.at<float> (i + half_k, j + half_k);

						auto pixel = source_image.ptr (y + i, x + j) + channel;
						total += (*pixel) * kernel_value;
					}
				}

				// the resulting pixel is the sum of the multiplications
				auto pixel = destiny_image.ptr (y, x) + channel;
				*pixel = total;
			}
		}
	}
}

__device__ int myMax (int a, int b) { return a > b ? a : b; }

__global__ void scalar_convolution_oldschool (unsigned char* source_image,
    unsigned char* destiny_image,
    float* gKernel,
    int k, 
    int w, int h, int channels) {

	__shared__ float kernel[KERNEL_SIZE];
	for (int i = threadIdx.x; i < k * k; i += blockDim.x) {
		kernel[i] = gKernel[i];
	}

	int half_k = k / 2;

	int linhasPorThread = h / blockDim.x;
	int h_efetiva = linhasPorThread + half_k * 2;
	int start_y = linhasPorThread * threadIdx.x - half_k;
	int end_y = start_y + h_efetiva;
	start_y = myMax (0, start_y);
	end_y = min (h, end_y);

	/*printf ("[%d] linhas %d~%d\n", threadIdx.x, start_y, end_y);*/


    // performs convolution
    // for each pixel, either 1 channel (BW) or 3 channel (colored) images
	for (int y = start_y + half_k; y < end_y - half_k; ++y) {
		for (int x = half_k; x < w - half_k; ++x) {
			for (int channel = 0; channel < channels; ++channel) {

				float total = 0;

				// multiply the kernel values by all neighboors
				for (int i = -half_k; i <= half_k; ++i) {
					for (int j = -half_k; j <= half_k; ++j) {
						auto kernel_value = kernel[(i + half_k) * k + j + half_k];

						auto pixel = source_image + channels * ((y + i) * w + x + j) + channel;
						total += *pixel * kernel_value;
					}
				}

				// the resulting pixel is the sum of the multiplications
				auto pixel = destiny_image + channels * (y * w + x) + channel;
				*pixel = total;
			}
		}
	}
}
