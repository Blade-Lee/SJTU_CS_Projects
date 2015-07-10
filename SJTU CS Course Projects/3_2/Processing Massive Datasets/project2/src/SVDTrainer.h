/*
 * SVDTrainer.h
 *
 *  Created on: 2014��10��19��
 *      Author: chenjing
 */

#ifndef SVDTRAINER_H_
#define SVDTRAINER_H_
#include "Trainer.h"
#include "MathTool.h"
#include<string.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>

#include "Node.h"
class SVDTrainer: public Trainer {
protected:
	//�Ƿ�ת��
	bool isTranspose;
	//�û���
	int mUserNum;
	//item��
	int mItemNum;
	//feature����
	int dim;
	//�û�feature
	float **p;
	//item feature
	float **q;
	//�û�����
	float *bu;
	//item����
	float *bi;
	//ƽ������
	float mean;
	//��߷�
	float mMaxRate;
	//��ͷ�
	float mMinRate;
	string mTestFileName;
	string mSeparator;
	MathTool *mt;
	map<int, int> mUserId2Map;
	map<int, int> mItemId2Map;
	vector<vector<Node> > mRateMatrix;
private:
	void init();
	void mapping(string fileName, int &un, int &in, string separator);
public:
	SVDTrainer(int f = 8, bool isTr = false);
	virtual void train(float alpha, float lambda, int nIter);
	void loadFile(string mTrainFileName, string mTestFileName, string separator,
			string mHisFileName = "");
	void predict(string mOutputFileName, string separator);
	virtual ~SVDTrainer();
};

#endif /* SVDTRAINER_H_ */
