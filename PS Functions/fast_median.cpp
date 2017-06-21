/* fast_median.cpp
 * Ver 0.83
 * Peter H. Li 2011 FreeBSD License
 * See fast_median.m for documentation.
 */
#include "fast_median.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  // Check inputs
  if (nrhs != 1) {
    mexErrMsgIdAndTxt("fast_median:nrhs", "Arguments should be the matrix of columns and the rank of the desired element");
  }
  if (!mxIsNumeric(prhs[0])) {
    mexErrMsgIdAndTxt("fast_median:prhs", "Input argument must be a numeric matrix.");
  }

  // Deconst input array, get its pointer; NAUGHTY BOY!!!!
  mxArray *incopy = mxDuplicateArray(prhs[0]);
  plhs[0] = run_fast_median(incopy);
}
