/*
 * AsymSVD.h
 *
 *  Created on: 2014��11��3��
 *      Author: chenjing
 */

#ifndef C___SRC_ASYMSVD_H_
#define C___SRC_ASYMSVD_H_

#include "SVDPlusPlusTrainer.h"

class AsymSVD: public SVDPlusPlusTrainer {
private:
	float **x;
	float *w;
	float *sumx;
public:
	AsymSVD(int dim, bool isTranspose = false);
	void train(float alpha, float lambda, int nIter);
	void loadFile(string mTrainFileName, string mTestFileName, string separator,
			string mHisFileName);
	void predict(string mOutputFileName, string separator);
	virtual ~AsymSVD();
};

#endif /* C___SRC_ASYMSVD_H_ */
