#include "opencv2/imgproc/imgproc.hpp"
#include "sobel_alg.h"
#include <arm_neon.h>
using namespace cv;

/*******************************************
 * Model: grayScale
 * Input: Mat img
 * Output: None directly. Modifies a ref parameter img_gray_out
 * Desc: This module converts the image to grayscale
 ********************************************/
void grayScale(Mat& img, Mat& img_gray_out)
{
  // double color;

  // rows x cols = 480 x 640

  // convert to integer, 0-255
  uint8_t r = (uint8_t) (256.0*0.144);
  uint8_t g = (uint8_t) (256.0*0.587);
  uint8_t b = (uint8_t) (256.0*0.299);
  uint16x8_t v_r = vmovl_u8(vdup_n_u8(r));
  uint16x8_t v_g = vmovl_u8(vdup_n_u8(g));
  uint16x8_t v_b = vmovl_u8(vdup_n_u8(b));

  // float16x8_t shift = vdupq_n_f16((float16_t) (256.0));
  printf("Gray Calc img rows & cols %d, %d\n", img.rows, img.cols);
  printf("Gray Calc img_gray_out rows & cols %d, %d\n", img_gray_out.rows, img_gray_out.cols);
  // Convert to grayscale
  for (int i=0; i<img.rows; i++) {
    for (int j=0; j<img.cols; j+=8) {
      // color = .114*img.data[STEP0*i + STEP1*j] +
      //         .587*img.data[STEP0*i + STEP1*j + 1] +
      //         .299*img.data[STEP0*i + STEP1*j + 2];

      uint8x8x3_t v8 = vld3_u8(&img.data[STEP0*i + STEP1*j]); // 3x16 vector of 8-bit integers
      uint8x8_t uint8_v8_r = v8.val[0];
      uint8x8_t uint8_v8_g = v8.val[1];
      uint8x8_t uint8_v8_b = v8.val[2];

      uint16x8_t uint16_v8_r = vmovl_u8(uint8_v8_r);
      uint16x8_t uint16_v8_g = vmovl_u8(uint8_v8_g);
      uint16x8_t uint16_v8_b = vmovl_u8(uint8_v8_b);

      uint16_v8_r = vmulq_u16(uint16_v8_r, v_r);
      uint16_v8_g = vmulq_u16(uint16_v8_g, v_g);
      uint16_v8_b = vmulq_u16(uint16_v8_b, v_b);

      // float16x8_t f16_color_r = vdivq_f16(vcvtq_f16_u16(uint16_v8_r), shift);
      // float16x8_t f16_color_g = vdivq_f16(vcvtq_f16_u16(uint16_v8_g), shift);
      // float16x8_t f16_color_b = vdivq_f16(vcvtq_f16_u16(uint16_v8_b), shift);
      
      
      uint8_v8_r = vqshrn_n_u16(uint16_v8_r, 8);
      uint8_v8_g = vqshrn_n_u16(uint16_v8_g, 8);
      uint8_v8_b = vqshrn_n_u16(uint16_v8_b, 8);

      uint8x8_t color = vadd_u8(uint8_v8_r, uint8_v8_g);
      color = vadd_u8(color, uint8_v8_b);
      vst1_u8(&img_gray_out.data[IMG_WIDTH*i + j], color);

      // img_gray_out.data[IMG_WIDTH*i + j] = color;
    }
  }
}

/*******************************************
 * Model: sobelCalc
 * Input: Mat img_in
 * Output: None directly. Modifies a ref parameter img_sobel_out
 * Desc: This module performs a sobel calculation on an image. It first
 *  converts the image to grayscale, calculates the gradient in the x
 *  direction, calculates the gradient in the y direction and sum it with Gx
 *  to finish the Sobel calculation
 ********************************************/
