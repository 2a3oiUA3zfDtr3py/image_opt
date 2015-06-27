#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/fcntl.h>

int main(int argc,char **argv)
{
	long file_size,i,j;
	unsigned char *buffer1,*buffer2;
	struct stat stbuf;
	int fd;
	
	if (argc != 2) {
		printf("argc != 2\n");
		exit(0);
	}
	fd = open(argv[1], O_RDONLY);
	if (fd == -1) {
		printf("file open error\n");
		exit(0);
	}
	if (fstat(fd, &stbuf) == -1) {
		printf("fstat error\n");
		exit(0);
	}
	
	file_size = stbuf.st_size;
	buffer1 = (unsigned char*)malloc(file_size);
	buffer2 = (unsigned char*)malloc(file_size);
	if (buffer1 == NULL) exit(0);
	if (buffer2 == NULL) exit(0);
	
	read(fd,buffer1,file_size);
	close(fd);
	
	if(buffer1[0] != 0xFF || buffer1[1] != 0xD8) {
		printf("is't jpegs\n");
		exit(0);
	}
	if(buffer1[2] != 0xFF || buffer1[3] != 0xE0) {
		printf("has't JFIF\n");
		exit(0);
	}
	
	buffer2[0]=buffer1[0];
	buffer2[1]=buffer1[1];
	i =  4;
	i += 0x100*buffer1[4] + buffer1[5];
	j =  2;
	while(file_size > i) {
		buffer2[j]=buffer1[i];
		i++;
		j++;
	}
	
	fd = open(argv[1], O_WRONLY|O_TRUNC);
	write(fd,buffer2,j);
	close(fd);
	
	return 0;
}
