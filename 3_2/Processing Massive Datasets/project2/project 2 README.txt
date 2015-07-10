Project Summary
================================================================================

In this project, you need to implement a movie recommendation system and give
predictions. The dataset is provided in the "data" folder. 


Dataset Description
================================================================================

The dataset contains a training set (training.txt) and a test set (test.txt).

Every line of training.txt corresponds to a rating on a movie by a user on a
specific day.

UserId,MovieId,DateId,Rating

- UserId ranges from 0 to 99999
- MovieId ranges from 0 to 17769
- DateId ranges from 0 to 5114 (x + 1 is the day after x)
- Rating ranges from 1 to 5

test.txt is similar to training.txt. But the all the ratings are removed and you
need to give predictions for them.

UserId,MovieId,DateId


Submission Instructions
================================================================================

Each group should send an email to TA (peterchou139 AT sjtu DOT edu DOT cn).
The email subject should be: "pmd-project" and the attachment is a .zip
or a .tar.gz file of the following  files:

- Your source code files
- Makefile // The TA will only use the "make" command to compile your source
  code. But if your source code doesn't need to be compiled before running, you
  do not need to submit this file. 
- run.sh // The TA will only use the "./run.sh" command to run the executable 
  file. 
- tools_used.txt // If you use some third party tools, you are required to
  submit a full list of the tools. For example, if you use numpy 1.9.2, you
  should add a line "numpy==1.9.2" into the file.
- report.pdf // A brief report on your project.
- student_id_list.txt // The rating predictions for the test set. Every line of
  this file corresponds to a line of test.txt sequentially. And the value of
  rating should be rounded to 1 decimal place. For example, if the test.txt 
  looks like:

  0,9934,5087
  0,13734,5087
  ...
  99999,10039,5082

  your namelist.txt should look like:

  2.3
  4.1
  ...
  3.0

  As to student_id_list, you should replace it with your student ids. For
  example, if your group has three members and the student ids are 124, 123 and
  125, the student_id_list is 124_123_125.

All the files above need to be put into one folder and packed. The data folder 
should be EXCLUDED before packing so the package can be downloaded quickly. The 
filename of the package should be "student_id_list.tar.gz".


Grading
================================================================================

The TA will calculate RMSEs of the predictions of all groups. Then the TA will
rank you RMSEs. The whole process is done automatically so make sure you name 
all your submission files correctly. Finally, the TA will grade you project 
according to your rank and your report. And all the members in one group will 
get the same grade.  

Important Notice
================================================================================

- Any forms of copying code is strictly prohibited. The TA will use some tools
  to perform duplicate checking on your codes. If any copying is found, all the
  members of related groups will get ZERO on this project. 
- Your system should be able to run on a normal Ubuntu 12.04 machine.
- You SHOULD use UNIX line ending character.