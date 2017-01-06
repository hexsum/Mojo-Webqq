# This Makefile is for the Mojo::Webqq extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.16 (Revision: 71600) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[A Smartqq Client Framework base on Mojolicious]
#     AUTHOR => [q[sjdy521 <sjdy521@163.com>]]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => {  }
#     DISTNAME => q[Mojo-Webqq]
#     LICENSE => q[perl]
#     META_MERGE => { meta-spec=>{ version=>q[2] }, resources=>{ repository=>{ type=>q[git], url=>q[git://github.com/sjdy521/Mojo-Webqq.git], web=>q[https://github.com/sjdy521/Mojo-Webqq] } } }
#     NAME => q[Mojo::Webqq]
#     PREREQ_PM => { Digest::MD5=>q[0], Encode::Locale=>q[0], IO::Socket::SSL=>q[1.94], Mojolicious=>q[6.11], Time::HiRes=>q[0], Time::Piece=>q[0], Time::Seconds=>q[0] }
#     TEST_REQUIRES => {  }
#     VERSION_FROM => q[lib/Mojo/Webqq.pm]
#     clean => { FILES=>q[Mojo-Webqq-* MANIFEST] }
#     dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = libc-2.12.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.6.32-431.el6.x86_64
RANLIB = :
SITELIBEXP = /home/lz/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4
SITEARCHEXP = /home/lz/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/x86_64-linux
SO = so
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Mojo::Webqq
NAME_SYM = Mojo_Webqq
VERSION = 1.8.9
VERSION_MACRO = VERSION
VERSION_SYM = 1_8_9
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 1.8.9
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /home/lz/.plenv/versions/5.18.4
SITEPREFIX = /home/lz/.plenv/versions/5.18.4
VENDORPREFIX = 
INSTALLPRIVLIB = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /home/lz/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /home/lz/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/x86_64-linux
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /home/lz/.plenv/versions/5.18.4/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /home/lz/.plenv/versions/5.18.4/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /home/lz/.plenv/versions/5.18.4/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /home/lz/.plenv/versions/5.18.4/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = 
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /home/lz/.plenv/versions/5.18.4/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /home/lz/.plenv/versions/5.18.4/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /home/lz/.plenv/versions/5.18.4/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /home/lz/.plenv/versions/5.18.4/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4
PERL_ARCHLIB = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux
PERL_ARCHLIBDEP = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux/CORE
PERL_INCDEP = /home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux/CORE
PERL = "/home/lz/.plenv/versions/5.18.4/bin/perl5.18.4"
FULLPERL = "/home/lz/.plenv/versions/5.18.4/bin/perl5.18.4"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /home/lz/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.16
MM_REVISION = 71600

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = Mojo/Webqq
BASEEXT = Webqq
PARENT_NAME = Mojo
DLBASE = $(BASEEXT)
VERSION_FROM = lib/Mojo/Webqq.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/Mojo/Webqq.pod \
	lib/Mojo/Webqq/Plugin/IPwhere.pm \
	lib/Mojo/Webqq/Plugin/ProgramCode.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/Mojo
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/Mojo

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/Mojo/Webqq.pm \
	lib/Mojo/Webqq.pod \
	lib/Mojo/Webqq/Base.pm \
	lib/Mojo/Webqq/Cache.pm \
	lib/Mojo/Webqq/Client.pm \
	lib/Mojo/Webqq/Client/Cron.pm \
	lib/Mojo/Webqq/Client/Remote/_check_sig.pm \
	lib/Mojo/Webqq/Client/Remote/_check_verify_code.pm \
	lib/Mojo/Webqq/Client/Remote/_cookie_proxy.pm \
	lib/Mojo/Webqq/Client/Remote/_get_group_pic.pm \
	lib/Mojo/Webqq/Client/Remote/_get_img_verify_code.pm \
	lib/Mojo/Webqq/Client/Remote/_get_offpic.pm \
	lib/Mojo/Webqq/Client/Remote/_get_qrlogin_pic.pm \
	lib/Mojo/Webqq/Client/Remote/_get_vfwebqq.pm \
	lib/Mojo/Webqq/Client/Remote/_login1.pm \
	lib/Mojo/Webqq/Client/Remote/_login2.pm \
	lib/Mojo/Webqq/Client/Remote/_prepare_for_login.pm \
	lib/Mojo/Webqq/Client/Remote/_recv_message.pm \
	lib/Mojo/Webqq/Client/Remote/_relink.pm \
	lib/Mojo/Webqq/Client/Remote/change_state.pm \
	lib/Mojo/Webqq/Client/Remote/logout.pm \
	lib/Mojo/Webqq/Counter.pm \
	lib/Mojo/Webqq/Discuss.pm \
	lib/Mojo/Webqq/Discuss/Member.pm \
	lib/Mojo/Webqq/Friend.pm \
	lib/Mojo/Webqq/Group.pm \
	lib/Mojo/Webqq/Group/Member.pm \
	lib/Mojo/Webqq/Log.pm \
	lib/Mojo/Webqq/Message.pm \
	lib/Mojo/Webqq/Message/Base.pm \
	lib/Mojo/Webqq/Message/Emoji.pm \
	lib/Mojo/Webqq/Message/Face.pm \
	lib/Mojo/Webqq/Message/Handle.pm \
	lib/Mojo/Webqq/Message/Queue.pm \
	lib/Mojo/Webqq/Message/Remote/_get_sess_sig.pm \
	lib/Mojo/Webqq/Message/Remote/_send_discuss_message.pm \
	lib/Mojo/Webqq/Message/Remote/_send_friend_message.pm \
	lib/Mojo/Webqq/Message/Remote/_send_group_message.pm \
	lib/Mojo/Webqq/Message/Remote/_send_sess_message.pm \
	lib/Mojo/Webqq/Message/XMLescape.pm \
	lib/Mojo/Webqq/Model.pm \
	lib/Mojo/Webqq/Model/Base.pm \
	lib/Mojo/Webqq/Model/Remote/_get_discuss_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_discuss_list_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_friend_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_friends_state.pm \
	lib/Mojo/Webqq/Model/Remote/_get_group_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_group_info_ext.pm \
	lib/Mojo/Webqq/Model/Remote/_get_group_list_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_group_list_info_ext.pm \
	lib/Mojo/Webqq/Model/Remote/_get_recent_info.pm \
	lib/Mojo/Webqq/Model/Remote/_get_user_friends.pm \
	lib/Mojo/Webqq/Model/Remote/_get_user_friends_ext.pm \
	lib/Mojo/Webqq/Model/Remote/_get_user_info.pm \
	lib/Mojo/Webqq/Model/Remote/_invite_friend.pm \
	lib/Mojo/Webqq/Model/Remote/_kick_group_member.pm \
	lib/Mojo/Webqq/Model/Remote/_qiandao.pm \
	lib/Mojo/Webqq/Model/Remote/_remove_group_admin.pm \
	lib/Mojo/Webqq/Model/Remote/_set_group_admin.pm \
	lib/Mojo/Webqq/Model/Remote/_set_group_member_card.pm \
	lib/Mojo/Webqq/Model/Remote/_shutup_group_member.pm \
	lib/Mojo/Webqq/Model/Remote/get_qq_from_id.pm \
	lib/Mojo/Webqq/Model/Remote/get_single_long_nick.pm \
	lib/Mojo/Webqq/Plugin.pm \
	lib/Mojo/Webqq/Plugin/FuckAndroid.pm \
	lib/Mojo/Webqq/Plugin/FuckDaShen.pm \
	lib/Mojo/Webqq/Plugin/GasPrice.pm \
	lib/Mojo/Webqq/Plugin/GroupManage.pm \
	lib/Mojo/Webqq/Plugin/IPwhere.pm \
	lib/Mojo/Webqq/Plugin/IRCShell.pm \
	lib/Mojo/Webqq/Plugin/KnowledgeBase.pm \
	lib/Mojo/Webqq/Plugin/LCMD.pm \
	lib/Mojo/Webqq/Plugin/MobileInfo.pm \
	lib/Mojo/Webqq/Plugin/Openqq.pm \
	lib/Mojo/Webqq/Plugin/Perlcode.pm \
	lib/Mojo/Webqq/Plugin/Perldoc.pm \
	lib/Mojo/Webqq/Plugin/PostImgVerifycode.pm \
	lib/Mojo/Webqq/Plugin/PostQRcode.pm \
	lib/Mojo/Webqq/Plugin/ProgramCode.pm \
	lib/Mojo/Webqq/Plugin/Pu.pm \
	lib/Mojo/Webqq/Plugin/Qiandao.pm \
	lib/Mojo/Webqq/Plugin/Riddle.pm \
	lib/Mojo/Webqq/Plugin/ShowMsg.pm \
	lib/Mojo/Webqq/Plugin/ShowQRcode.pm \
	lib/Mojo/Webqq/Plugin/SmartReply.pm \
	lib/Mojo/Webqq/Plugin/StockInfo.pm \
	lib/Mojo/Webqq/Plugin/Translation.pm \
	lib/Mojo/Webqq/Plugin/UploadQRcode.pm \
	lib/Mojo/Webqq/Plugin/UploadQRcode2.pm \
	lib/Mojo/Webqq/Plugin/ZiYue.pm \
	lib/Mojo/Webqq/Recent/Discuss.pm \
	lib/Mojo/Webqq/Recent/Friend.pm \
	lib/Mojo/Webqq/Recent/Group.pm \
	lib/Mojo/Webqq/Request.pm \
	lib/Mojo/Webqq/Run.pm \
	lib/Mojo/Webqq/Server.pm \
	lib/Mojo/Webqq/User.pm \
	lib/Mojo/Webqq/Util.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.16
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip -9f
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Mojo-Webqq
DISTVNAME = Mojo-Webqq-1.8.9


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='$(INC) $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	lib/Mojo/Webqq.pod \
	lib/Mojo/Webqq/Plugin/IPwhere.pm \
	lib/Mojo/Webqq/Plugin/ProgramCode.pm
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) -u \
	  lib/Mojo/Webqq.pod $(INST_MAN3DIR)/Mojo::Webqq.$(MAN3EXT) \
	  lib/Mojo/Webqq/Plugin/IPwhere.pm $(INST_MAN3DIR)/Mojo::Webqq::Plugin::IPwhere.$(MAN3EXT) \
	  lib/Mojo/Webqq/Plugin/ProgramCode.pm $(INST_MAN3DIR)/Mojo::Webqq::Plugin::ProgramCode.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  MANIFEST Mojo-Webqq-* \
	  blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''A Smartqq Client Framework base on Mojolicious'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''sjdy521 <sjdy521@163.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.16, CPAN::Meta::Converter version 2.143240'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: Mojo-Webqq' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Digest::MD5: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Encode::Locale: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Socket::SSL: '\''1.94'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Mojolicious: '\''6.11'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::HiRes: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::Piece: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::Seconds: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'resources:' >> META_new.yml
	$(NOECHO) $(ECHO) '  repository: git://github.com/sjdy521/Mojo-Webqq.git' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: v1.8.9' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "A Smartqq Client Framework base on Mojolicious",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "sjdy521 <sjdy521@163.com>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.16, CPAN::Meta::Converter version 2.143240",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "perl_5"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : "2"' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "Mojo-Webqq",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Digest::MD5" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Encode::Locale" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Socket::SSL" : "1.94",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Mojolicious" : "6.11",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::HiRes" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::Piece" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::Seconds" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "resources" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "repository" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "type" : "git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "url" : "git://github.com/sjdy521/Mojo-Webqq.git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/sjdy521/Mojo-Webqq"' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "v1.8.9"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist"

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist"


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "/home/lz/.plenv/versions/5.18.4/bin/perl5.18.4"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4/x86_64-linux" "-I/home/lz/.plenv/versions/5.18.4/lib/perl5/5.18.4"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="Mojo-Webqq" VERSION="1.8.9">' > Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>A Smartqq Client Framework base on Mojolicious</ABSTRACT>' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>sjdy521 &lt;sjdy521@163.com&gt;</AUTHOR>' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Digest::MD5" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Encode::Locale" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IO::Socket::SSL" VERSION="1.94" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Mojolicious::" VERSION="6.11" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::HiRes" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::Piece" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::Seconds" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-5.18" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> Mojo-Webqq.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> Mojo-Webqq.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Mojo/Webqq.pm' 'blib/lib/Mojo/Webqq.pm' \
	  'lib/Mojo/Webqq.pod' 'blib/lib/Mojo/Webqq.pod' \
	  'lib/Mojo/Webqq/Base.pm' 'blib/lib/Mojo/Webqq/Base.pm' \
	  'lib/Mojo/Webqq/Cache.pm' 'blib/lib/Mojo/Webqq/Cache.pm' \
	  'lib/Mojo/Webqq/Client.pm' 'blib/lib/Mojo/Webqq/Client.pm' \
	  'lib/Mojo/Webqq/Client/Cron.pm' 'blib/lib/Mojo/Webqq/Client/Cron.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_check_sig.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_check_sig.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_check_verify_code.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_check_verify_code.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_cookie_proxy.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_cookie_proxy.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_get_group_pic.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_get_group_pic.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_get_img_verify_code.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_get_img_verify_code.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_get_offpic.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_get_offpic.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_get_qrlogin_pic.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_get_qrlogin_pic.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_get_vfwebqq.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_get_vfwebqq.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_login1.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_login1.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_login2.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_login2.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_prepare_for_login.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_prepare_for_login.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_recv_message.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_recv_message.pm' \
	  'lib/Mojo/Webqq/Client/Remote/_relink.pm' 'blib/lib/Mojo/Webqq/Client/Remote/_relink.pm' \
	  'lib/Mojo/Webqq/Client/Remote/change_state.pm' 'blib/lib/Mojo/Webqq/Client/Remote/change_state.pm' \
	  'lib/Mojo/Webqq/Client/Remote/logout.pm' 'blib/lib/Mojo/Webqq/Client/Remote/logout.pm' \
	  'lib/Mojo/Webqq/Counter.pm' 'blib/lib/Mojo/Webqq/Counter.pm' \
	  'lib/Mojo/Webqq/Discuss.pm' 'blib/lib/Mojo/Webqq/Discuss.pm' \
	  'lib/Mojo/Webqq/Discuss/Member.pm' 'blib/lib/Mojo/Webqq/Discuss/Member.pm' \
	  'lib/Mojo/Webqq/Friend.pm' 'blib/lib/Mojo/Webqq/Friend.pm' \
	  'lib/Mojo/Webqq/Group.pm' 'blib/lib/Mojo/Webqq/Group.pm' \
	  'lib/Mojo/Webqq/Group/Member.pm' 'blib/lib/Mojo/Webqq/Group/Member.pm' \
	  'lib/Mojo/Webqq/Log.pm' 'blib/lib/Mojo/Webqq/Log.pm' \
	  'lib/Mojo/Webqq/Message.pm' 'blib/lib/Mojo/Webqq/Message.pm' \
	  'lib/Mojo/Webqq/Message/Base.pm' 'blib/lib/Mojo/Webqq/Message/Base.pm' \
	  'lib/Mojo/Webqq/Message/Emoji.pm' 'blib/lib/Mojo/Webqq/Message/Emoji.pm' \
	  'lib/Mojo/Webqq/Message/Face.pm' 'blib/lib/Mojo/Webqq/Message/Face.pm' \
	  'lib/Mojo/Webqq/Message/Handle.pm' 'blib/lib/Mojo/Webqq/Message/Handle.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Mojo/Webqq/Message/Queue.pm' 'blib/lib/Mojo/Webqq/Message/Queue.pm' \
	  'lib/Mojo/Webqq/Message/Remote/_get_sess_sig.pm' 'blib/lib/Mojo/Webqq/Message/Remote/_get_sess_sig.pm' \
	  'lib/Mojo/Webqq/Message/Remote/_send_discuss_message.pm' 'blib/lib/Mojo/Webqq/Message/Remote/_send_discuss_message.pm' \
	  'lib/Mojo/Webqq/Message/Remote/_send_friend_message.pm' 'blib/lib/Mojo/Webqq/Message/Remote/_send_friend_message.pm' \
	  'lib/Mojo/Webqq/Message/Remote/_send_group_message.pm' 'blib/lib/Mojo/Webqq/Message/Remote/_send_group_message.pm' \
	  'lib/Mojo/Webqq/Message/Remote/_send_sess_message.pm' 'blib/lib/Mojo/Webqq/Message/Remote/_send_sess_message.pm' \
	  'lib/Mojo/Webqq/Message/XMLescape.pm' 'blib/lib/Mojo/Webqq/Message/XMLescape.pm' \
	  'lib/Mojo/Webqq/Model.pm' 'blib/lib/Mojo/Webqq/Model.pm' \
	  'lib/Mojo/Webqq/Model/Base.pm' 'blib/lib/Mojo/Webqq/Model/Base.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_discuss_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_discuss_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_discuss_list_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_discuss_list_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_friend_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_friend_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_friends_state.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_friends_state.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_group_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_group_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_group_info_ext.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_group_info_ext.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_group_list_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_group_list_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_group_list_info_ext.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_group_list_info_ext.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_recent_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_recent_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_user_friends.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_user_friends.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_user_friends_ext.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_user_friends_ext.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_get_user_info.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_get_user_info.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_invite_friend.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_invite_friend.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_kick_group_member.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_kick_group_member.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_qiandao.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_qiandao.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_remove_group_admin.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_remove_group_admin.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Mojo/Webqq/Model/Remote/_set_group_admin.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_set_group_admin.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_set_group_member_card.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_set_group_member_card.pm' \
	  'lib/Mojo/Webqq/Model/Remote/_shutup_group_member.pm' 'blib/lib/Mojo/Webqq/Model/Remote/_shutup_group_member.pm' \
	  'lib/Mojo/Webqq/Model/Remote/get_qq_from_id.pm' 'blib/lib/Mojo/Webqq/Model/Remote/get_qq_from_id.pm' \
	  'lib/Mojo/Webqq/Model/Remote/get_single_long_nick.pm' 'blib/lib/Mojo/Webqq/Model/Remote/get_single_long_nick.pm' \
	  'lib/Mojo/Webqq/Plugin.pm' 'blib/lib/Mojo/Webqq/Plugin.pm' \
	  'lib/Mojo/Webqq/Plugin/FuckAndroid.pm' 'blib/lib/Mojo/Webqq/Plugin/FuckAndroid.pm' \
	  'lib/Mojo/Webqq/Plugin/FuckDaShen.pm' 'blib/lib/Mojo/Webqq/Plugin/FuckDaShen.pm' \
	  'lib/Mojo/Webqq/Plugin/GasPrice.pm' 'blib/lib/Mojo/Webqq/Plugin/GasPrice.pm' \
	  'lib/Mojo/Webqq/Plugin/GroupManage.pm' 'blib/lib/Mojo/Webqq/Plugin/GroupManage.pm' \
	  'lib/Mojo/Webqq/Plugin/IPwhere.pm' 'blib/lib/Mojo/Webqq/Plugin/IPwhere.pm' \
	  'lib/Mojo/Webqq/Plugin/IRCShell.pm' 'blib/lib/Mojo/Webqq/Plugin/IRCShell.pm' \
	  'lib/Mojo/Webqq/Plugin/KnowledgeBase.pm' 'blib/lib/Mojo/Webqq/Plugin/KnowledgeBase.pm' \
	  'lib/Mojo/Webqq/Plugin/LCMD.pm' 'blib/lib/Mojo/Webqq/Plugin/LCMD.pm' \
	  'lib/Mojo/Webqq/Plugin/MobileInfo.pm' 'blib/lib/Mojo/Webqq/Plugin/MobileInfo.pm' \
	  'lib/Mojo/Webqq/Plugin/Openqq.pm' 'blib/lib/Mojo/Webqq/Plugin/Openqq.pm' \
	  'lib/Mojo/Webqq/Plugin/Perlcode.pm' 'blib/lib/Mojo/Webqq/Plugin/Perlcode.pm' \
	  'lib/Mojo/Webqq/Plugin/Perldoc.pm' 'blib/lib/Mojo/Webqq/Plugin/Perldoc.pm' \
	  'lib/Mojo/Webqq/Plugin/PostImgVerifycode.pm' 'blib/lib/Mojo/Webqq/Plugin/PostImgVerifycode.pm' \
	  'lib/Mojo/Webqq/Plugin/PostQRcode.pm' 'blib/lib/Mojo/Webqq/Plugin/PostQRcode.pm' \
	  'lib/Mojo/Webqq/Plugin/ProgramCode.pm' 'blib/lib/Mojo/Webqq/Plugin/ProgramCode.pm' \
	  'lib/Mojo/Webqq/Plugin/Pu.pm' 'blib/lib/Mojo/Webqq/Plugin/Pu.pm' \
	  'lib/Mojo/Webqq/Plugin/Qiandao.pm' 'blib/lib/Mojo/Webqq/Plugin/Qiandao.pm' \
	  'lib/Mojo/Webqq/Plugin/Riddle.pm' 'blib/lib/Mojo/Webqq/Plugin/Riddle.pm' \
	  'lib/Mojo/Webqq/Plugin/ShowMsg.pm' 'blib/lib/Mojo/Webqq/Plugin/ShowMsg.pm' \
	  'lib/Mojo/Webqq/Plugin/ShowQRcode.pm' 'blib/lib/Mojo/Webqq/Plugin/ShowQRcode.pm' \
	  'lib/Mojo/Webqq/Plugin/SmartReply.pm' 'blib/lib/Mojo/Webqq/Plugin/SmartReply.pm' \
	  'lib/Mojo/Webqq/Plugin/StockInfo.pm' 'blib/lib/Mojo/Webqq/Plugin/StockInfo.pm' \
	  'lib/Mojo/Webqq/Plugin/Translation.pm' 'blib/lib/Mojo/Webqq/Plugin/Translation.pm' \
	  'lib/Mojo/Webqq/Plugin/UploadQRcode.pm' 'blib/lib/Mojo/Webqq/Plugin/UploadQRcode.pm' \
	  'lib/Mojo/Webqq/Plugin/UploadQRcode2.pm' 'blib/lib/Mojo/Webqq/Plugin/UploadQRcode2.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Mojo/Webqq/Plugin/ZiYue.pm' 'blib/lib/Mojo/Webqq/Plugin/ZiYue.pm' \
	  'lib/Mojo/Webqq/Recent/Discuss.pm' 'blib/lib/Mojo/Webqq/Recent/Discuss.pm' \
	  'lib/Mojo/Webqq/Recent/Friend.pm' 'blib/lib/Mojo/Webqq/Recent/Friend.pm' \
	  'lib/Mojo/Webqq/Recent/Group.pm' 'blib/lib/Mojo/Webqq/Recent/Group.pm' \
	  'lib/Mojo/Webqq/Request.pm' 'blib/lib/Mojo/Webqq/Request.pm' \
	  'lib/Mojo/Webqq/Run.pm' 'blib/lib/Mojo/Webqq/Run.pm' \
	  'lib/Mojo/Webqq/Server.pm' 'blib/lib/Mojo/Webqq/Server.pm' \
	  'lib/Mojo/Webqq/User.pm' 'blib/lib/Mojo/Webqq/User.pm' \
	  'lib/Mojo/Webqq/Util.pm' 'blib/lib/Mojo/Webqq/Util.pm' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:


# End.
