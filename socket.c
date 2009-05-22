#include <errno.h> /* perror() and errno */
#include <netdb.h> /* required by getprotobyname() */

#include <sys/types.h>
#include <sys/socket.h> /* both required by socket() */

#include <netinet/in.h> /* define sockaddr_in */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <time.h>

extern int errno;

int main(int argc, char **argv) {

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

  extern int h_errno;
  struct hostent *hostaddr;
  hostaddr = gethostbyname(argv[1]);
  if(!hostaddr) {
    fprintf(stderr, "gethostbyname(): %s\n", hstrerror(h_errno));
    return(h_errno);
  }
  memcpy(&socketaddr.sin_addr, hostaddr->h_addr, hostaddr->h_length);

  int rval;
  int attempts = 0;
  struct timespec ts = { .tv_sec = 0, .tv_nsec = 50000000 };
  do { 
    rval = connect(sd, (struct sockaddr *) &socketaddr, sizeof(socketaddr));
    attempts += 1;
    nanosleep(&ts, NULL);
  } while (rval == -1 && attempts < 400);
    
  if (rval == -1) {
    perror("connect()");
    return(errno);
  }

  rval = send(sd, argv[3], strlen(argv[3]), NULL);
  if (rval == -1) {
    perror("send()");
    return(errno);
  }

  close(sd);
  return EXIT_SUCCESS;

}


