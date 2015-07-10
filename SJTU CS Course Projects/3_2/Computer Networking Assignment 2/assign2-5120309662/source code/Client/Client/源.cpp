#undef UNICODE

#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <cstdio>
#include <fstream>
#include <Mswsock.h>
#include <shlwapi.h>
#include <sys/types.h>
#include <cstdlib>
#include <tchar.h> 
#include <strsafe.h>
#include <vector>


// Need to link with Ws2_32.lib, Mswsock.lib, and Advapi32.lib
#pragma comment (lib, "Ws2_32.lib")
#pragma comment (lib, "Mswsock.lib")
#pragma comment (lib, "AdvApi32.lib")

#define DEFAULT_BUFLEN 512
#define CONTROL_PORT "21"

using namespace std;

int getResponseCode(char a[]){
	return atoi(a);
}

int socket_connect(SOCKET &socket_temp, struct addrinfo &hints, struct addrinfo *result, struct addrinfo *ptr, char data_ip[],char data_port[]){

	int iResult;

	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;

	// Resolve the server address and port
	iResult = getaddrinfo(data_ip, data_port, &hints, &result);
	if (iResult != 0) {
		printf("getaddrinfo failed with error: %d\n", iResult);
		WSACleanup();
		return 1;
	}

	// Attempt to connect to an address until one succeeds
	for (ptr = result; ptr != NULL; ptr = ptr->ai_next) {

		// Create a SOCKET for connecting to server
		socket_temp = socket(ptr->ai_family, ptr->ai_socktype,
			ptr->ai_protocol);
		if (socket_temp == INVALID_SOCKET) {
			printf("socket failed with error: %ld\n", WSAGetLastError());
			WSACleanup();
			return 1;
		}

		// Connect to server.
		iResult = connect(socket_temp, ptr->ai_addr, (int)ptr->ai_addrlen);
		if (iResult == SOCKET_ERROR) {
			closesocket(socket_temp);
			socket_temp = INVALID_SOCKET;
			continue;
		}
		break;
	}

	freeaddrinfo(result);

	if (socket_temp == INVALID_SOCKET) {
		printf("Unable to connect to server!\n");
		WSACleanup();
		return 1;
	}

	return 0;
}

int passive_mode(SOCKET &socket_temp, int data_socket_ip[], int data_socket_port[], char ip[],char port[]){
	char sendbuf[DEFAULT_BUFLEN];
	char recvbuf[DEFAULT_BUFLEN];

	int iResult;
	// Send the passive mode
	sprintf_s(sendbuf, "PASV\r\n");
	iResult = send(socket_temp, sendbuf, (int)strlen(sendbuf), 0);
	if (iResult == SOCKET_ERROR) {
		printf("send failed with error: %d\n", WSAGetLastError());
		closesocket(socket_temp);
		WSACleanup();
		return 1;
	}
	// Receive the response code of passive mode
	memset(recvbuf, '\0', DEFAULT_BUFLEN);
	iResult = recv(socket_temp, recvbuf, DEFAULT_BUFLEN, 0);
	if (iResult > 0){
		cout << recvbuf << endl;
		if (getResponseCode(recvbuf) != 227)
			printf("response code error\n");
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());

	// Process the IP and port
	for (int i = 0; i < DEFAULT_BUFLEN; ++i){
		if (recvbuf[i] == '('){
			sscanf_s(recvbuf + i, "(%d,%d,%d,%d,%d,%d)", &data_socket_ip[0], &data_socket_ip[1], &data_socket_ip[2], &data_socket_ip[3], &data_socket_port[0], &data_socket_port[1]);
			break;
		}
	}

	printf("IP: %d.%d.%d.%d \nPort: %d\n", data_socket_ip[0], data_socket_ip[1], data_socket_ip[2], data_socket_ip[3], data_socket_port[0] * 256 + data_socket_port[1]);

	char data_ip[50];
	char data_port[10];

	sprintf_s(data_ip, "%d.%d.%d.%d", data_socket_ip[0], data_socket_ip[1], data_socket_ip[2], data_socket_ip[3]);
	sprintf_s(data_port, "%d", data_socket_port[0] * 256 + data_socket_port[1]);

	for (int i = 0; i < 50; ++i)
		ip[i] = data_ip[i];
	for (int i = 0; i < 10; ++i)
		port[i] = data_port[i];

	return 0;
}

