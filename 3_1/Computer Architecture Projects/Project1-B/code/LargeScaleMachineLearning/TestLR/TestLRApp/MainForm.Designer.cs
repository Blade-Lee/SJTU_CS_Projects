namespace TestLRApp
{
    partial class MainForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
			this.components = new System.ComponentModel.Container();
			System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
			System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
			System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
			this.btnLoad = new System.Windows.Forms.Button();
			this.dgv_trainingData = new System.Windows.Forms.DataGridView();
			this.YearBuilt = new System.Windows.Forms.DataGridViewTextBoxColumn();
			this.openFileDialog1 = new System.Windows.Forms.OpenFileDialog();
			this.btn_trainLinearRegression = new System.Windows.Forms.Button();
			this.btn_predict = new System.Windows.Forms.Button();
			this.label1 = new System.Windows.Forms.Label();
			this.label2 = new System.Windows.Forms.Label();
			this.labelPrice = new System.Windows.Forms.Label();
			this.label3 = new System.Windows.Forms.Label();
			this.label4 = new System.Windows.Forms.Label();
			this.label5 = new System.Windows.Forms.Label();
			this.txt_learningRate = new System.Windows.Forms.TextBox();
			this.txt_Iterations = new System.Windows.Forms.TextBox();
			this.txt_RegularizationTerm = new System.Windows.Forms.TextBox();
			this.txt_bedrooms = new System.Windows.Forms.TextBox();
			this.txt_sqfeet = new System.Windows.Forms.TextBox();
			this.label6 = new System.Windows.Forms.Label();
			this.txt_YearBuilt = new System.Windows.Forms.TextBox();
			this.labelHypothesis = new System.Windows.Forms.Label();
			this.bedroomCountDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
			this.squareFeetDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
			this.priceDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
			this.housingDTOBindingSource = new System.Windows.Forms.BindingSource(this.components);
			((System.ComponentModel.ISupportInitialize)(this.dgv_trainingData)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.housingDTOBindingSource)).BeginInit();
			this.SuspendLayout();
			// 
			// btnLoad
			// 
			this.btnLoad.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.btnLoad.Location = new System.Drawing.Point(505, 12);
			this.btnLoad.Name = "btnLoad";
			this.btnLoad.Size = new System.Drawing.Size(147, 23);
			this.btnLoad.TabIndex = 0;
			this.btnLoad.Text = "1. Load Data";
			this.btnLoad.UseVisualStyleBackColor = true;
			this.btnLoad.Click += new System.EventHandler(this.btnLoadData_Click);
			// 
			// dgv_trainingData
			// 
			this.dgv_trainingData.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.dgv_trainingData.AutoGenerateColumns = false;
			dataGridViewCellStyle1.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
			dataGridViewCellStyle1.BackColor = System.Drawing.SystemColors.Control;
			dataGridViewCellStyle1.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
			dataGridViewCellStyle1.ForeColor = System.Drawing.SystemColors.WindowText;
			dataGridViewCellStyle1.SelectionBackColor = System.Drawing.SystemColors.Highlight;
			dataGridViewCellStyle1.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
			dataGridViewCellStyle1.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
			this.dgv_trainingData.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle1;
			this.dgv_trainingData.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
			this.dgv_trainingData.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.bedroomCountDataGridViewTextBoxColumn,
            this.squareFeetDataGridViewTextBoxColumn,
            this.YearBuilt,
            this.priceDataGridViewTextBoxColumn});
			this.dgv_trainingData.DataSource = this.housingDTOBindingSource;
			dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
			dataGridViewCellStyle2.BackColor = System.Drawing.SystemColors.Window;
			dataGridViewCellStyle2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
			dataGridViewCellStyle2.ForeColor = System.Drawing.SystemColors.ControlText;
			dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.Highlight;
			dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
			dataGridViewCellStyle2.WrapMode = System.Windows.Forms.DataGridViewTriState.False;
			this.dgv_trainingData.DefaultCellStyle = dataGridViewCellStyle2;
			this.dgv_trainingData.Location = new System.Drawing.Point(12, 12);
			this.dgv_trainingData.Name = "dgv_trainingData";
			dataGridViewCellStyle3.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
			dataGridViewCellStyle3.BackColor = System.Drawing.SystemColors.Control;
			dataGridViewCellStyle3.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
			dataGridViewCellStyle3.ForeColor = System.Drawing.SystemColors.WindowText;
			dataGridViewCellStyle3.SelectionBackColor = System.Drawing.SystemColors.Highlight;
			dataGridViewCellStyle3.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
			dataGridViewCellStyle3.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
			this.dgv_trainingData.RowHeadersDefaultCellStyle = dataGridViewCellStyle3;
			this.dgv_trainingData.Size = new System.Drawing.Size(484, 420);
			this.dgv_trainingData.TabIndex = 1;
			this.dgv_trainingData.DataBindingComplete += new System.Windows.Forms.DataGridViewBindingCompleteEventHandler(this.dgv_trainingData_DataBindingComplete);
			// 
			// YearBuilt
			// 
			this.YearBuilt.DataPropertyName = "YearBuilt";
			this.YearBuilt.HeaderText = "YearBuilt";
			this.YearBuilt.Name = "YearBuilt";
			// 
			// openFileDialog1
			// 
			this.openFileDialog1.FileName = "openFileDialog1";
			// 
			// btn_trainLinearRegression
			// 
			this.btn_trainLinearRegression.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.btn_trainLinearRegression.Enabled = false;
			this.btn_trainLinearRegression.Location = new System.Drawing.Point(505, 246);
			this.btn_trainLinearRegression.Name = "btn_trainLinearRegression";
			this.btn_trainLinearRegression.Size = new System.Drawing.Size(147, 23);
			this.btn_trainLinearRegression.TabIndex = 0;
			this.btn_trainLinearRegression.Text = "2. Train Linear Regression";
			this.btn_trainLinearRegression.UseVisualStyleBackColor = true;
			this.btn_trainLinearRegression.Click += new System.EventHandler(this.btn_trainLinearRegression_Click);
			// 
			// btn_predict
			// 
			this.btn_predict.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.btn_predict.Enabled = false;
			this.btn_predict.Location = new System.Drawing.Point(508, 379);
			this.btn_predict.Name = "btn_predict";
			this.btn_predict.Size = new System.Drawing.Size(147, 23);
			this.btn_predict.TabIndex = 0;
			this.btn_predict.Text = "3. Predict";
			this.btn_predict.UseVisualStyleBackColor = true;
			this.btn_predict.Click += new System.EventHandler(this.btn_predict_Click);
			// 
			// label1
			// 
			this.label1.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(505, 306);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(54, 13);
			this.label1.TabIndex = 2;
			this.label1.Text = "Bedrooms";
			// 
			// label2
			// 
			this.label2.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(505, 332);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(65, 13);
			this.label2.TabIndex = 2;
			this.label2.Text = "Square Feet";
			// 
			// labelPrice
			// 
			this.labelPrice.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.labelPrice.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
			this.labelPrice.Location = new System.Drawing.Point(505, 411);
			this.labelPrice.Name = "labelPrice";
			this.labelPrice.Size = new System.Drawing.Size(150, 19);
			this.labelPrice.TabIndex = 2;
			this.labelPrice.Text = "$0";
			// 
			// label3
			// 
			this.label3.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label3.AutoSize = true;
			this.label3.Location = new System.Drawing.Point(502, 173);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(74, 13);
			this.label3.TabIndex = 2;
			this.label3.Text = "Learning Rate";
			// 
			// label4
			// 
			this.label4.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label4.AutoSize = true;
			this.label4.Location = new System.Drawing.Point(502, 199);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(50, 13);
			this.label4.TabIndex = 2;
			this.label4.Text = "Iterations";
			// 
			// label5
			// 
			this.label5.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label5.AutoSize = true;
			this.label5.Location = new System.Drawing.Point(502, 225);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(74, 13);
			this.label5.TabIndex = 2;
			this.label5.Text = "Regularization";
			// 
			// txt_learningRate
			// 
			this.txt_learningRate.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_learningRate.Location = new System.Drawing.Point(576, 170);
			this.txt_learningRate.Name = "txt_learningRate";
			this.txt_learningRate.Size = new System.Drawing.Size(79, 20);
			this.txt_learningRate.TabIndex = 5;
			this.txt_learningRate.Text = "0.1";
			// 
			// txt_Iterations
			// 
			this.txt_Iterations.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_Iterations.Location = new System.Drawing.Point(576, 196);
			this.txt_Iterations.Name = "txt_Iterations";
			this.txt_Iterations.Size = new System.Drawing.Size(79, 20);
			this.txt_Iterations.TabIndex = 5;
			this.txt_Iterations.Text = "100";
			// 
			// txt_RegularizationTerm
			// 
			this.txt_RegularizationTerm.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_RegularizationTerm.Location = new System.Drawing.Point(576, 222);
			this.txt_RegularizationTerm.Name = "txt_RegularizationTerm";
			this.txt_RegularizationTerm.Size = new System.Drawing.Size(79, 20);
			this.txt_RegularizationTerm.TabIndex = 5;
			this.txt_RegularizationTerm.Text = "0";
			// 
			// txt_bedrooms
			// 
			this.txt_bedrooms.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_bedrooms.Location = new System.Drawing.Point(576, 303);
			this.txt_bedrooms.Name = "txt_bedrooms";
			this.txt_bedrooms.Size = new System.Drawing.Size(79, 20);
			this.txt_bedrooms.TabIndex = 5;
			this.txt_bedrooms.Text = "3";
			// 
			// txt_sqfeet
			// 
			this.txt_sqfeet.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_sqfeet.Location = new System.Drawing.Point(576, 329);
			this.txt_sqfeet.Name = "txt_sqfeet";
			this.txt_sqfeet.Size = new System.Drawing.Size(79, 20);
			this.txt_sqfeet.TabIndex = 5;
			this.txt_sqfeet.Text = "2100";
			// 
			// label6
			// 
			this.label6.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.label6.AutoSize = true;
			this.label6.Location = new System.Drawing.Point(505, 356);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(52, 13);
			this.label6.TabIndex = 2;
			this.label6.Text = "Year Built";
			// 
			// txt_YearBuilt
			// 
			this.txt_YearBuilt.Anchor = System.Windows.Forms.AnchorStyles.Right;
			this.txt_YearBuilt.Location = new System.Drawing.Point(576, 353);
			this.txt_YearBuilt.Name = "txt_YearBuilt";
			this.txt_YearBuilt.Size = new System.Drawing.Size(79, 20);
			this.txt_YearBuilt.TabIndex = 5;
			this.txt_YearBuilt.Text = "1999";
			// 
			// labelHypothesis
			// 
			this.labelHypothesis.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.labelHypothesis.Location = new System.Drawing.Point(12, 435);
			this.labelHypothesis.Name = "labelHypothesis";
			this.labelHypothesis.Size = new System.Drawing.Size(643, 22);
			this.labelHypothesis.TabIndex = 2;
			// 
			// bedroomCountDataGridViewTextBoxColumn
			// 
			this.bedroomCountDataGridViewTextBoxColumn.DataPropertyName = "BedroomCount";
			this.bedroomCountDataGridViewTextBoxColumn.HeaderText = "BedroomCount";
			this.bedroomCountDataGridViewTextBoxColumn.Name = "bedroomCountDataGridViewTextBoxColumn";
			// 
			// squareFeetDataGridViewTextBoxColumn
			// 
			this.squareFeetDataGridViewTextBoxColumn.DataPropertyName = "SquareFeet";
			this.squareFeetDataGridViewTextBoxColumn.HeaderText = "SquareFeet";
			this.squareFeetDataGridViewTextBoxColumn.Name = "squareFeetDataGridViewTextBoxColumn";
			// 
			// priceDataGridViewTextBoxColumn
			// 
			this.priceDataGridViewTextBoxColumn.DataPropertyName = "Price";
			this.priceDataGridViewTextBoxColumn.HeaderText = "Price";
			this.priceDataGridViewTextBoxColumn.Name = "priceDataGridViewTextBoxColumn";
			// 
			// housingDTOBindingSource
			// 
			this.housingDTOBindingSource.DataSource = typeof(TestLRApp.HousingDTO);
			// 
			// MainForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(664, 466);
			this.Controls.Add(this.txt_YearBuilt);
			this.Controls.Add(this.txt_sqfeet);
			this.Controls.Add(this.txt_bedrooms);
			this.Controls.Add(this.txt_RegularizationTerm);
			this.Controls.Add(this.txt_Iterations);
			this.Controls.Add(this.txt_learningRate);
			this.Controls.Add(this.labelHypothesis);
			this.Controls.Add(this.labelPrice);
			this.Controls.Add(this.label6);
			this.Controls.Add(this.label5);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.label4);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.dgv_trainingData);
			this.Controls.Add(this.btn_predict);
			this.Controls.Add(this.btn_trainLinearRegression);
			this.Controls.Add(this.btnLoad);
			this.Name = "MainForm";
			this.Text = "Machine Learning on GPU using CUDA";
			((System.ComponentModel.ISupportInitialize)(this.dgv_trainingData)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.housingDTOBindingSource)).EndInit();
			this.ResumeLayout(false);
			this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnLoad;
		private System.Windows.Forms.DataGridView dgv_trainingData;
		private System.Windows.Forms.BindingSource housingDTOBindingSource;
		private System.Windows.Forms.OpenFileDialog openFileDialog1;
		private System.Windows.Forms.Button btn_trainLinearRegression;
		private System.Windows.Forms.Button btn_predict;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.Label labelPrice;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.TextBox txt_learningRate;
		private System.Windows.Forms.TextBox txt_Iterations;
		private System.Windows.Forms.TextBox txt_RegularizationTerm;
		private System.Windows.Forms.TextBox txt_bedrooms;
		private System.Windows.Forms.TextBox txt_sqfeet;
		private System.Windows.Forms.DataGridViewTextBoxColumn bedroomCountDataGridViewTextBoxColumn;
		private System.Windows.Forms.DataGridViewTextBoxColumn squareFeetDataGridViewTextBoxColumn;
		private System.Windows.Forms.DataGridViewTextBoxColumn YearBuilt;
		private System.Windows.Forms.DataGridViewTextBoxColumn priceDataGridViewTextBoxColumn;
		private System.Windows.Forms.Label label6;
		private System.Windows.Forms.TextBox txt_YearBuilt;
		private System.Windows.Forms.Label labelHypothesis;
    }
}

