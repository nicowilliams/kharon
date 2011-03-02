#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>

#include "parse.h"

typedef struct self ArrayHash;

/* append input = array of strings, out = whether to continue, bool */

/* Reset */

/* results returns result array */

/* Parse */

/* Encode */

/* Encode_Error */

/* Marshall */

/* Unmarshall */

MODULE = Kharon::Protocol::ArrayHash  PACKAGE = Kharon::Protocol::ArrayHash

PROTOTYPES: ENABLE

ArrayHash *
new(class, ...)
	SV	*class
 INIT:
        ArrayHash	*self;
	int		 i;
	char		*key;
	STRLEN		 len;
 CODE:
        self = parse_init();
	for (i=0; i*2+1 < items; i++) {
		key = SvPV(ST(1+i*2), len);
		if (len != strlen("banner"))
			croak("hash contains unrecognised argument (len)");
		if (strncmp(key, "banner", strlen("banner")))
			croak("hash contains unrecognised argument (key)");
		/* XXXrcd: inc ref count? */
		self->banner = ST(1+i*2+1);
		SvREFCNT_inc(self->banner);
	}
        RETVAL = self;
 OUTPUT:
        RETVAL

MODULE = Kharon::Protocol::ArrayHash  PACKAGE = ArrayHashPtr PREFIX = ArrayHash_

void
ArrayHash_DESTROY(self)
        ArrayHash *self
 CODE:
        parse_free(self);

SV *
ArrayHash_SendBanner(self)
	ArrayHash *self
 CODE:
	/* XXXrcd: hmmm, need to do better than this... */
	RETVAL = self->banner;
 OUTPUT:
	RETVAL

int
ArrayHash_bannerMatches(self, banner)
	ArrayHash	*self
	SV		*banner
 CODE:
	/* XXXrcd: hmmm, do a comparison? */
	RETVAL = 1;
 OUTPUT:
	RETVAL

int
ArrayHash_append(self, input)
	ArrayHash	*self
	SV		*input
 INIT:
	char	*in;
	STRLEN	 len;
 CODE:
	in = SvPV(input, len);
	if (!in)
		croak("append method requires a defined scalar");
	RETVAL = parse_append(self, in, len);
 OUTPUT:
	RETVAL

void
ArrayHash_Reset(self)
	ArrayHash	*self
CODE:
	// fprintf(stderr, "Reset xs entry\n");
	parse_reset(self);

SV *
ArrayHash_Encode(self, code, ...)
	ArrayHash	*self
	int		 code
 INIT:
        char			 buf[8192];
	int			 i;
	int			 len;
	struct encode_state	*st;
	SV			*ret;
 CODE:
	/* XXXrcd: this encodes over itself, just testing */
	ret = newSVpvn(buf, 0);
	for (i=2; i < items; i++) {
		st = encode_init(ST(i), CTX_SPACE);
		snprintf(buf, sizeof(buf), "%03d %c ", code,
		    i==(items-1)?'.':'-');
		sv_catpvn(ret, buf, (STRLEN) strlen(buf));
		for (;;) {
			len = encode(&st, buf, sizeof(buf));
			sv_catpvn(ret, buf, (STRLEN) len);
			if (len < sizeof(buf))
				break;
		}
		snprintf(buf, sizeof(buf), "\r\n", code);
		sv_catpvn(ret, buf, (STRLEN) strlen(buf));
	}
        RETVAL = ret;
 OUTPUT:
        RETVAL

SV *
ArrayHash_Marshall(self, cmd)
	ArrayHash	*self
	SV		*cmd
 INIT:
	struct encode_state	*st;
        char			 buf[8192];
	int			 len;
	SV	*ret;
 CODE:
	ret = newSVpvn(buf, 0);
	st = marshall_init(cmd);
	for (;;) {
		len = encode(&st, buf, sizeof(buf));
		sv_catpvn(ret, buf, (STRLEN) len);
		if (len < sizeof(buf))
			break;
	}
	sv_catpvn(ret, "\n", 1);
	RETVAL = ret;
 OUTPUT:
	RETVAL

SV *
ArrayHash_Unmarshall(self, line)
	ArrayHash	*self
	char		*line
 PPCODE:
	/* XXXrcd: line should not be a char... */
	unmarshall(self, line, strlen(line));
	if (!self->done)
		croak("Parsing is not complete");
	if (!self->results)
		croak("No results are available, yet");
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(*self->results));
	*self->results = NULL;

SV *
ArrayHash_Parse(self)
        ArrayHash	*self
 PPCODE:  
//	fprintf(stderr, "self = %p\n", self);
//	fprintf(stderr, "self->code     = %d\n", self->code);
//	fprintf(stderr, "self->st       = %p\n", self->st);
//	fprintf(stderr, "self->results  = %p\n", self->results);
//	fprintf(stderr, "*self->results = %p\n", *self->results);
	if (!self->done)
		croak("Parsing is not complete");
	if (!self->results)
		croak("No results are available, yet");
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv(self->code)));
	PUSHs(sv_2mortal(*self->results));
	*self->results = NULL;
