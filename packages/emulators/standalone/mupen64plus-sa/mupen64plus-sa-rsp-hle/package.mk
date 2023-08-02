# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 Nicholas Ricciuti (rishooty@gmail.com)
# Copyright (C) 2023 Fewtarius (fewtarius@jelos.org)

PKG_NAME="mupen64plus-sa-rsp-hle"
PKG_VERSION="f22dc143771f1a0784c7d62977722a68fa0bdf85"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/mupen64plus/mupen64plus-rsp-hle"
PKG_URL="https://github.com/mupen64plus/mupen64plus-rsp-hle/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plus-sa-core"
PKG_SHORTDESC="mupen64plus-rsp-hle"
PKG_LONGDESC="Mupen64Plus Standalone RSP HLE"
PKG_TOOLCHAIN="manual"

case ${DEVICE} in
  AMD64|RK3588|S922X)
    PKG_DEPENDS_TARGET+=" mupen64plus-sa-simplecore"
  ;;
esac

if [ "${OPENGL_SUPPORT}" = "yes" ]
then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
else
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

make_target() {
  if [ "${OPENGL_SUPPORT}" = "yes" ]
  then
    export USE_GLES=0
  else
    export USE_GLES=1
  fi

  export HOST_CPU=${TARGET_ARCH} \
         VFP_HARD=1 \
         NEW_DYNAREC=1 \
         V=1 \
         VC=0 \
         OSD=0

  export BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  export APIDIR=$(get_build_dir mupen64plus-sa-core)/src/api
  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -pthread -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="${TARGET_PREFIX}"

  make -C projects/unix clean
  make -C projects/unix all ${PKG_MAKE_OPTS_TARGET}
  cp ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle.so ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle-base.so

  case ${DEVICE} in
    AMD64|RK3588|S922X)
      export APIDIR=$(get_build_dir mupen64plus-sa-simple64)/src/api
      make -C projects/unix all ${PKG_MAKE_OPTS_TARGET}
      cp ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle.so ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle-simple.so
    ;;
  esac
}

makeinstall_target() {
  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib
  UPLUGINDIR=${ULIBDIR}/mupen64plus
  mkdir -p ${UPLUGINDIR}
  cp ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle-base.so ${UPLUGINDIR}/mupen64plus-rsp-hle.so
  chmod 0644 ${UPLUGINDIR}/mupen64plus-rsp-hle.so

  if [ -e "${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle-simple.so" ]
  then
    cp ${PKG_BUILD}/projects/unix/mupen64plus-rsp-hle-simple.so ${UPLUGINDIR}
    chmod 0644 ${UPLUGINDIR}/mupen64plus-rsp-hle-simple.so
  fi
}

