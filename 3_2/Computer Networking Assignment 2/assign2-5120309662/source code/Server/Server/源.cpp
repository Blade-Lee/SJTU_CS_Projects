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

// Need to link with Ws2_32.lib
#pragma comment (lib, "Ws2_32.lib")
// #pragma comment (lib, "Mswsock.lib")

#define DEFAULT_BUFLEN 512
#define CONTROL_PORT "21"
#define DATA_PORT "27014"
const int data_port = 27014;

using namespace std;

int	establish_socket_connection(SOCKET &ClientSocket){

	int iResult;

	SOCKET ListenSocket = INVALID_SOCKET;

	struct addrinfo *result = NULL;
	struct addrinfo hints;

	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	hints.ai_flags = AI_PASSIVE;

	// Resolve the server address and port
	iResult = getaddrinfo(NULL, CONTROL_PORT, &hints, &result);
	if (iResult != 0) {
		printf("getaddrinfo failed with error: %d\n", iResult);
		WSACleanup();
		return 1;
	}

	// Create a SOCKET for connecting to server
	ListenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
	if (ListenSocket == INVALID_SOCKET) {
		printf("socket failed with error: %ld\n", WSAGetLastError());
		freeaddrinfo(result);
		WSACleanup();
		return 1;
	}

	// Setup the TCP listening socket
	iResult = bind(ListenSocket, result->ai_addr, (int)result->ai_addrlen);
	if (iResult == SOCKET_ERROR) {
		printf("bind failed with error: %d\n", WSAGetLastError());
		freeaddrinfo(result);
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	freeaddrinfo(result);

	iResult = listen(ListenSocket, SOMAXCONN);
	if (iResult == SOCKET_ERROR) {
		printf("listen failed with error: %d\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	// Accept a client socket
	ClientSocket = accept(ListenSocket, NULL, NULL);
	if (ClientSocket == INVALID_SOCKET) {
		printf("accept failed with error: %d\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	closesocket(ListenSocket);

	return 0;

}

int build_data_socket(SOCKET &ListenSocket){
	int iResult;

	struct addrinfo *result = NULL;
	struct addrinfo hints;

	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	hints.ai_flags = AI_PASSIVE;

	// Resolve the server address and port
	iResult = getaddrinfo(NULL, DATA_PORT, &hints, &result);
	if (iResult != 0) {
		printf("getaddrinfo failed with error: %d\n", iResult);
		WSACleanup();
		return 1;
	}

	// Create a SOCKET for connecting to server
	ListenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
	if (ListenSocket == INVALID_SOCKET) {
		printf("socket failed with error: %ld\n", WSAGetLastError());
		freeaddrinfo(result);
		WSACleanup();
		return 1;
	}

	// Setup the TCP listening socket
	iResult = bind(ListenSocket, result->ai_addr, (int)result->ai_addrlen);
	if (iResult == SOCKET_ERROR) {
		printf("bind failed with error: %d\n", WSAGetLastError());
		freeaddrinfo(result);
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	return 0;
}

int listen_data_socket(SOCKET &ListenSocket, SOCKET &ClientSocket){

	int iResult;

	iResult = listen(ListenSocket, SOMAXCONN);
	if (iResult == SOCKET_ERROR) {
		printf("listen failed with error: %d\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	// Accept a client socket
	ClientSocket = accept(ListenSocket, NULL, NULL);
	if (ClientSocket == INVALID_SOCKET) {
		printf("accept failed with error: %d\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	closesocket(ListenSocket);

	return 0;
}

void listDir(const char * dirn)
{
	char dirnPath[1024];
	sprintf_s(dirnPath, "%s\\*", dirn);

	WIN32_FIND_DATA f;
	HANDLE h = FindFirstFile(dirnPath, &f);

	if (h == INVALID_HANDLE_VALUE) { return; }

	do
	{
		const char * name = f.cFileName;

		if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0) { continue; }

		char filePath[1024];
		sprintf_s(filePath, "%s%s%s", dirn, "\\", name);

		cout << name << endl;
		/*
		if (f.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY)
		{
			listDir(filePath);
		}
		*/

	} while (FindNextFile(h, &f));
	FindClose(h);
}

int __cdecl main(void)
{
	WSADATA wsaData;
	int iResult;

	char *usrname = "ComputerNetworking";
	char *psw = "123456";

	SOCKET ControlSocket = INVALID_SOCKET;
	SOCKET DataSocket = INVALID_SOCKET;

	char recvbuf[DEFAULT_BUFLEN];
	char sendbuf[DEFAULT_BUFLEN];

	// Initialize Winsock
	iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != 0) {
		printf("WSAStartup failed with error: %d\n", iResult);
		return 1;
	}

	/**************************************************************************************/
	/*                     Establish, listening, and accepting                            */
	/**************************************************************************************/

	establish_socket_connection(ControlSocket);

	// Send confirming response code
	sprintf_s(sendbuf,"220-\n");
	iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
	if (iResult == SOCKET_ERROR) {
		printf("send failed with error: %d\n", WSAGetLastError());
		closesocket(ControlSocket);
		WSACleanup();
		return 1;
	}

	// Send welcome message
	sprintf_s(sendbuf, "220-  -- Welcome to Portal of Blade Lee --\n220- -This is a private system - No anonymous login allowed\n");
	iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
	if (iResult == SOCKET_ERROR) {
		printf("send failed with error: %d\n", WSAGetLastError());
		closesocket(ControlSocket);
		WSACleanup();
		return 1;
	}

	/**************************************************************************************/
	/*                        Accepting user name and password                            */
	/**************************************************************************************/

	// User name
	memset(recvbuf, '\0', DEFAULT_BUFLEN);
	iResult = recv(ControlSocket, recvbuf, DEFAULT_BUFLEN, 0);
	if (iResult > 0){

		char command[20];
		char username[50];

		sscanf_s(recvbuf, "%s %s", command, 10,username,50);
		
		cout << "command: " << command << endl;
		cout << "Username: " << username << endl;

		if (!strcmp(command, "USER")&& !strcmp(username,"ComputerNetworking")){
			sprintf_s(sendbuf, "331 Password required for ComputerNetworking\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}
		}
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());

	// Password
	memset(recvbuf, '\0', DEFAULT_BUFLEN);
	iResult = recv(ControlSocket, recvbuf, DEFAULT_BUFLEN, 0);
	if (iResult > 0){

		char command[20];
		char password[50];

		sscanf_s(recvbuf, "%s %s", command, 10, password, 50);

		cout << "command: " << command << endl;
		cout << "password: " << password << endl;

		if (!strcmp(command, "PASS") && !strcmp(password,"123456")){
			sprintf_s(sendbuf, "230- Password correct\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}
			sprintf_s(sendbuf, "230 User ComputerNetworking logged in\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}
		}
	}
	else if (iResult == 0)
		printf("Connection closed\n");
	else
		printf("recv failed with error: %d\n", WSAGetLastError());


	/**************************************************************************************/
	/*                              Accepting commands                                    */
	/**************************************************************************************/


	// Get the root directory
	char rootDir[MAX_PATH];
	// get the root directory, and store it
	if (!GetCurrentDirectory(MAX_PATH, rootDir)) {
		cerr << "Error getting current directory: #" << GetLastError();
		return 1; // quit if it failed
	}

	while (true){

		// Get command

		char command[50];
		char path[50];

		memset(recvbuf, '\0', DEFAULT_BUFLEN);
		iResult = recv(ControlSocket, recvbuf, DEFAULT_BUFLEN, 0);
		if (iResult > 0){
			sscanf_s(recvbuf, "%s", command, 50);
		}
		else if (iResult == 0)
			printf("Connection closed\n");
		else
			printf("recv failed with error: %d\n", WSAGetLastError());

		// Passive Mode command
		if (!strcmp(command, "PASV")){

			SOCKET ListenSocket = INVALID_SOCKET;

			build_data_socket(ListenSocket);

			// Send the PASV command response
			sprintf_s(sendbuf, "227 Entering Passive Mode (127,0,0,1,%d,%d)\r\n",data_port /256,data_port % 256);
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			listen_data_socket(ListenSocket, DataSocket);

		}

		// PWD command
		else if (!strcmp(command, "PWD")){

			char currentDir[MAX_PATH];

			if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			// Send the PWD command response
			sprintf_s(sendbuf, "257 %s\r\n",currentDir,MAX_PATH);
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}
		}

		//LIST command
		else if (!strcmp(command, "LIST")){

			// Send the LIST command response at the beginning
			sprintf_s(sendbuf, "150 Opening ASCII mode data connection for file list\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			char currentDir[MAX_PATH];

			if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			vector <string> temp;

			char dirnPath[1024];
			sprintf_s(dirnPath, "%s\\*", currentDir);

			WIN32_FIND_DATA f;
			HANDLE h = FindFirstFile(dirnPath, &f);

			do
			{
				string t = f.cFileName;

				if (t == "." || t == "..") continue;

				if (f.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY){
					temp.push_back("DIR: "+ t);
				}
				else {
					temp.push_back("FILE: " + t);
				}

			} while (FindNextFile(h, &f));
			FindClose(h);

			string s;
			int index = 0;

			memset(sendbuf, '\0', DEFAULT_BUFLEN);
			for (int i = 0; i < temp.size();++i){
				s = temp[i];
				for (int j = 0; j < s.length(); ++j){
					sendbuf[j + index] = s[j];
				}
				sendbuf[s.length() + index] = '\n';

				index += s.length() + 1;
			}

			// Send the list via data socket
			iResult = send(DataSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			// Send the LIST command response in the end
			sprintf_s(sendbuf, "226 Transfer complete\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			// shutdown the data connection since we're done
			iResult = shutdown(DataSocket, SD_SEND);
			if (iResult == SOCKET_ERROR) {
				printf("shutdown failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

		}

		//CWD command
		else if (!strcmp(command, "CWD")){

			char currentDir[MAX_PATH];

			if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			sscanf_s(recvbuf, "%s %s", command,50,path, 50);

			int len = strlen(currentDir);

			currentDir[len++] = '\\';

			for (int i =0; i < strlen(path); ++i){
				currentDir[i + len] = path[i];
			}

			currentDir[len + strlen(path)] = '\0';
			
			if (!SetCurrentDirectory(currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			// Send the CWD command response in the end
			sprintf_s(sendbuf, "250 CWD command successful\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}


		}

		//CDUP command
		else if (!strcmp(command, "CDUP")){

			char currentDir[MAX_PATH];

			if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
				std::cerr << "Error getting current directory: #" << GetLastError();
				return 1; // quit if it failed
			}

			// Now it is not the root directory
			if (strcmp(currentDir, rootDir)){
				int len = strlen(currentDir);
				currentDir[len++] = '\\';
				currentDir[len++] = '.';
				currentDir[len++] = '.';
				currentDir[len++] = '\0';

				if (!SetCurrentDirectory(currentDir)) {
					std::cerr << "Error getting current directory: #" << GetLastError();
					return 1; // quit if it failed
				}

				if (!GetCurrentDirectory(MAX_PATH, currentDir)) {
					std::cerr << "Error getting current directory: #" << GetLastError();
					return 1; // quit if it failed
				}
			}

			// Send the CDUP command response in the end
			sprintf_s(sendbuf, "250 CDUP command successful\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}
		}

		//RETR command
		else if (!strcmp(command, "RETR")){

			sscanf_s(recvbuf, "%s %s", command, 50, path, 50);

			// Send the RETR command response at beginning
			sprintf_s(sendbuf, "150 Opening	ASCII mode data conenction for %s\r\n", path);
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			ifstream temp(path, ios::binary | ios::ate);
			int fileSize = (int)temp.tellg();
			temp.close();

			ifstream myfile(path, ios::binary);

			int send_times = fileSize / (DEFAULT_BUFLEN - 5) + (fileSize % (DEFAULT_BUFLEN - 5) == 0 ? 0 : 1);

			while (send_times--){

				memset(sendbuf, '\0', DEFAULT_BUFLEN);
				myfile.read(sendbuf, DEFAULT_BUFLEN - 5);

				iResult = send(DataSocket, sendbuf, (int)strlen(sendbuf), 0);
				if (iResult == SOCKET_ERROR) {
					printf("send failed with error: %d\n", WSAGetLastError());
					closesocket(DataSocket);
					WSACleanup();
					return 1;
				}
			}
			// shutdown the data connection since no more data will be sent
			iResult = shutdown(DataSocket, SD_SEND);
			if (iResult == SOCKET_ERROR) {
				printf("shutdown failed with error: %d\n", WSAGetLastError());
				closesocket(DataSocket);
				WSACleanup();
				return 1;
			}

			// Send the RETR command response in the end
			sprintf_s(sendbuf, "226 Transfer complete\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			myfile.close();

		}

		//STOR command
		else if (!strcmp(command, "STOR")){

			sscanf_s(recvbuf, "%s %s", command, 50, path, 50);

			// Send the STOR command response at beginning
			sprintf_s(sendbuf, "150 Opening	ASCII mode data conenction for %s\r\n", path);
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			ofstream myfile;
			myfile.open(path, ios::binary);

			while (true){
				memset(recvbuf, '\0', DEFAULT_BUFLEN);
				iResult = recv(DataSocket, recvbuf, DEFAULT_BUFLEN-1, 0);
				if (iResult > 0){
					myfile << recvbuf;
				}
				else if (iResult == 0){
					break;
				}
				else
					printf("recv failed with error: %d\n", WSAGetLastError());
			}

			// Send the STOR command response in the end
			sprintf_s(sendbuf, "226 Transfer complete\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			myfile.close();
		}

		//QUIT command
		else if (!strcmp(command, "QUIT")){

			// Send the QUIT command response at beginning
			sprintf_s(sendbuf, "221 Goodbye!\r\n");
			iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
			if (iResult == SOCKET_ERROR) {
				printf("send failed with error: %d\n", WSAGetLastError());
				closesocket(ControlSocket);
				WSACleanup();
				return 1;
			}

			break;
		}

		//DELE command
		else if (!strcmp(command, "DELE")){

			sscanf_s(recvbuf, "%s %s", command, 50, path, 50);

			if (remove(path) != 0)
				perror("Error deleting file");
			else{
				// Send the DELE command response at beginning
				sprintf_s(sendbuf, "250 DELE command successful\r\n");
				iResult = send(ControlSocket, sendbuf, (int)strlen(sendbuf), 0);
				if (iResult == SOCKET_ERROR) {
					printf("send failed with error: %d\n", WSAGetLastError());
					closesocket(ControlSocket);
					WSACleanup();
					return 1;
				}
			}
		}
	}

	// cleanup
	closesocket(ControlSocket);
	WSACleanup();

	return 0;
}