
/* v1495firmware.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#ifdef Linux_vme

int
main(int argc, char *argv[])
{
  int res, page = -1, user_vme = -1;
  char myname[256];
  unsigned int addr, laddr;

  if(argc==5)
  {
    addr = strtol(argv[1], (char **)NULL, 16);
    printf("use argument >0x%08x< as board VME address\n",addr);

    strncpy(myname, argv[2], 255);
    printf("use argument >%s< as rbf file name\n",myname);
	 
	 page = atoi(argv[3]);
	 user_vme = atoi(argv[4]);
  }
  else
  {
    printf("Usage: v1495firmware <vme_address> <rbf file> <page> <user_vme>\n");
	 printf("       page:     0=standard, 1=backup\n");
	 printf("       user_vme: 0=USER FPGA, 1=VME FPGA\n");
    exit(0);
  }

  /* Open the default VME windows */
  vmeOpenDefaultWindows();

  /* get address in A24 space */
  res = vmeBusToLocalAdrs(0x39,(char *)addr,(char **)&laddr);
  if (res != 0) 
  {
	printf("ERROR in vmeBusToLocalAdrs(0x39,0x%x,&laddr) \n",addr);
  }
  else
  {
    printf("INFO: addr=0x%08x, laddr=0x%08x\n",addr,laddr);
    /* update firmware */
    v1495firmware(laddr,myname,page,user_vme);
  }

  exit(0);
}

#else

int
main()
{
  return(0);
}

#endif
