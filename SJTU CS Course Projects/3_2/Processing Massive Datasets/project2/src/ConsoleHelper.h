/*
 * ConsoleHelper.h
 *
 *  Created on: 2014��10��31��
 *      Author: jingchen
 */

#ifndef CONSOLEHELPER_H_
#define CONSOLEHELPER_H_
#include <iostream>
#include <map>
#include <stdlib.h>
using namespace std;
class ConsoleHelper {
private:
	map<string, string> mArgMap;
public:
	ConsoleHelper(int argc, char **argv);
	string getArg(string argName, string defaultValue);
	int getArg(string argName, int defaultValue);
	float getArg(string argName, float defaultValue);
	virtual ~ConsoleHelper();
};

#endif /* CONSOLEHELPER_H_ */