void sobelCalc(Mat& img_gray, Mat& img_sobel_out, bool up)
{
  Mat img_outx = img_gray.clone();
  Mat img_outy = img_gray.clone();

  printf("Sobel Calc After Clone Start\n");

  // Apply Sobel filter to black & white image
  // unsigned short sobel;
  // rows x cols = 480 x 640

  uint16x8_t vmax = vmovl_u8(vdup_n_u8((uint8_t) 255));

  // Calculate the x convolution
  printf("Sobel Calc img_gray rows & cols %d, %d\n", img_gray.rows, img_gray.cols);
  printf("Sobel Calc img_sobel_out rows & cols %d, %d\n", img_sobel_out.rows, img_sobel_out.cols);
  printf("Sobel Calc img_sobel_out rows & cols %d, %d\n", img_outx.rows, img_outx.cols);
  for (int i=1; i<img_gray.rows-up; i++) {
    for (int j=1; j<img_gray.cols-7; j+=8) {      
      // printf("Convolution x start i j = %d, %d\n", i, j);
      // sobel = abs(img_gray.data[IMG_WIDTH*(i-1) + (j-1)] -
		  // img_gray.data[IMG_WIDTH*(i+1) + (j-1)] +
		  // 2*img_gray.data[IMG_WIDTH*(i-1) + (j)] -
		  // 2*img_gray.data[IMG_WIDTH*(i+1) + (j)] +
		  // img_gray.data[IMG_WIDTH*(i-1) + (j+1)] -
		  // img_gray.data[IMG_WIDTH*(i+1) + (j+1)]);
      
      uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1) + (j-1)]));
      uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1) + (j-1)]));
      uint16x8_t uint16_v8_3 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1) + (j)])); // 2*
      uint16x8_t uint16_v8_4 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1) + (j)])); // 2*
      uint16x8_t uint16_v8_5 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1) + (j+1)]));
      uint16x8_t uint16_v8_6 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1) + (j+1)]));

      // printf("Convolution x load vecs\n");
      uint16_v8_3 = vmulq_n_u16(uint16_v8_3, (uint16_t) 2);
      uint16_v8_4 = vmulq_n_u16(uint16_v8_4, (uint16_t) 2);

      // printf("Convolution x multiply vecs\n");


      uint16x8_t pos = vaddq_u16(uint16_v8_1, uint16_v8_3);
      pos = vaddq_u16(pos, uint16_v8_5);
      uint16x8_t neg = vaddq_u16(uint16_v8_2, uint16_v8_4);
      neg = vaddq_u16(neg, uint16_v8_6);

      // printf("Convolution x add vecs\n");

      uint16x8_t uint16_temp = vabdq_u16(pos, neg); // abs(pos - neg)

      // printf("Convolution x abs vecs\n");


      uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp); 

      // printf("Convolution x clamp vecs\n");

      vst1_u8(&img_outx.data[IMG_WIDTH*i + j], vqmovn_u16(uint16_temp));

      // printf("Convolution x store vecs\n");

      // printf("Convolution x done i j = %d, %d\n", i, j);

      // sobel = (sobel > 255) ? 255 : sobel;
      // img_outx.data[IMG_WIDTH*(i) + (j)] = sobel;
    }
  }

  printf("Convolution x done\n");
  printf("x done Sobel Calc img_gray rows & cols %d, %d\n", img_gray.rows, img_gray.cols);
  printf("x done Sobel Calc img_sobel_out rows & cols %d, %d\n", img_sobel_out.rows, img_sobel_out.cols);
  printf("x done Sobel Calc img_sobel_out rows & cols %d, %d\n", img_outy.rows, img_outy.cols);
  // Calc the y convolution
  for (int i=1; i<img_gray.rows-up; i++) {
    for (int j=1; j<img_gray.cols-7; j+=8) {
    // printf("Convolution y start i j = %d, %d\n", i, j);
    //  sobel = abs(img_gray.data[IMG_WIDTH*(i-1) + (j-1)] -
		//    img_gray.data[IMG_WIDTH*(i-1) + (j+1)] +
		//    2*img_gray.data[IMG_WIDTH*(i) + (j-1)] -
		//    2*img_gray.data[IMG_WIDTH*(i) + (j+1)] +
		//    img_gray.data[IMG_WIDTH*(i+1) + (j-1)] -
		//    img_gray.data[IMG_WIDTH*(i+1) + (j+1)]);

    uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1) + (j-1)]));
    uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1) + (j+1)]));
    uint16x8_t uint16_v8_3 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i) + (j-1)])); // 2*
    uint16x8_t uint16_v8_4 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i) + (j+1)])); // 2*
    uint16x8_t uint16_v8_5 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1) + (j-1)]));
    uint16x8_t uint16_v8_6 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1) + (j+1)]));

    // printf("Convolution y b 1 i j = %d, %d\n", i, j);

    uint16_v8_3 = vmulq_n_u16(uint16_v8_3, (uint16_t) 2);
    uint16_v8_4 = vmulq_n_u16(uint16_v8_4, (uint16_t) 2);

    uint16x8_t pos = vaddq_u16(uint16_v8_1, uint16_v8_3);
    pos = vaddq_u16(pos, uint16_v8_5);
    uint16x8_t neg = vaddq_u16(uint16_v8_2, uint16_v8_4);
    neg = vaddq_u16(neg, uint16_v8_6);

    // printf("Convolution y b 2 i j = %d, %d\n", i, j);

    uint16x8_t uint16_temp = vabdq_u16(pos, neg); // abs(pos - neg)

    uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp);
    // printf("Convolution y b 3 i j = %d, %d\n", i, j);
    vst1_u8(&img_outy.data[IMG_WIDTH*i + j], vqmovn_u16(uint16_temp));
    // printf("Convolution y b 4 i j = %d, %d\n", i, j);


    //  sobel = (sobel > 255) ? 255 : sobel;

    //  img_outy.data[IMG_WIDTH*(i) + j] = sobel;

    // printf("Convolution y done i j = %d, %d\n", i, j);
    }
  }

  printf("Convolution y done\n");

  // Combine the two convolutions into the output image
  for (int i=1; i<img_gray.rows; i++) {
    for (int j=1; j<img_gray.cols-7; j+=8) {
      // sobel = img_outx.data[IMG_WIDTH*(i) + j] + img_outy.data[IMG_WIDTH*(i) + j];

      uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_outx.data[IMG_WIDTH*(i) + j]));
      uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_outy.data[IMG_WIDTH*(i) + j]));
      // printf("load vecs\n");

      uint16x8_t uint16_temp = vaddq_u16(uint16_v8_1, uint16_v8_2);
      // printf("add vecs\n");

      uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp);
      // printf("clamp vecs\n");

      vst1_u8(&img_sobel_out.data[IMG_WIDTH*i + j], vqmovn_u16(uint16_temp));
      // printf("store vecs\n");
      // printf("done i j = %d, %d\n", i, j);

      // sobel = (sobel > 255) ? 255 : sobel;
      // img_sobel_out.data[IMG_WIDTH*(i) + j] = sobel;
    }
  }
}




