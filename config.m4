dnl $Id$
dnl config.m4 for extension swoole

dnl Comments in this file start with the string 'dnl'.
dnl Remove where necessary. This file will not work
dnl without editing.

dnl If your extension references something external, use with:

dnl Otherwise use enable:

PHP_ARG_ENABLE(swoole-debug, whether to enable swoole debug,
[  --enable-swoole-debug   Enable swoole debug], no, no)

PHP_ARG_ENABLE(msgqueue, set ipc mode,
[  --enable-msgqueue       Use message queue?], no, no)

PHP_ARG_ENABLE(sockets, enable sockets support,
[  --enable-sockets        Do you have sockets extension?], no, no)

PHP_ARG_ENABLE(ringbuffer, enable ringbuffer shared memory pool support,
[  --enable-ringbuffer     Use ringbuffer memory pool?], no, no)

PHP_ARG_ENABLE(async_mysql, enable async_mysql support,
[  --enable-async-mysql    Do you have mysqli and mysqlnd?], no, no)

PHP_ARG_ENABLE(openssl, enable openssl support,
[  --enable-openssl        Use openssl?], no, no)

PHP_ARG_WITH(swoole, swoole support,
[  --with-swoole           Include swoole support])

AC_DEFUN([SWOOLE_HAVE_PHP_EXT], [
    extname=$1
    haveext=$[PHP_]translit($1,a-z_-,A-Z__)
    
    AC_MSG_CHECKING([for ext/$extname support])
    if test -x "$PHP_EXECUTABLE"; then
        grepext=`$PHP_EXECUTABLE -m | $EGREP ^$extname\$`
        if test "$grepext" = "$extname"; then
            [PHP_HTTP_HAVE_EXT_]translit($1,a-z_-,A-Z__)=1
            AC_MSG_RESULT([yes])
            $2
        else
            [PHP_HTTP_HAVE_EXT_]translit($1,a-z_-,A-Z__)=
            AC_MSG_RESULT([no])
            $3
        fi
    elif test "$haveext" != "no" && test "x$haveext" != "x"; then
        [PHP_HTTP_HAVE_EXT_]translit($1,a-z_-,A-Z__)=1
        AC_MSG_RESULT([yes])
        $2
    else
        [PHP_HTTP_HAVE_EXT_]translit($1,a-z_-,A-Z__)=
        AC_MSG_RESULT([no])
        $3
    fi
])

AC_DEFUN([AC_SWOOLE_CPU_AFFINITY],
[
    AC_MSG_CHECKING([for cpu affinity])
    AC_TRY_COMPILE(
    [
		#include <sched.h>
    ], [
		cpu_set_t cpu_set;
		CPU_ZERO(&cpu_set);
    ], [
        AC_DEFINE([HAVE_CPU_AFFINITY], 1, [cpu affinity?])
        AC_MSG_RESULT([yes])
    ], [
        AC_MSG_RESULT([no])
    ])
])

AC_MSG_CHECKING([if compiling with clang])
AC_COMPILE_IFELSE([
    AC_LANG_PROGRAM([], [[
        #ifndef __clang__
            not clang
        #endif
    ]])],
    [CLANG=yes], [CLANG=no]
)
AC_MSG_RESULT([$CLANG])

if test "$CLANG" = "yes"; then
    CFLAGS="$CFLAGS -std=gnu89"
fi

