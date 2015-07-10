using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

namespace TestLRApp
{
	class LR_GPULibProxy
	{
		[DllImport("LR_GPULib.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern void Learn(
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] featureData, 
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] labelData, 
			uint featureCount, 
			uint trainingDataCount,
			uint gdgdIterationCount,
			float learningRate,
			float regularizationParam,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] result,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] meanResult,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] stdResult);

		[DllImport("LR_GPULib.dll", CallingConvention = CallingConvention.Cdecl)]
		public static extern void Predict(
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] testData,
			uint featureCount,
			uint testDataCount,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] hypothesis,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] mean,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] std,
			[MarshalAsAttribute(UnmanagedType.LPArray, ArraySubType = UnmanagedType.R4)] float[] stdResult);

	}
}
