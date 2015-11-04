
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
            else if (string(argv[i]) == "--opencv-std]") {
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

    medianBlur(source_image, destiny_image, KERNEL_SIZE);

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