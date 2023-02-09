Group: ee180-6z.stanford.edu
Yifan Yang (yyang29@stanford.edu)
Mingfei Guo (mfguo@stanford.edu)

### What changes you made to the code as part of the assignment and how/why they sped up the code. If you did anything beyond what the assignment asked for to get extra speed, please explain it as well.

1. SIMD. We use Neon intrinsics to do vectorized computation.
This allows us to process 8 pixels at one time instead of processing one pixel at one time, which can reduce the number of instructions and improve the performance.
Because we are dealing with a 8-bit image, we use 'uint8x8_t' to represent the pixels and to avoid overflow, we use 'uint16x8_t' during the computation.
When loading the image, we use 'vld1_u8' to load 8 pixels from the image at one time and 'vmovl_u8' to convert the 8-bit pixels to 16-bit pixels.
When doing the computation, we use 'vmulq_n_u16' to multiply the 16-bit pixels with the 16-bit constant, 'vaddq_u16' to add the 16-bit pixels with the 16-bit constant, and 'vabdq_u16' to compute the absolute difference between the 16-bit pixels and the 16-bit constant.    
Then we use 'vcgtq_u16' and 'vandq_u16' to clamp the 16-bit pixels to the range [0, 255].
Finally, we use 'vqmovn_u16' to convert the 16-bit pixels to 8-bit pixels and'vst1_u8' to store the 8-bit pixels back to the image.

2. Multithreading. Multithreading can improve the performance by doing the computation in parallel.
If we have two threads, we can split the image into two parts and let each thread process one part of the image, so we only need to do half of the computation.
We use `pthread` to implement the multithreading.
We split the image ($HEIGHT*WIDTH = 480*640$) into two parts ($HEIGHT/2*WIDTH = 240*640$) and let one thread process the first half of the image, and the other thread process the second half of the image.
Because both threads can access the same memory of the image, we don't need to copy the image to two different memory locations or concat the two images together.
To avoid race conditions when accessing global variables, we use `pthread_mutex_lock` and `pthread_mutex_unlock` to lock the global variables.
Also, we use `pthread_barrier_wait` to help the two threads to synchronize:
    1) Thread0 allocates the memory to hold grayscale and sobel images, and thread1 may wait for thread0 to finish the allocation. Then thread0 and thread1 can start to do the computation without repeating the allocation. After both of them pass pthread_barrier_wait(&thread0First), the memory is safely allocated and we can start to do the computation.
    2) Thread0 and thread1 may wait for each other to finish the grayscale computation and the sobel convolution, so that the whole image is processed. We use pthread_barrier_wait(&endGrayConv) pthread_barrier_wait(&endSobelConv) to help them synchronize.
    3) Thread0 and thread1 quit the program when reach the maximum number of frames or reveive the stop signal, especially to avoid one thread quitting while the other thread is still running. Here we only let thread0 catch the quit signal and use pthread_barrier_wait(&quitSobel) to help synchronize the two threads. If thread0 catches the quit signal, it will set the quit flag and let thread1 know that it should quit. No matter which thread waits for the other thread, both of them will quit when the quit flag is set.


### If you ran into any tough problems while implementing this assignment, describe them. If you solved it, document how or maybe what you learned. If you weren't able to solve the problem(s), describe what you tried / what you think is going wrong. For example, if you had a problem with your multithreaded implementation and tried to debug it, tell us how.
1. Split the image in a way that can make the implementation of multithreading easier.
We first tried to split the image ($HEIGHT*WIDTH = 480*640$) by its width ($HEIGHT*WIDTH/2 = 480*320$) because width is the larger value.
However, the image is stored in a 1D array, and we need to access the pixels by 640*i + j.
If we split the image by its width, i is [0, 480) and j is [0, 320) and [320, 640), so we need to change it to 320*i + j to avoid segmentation fault, which is hard to implement because we need to rewrite the code.
So we split the image by its height ($HEIGHT/2*WIDTH = 240*640$) and let each thread process one part of the image.
For this way, i is [0, 240) and [240, 480) and j is [0, 640), so we don't need to change the code.
In practice, we use IMG_HEIGHT/2+1 instead of IMG_HEIGHT/2 to guarantee that the middle part of the image is also processed.

2. Ignore the first/last row of the image to avoid segmentation fault.
When iterating through the image and compuing the sobel convolution, we need to access the pixels in the neighborhood of the current pixel.
To avoid accessing non-allocted memory, we need to ignore the first/last row of the image and use i in [1, img_gray.rows-1) and j in [1, img_gray.cols-7) instead.
This is acceptable because bottom row/column of pixels aren't that visible. In multithreading case, we added a flag to indicate whether the current image input is the upper half or the lower half of the image, and we use this flag to decide the iteration boundary of i.

3. Delete concat function and clone function.
Since the Mat class in OpenCV is reference based, and we clone these images in the calculation function, we don't need to clone it in the run function. Also, since the Mat class is reference based, we do not need to concat the two halves of image together.

### Justify your performance counting. In particular once you go to multithreaded, explain how performance is measured and explain how accurately it tracks your code's performance.
Our implementation achieved a performance of around 75 fps on multithreading and 55 fps on single thread. This performance is over 10x increase compared to the baseline performance. We made the calculation function vectorizable and explicitly used compiler flags `-ftree-vectorize` and `-O3`, although `-ftree-no-vectorize` is implicit in `-O3`. This makes the compiled instructions vectorized and can perform SIMD improvements.

For multithreading, the performance is measured in each step wrapping all the work related to each section(gray scale, sobel, etc) including synchronization operation to measure the true performance of 2 threads. 