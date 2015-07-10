#include <stdio.h>
#include <iostream>

#include <cuda.h>
#include "cuda_runtime.h"

#include <thrust\transform.h>
#include <thrust\transform_reduce.h>
#include <thrust\device_ptr.h>
#include <thrust\device_vector.h>
#include <thrust\host_vector.h>
#include <thrust\functional.h>
#include <thrust\iterator\counting_iterator.h>
#include <thrust\sequence.h>

#include "LR_GPU_Functors.cu"

//DLL exports
extern "C" __declspec(dllexport) int __cdecl Learn(float*, float*, unsigned int, unsigned int, unsigned int, float, float, float*, float*, float*);
extern "C" __declspec(dllexport) int __cdecl Predict(float*, unsigned int, unsigned int, float*, float *, float *, float *);


//
//This method does mean normalization
//
void NormalizeFeaturesByMeanAndStd(unsigned int trainingDataCount, float * d_trainingData, thrust::device_vector<float> dv_mean, thrust::device_vector<float> dv_std)
{
	//Calculate mean norm: (x - mean) / std
	//featureCount == 8
	unsigned int featureCount = dv_mean.size();
	float * dvp_Mean = thrust::raw_pointer_cast( &dv_mean[0] );
	float * dvp_Std = thrust::raw_pointer_cast( &dv_std[0] );
	FeatureNormalizationgFunctor featureNormalizationgFunctor(dvp_Mean, dvp_Std, featureCount); 
	thrust::device_ptr<float> dvp_trainingData(d_trainingData); 
	thrust::transform(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(trainingDataCount * featureCount), dvp_trainingData, dvp_trainingData, featureNormalizationgFunctor);
}

//
//This method calculates mean, standard deviation and does mean normalization
//
void NormalizeFeatures(unsigned int featureCount, unsigned int trainingDataCount, float * d_trainingData, float * meanResult, float * stdResult)
{
	//featureCount == 8

	//Calculate the mean. One thread per feature.
	thrust::device_vector<float> dv_mean(featureCount,0);
	MeanFunctor meanFunctor(d_trainingData, trainingDataCount, featureCount); 
	thrust::transform(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(featureCount), dv_mean.begin(), meanFunctor);

	//Calculate the standard deviation. One thread per feature.
	thrust::device_vector<float> dv_std(featureCount,0);
	STDFunctor stdFunctor(d_trainingData, trainingDataCount, featureCount); 
	thrust::transform(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(featureCount), dv_mean.begin(), dv_std.begin(), stdFunctor);

	//Calculate mean norm: (x - mean) / std
	NormalizeFeaturesByMeanAndStd(trainingDataCount, d_trainingData, dv_mean, dv_std);

	thrust::copy(dv_mean.begin(), dv_mean.end(), meanResult);
	thrust::copy(dv_std.begin(), dv_std.end(), stdResult);
}

void AddBiasTerm(float * inputData, float * outputData, int dataCount, int featureCount)
{
	//transfer the trainindata by adding also the bias term
	//featureCount == 8
	for(int i = 0; i < dataCount; i++)
	{
		//all the first feature is 1
		outputData[i * featureCount] = 1;
		for(int f = 1; f < featureCount; f++)
			outputData[i * featureCount + f] = inputData[(i * (featureCount - 1)) + (f-1)];
	}

}

#define IsValidNumber(x)  (x == x && x <= DBL_MAX && x >= -DBL_MAX)