// void sobelCalcMT(Mat& img_gray, Mat& img_sobel_out)
// {
//   Mat img_outx = img_gray.clone();
//   Mat img_outy = img_gray.clone();

//   printf("Sobel Calc After Clone Start\n");

//   // Apply Sobel filter to black & white image
//   // unsigned short sobel;
//   // rows x cols = 480 x 640

//   uint16x8_t vmax = vmovl_u8(vdup_n_u8((uint8_t) 255));

//   // Calculate the x convolution
//   printf("Sobel Calc img_gray rows & cols %d, %d\n", img_gray.rows, img_gray.cols);
//   printf("Sobel Calc img_sobel_out rows & cols %d, %d\n", img_sobel_out.rows, img_sobel_out.cols);
//   printf("Sobel Calc img_sobel_out rows & cols %d, %d\n", img_outx.rows, img_outx.cols);
//   // IMG_WIDTH 640
//   // rows 480
//   // cols 320
//   for (int i=1; i<img_gray.rows; i++) {
//     for (int j=1; j<img_gray.cols-7; j+=8) {      
//       // printf("Convolution x start i j = %d, %d\n", i, j);
//       // sobel = abs(img_gray.data[IMG_WIDTH*(i-1) + (j-1)] -
// 		  // img_gray.data[IMG_WIDTH*(i+1) + (j-1)] +
// 		  // 2*img_gray.data[IMG_WIDTH*(i-1) + (j)] -
// 		  // 2*img_gray.data[IMG_WIDTH*(i+1) + (j)] +
// 		  // img_gray.data[IMG_WIDTH*(i-1) + (j+1)] -
// 		  // img_gray.data[IMG_WIDTH*(i+1) + (j+1)]);
      
//       uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1)/2 + (j-1)]));
//       uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1)/2 + (j-1)]));
//       uint16x8_t uint16_v8_3 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1)/2 + (j)])); // 2*
//       uint16x8_t uint16_v8_4 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1)/2 + (j)])); // 2*
//       uint16x8_t uint16_v8_5 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1)/2 + (j+1)]));
//       uint16x8_t uint16_v8_6 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1)/2 + (j+1)]));

//       // printf("Convolution x load vecs\n");
//       uint16_v8_3 = vmulq_n_u16(uint16_v8_3, (uint16_t) 2);
//       uint16_v8_4 = vmulq_n_u16(uint16_v8_4, (uint16_t) 2);

//       // printf("Convolution x multiply vecs\n");


//       uint16x8_t pos = vaddq_u16(uint16_v8_1, uint16_v8_3);
//       pos = vaddq_u16(pos, uint16_v8_5);
//       uint16x8_t neg = vaddq_u16(uint16_v8_2, uint16_v8_4);
//       neg = vaddq_u16(neg, uint16_v8_6);

//       // printf("Convolution x add vecs\n");

//       uint16x8_t uint16_temp = vabdq_u16(pos, neg); // abs(pos - neg)

//       // printf("Convolution x abs vecs\n");


//       uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp); 

//       // printf("Convolution x clamp vecs\n");

//       vst1_u8(&img_outx.data[IMG_WIDTH*i/2 + j], vqmovn_u16(uint16_temp));

//       // printf("Convolution x store vecs\n");

