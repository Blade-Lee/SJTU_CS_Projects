/*
 * ConsoleHelper.cpp
 *
 *  Created on: 2014��10��31��
 *      Author: jingchen
 */

#include "ConsoleHelper.h"

ConsoleHelper::ConsoleHelper(int argc, char **argv) {
	for (int i = 1; i < argc; i += 2) {
		mArgMap.insert(map<string, string>::value_type(argv[i], argv[i + 1]));
	}
}
string ConsoleHelper::getArg(string argName, string defaultValue) {
	if (mArgMap.find(argName) == mArgMap.end()) {
		return defaultValue;
	} else
		return mArgMap[argName];
}
int ConsoleHelper::getArg(string argName, int defaultValue) {
	if (mArgMap.find(argName) == mArgMap.end()) {
		return defaultValue;
	} else
		return atoi(mArgMap[argName].c_str());
}
float ConsoleHelper::getArg(string argName, float defaultValue) {
	if (mArgMap.find(argName) == mArgMap.end()) {
		return defaultValue;
	} else
		return atof(mArgMap[argName].c_str());
}
ConsoleHelper::~ConsoleHelper() {
}

