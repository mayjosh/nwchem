#include <stdio.h>
#include "types.f2c.h"

#if defined(CRAY) || defined(CRAY_T3D) || defined(CRAY_T3E)
#define util_batch_job_time_remaining_ UTIL_BATCH_job_TIME_REMAINING
#endif

#define NOT_AVAILABLE -1

/* util_batch_job_time_remaining returns the wall time (>=0) in seconds
   remaining for job execution, or -1 if no information is available */

#if (defined(SP1) && defined(BINDIR))
#define DONEIT 1  

#include <unistd.h>

Integer util_batch_job_time_remaining_(void)
{
  FILE *p;
  char cmd[1024];
  int t;

  sprintf(cmd,"%s/jobtime",BINDIR);

  if (!access("cmd",X_OK)) {	/* If cannot access perl script */
    /*(void) fprintf(stderr,"ujtr: cannot access %s\n",cmd);*/
    return NOT_AVAILABLE;
  }

  if (!(p = popen(cmd,"r"))) {
    /*(void) fprintf(stderr,"ujtr: popen %s failed\n",cmd);*/
    return NOT_AVAILABLE;
  }
  
  if (fscanf(p,"%d",&t) != 1) {
    /*(void) fprintf(stderr,"ujtr: failed to read time from pipe\n");*/
    return NOT_AVAILABLE;
  }

  if (t < 0) t = 0;

  return t;
}

#endif


#ifndef DONEIT
Integer util_batch_job_time_remaining_(void)
{
  return NOT_AVAILABLE;
}
#endif
