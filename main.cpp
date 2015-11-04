
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>

using namespace std;
using namespace cv;

/// Global Variables
int KERNEL_SIZE = 5;

int main( int argc, char** argv ) {

    // auxiliars
    Mat source_image; Mat destiny_image;
    bool black_and_white = false, visual = false;
    bool dont_save_image = false, opencv_std = false;


    // validade the input
    if (argc < 2) {
        cerr <<
        "usage: ./smooth image_path [--black-and-white] [--opencv-std] \n\
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
            else if (string(argv[i]) == "--opencv-std") {
                opencv_std = true;
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

    destiny_image = Mat(source_image.cols, source_image.rows, CV_32F);

    if (opencv_std) {
        blur(source_image, destiny_image, Size(KERNEL_SIZE, KERNEL_SIZE));
    } else {

        // creates the kernel
        Mat kernel = Mat::ones(KERNEL_SIZE, KERNEL_SIZE, CV_32F)/
            (float)(KERNEL_SIZE*KERNEL_SIZE);

        int half_k = KERNEL_SIZE/2;
        int h = source_image.cols, w = source_image.rows;

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
                                source_image.at<uchar>(y+i, x+j);// * kernel_value;
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
                    cout << total[0]/25 <<endl;
                    destiny_image.at<uchar>(y, x) = uchar(total[0]/25.0);
                } else {
                    for (int k=0; k<3; k++)
                        destiny_image.at<Vec3b>(y, x)[k] = total[k];
                }
            }
        }
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