int __cdecl main(int argc, char **argv)
{

	// Validate the parameters
	if (argc != 2) {
		printf("usage: %s server-name\n", argv[0]);
		return 1;
	}

	WSADATA wsaData;
	SOCKET control_socket = INVALID_SOCKET;
	SOCKET data_socket = INVALID_SOCKET;
	struct addrinfo *result = NULL,
		*ptr = NULL,
		hints;

	int data_socket_ip[4] = { 0, 0, 0, 0 };
	int data_socket_port[2] = { 0, 0 };

	char data_ip[50];
	char data_port[10];

	char sendbuf[DEFAULT_BUFLEN];
	char recvbuf[DEFAULT_BUFLEN];
	int iResult;
	int recvbuflen = DEFAULT_BUFLEN;

	char username[DEFAULT_BUFLEN];
	char password[DEFAULT_BUFLEN];

	// Initialize Winsock
	iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != 0) {
		printf("WSAStartup failed with error: %d\n", iResult);
		return 1;
	}

	/***********************************************************************************/
	/*                           Connect to the control socket                         */
	/***********************************************************************************/

	iResult = socket_connect(control_socket, hints, result, ptr, argv[1], CONTROL_PORT);
	if (iResult == 1) return 1;

	/***********************************************************************************/
	/*                         Receive initiation message                              */
	/***********************************************************************************/

	// Receive the response code
	memset(recvbuf, '\0', recvbuflen);
	iResult = recv(control_socket, recvbuf, recvbuflen-1, 0);
	if (iResult > 0){
		int k = getResponseCode(recvbuf);
		switch (k){
		case 220:
			printf("Connection establised.\n");
			break;
		default:
			printf("response code error\n");
		}
		
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());


	// Receive the welcome message
	memset(recvbuf, '\0',recvbuflen);
	iResult = recv(control_socket, recvbuf, recvbuflen, 0);
	if (iResult > 0)
		cout << recvbuf << endl;
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());

	// Request the username and password
	cout << "Username: ";
	memset(username, '\0', DEFAULT_BUFLEN);
	cin >> username;

	cout << "Password: ";
	memset(password, '\0', DEFAULT_BUFLEN);
	cin >> password;

	/***********************************************************************************/
	/*                            Send the user name                                   */
	/***********************************************************************************/

	sprintf_s(sendbuf, "USER %s\r\n", username);
	iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
	if (iResult == SOCKET_ERROR) {
		printf("send failed with error: %d\n", WSAGetLastError());
		closesocket(control_socket);
		WSACleanup();
		return 1;
	}
	// Receive the response code of user name
	memset(recvbuf, '\0', recvbuflen);
	iResult = recv(control_socket, recvbuf, recvbuflen, 0);
	if (iResult > 0){
		if (getResponseCode(recvbuf) != 331)
			printf("response code error\n");
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());

	/***********************************************************************************/
	/*                                Send the password                                */
	/***********************************************************************************/

	sprintf_s(sendbuf, "PASS %s\r\n", password);
	iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
	if (iResult == SOCKET_ERROR) {
		printf("send failed with error: %d\n", WSAGetLastError());
		closesocket(control_socket);
		WSACleanup();
		return 1;
	}
	// Receive the response code of password
	memset(recvbuf, '\0', recvbuflen);
	iResult = recv(control_socket, recvbuf, recvbuflen, 0);
	if (iResult > 0){
		cout <<recvbuf << endl;
		if (getResponseCode(recvbuf)!= 230)
			printf("response code error\n");
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());

	memset(recvbuf, '\0', recvbuflen);
	iResult = recv(control_socket, recvbuf, recvbuflen, 0);
	if (iResult > 0){
		cout << recvbuf << endl;
		if (getResponseCode(recvbuf) != 230)
			printf("response code error\n");
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());	

	char currentDir[MAX_PATH];

	if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
		std::cerr << "Error getting current directory: #" << GetLastError();
		return 1; // quit if it failed
	}

	cout << "Please put the file to be uploaded in: " << currentDir << endl;
	cout << "File stored location: " << currentDir << endl << endl;

	/***********************************************************************************/
	/*                                Input the command                                */
	/***********************************************************************************/

	string command;

	while (cin >> command){

		// PWD command
		if (command == "PWD"){
			// Send the PWD command
			sprintf_s(sendbuf, "PWD\r\n");
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of PWD command
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 257)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
		}

		// LIST command
		else if (command == "LIST"){

			// Start data connection
			iResult = passive_mode(control_socket,data_socket_ip,data_socket_port,data_ip,data_port);
			if (iResult) return 1;
		
			iResult = socket_connect(data_socket, hints, result, ptr, data_ip, data_port);
			if (iResult) return 1;


			// Send the LIST command
			sprintf_s(sendbuf, "LIST\r\n");
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}

			// Receive the response code of LIST command on the control socket for the first time
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 150)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());


			// Receive the response code of LIST command on the data socket
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(data_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
			
			
			// Receive the response code of LIST command on the control socket for the second time
			cout << "Retriving data, please wait..." << endl;
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 226)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
			
		}

		// CWD command
		else if (command == "CWD"){

			char path[50];
			cin >> path;

			// Send the CWD command
			sprintf_s(sendbuf, "CWD %s\r\n", path);
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of CWD command
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 250)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
		}

		// CDUP command
		else if (command == "CDUP"){

			// Send the CDUP command
			sprintf_s(sendbuf, "CDUP\r\n");
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of CDUP command
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 250)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
		}

		// RETR command
		else if (command == "RETR"){

			// Start data connection
			iResult = passive_mode(control_socket, data_socket_ip, data_socket_port, data_ip, data_port);
			if (iResult) return 1;

			iResult = socket_connect(data_socket, hints, result, ptr, data_ip, data_port);
			if (iResult) return 1;


			// Input the path(name)
			char path[50];
			cin >> path;


			// Send the RETR command
			sprintf_s(sendbuf, "RETR %s\r\n",path);
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of RETR command on the control socket for the first time
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 150)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
			

			// Download data via data socket

			ofstream myfile;
			myfile.open(path,ios::binary);

			while (true){
				memset(recvbuf, '\0', recvbuflen); 
				iResult = recv(data_socket, recvbuf, recvbuflen-1, 0);
				if (iResult > 0){
					myfile << recvbuf;
				}
				else if (iResult == 0){
					break;
				}
				else
					printf("recv failed with error: %d\n", WSAGetLastError());

			}

			// Receive the response code of RETR command on the control socket for the second time
			cout << "Retriving data, please wait..." << endl;
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 226)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());

			myfile.close();

		}

		// STOR command
		else if (command == "STOR"){
			
			// Start data connection
			iResult = passive_mode(control_socket, data_socket_ip, data_socket_port, data_ip, data_port);
			if (iResult) return 1;

			iResult = socket_connect(data_socket, hints, result, ptr, data_ip, data_port);
			if (iResult) return 1;


			// Input the path(name)
			char path[50];
			cin >> path;


			// Send the STOR command
			sprintf_s(sendbuf, "STOR %s\r\n", path);
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of STOR command on the control socket for the first time
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 150)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());


			// Upload data via data socket

			ifstream temp(path, ios::binary | ios::ate);
			int fileSize = (int)temp.tellg();
			temp.close();

			ifstream myfile(path, ios::binary);

			cout << "File size:" << fileSize << endl;

			int send_times = fileSize / (DEFAULT_BUFLEN-1) + (fileSize % (DEFAULT_BUFLEN-1) == 0 ? 0 : 1);

			while (send_times--){

				memset(sendbuf, '\0', DEFAULT_BUFLEN);
				myfile.read(sendbuf, DEFAULT_BUFLEN - 1);

				iResult = send(data_socket, sendbuf, DEFAULT_BUFLEN-1, 0);
				if (iResult == SOCKET_ERROR) {
					printf("send failed with error: %d\n", WSAGetLastError());
					closesocket(data_socket);
					WSACleanup();
					return 1;
				}
			}

			// shutdown the data connection since no more data will be sent
			iResult = shutdown(data_socket, SD_SEND);
			if (iResult == SOCKET_ERROR) {
				printf("shutdown failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			

			// Receive the response code of STOR command on the control socket for the second time
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 226)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());

			myfile.close();

		}

		// QUIT command
		else if (command == "QUIT"){

			// Send the QUIT command
			sprintf_s(sendbuf, "QUIT\r\n");
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of QUIT command
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 221)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());

			// shutdown the connection since no more data will be sent
			iResult = shutdown(control_socket, SD_SEND);
			if (iResult == SOCKET_ERROR) {
				printf("shutdown failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}

			break;

		}

		// DELE command
		else if (command == "DELE"){

			char path[50];
			cin >> path;

			// Send the DELE command
			sprintf_s(sendbuf, "DELE %s\r\n", path);
			iResult = send(control_socket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(control_socket);
				WSACleanup();
				return 1;
			}
			// Receive the response code of DELE command
			memset(recvbuf, '\0', recvbuflen);
			iResult = recv(control_socket, recvbuf, recvbuflen, 0);
			if (iResult > 0){
				cout << recvbuf << endl;
				if (getResponseCode(recvbuf) != 250)
					printf("response code error\n");
			}
			else if (iResult == 0)
				printf("Connection closed\n");
			else
				printf("recv failed with error: %d\n", WSAGetLastError());
		}

		// Wrong command
		else{
			printf("Wrong command!\n");
		}
	}

	// cleanup
	closesocket(control_socket);
	WSACleanup();

	cout << "System off.\n";

	return 0;
}