//       // printf("Convolution x done i j = %d, %d\n", i, j);

//       // sobel = (sobel > 255) ? 255 : sobel;
//       // img_outx.data[IMG_WIDTH*(i) + (j)] = sobel;
//     }
//   }

//   printf("Convolution x done\n");
//   printf("x done Sobel Calc img_gray rows & cols %d, %d\n", img_gray.rows, img_gray.cols);
//   printf("x done Sobel Calc img_sobel_out rows & cols %d, %d\n", img_sobel_out.rows, img_sobel_out.cols);
//   printf("x done Sobel Calc img_sobel_out rows & cols %d, %d\n", img_outy.rows, img_outy.cols);
//   // Calc the y convolution
//   for (int i=1; i<img_gray.rows; i++) {
//     for (int j=1; j<img_gray.cols-7; j+=8) {
//     // printf("Convolution y start i j = %d, %d\n", i, j);
//     //  sobel = abs(img_gray.data[IMG_WIDTH*(i-1) + (j-1)] -
// 		//    img_gray.data[IMG_WIDTH*(i-1) + (j+1)] +
// 		//    2*img_gray.data[IMG_WIDTH*(i) + (j-1)] -
// 		//    2*img_gray.data[IMG_WIDTH*(i) + (j+1)] +
// 		//    img_gray.data[IMG_WIDTH*(i+1) + (j-1)] -
// 		//    img_gray.data[IMG_WIDTH*(i+1) + (j+1)]);

//     uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1)/2 + (j-1)]));
//     uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i-1)/2 + (j+1)]));
//     uint16x8_t uint16_v8_3 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i)/2 + (j-1)])); // 2*
//     uint16x8_t uint16_v8_4 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i)/2 + (j+1)])); // 2*
//     uint16x8_t uint16_v8_5 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1)/2 + (j-1)]));
//     uint16x8_t uint16_v8_6 = vmovl_u8(vld1_u8(&img_gray.data[IMG_WIDTH*(i+1)/2 + (j+1)]));

//     // printf("Convolution y b 1 i j = %d, %d\n", i, j);

//     uint16_v8_3 = vmulq_n_u16(uint16_v8_3, (uint16_t) 2);
//     uint16_v8_4 = vmulq_n_u16(uint16_v8_4, (uint16_t) 2);

//     uint16x8_t pos = vaddq_u16(uint16_v8_1, uint16_v8_3);
//     pos = vaddq_u16(pos, uint16_v8_5);
//     uint16x8_t neg = vaddq_u16(uint16_v8_2, uint16_v8_4);
//     neg = vaddq_u16(neg, uint16_v8_6);

//     // printf("Convolution y b 2 i j = %d, %d\n", i, j);

//     uint16x8_t uint16_temp = vabdq_u16(pos, neg); // abs(pos - neg)

//     uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp);
//     // printf("Convolution y b 3 i j = %d, %d\n", i, j);
//     vst1_u8(&img_outy.data[IMG_WIDTH*i/2 + j], vqmovn_u16(uint16_temp));
//     // printf("Convolution y b 4 i j = %d, %d\n", i, j);


//     //  sobel = (sobel > 255) ? 255 : sobel;

//     //  img_outy.data[IMG_WIDTH*(i) + j] = sobel;

//     // printf("Convolution y done i j = %d, %d\n", i, j);
//     }
//   }

//   printf("Convolution y done\n");

//   // Combine the two convolutions into the output image
//   for (int i=1; i<img_gray.rows; i++) {
//     for (int j=1; j<img_gray.cols-7; j+=8) {
//       // sobel = img_outx.data[IMG_WIDTH*(i) + j] + img_outy.data[IMG_WIDTH*(i) + j];

//       uint16x8_t uint16_v8_1 = vmovl_u8(vld1_u8(&img_outx.data[IMG_WIDTH*(i)/2 + j]));
//       uint16x8_t uint16_v8_2 = vmovl_u8(vld1_u8(&img_outy.data[IMG_WIDTH*(i)/2 + j]));
//       // printf("load vecs\n");

//       uint16x8_t uint16_temp = vaddq_u16(uint16_v8_1, uint16_v8_2);
//       // printf("add vecs\n");

//       uint16_temp = vbslq_u16(vcgtq_u16(uint16_temp, vmax), vmax, uint16_temp);
//       // printf("clamp vecs\n");

//       vst1_u8(&img_sobel_out.data[IMG_WIDTH*i/2 + j], vqmovn_u16(uint16_temp));
//       // printf("store vecs\n");
//       // printf("done i j = %d, %d\n", i, j);

//       // sobel = (sobel > 255) ? 255 : sobel;
//       // img_sobel_out.data[IMG_WIDTH*(i) + j] = sobel;
//     }
//   }
// }