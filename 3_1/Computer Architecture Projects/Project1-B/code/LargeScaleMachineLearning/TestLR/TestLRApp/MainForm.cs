using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Diagnostics;

namespace TestLRApp
{
    public partial class MainForm : Form
    {
		private float[] hypothesis;
		private float[] mean;
		private float[] std;

        public MainForm()
        {
            InitializeComponent();
        }

        private void btnLoadData_Click(object sender, EventArgs e)
        {
			openFileDialog1.Multiselect = false;
			DialogResult result = openFileDialog1.ShowDialog();
			if (result != System.Windows.Forms.DialogResult.OK)
				return;

			string filePath = openFileDialog1.FileName;

			IList<HousingDTO> featuresList = new List<HousingDTO>();
			using (StreamReader sourceFile = File.OpenText(filePath))
			{
				while (!sourceFile.EndOfStream)
				{
					string[] readLine = sourceFile.ReadLine().Split('\t');
					if (readLine.Length != 4)
						continue;
					featuresList.Add(new HousingDTO(){ SquareFeet = float.Parse(readLine[0]), BedroomCount = float.Parse(readLine[1]), YearBuilt = float.Parse(readLine[2]), Price = float.Parse(readLine[3])});
				}
			}

			dgv_trainingData.DataSource = featuresList;

        }

		private void btn_trainLinearRegression_Click(object sender, EventArgs e)
		{
			//get the data
			IList<HousingDTO> housingDataList = dgv_trainingData.DataSource as List<HousingDTO>;

			if (dgv_trainingData.RowCount < 1 || housingDataList == null)
			{
				MessageBox.Show("Please load data");
				return;
			}


			//convert data to array
			int featureCount = 7;
			float[] featureData = new float[housingDataList.Count * featureCount];
			float[] labelData = new float[housingDataList.Count];
			int idx = 0;
			int labelIdx = 0;
			//Add the polynomial terms
			foreach (HousingDTO dto in housingDataList)
			{
				featureData[idx++] = dto.SquareFeet;
				featureData[idx++] = dto.BedroomCount;
				featureData[idx++] = dto.YearBuilt;
				featureData[idx++] = (float)Math.Sqrt(dto.SquareFeet); //add polynomial term for better fit
				featureData[idx++] = (float)Math.Sqrt(dto.BedroomCount); //add polynomial term for better fit
				featureData[idx++] = (float)Math.Sqrt(dto.YearBuilt); //add polynomial term for better fit
				featureData[idx++] = dto.SquareFeet * dto.BedroomCount; 
				labelData[labelIdx++] = dto.Price;
			}

			
			int trainingDataCount = labelData.Length;
			float learningRate = float.Parse(txt_learningRate.Text);
			uint iterations = uint.Parse(txt_Iterations.Text);
			float regularizationTerm = float.Parse(txt_RegularizationTerm.Text);

            //featureCount == 7 -> == 8
			hypothesis = new float[featureCount + 1]; //add one for the bias term
			mean = new float[featureCount + 1];
			std = new float[featureCount + 1];

			//Call the GPU module
			LR_GPULibProxy.Learn(featureData, labelData, (uint)featureCount, (uint)trainingDataCount, iterations, learningRate, regularizationTerm, hypothesis, mean, std);

			//Display the model
			StringBuilder model = new StringBuilder();

            model.Append(string.Format("{0:N2}",hypothesis[0]));

            //featureCount == 7
			for (int i = 1; i < featureCount + 1; i++)
				model.Append(string.Format("{0}{1:N2}*X{2}", hypothesis[i] < 0 ? "" : "+", hypothesis[i], i));
			labelHypothesis.Text = model.ToString();

			btn_predict.Enabled = true;
		}

		private void dgv_trainingData_DataBindingComplete(object sender, DataGridViewBindingCompleteEventArgs e)
		{
			btn_trainLinearRegression.Enabled = dgv_trainingData.RowCount > 0;

		}

		private void btn_predict_Click(object sender, EventArgs e)
		{
			float sqFeet = 0;
			if (!float.TryParse(txt_sqfeet.Text, out sqFeet) || sqFeet < 1)
			{
				MessageBox.Show("Please enter square feet value");
				return;
			}

			float bedrooms = 0;
			if (!float.TryParse(txt_bedrooms.Text, out bedrooms) || bedrooms < 1)
			{
				MessageBox.Show("Please enter bedroom count");
				return;
			}

			float year = 0;
			if (!float.TryParse(txt_YearBuilt.Text, out year) || year < 1)
			{
				MessageBox.Show("Please enter year built");
				return;
			}

			float[] testData = { sqFeet, bedrooms, year, (float)Math.Sqrt(sqFeet), (float)Math.Sqrt(bedrooms), (float)Math.Sqrt(year), sqFeet * bedrooms };

			uint featureCount = 7;
			uint testDataCount = 1;
			float[] predictionResult = new float[testDataCount];

			//Call the GPU module
			LR_GPULibProxy.Predict(testData, featureCount, testDataCount, hypothesis, mean, std, predictionResult);

			labelPrice.Text = predictionResult[0].ToString("N0");

		}
    }
}
