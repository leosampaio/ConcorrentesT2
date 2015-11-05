#include <stdio.h>
#include <stdlib.h>
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>
#include <mpi.h>
#include <string>
#include <unistd.h>
#include <vector>

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
    int rank = 0, number_of_processes = 1;
    MPI_Status status;

    // auxiliars
    Mat source_image, destiny_image, final_image;
    bool black_and_white = false, visual = false;
    bool dont_save_image = false, opencv_std = false, parallel = false;
    int sizes[3];

    // validade the input
    if (argc < 2) {
        cerr <<
        "usage: ./smooth image_path [--black-and-white] [--opencv-std] \n\
                                    [--visual] [--dont-save-image] [--parallel]"
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
            else if (string(argv[i]) == "--opencv-std") {
                opencv_std = true;
            }
            else if (string(argv[i]) == "--parallel") {
                parallel = true;
            }
        }
    }

    // load the image and validate
    string image_path(argv[1]);
    if (rank == 0) {

        if (!black_and_white) {
            source_image = imread(image_path, CV_LOAD_IMAGE_COLOR);
        } else {
            source_image = imread(image_path, CV_LOAD_IMAGE_GRAYSCALE);
        }
    }

    if (parallel) {
        
        // start MPI processes and get rank
        MPI_Init(&argc,&argv);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);

        // how many procecess we have
        MPI_Comm_size(MPI_COMM_WORLD, &number_of_processes);

        // root process distributes images
        if (rank == 0 && source_image.data) {

            int size_of_pieces = source_image.rows/number_of_processes;
            int height = size_of_pieces + KERNEL_SIZE/2;

            for (int i = 1; i < number_of_processes; i++) {

                int y = size_of_pieces*i - KERNEL_SIZE/2;

                // create a rectangle representing the area to 'cut'
                Rect region_of_interest = Rect(0, y, source_image.cols, height);
                Mat piece = source_image(region_of_interest);

                // compute size to send
                sizes[0] = piece.size().height;
                sizes[1] = piece.size().width;
                sizes[2] = piece.type();
                MPI_Send(sizes, 3, MPI_INT, i, 0, MPI_COMM_WORLD);

                // send to other processes
                MPI_Send(piece.data,
                    sizes[0]*sizes[1]*piece.channels(),
                    MPI_UNSIGNED_CHAR,
                    i,
                    1,
                    MPI_COMM_WORLD);
            }

            source_image = source_image(Rect(0, 0, source_image.cols, height));
        }

        else {

            // get size and create matrix
            MPI_Recv(sizes, 3, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
            source_image = Mat(sizes[0], sizes[1], sizes[2]);

            MPI_Recv(source_image.data,
                sizes[0]*sizes[1]*source_image.channels(),
                MPI_UNSIGNED_CHAR,
                0,
                1,
                MPI_COMM_WORLD,
                &status);

        }
    }

    if (!source_image.data) {
        cerr << "Abort! Couldn't load image!" << endl;
        return -1;
    }

    destiny_image = Mat::zeros(source_image.size(), source_image.type());

    if (opencv_std) {
        blur(source_image, destiny_image, Size(KERNEL_SIZE, KERNEL_SIZE));
    } else {

        // creates the kernel for a uniform filter
        Mat kernel = Mat::ones(KERNEL_SIZE, KERNEL_SIZE, CV_32F)/
            (float)(KERNEL_SIZE*KERNEL_SIZE);

        scalar_convolution(source_image, destiny_image, kernel);
    }

    if (rank == 0) {

        final_image = destiny_image(Rect(KERNEL_SIZE/2,
                KERNEL_SIZE/2,
                destiny_image.cols - KERNEL_SIZE/2-2,
                destiny_image.rows - KERNEL_SIZE/2));
        for (int i = 1; i < number_of_processes; i++) {

            // get result from other friends
            MPI_Recv(sizes, 3, MPI_INT, i, 2, MPI_COMM_WORLD, &status);
            Mat piece(sizes[0], sizes[1], sizes[2]);
            MPI_Recv(piece.data,
                sizes[0]*sizes[1]*source_image.channels(),
                MPI_UNSIGNED_CHAR,
                i,
                3,
                MPI_COMM_WORLD,
                &status);

            // cut black borders
            Rect region_of_interest = Rect(KERNEL_SIZE/2,
                KERNEL_SIZE/2,
                piece.cols - KERNEL_SIZE/2-2,
                piece.rows - KERNEL_SIZE/2);
            piece = piece(region_of_interest);

            // concatenate
            vconcat(final_image, piece, final_image);
        } 

        if (visual) {
            imshow("Original Image", source_image);
            imshow("Blured Image", destiny_image);
            waitKey(0);
        }

        if (!dont_save_image) {
            string new_file_name = "blured_" + to_string(rank) + image_path;
            imwrite(new_file_name, final_image);
        }

    } else {

        // send result to root
        MPI_Send(sizes, 3, MPI_INT, 0, 2, MPI_COMM_WORLD);
        MPI_Send(destiny_image.data,
            sizes[0]*sizes[1]*destiny_image.channels(),
            MPI_UNSIGNED_CHAR,
            0,
            3,
            MPI_COMM_WORLD);

    }

    // horraaaaay, finish it up
    if (parallel) MPI_Finalize();
    return 0;
}

void scalar_convolution(cv::Mat& source_image,
    cv::Mat& destiny_image,
    cv::Mat& kernel) {

    int half_k = kernel.rows/2;
    int w = source_image.cols, h = source_image.rows;
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