if test "$PHP_SWOOLE" != "no"; then
    PHP_ADD_INCLUDE($SWOOLE_DIR/include)
    PHP_ADD_LIBRARY(pthread)
    PHP_SUBST(SWOOLE_SHARED_LIBADD)

    AC_ARG_ENABLE(debug, 
        [--enable-debug,  compile with debug symbols],
        [PHP_DEBUG=$enableval],
        [PHP_DEBUG=0]
    )
  
    if test "$PHP_SWOOLE_DEBUG" != "no"; then
        AC_DEFINE(SW_DEBUG, 1, [do we enable swoole debug])
    fi
    
    if test "$PHP_MYSQLI" = "yes"; then
		AC_DEFINE(HAVE_MYSQLI, 1, [have mysqli extension])
    fi

    if test "$PHP_MYSQLND" = "yes"; then
		AC_DEFINE(HAVE_MYSQLND, 1, [have mysqlnd extension])
    fi

    if test "$PHP_SOCKETS" = "yes"; then
		AC_DEFINE(SW_SOCKETS, 1, [enable sockets support])
    fi

    if test "$PHP_RINGBUFFER" = "yes"; then
		AC_DEFINE(SW_USE_RINGBUFFER, 1, [enable ringbuffer support])
    fi

	if test "$PHP_ASYNC_MYSQL" = "yes"; then
		AC_DEFINE(SW_ASYNC_MYSQL, 1, [enable async_mysql support])
    fi
    
    if test "$PHP_MSGQUEUE" != "no"; then
        AC_DEFINE(SW_WORKER_IPC_MODE, 2, [use message queue])
    else
        AC_DEFINE(SW_WORKER_IPC_MODE, 1, [use unix socket])
    fi
        
    AC_SWOOLE_CPU_AFFINITY
    
    SWOOLE_HAVE_PHP_EXT([mysqli], [
        AC_DEFINE(SW_HAVE_MYSQLI, 1, [have mysqli])
    ])

    SWOOLE_HAVE_PHP_EXT([mysqlnd], [
        AC_DEFINE(SW_HAVE_MYSQLND, 1, [have mysqlnd])
    ])

    CFLAGS="-Wall -pthread $CFLAGS"
    LDFLAGS="$LDFLAGS -lpthread"
  
    AC_CHECK_LIB(c, accept4, AC_DEFINE(SW_USE_ACCEPT4, 1, [have accept4]))
    AC_CHECK_LIB(c, signalfd, AC_DEFINE(HAVE_SIGNALFD, 1, [have signalfd]))
    AC_CHECK_LIB(c, timerfd_create, AC_DEFINE(HAVE_TIMERFD, 1, [have timerfd]))
    AC_CHECK_LIB(c, eventfd, AC_DEFINE(HAVE_EVENTFD, 1, [have eventfd]))
    AC_CHECK_LIB(c, epoll_create, AC_DEFINE(HAVE_EPOLL, 1, [have epoll]))
    AC_CHECK_LIB(c, kqueue, AC_DEFINE(HAVE_KQUEUE, 1, [have kqueue]))
    AC_CHECK_LIB(c, daemon, AC_DEFINE(HAVE_DAEMON, 1, [have daemon]))
    AC_CHECK_LIB(c, mkostemp, AC_DEFINE(HAVE_MKOSTEMP, 1, [have mkostemp]))
    AC_CHECK_LIB(pthread, pthread_rwlock_init, AC_DEFINE(HAVE_RWLOCK, 1, [have pthread_rwlock_init]))
    AC_CHECK_LIB(pthread, pthread_spin_lock, AC_DEFINE(HAVE_SPINLOCK, 1, [have pthread_spin_lock]))
    AC_CHECK_LIB(ssl, SSL_library_init, AC_DEFINE(HAVE_OPENSSL, 1, [have openssl]))

    if test `uname` = "Darwin" ; then
        AC_CHECK_LIB(c, clock_gettime, AC_DEFINE(HAVE_CLOCK_GETTIME, 1, [have clock_gettime]))
        AC_CHECK_LIB(c, aio_read, AC_DEFINE(HAVE_GCC_AIO, 1, [have gcc aio]))
    else
        AC_CHECK_LIB(rt, clock_gettime, AC_DEFINE(HAVE_CLOCK_GETTIME, 1, [have clock_gettime]))
        AC_CHECK_LIB(rt, aio_read, AC_DEFINE(HAVE_GCC_AIO, 1, [have gcc aio]))
        PHP_ADD_LIBRARY(rt, 1, SWOOLE_SHARED_LIBADD)
    fi


    PHP_ADD_LIBRARY(pthread, 1, SWOOLE_SHARED_LIBADD)

    if test "$PHP_OPENSSL" = "yes"; then
        AC_DEFINE(SW_USE_OPENSSL, 1, [enable openssl support])
        PHP_ADD_LIBRARY(ssl, 1, SWOOLE_SHARED_LIBADD)
        PHP_ADD_LIBRARY(crypt, 1, SWOOLE_SHARED_LIBADD)
        PHP_ADD_LIBRARY(crypto, 1, SWOOLE_SHARED_LIBADD)
    fi

    PHP_NEW_EXTENSION(swoole, swoole.c \
        swoole_lock.c \
        swoole_client.c \
        swoole_async.c \
        swoole_process.c \
        swoole_buffer.c \
        swoole_table.c \
        src/core/Base.c \
        src/core/log.c \
        src/core/hashmap.c \
        src/core/RingQueue.c \
        src/core/Channel.c \
        src/core/string.c \
        src/core/array.c \
        src/memory/ShareMemory.c \
        src/memory/MemoryGlobal.c \
        src/memory/RingBuffer.c \
        src/memory/FixedPool.c \
        src/memory/Table.c \
        src/factory/Factory.c \
        src/factory/FactoryThread.c \
        src/factory/FactoryProcess.c \
        src/reactor/ReactorBase.c \
        src/reactor/ReactorSelect.c \
        src/reactor/ReactorPoll.c \
        src/reactor/ReactorEpoll.c \
        src/reactor/ReactorKqueue.c \
        src/pipe/PipeBase.c \
        src/pipe/PipeEventfd.c \
        src/pipe/PipeUnsock.c \
        src/queue/Msg.c \
        src/lock/Semaphore.c \
        src/lock/Mutex.c \
        src/lock/RWLock.c \
        src/lock/SpinLock.c \
        src/lock/FileLock.c \
        src/network/Server.c \
        src/network/TaskWorker.c \
        src/network/Client.c \
        src/network/Buffer.c \
        src/network/Connection.c \
        src/network/ProcessPool.c \
        src/network/ThreadPool.c \
        src/network/ReactorThread.c \
        src/network/ReactorProcess.c \
        src/network/Worker.c \
        src/os/base.c \
        src/os/linux_aio.c \
        src/os/gcc_aio.c \
        src/os/sendfile.c \
        src/os/signal.c \
        src/os/timer.c \
        src/protocol/SSL.c \
        src/protocol/Http.c \
      , $ext_shared)
      
    PHP_ADD_INCLUDE([$ext_srcdir/include])
    PHP_ADD_BUILD_DIR($ext_builddir/src/core)
    PHP_ADD_BUILD_DIR($ext_builddir/src/memory)
    PHP_ADD_BUILD_DIR($ext_builddir/src/factory)
    PHP_ADD_BUILD_DIR($ext_builddir/src/reactor)
    PHP_ADD_BUILD_DIR($ext_builddir/src/pipe)
    PHP_ADD_BUILD_DIR($ext_builddir/src/queue)
    PHP_ADD_BUILD_DIR($ext_builddir/src/lock)
    PHP_ADD_BUILD_DIR($ext_builddir/src/os)
    PHP_ADD_BUILD_DIR($ext_builddir/src/network)
    PHP_ADD_BUILD_DIR($ext_builddir/src/protocol)
fi

