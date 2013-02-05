# $FreeBSD$

.PATH:	${.CURDIR}/../../../dev/drm2/radeon

KMOD	= radeonkms
SRCS	=								\
	radeon_acpi.c							\
	radeon_asic.c							\
	radeon_atombios.c						\
	radeon_benchmark.c						\
	radeon_bios.c							\
	radeon_combios.c						\
	radeon_device.c							\
	radeon_display.c						\
	radeon_drv.c							\
	radeon_fb.c							\
	radeon_gem.c							\
	radeon_i2c.c							\
	radeon_kms.c							\
	radeon_pm.c							\
	radeon_ring.c							\
	radeon_test.c							\
	radeon_ttm.c							\
	atom.c								\
	atombios_crtc.c							\
	atombios_encoders.c						\
	cayman_reg_safe.h						\
	cayman_blit_shaders.c						\
	evergreen_reg_safe.h						\
	evergreen.c							\
	evergreen_blit_kms.c						\
	evergreen_blit_shaders.c					\
	evergreen_cs.c							\
	evergreen_hdmi.c

#	atombios_dp.c							\
#	atombios_i2c.c							\

SRCS	+=								\
	opt_acpi.h							\
	opt_compat.h							\
	opt_drm.h							\
	acpi_if.h							\
	bus_if.h							\
	device_if.h							\
	pci_if.h
#SRCS	+= iicbus_if.h iicbb_if.h

CFLAGS  += -I${.CURDIR}/../../../dev/drm2/radeon

MKREGTABLE=	./mkregtable
REG_SRCS_DIR=	${.CURDIR}/../../../dev/drm2/radeon/reg_srcs

cayman_reg_safe.h: ${REG_SRCS_DIR}/cayman ${MKREGTABLE}
	${MKREGTABLE} ${REG_SRCS_DIR}/cayman > $@

evergreen_reg_safe.h: ${REG_SRCS_DIR}/evergreen ${MKREGTABLE}
	${MKREGTABLE} ${REG_SRCS_DIR}/evergreen > $@

.include <bsd.kmod.mk>