//
//Learn the hypothesis for the given data
//
extern int Learn(float* trainingData, float * labelData, unsigned int featureCount, unsigned int trainingDataCount, unsigned int gdIterationCount, float learningRate, float regularizationParam, float * result, float * meanResult, float * stdResult)
{
	//featureCount == 7 -> == 8
	featureCount++;
	//allcate host memory
	thrust::host_vector<float> hv_hypothesis(featureCount, 0);
	thrust::host_vector<float> hv_trainingData(trainingDataCount * featureCount);
	thrust::host_vector<float> hv_labelData(labelData, labelData + trainingDataCount);
	//transfer the trainindata by adding also the bias term
	AddBiasTerm(trainingData, &hv_trainingData[0], trainingDataCount, featureCount);
	
	//allocate device vector
	thrust::device_vector<float> dv_hypothesis = hv_hypothesis;
	thrust::device_vector<float> dv_trainingData = hv_trainingData;
	thrust::device_vector<float> dv_labelData = hv_labelData;
	thrust::device_vector<float> dv_costData(trainingDataCount, 0);
	//Get device vector pointers
	float * pdv_hypothesis = thrust::raw_pointer_cast( &dv_hypothesis[0] );
	float * pdv_trainingData = thrust::raw_pointer_cast( &dv_trainingData[0] );
	float * pdv_costData = thrust::raw_pointer_cast( &dv_costData[0] );
	
	//Normalize the features
	NormalizeFeatures(featureCount, trainingDataCount, pdv_trainingData, meanResult, stdResult);

	TrainFunctor tf(pdv_trainingData, pdv_hypothesis, featureCount);
	TrainFunctor2 tf2(pdv_costData, pdv_trainingData, featureCount);
	//run gdIterationCount of gradient descent iterations
	for(int i = 0; i < gdIterationCount; i++)
	{
		thrust::transform(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(trainingDataCount),  dv_labelData.begin(), dv_costData.begin(), tf);

		//calculate gradient descent iterations
		for(int featureNumber = 0; featureNumber < featureCount; featureNumber++) 
		{
			tf2.SetFeatureNumber(featureNumber);
			float totalCost = thrust::transform_reduce(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(trainingDataCount),  tf2, 0.0f, thrust::plus<float>());
			if (!IsValidNumber(totalCost))
			{
				i = gdIterationCount;
				break;
			}
			float regularizationTerm = 1 - (learningRate * (regularizationParam / trainingDataCount));
			hv_hypothesis[featureNumber] = (hv_hypothesis[featureNumber] * regularizationTerm) -  learningRate * (totalCost / trainingDataCount);
		}
		
		//Copy the theta back to the device vector
		dv_hypothesis = hv_hypothesis;
	}

	//copy the hypothesis into the result buffer
	thrust::copy(hv_hypothesis.begin(), hv_hypothesis.end(), result);

	return 0;
}

//
//makes prediction for the given test data based on the hypothesis. Also applies feature normalization.
//
extern int Predict(float* testData, unsigned int featureCount, unsigned int testDataCount, float* hypothesis, float * mean, float * std, float * result)
{
	//featureCount == 7 -> == 8
	featureCount++;
	thrust::host_vector<float> hv_testData(testDataCount * featureCount);
	AddBiasTerm(testData, &hv_testData[0], testDataCount, featureCount);
	
	//Allocate device memory
	thrust::device_vector<float> dv_hypothesis(hypothesis, hypothesis + featureCount);
	thrust::device_vector<float> dv_testData = hv_testData;
	thrust::device_vector<float> dv_result(testDataCount);
	thrust::device_vector<float> dv_mean(mean, mean + featureCount);
	thrust::device_vector<float> dv_std(std, std + featureCount);

	//Normalize features
	float * pdv_hypothesis = thrust::raw_pointer_cast( &dv_hypothesis[0] );
	float * pdv_testData = thrust::raw_pointer_cast( &dv_testData[0] );
	NormalizeFeaturesByMeanAndStd(testDataCount, pdv_testData, dv_mean, dv_std);

	//Predict
	PredictFunctor predictFunctor(pdv_testData, pdv_hypothesis, featureCount);
	thrust::transform(thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(testDataCount), dv_result.begin(), predictFunctor);

	//copy the result from device memory into the result buffer
	thrust::copy(dv_result.begin(), dv_result.end(), result);

	return 0;
}



