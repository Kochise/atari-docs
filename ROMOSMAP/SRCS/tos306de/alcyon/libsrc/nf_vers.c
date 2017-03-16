#include "lib.h"
#include <mint/arch/nf_ops.h>

long nf_version(NOTHING)
{
	struct nf_ops *nf_ops;
	long version = 0;
	
	if ((nf_ops = nf_init()) != NULL)
	{
		long nfid_version = NF_GET_ID(nf_ops, NF_ID_VERSION);
		
		if (nfid_version)
		{
			version = (*nf_ops->call)(nfid_version | 0);
		}
	}
	return version;
}
