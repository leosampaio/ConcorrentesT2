#include <stdio.h>
#include <stdlib.h>
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>
#include <string>
#include <unistd.h>

using namespace std;
using namespace cv;

/// Constants
#define KERNEL_SIZE 5

/// Funcion Prototypes
void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel);

void scalar_convolution_oldschool(unsigned char* source_image,
    unsigned char* destiny_image,
    float* kernel,
    int k, 
    int w, int h, int channels);

int main( int argc, char** argv ) {

    // auxiliars
    Mat source_image, destiny_image, destiny_imageAux;
    bool black_and_white = false, visual = false;
    bool dont_save_image = false, opencv_std = false;

    // validade the input
    if (argc < 2) {
        cerr <<
        "usage: ./smooth image_path [--black-and-white] [--opencv-std] \n\
                                    [--visual] [--dont-save-image] [--parallel]"
        << endl;
        return -1;
    }

    // check the optional values
	for (int i = 2; i < argc; i++) {
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

		scalar_convolution (source_image, destiny_imageAux, kernel);

        //scalar_convolution(source_image, destiny_image, kernel);
        scalar_convolution_oldschool(
        	source_image.data, destiny_image.data, 
        	(float*) kernel.data, KERNEL_SIZE,  
			source_image.cols, source_image.rows, source_image.channels()
		);

		cout << "Resultado: " << (destiny_image == destiny_imageAux) << endl;
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

    int half_k = kernel.rows/2;
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

void scalar_convolution_oldschool(unsigned char* source_image,
    unsigned char* destiny_image,
    float* kernel,
    int k, 
    int w, int h, int channels) {

	int half_k = k / 2;

    // performs convolution
    // for each pixel, either 1 channel (BW) or 3 channel (colored) images
	for (int y = half_k; y < h - half_k; ++y) {
		for (int x = half_k; x < w - half_k; ++x) {
			for (int channel = 0; channel < channels; ++channel) {

				float total = 0;

				// multiply the kernel values by all neighboors
				for (int i = -half_k; i <= half_k; ++i) {
					for (int j = -half_k; j <= half_k; ++j) {
						auto kernel_value = kernel[i + half_k + (j + half_k) * k];

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
