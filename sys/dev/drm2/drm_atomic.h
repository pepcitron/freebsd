/**
 * \file drm_atomic.h
 * Atomic operations used in the DRM which may or may not be provided by the OS.
 * 
 * \author Eric Anholt <anholt@FreeBSD.org>
 */

/*-
 * Copyright 2004 Eric Anholt
 * All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * VA LINUX SYSTEMS AND/OR ITS SUPPLIERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#include <sys/cdefs.h>
__FBSDID("$FreeBSD$");

/* Many of these implementations are rather fake, but good enough. */

typedef u_int32_t atomic_t;
typedef u_int64_t atomic64_t;

#define atomic_set(p, v)	(*(p) = (v))
#define atomic_read(p)		(*(p))
#define atomic_inc(p)		atomic_add_int(p, 1)
#define atomic_dec(p)		atomic_subtract_int(p, 1)
#define atomic_add(n, p)	atomic_add_int(p, n)
#define atomic_sub(n, p)	atomic_subtract_int(p, n)

static __inline atomic_t
test_and_set_bit(int b, volatile void *p)
{
	long bit, val;

	bit = 1 << b;
	do {
		val = *(volatile long *)p;
	} while (atomic_cmpset_long(p, val, val | bit) == 0);

	return ((val & bit) != 0);
}

static __inline void
clear_bit(int b, volatile void *p)
{
	atomic_clear_int(((volatile int *)p) + (b >> 5), 1 << (b & 0x1f));
}

static __inline void
set_bit(int b, volatile void *p)
{
	atomic_set_int(((volatile int *)p) + (b >> 5), 1 << (b & 0x1f));
}

static __inline int
test_bit(int b, volatile void *p)
{
	return ((volatile int *)p)[b >> 5] & (1 << (b & 0x1f));
}

static __inline int
find_first_zero_bit(volatile void *p, int max)
{
	int b;
	volatile int *ptr = (volatile int *)p;

	for (b = 0; b < max; b += 32) {
		if (ptr[b >> 5] != ~0) {
			for (;;) {
				if ((ptr[b >> 5] & (1 << (b & 0x1f))) == 0)
					return b;
				b++;
			}
		}
	}
	return max;
}

static __inline int
atomic_xchg(volatile int *p, int new)
{
	int old;

	do {
		old = *p;
	} while(!atomic_cmpset_int(p, old, new));

	return (old);
}

static __inline uint64_t
atomic64_xchg(volatile uint64_t *p, uint64_t new)
{
	uint64_t old;

	do {
		old = *p;
	} while(!atomic_cmpset_64(p, old, new));

	return (old);
}

static __inline int
atomic_add_return(int i, atomic_t *p)
{

	return i + atomic_fetchadd_int(p, i);
}

static __inline int
atomic_sub_return(int i, atomic_t *p)
{

	return atomic_fetchadd_int(p, -i) - i;
}

#define	atomic_inc_return(v)		atomic_add_return(1, (v))
#define	atomic_dec_return(v)		atomic_sub_return(1, (v))

#define	atomic_sub_and_test(i, v)	(atomic_sub_return((i), (v)) == 0)
#define	atomic_dec_and_test(v)		(atomic_dec_return(v) == 0)
#define	atomic_inc_and_test(v)		(atomic_inc_return(v) == 0)

#define	BITS_TO_LONGS(x) (howmany((x), NBBY * sizeof(long)))
