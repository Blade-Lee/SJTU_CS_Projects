import numpy as np
import numpy as num
import random
from sklearn.decomposition import PCA
from sklearn.neighbors import KNeighborsClassifier

def transpose_raw():

    temp_1 = []

    with open('/home/blade/Desktop/AI project/E-TABM-185.rawdata.txt', 'r') as gene_sample:
        for line in gene_sample.readlines():
            temp = line.strip('\n').split('\t')
            temp_1.append(temp)


    with open('/home/blade/Desktop/AI project/transpose.txt', 'w') as training:

        # 0-sign; 1~5896-tag
        # y is 5897
        y = len(temp_1)

        # x is 22284
        x = len(temp_1[0])

        countX = 0
        countY = 0

        for j in range(1, x):
            countX = 0
            for i in range(1, y):
                training.write(temp_1[i][j])
                countX += 1
                if i != y - 1: 
                    training.write('\t')
            training.write('\n')
            countY += 1
            if j % 500 == 0:
                print('Transposing: %.2f%%' %(j*100/float(5900)))
        
        print('countX:%d countY:%d' %(countX,countY))

def filt_illness():

    temp_1 = []
    temp_2 = {}
    index = 2

    # 0-sign; 1~5896-tag
    max = 5897 

    with open('/home/blade/Desktop/AI project/E-TABM-185_sdrf.txt', 'r') as gene_sample:
        i = 1
        for line in gene_sample.readlines():
            temp_1.append(line.strip('\n').split('\t'))
            i+=1
            if i > max:
                break


    with open('/home/blade/Desktop/AI project/filt_illness.txt', 'w') as filt:

        x = len(temp_1[0])

        illness = 0

        for j in range(0, x):
            if (cmp(temp_1[0][j], 'Characteristics[DiseaseState]') == 0):
                illness = j

        count = 0

        for i in range(1, max):
            k = temp_1[i][illness]
            if k == '':
                k = 'unknown'
            if not (k in temp_2):
                if cmp(k, 'unknown') == 0:
                    temp_2[k] = 0
                elif cmp(k, 'normal') == 0:
                    temp_2[k] = 1
                else:
                    temp_2[k] = index
                    index += 1
            filt.write('%d\n' %temp_2[k])
            count += 1

        print('count:%d' %(count))

    with open('/home/blade/Desktop/AI project/illness_index.txt', 'w') as illness_index:

        tmp_list = []

        for item in temp_2:
            tmp_list.append([temp_2[item], item])

        tmp_list.sort(key=lambda x:x[0])

        for item in tmp_list:
            illness_index.write('%d\t%s\n' %(item[0], item[1]))

def integrate_features():

    temp_1 = []

    count = 0

    with open('/home/blade/Desktop/AI project/transpose.txt', 'r') as all_feature:
        for feature in all_feature.readlines():
            count += 1
            temp_1.append(feature.strip('\n').split('\t'))

            if count % 200 == 0:
                print('Reading: %.2f%%' %(count*100/float(5896)))

    num = 0

    #temp_1: 5896 rows, 22283 columns 

    with open('/home/blade/Desktop/AI project/training_testing_features.txt', 'w') as training_testing:
      
        len_1 = 5896
        len_2 = 22283

        while num < len_1:

            if num % 300 == 0:
                print('Writing: %.2f%%'%(num*100/float(len_1)))

            for index in range(0, len_2):
                training_testing.write(temp_1[num][index])
                if index != len_2 - 1:
                    training_testing.write('\t')
                else:
                    training_testing.write('\n')

            num += 1

def PCA_decomposition(dim):

    with open('/home/blade/Desktop/AI project/training_testing_features.txt', 'r') as training_testing:

        training_testing_features = []
        num = 0
        for line in training_testing.readlines():

            if num % 300 == 0:
                print('Reading: %.2f%%' %(num*100/float(5896)))

            num += 1

            training_testing_features.append(line.strip('\n').split('\t'))

    pca = PCA(n_components = dim)
    print 'Reading Over, len:', len(training_testing_features)
    new_training_testing_features = pca.fit_transform(training_testing_features)

    print new_training_testing_features

    str_temp = '/home/blade/Desktop/AI project/new_training_testing_features_%ddim.txt' %dim
    
    np.savetxt(str_temp, new_training_testing_features, delimiter="\t", fmt="%s")

