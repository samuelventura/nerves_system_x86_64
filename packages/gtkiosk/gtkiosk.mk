GTKIOSK_VERSION = 0.1
GTKIOSK_SITE = $(NERVES_DEFCONFIG_DIR)/packages/gtkiosk/src
GTKIOSK_SITE_METHOD = local
GTKIOSK_DEPENDENCIES += libgtk3 webkitgtk

define GTKIOSK_BUILD_CMDS
    $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define GTKIOSK_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/gtkiosk $(TARGET_DIR)/usr/bin
endef

$(eval $(generic-package))
