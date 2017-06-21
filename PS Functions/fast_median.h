/* fast_median.h
 * Ver 0.83
 * Peter H. Li 2011 FreeBSD License
 */
#ifndef ALGORITHM_H
  #include <algorithm>
  #define ALGORITHM_H
#endif

#ifndef MEX_H
  #include "mex.h"
  #define MEX_H
#endif

#ifndef NTH_ELEMENT_H
  #include "nth_element.h"
  #define NTH_ELEMENT_H
#endif

template <typename T> mxArray *fast_median(T *indata, mxArray *arr) {
  // Find halfway point, i.e. the rank of the median
  const mwSize nrows = mxGetM(arr);
  const mwIndex half = nrows / 2;

  // Loop through columns and iteratively pivot to put median in rank position
  const mwSize ncols = mxGetN(arr);
  nth_element_cols(indata, half, ncols, nrows);

  // Create output array, get pointer to its internal data
  const mwSize size[2] = {1, ncols};
  mxArray *result = mxCreateNumericArray(2, size, mxGetClassID(arr), mxREAL);
  T *outdata = (T *) mxGetData(result);

  // Get output values from pivoted indata, assign to output
  for (mwIndex i = 0; i < ncols; i++) {
    outdata[i] = indata[(i * nrows) + half];
  }

  // If even number of elements, we have more work to do
  if (half * 2 == nrows) {
    mwIndex start;
    T *median2;
    for (mwIndex i = 0; i < ncols; i++) {
      start = i * nrows;
      median2 = std::max_element(indata + start, indata + start + half);

      outdata[i] = (0.5 * outdata[i]) + (0.5 * *median2);
    }
  }

  return result;
}


// Determine type of data, run fast_median, assign output
mxArray *run_fast_median(mxArray *inarr) {
  void *indata = mxGetData(inarr);
  mxArray *outarr;

  switch (mxGetClassID(inarr)) {
    case mxDOUBLE_CLASS:
      outarr = fast_median((double *) indata, inarr);
      break;

    case mxSINGLE_CLASS:
      outarr = fast_median((float *) indata, inarr);
      break;

    case mxINT8_CLASS:
      outarr = fast_median((signed char *) indata, inarr);
      break;

    case mxUINT8_CLASS:
      outarr = fast_median((unsigned char *) indata, inarr);
      break;

    case mxINT16_CLASS:
      outarr = fast_median((signed short *) indata, inarr);
      break;

    case mxUINT16_CLASS:
      outarr = fast_median((unsigned short *) indata, inarr);
      break;

    case mxINT32_CLASS:
      outarr = fast_median((signed int *) indata, inarr);
      break;

    case mxUINT32_CLASS:
      outarr = fast_median((unsigned int *) indata, inarr);
      break;

    // Uncomment these if int64 is needed, but note that on some compilers
    // it's called "__int64" instead of "long long"
    //case mxINT64_CLASS:
      //outarr = fast_median((signed long long *) indata, inarr);
      //break;

    //case mxUINT64_CLASS:
      //outarr = fast_median((unsigned long long *) indata, inarr);
      //break;

    default:
      mexErrMsgIdAndTxt("Numerical:fast_median:prhs", "Unrecognized numeric array type.");
  }

  return outarr;
}
