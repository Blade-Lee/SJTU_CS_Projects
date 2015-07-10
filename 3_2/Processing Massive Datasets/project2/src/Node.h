/*
 * Node.h
 *
 *  Created on: 2014��10��24��
 *      Author: chenjing
 */

#ifndef NODE_H_
#define NODE_H_

class Node {
private:
	int mId;
	float mRate;
public:
	Node(int id, float rate) :
			mId(id), mRate(rate) {

	}
	int getId() {
		return mId;
	}
	float getRate() {
		return mRate;
	}
	~Node() {

	}
};

#endif /* NODE_H_ */
