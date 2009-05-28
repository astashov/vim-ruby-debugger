#include <errno.h> /* perror() and errno */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <winsock.h>
#include <windows.h>

extern int errno;

int main(int argc, char **argv) {

  WSADATA wsa_data;
  if (WSAStartup(MAKEWORD(2, 0), &wsa_data) != 0) {
    fprintf(stderr, "WSAStartup() failed\n");
    return EXIT_FAILURE;
  }

  if(argc != 4) {
    fprintf(stderr, "Wrong number of arguments: %d instead of 3\n", argc - 1);
    return EXIT_FAILURE;
  }

  struct protoent *protocol;
  protocol = getprotobyname("tcp");
  if(!protocol) {
    perror("getprotobyname()");
    return(errno);
  }

  int sd; /* our socket descriptor */
  sd = socket(PF_INET, SOCK_STREAM, protocol->p_proto);
  if(!sd) {
    perror("socket()");
    return(errno);
  }

  struct sockaddr_in socketaddr;
  memset(&socketaddr, 0, sizeof(socketaddr)); /* initialize it */
  socketaddr.sin_family = AF_INET; /* set the family type to Internet */
  socketaddr.sin_port = htons(atoi(argv[2]));

  struct hostent *hostaddr;
  hostaddr = gethostbyname(argv[1]);
  if(!hostaddr) {
    fprintf(stderr, "gethostbyname() failed\n");
    return EXIT_FAILURE;
  }
  memcpy(&socketaddr.sin_addr, hostaddr->h_addr, hostaddr->h_length);

  int rval;
  int attempts = 0;
  do { 
    rval = connect(sd, (struct sockaddr *) &socketaddr, sizeof(socketaddr));
    attempts += 1;
    Sleep(500);
  } while (rval == -1 && attempts < 50);
    
  if (rval == -1) {
    perror("connect()");
    return(errno);
  }

  rval = send(sd, argv[3], strlen(argv[3]), 0);
  if (rval != strlen(argv[3])) {
    perror("send()");
    return(errno);
  }


  //WSACleanup();
  closesocket(sd);
  return EXIT_SUCCESS;

}


