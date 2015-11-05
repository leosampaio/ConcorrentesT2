#include <stdio.h>
#include <stdlib.h>
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>
#include <mpi.h>
#include <unistd.h>

using namespace std;
using namespace cv;

/// Constants
#define KERNEL_SIZE 5

/// Funcion Prototypes
void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel);

int main( int argc, char** argv ) {

    // mpi auxiliars
    int rank, number_of_procecess;
    char *cpu_name;

    // start MPI processes and get rank
    MPI_Init(&argc,&argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    // how many procecess we have
    MPI_Comm_size(MPI_COMM_WORLD, &number_of_procecess);

    // for debugging purposes, get hostname
    cpu_name    = (char *)calloc(80,sizeof(char));
    gethostname(cpu_name,80);
    printf("hello MPI user: from process = %i on machine=%s, of NCPU=%i processes\n",
           rank, cpu_name, number_of_procecess);

    // auxiliars
    Mat source_image; Mat destiny_image;
    bool black_and_white = false, visual = false;
    bool dont_save_image = false, is_root = rank == 0;

    // validade the input
    if (argc < 2) {
        cerr <<
        "usage: ./smooth image_path [--black-and-white] \n\
                                    [--visual] [--dont-save-image]"
        << endl;
        return -1;
    }

    // check the optional values
    if (argc > 2) {
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
    }

    // load the image and validate
    string image_path(argv[1]);
    if (!black_and_white) {
        source_image = imread(image_path, CV_LOAD_IMAGE_COLOR);
    } else {
        source_image = imread(image_path, CV_LOAD_IMAGE_GRAYSCALE);
    }
        
    if (!source_image.data) {
        cerr << "Abort! Couldn't load " << image_path << "!" << endl;
        return -1;
    }

    destiny_image = Mat::zeros(source_image.size(), source_image.type());

    // creates the kernel for a uniform filter
    Mat kernel = Mat::ones(KERNEL_SIZE, KERNEL_SIZE, CV_32F)/
        (float)(KERNEL_SIZE*KERNEL_SIZE);

    scalar_convolution(source_image, destiny_image, kernel);

    if (visual) {
        imshow("Original Image", source_image);
        imshow("Blured Image", destiny_image);
        waitKey(0);
    }

    if (!dont_save_image) {
        string new_file_name = "blured_" + to_string(rank) + image_path;
        imwrite(new_file_name, destiny_image);
    }

    // horraaaaay, finish it up
    MPI_Finalize();
    return 0;
}

void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel) {

    int half_k = kernel.rows/2;
    int h = source_image.cols, w = source_image.rows;
    bool black_and_white = source_image.channels() == 1;

    // performs convolution
    // for each pixel
    for (int y = half_k; y < h - half_k; ++y) {
        for (int x = half_k; x < w - half_k; ++x) {

            float total[3]; total[0] = 0; total[1] = 0; total[2] = 0;

            // multiply the kernel values by all neighboors
            for (int i = -half_k; i <= half_k; ++i) {
                for (int j = -half_k; j <= half_k; ++j) {
                    float kernel_value = 
                        kernel.at<float>(i+half_k, j+half_k);

                    if (black_and_white) {
                        total[0] += 
                            source_image.at<uchar>(y+i, x+j) * kernel_value;
                    } else {
                        for (int k=0; k<3; k++) {
                            total[k] += 
                                source_image.at<Vec3b>(y+i, x+j)[k] * 
                                kernel_value;
                        }
                    }
                }
            }

            // the resulting pixel is the sum of the multiplications
            if (black_and_white) { 
                destiny_image.at<uchar>(y, x) = total[0];
            } else {
                for (int k=0; k<3; k++)
                    destiny_image.at<Vec3b>(y, x)[k] = total[k];
            }
        }
    }
}