def divide_data(dim_1):

    temp_1 = []
    temp_2 = []

    count = 0

    str_temp = '/home/blade/Desktop/AI project/new_training_testing_features_%ddim.txt' %dim_1

    with open(str_temp, 'r') as all_feature:

        for feature in all_feature.readlines():
            count += 1
            temp_1.append(feature.strip('\n').split('\t'))

            #if count % 200 == 0:
                #print('Reading features: %.2f%%' %(count*100/float(5896)))


    count = 0

    with open('/home/blade/Desktop/AI project/filt_illness.txt', 'r') as all_label:

        for label in all_label.readlines():
            count += 1 
            temp_2.append(label.strip('\n'))

            #if count % 200 == 0:
                #print('Reading labels: %.2f%%' %(count*100/float(5896)))

        print 'count is:', count


    num = 0


    #temp_1: 5896 rows, 15 columns 
    #temp_2: 5896 rows, 1 columns

    with open('/home/blade/Desktop/AI project/training_feature.txt', 'w') as training:
        with open('/home/blade/Desktop/AI project/testing_feature.txt', 'w') as testing: 
            with open('/home/blade/Desktop/AI project/training_label.txt', 'w') as training_label:
                with open('/home/blade/Desktop/AI project/testing_label.txt', 'w') as testing_label:
                    len_1 = 5896
                    len_2 = dim_1

                    while num < len_1:

                        ran_result = random.randint(0,4)

                        #if num % 300 == 0:
                            #print('Writing: %.2f%%'%(num*100/float(len_1)))

                        if ran_result >= 0 and ran_result <= 2:
                            training_label.write(temp_2[num])
                            training_label.write('\n')

                            for index in range(0, len_2):
                                training.write(temp_1[num][index])
                                if index != len_2 - 1:
                                    training.write('\t')
                                else:
                                    training.write('\n')
                        else:
                            testing_label.write(temp_2[num])
                            testing_label.write('\n')

                            for index in range(0, len_2):
                                testing.write(temp_1[num][index])
                                if index != len_2 - 1:
                                    testing.write('\t')
                                else:
                                    testing.write('\n')

                        num += 1

def error_check(dim, est_y, testing_y):

    testing_y_count = {}

    for item in testing_y:
        if item in testing_y_count:
            testing_y_count[item] += 1
        else:
            testing_y_count[item] = 1

    est_right ={}

    for index in range(0, len(est_y)):

        if est_y[index] == testing_y[index]:
            if testing_y[index] in est_right:
                est_right[testing_y[index]] += 1
            else:
                est_right[testing_y[index]] = 1
        else:
            if not (testing_y[index] in est_right):
                est_right[testing_y[index]] = 0


    check_list = []

    for item in testing_y_count:
        if item in est_right:
            check_list.append([item, est_right[item]/float(testing_y_count[item]), testing_y_count[item]])
        else:
            check_list.append([item, 0.0, testing_y_count[item]])

    check_list.sort(key=lambda x:x[1])

    with open('/home/blade/Desktop/AI project/est_rate_%ddim.txt' %dim, 'w') as est_rate:
        for item in check_list:
            est_rate.write('%s\t%.4f\t%d\n' %(item[0], item[1], item[2]))

def kNN(neigh_num, dim):

    X = []
    y = []

    Testing_X = []
    Testing_est = []
    Testing_y = []

    count = 0
    with open('/home/blade/Desktop/AI project/training_feature.txt', 'r') as training_feature:

        for feature in training_feature.readlines():
            X.append(feature.strip('\n').split('\t'))
            count += 1

        #print 'Training Features:', count


    count = 0
    with open('/home/blade/Desktop/AI project/training_label.txt', 'r') as training_label:  

        for label in training_label.readlines():
            y.append(label.strip('\n'))
            count += 1

        #print 'Training Labels:', count


    count = 0
    with open('/home/blade/Desktop/AI project/testing_feature.txt', 'r') as testing_feature:

        for feature in testing_feature.readlines():
            Testing_X.append(feature.strip('\n').split('\t'))
            count += 1

        #print 'Testing Features:', count


    count = 0
    with open('/home/blade/Desktop/AI project/testing_label.txt', 'r') as testing_label:  

        for label in testing_label.readlines():
            Testing_y.append(label.strip('\n'))
            count += 1

        #print 'Testing Labels:', count

    knn = KNeighborsClassifier(n_neighbors = neigh_num)
    knn.fit(X, y)

    Testing_est = knn.predict(Testing_X)

    sum = 0

    for index in range(0, len(Testing_est)):
        if Testing_est[index] == Testing_y[index]:
            sum += 1

    if (neigh_num == 1):
        error_check(dim, Testing_est, Testing_y)

    #print('Neigh Num: %d \t Prediction Rate: %.3f%%' %(neigh_num, sum*100/float(len(Testing_est))))

    return [neigh_num, sum/float(len(Testing_est))]

def kNN_combine(dim):

    divide_data(dim)

    result = []

    for num in range(1, 51):

        result.append(kNN(num, dim))

    return result

def main():
    #transpose_raw()
    #filt_illness()

    #integrate_features()
    
    #PCA_decomposition(100)

    #dim = 10, 15, 30, 40, 50, 100

    dimen = [10, 15, 30, 40, 50, 100]

    for num in dimen:

        str_temp = '/home/blade/Desktop/AI project/knn_result(dim=%d).txt' %num

        result = kNN_combine(num)

        with open(str_temp, 'w') as output:
            for index in result:
                str_temp_2 = '%d\t%.5f\n' %(index[0], index[1])
                output.write(str_temp_2)


if __name__ == '__main__':
    main()
