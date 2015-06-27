# image_opt
image optimization parallel script  
the script searches and optimizes images in current directory.  

#### use
run with the default values.
`$ image_opt.pl`
run with 64 process.
`$ image_opt.pl 64`
  
the default values:
`$ cat /proc/cpuinfo | grep processor | wc -l`
  
#### require
convert (ImageMagick)  
mozjpeg  
jpegoptim  
optipng  
zopflipng  
gif2apng  
apng2gif  
advdef  
base64  
  
#### compile
`$ gcc -o removeapp0 -fstack-protector-all -O3 -fPIE -pie removeapp0.c`
