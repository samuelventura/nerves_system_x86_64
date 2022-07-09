PLAN

- compile default kernel + icu + mesa3d
- manually add webkitgtk
- test in qemu and qemu-virgil

#https://stackoverflow.com/questions/19783795/how-to-add-my-own-software-to-a-buildroot-linux-package
#https://wiki.st.com/stm32mpu/wiki/Create_a_simple_hello-world_application
#https://www.levien.com/gimp/hello.html

NOTICE: Since nerves_system_x86_64 dependency has the nerves compile flag enabled it is better
    to trigger the image compile from the example folder with the firmware task.

#https://github.com/nerves-project/nerves_system_x86_64
#https://github.com/samuelventura/nerves_system_x86_64/blob/qt5webengine/readme.txt
#https://github.com/samuelventura/kiosk_system_x86_64/blob/master/nerves_defconfig


git clone git@github.com:samuelventura/nerves_system_x86_64.git
cd nerves_system_x86_64
rm -fr deps/ .nerves/ _build/
mix archive.install hex nerves_bootstrap
mix deps.get
mix nerves.system.shell
make menuconfig
make savedefconfig
make -j16
exit
mix nerves.artifact
mv *.tar.gz ~/.nerves/artifacts/

mix nerves.new example #no deps
cd example
rm -fr deps/ .nerves/ _build/
MIX_TARGET=x86_64 mix deps.unlock --all
#update app and host names wxkiosk
#update nerves_system_x86_64 path ../
MIX_TARGET=x86_64 mix deps.get
MIX_TARGET=x86_64 mix firmware
MIX_TARGET=x86_64 mix firmware.image image.img
MIX_TARGET=x86_64 mix burn
MIX_TARGET=x86_64 mix burn -d image.img
chown samuel:samuel image.img
truncate -s 1G image.img

rsync -av build:src/nerves_system_x86_64/example/image.img ~/Downloads/

#from https://github.com/nerves-project/nerves_system_x86_64/issues/129
qemu-system-x86_64 -enable-kvm -m 512M \
    -drive file=image.img,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22 \
    -serial stdio -show-cursor

#works as well
sudo qemu-system-x86_64 \
    -drive file=/dev/sdc,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22 \
    -serial stdio -show-cursor

qemu-virgil -enable-kvm -m 512M \
    -device virtio-vga,virgl=on -display sdl,gl=on \
    -drive file=image.img,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22,hostfwd=tcp::8081-:8081,hostfwd=tcp::3389-:3389 \
    -usbdevice tablet \
    -show-cursor \
    -serial stdio \

#SSH works on first boot (not sure if delayed)
ssh localhost -p 8022
ssh p3420 -p 8022
NervesMOTD.print

#WESTON RDP
cd rootfs_overlay/etc
openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out tls.csr
openssl x509 -req -days 365 -signkey tls.key -in tls.csr -out tls.crt
File.mkdir("/data/xdg_rt")
File.chmod("/data/xdg_rt", 0o700)
System.cmd("weston", ["--backend=rdp-backend.so", "--rdp-tls-key=/etc/tls.key", "--rdp-tls-cert=/etc/tls.crt"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
cmd "killall weston"
#multiple sessions connect to same shell
xfreerdp /sec:tls /v:localhost 
Certificate details for localhost:3389 (RDP-Server):
        Common Name: Yeico
        Subject:     C = MX, ST = SLP, L = SLP, O = Yeico, OU = Yeico, CN = Yeico, emailAddress = nerves@yeico.com
        Issuer:      C = MX, ST = SLP, L = SLP, O = Yeico, OU = Yeico, CN = Yeico, emailAddress = nerves@yeico.com
        Thumbprint:  cf:c9:3f:e8:cd:70:cf:a8:76:ea:60:67:4f:f9:e4:0c:24:b3:3e:d3:e2:52:46:5b:3b:75:a7:df:71:33:8c:be
The above X.509 certificate could not be verified, possibly because you do not have
the CA certificate in your certificate store, or the certificate has expired.
Please look at the OpenSSL documentation on how to add a private CA to the store.
#Do you trust the above certificate? (Y/T/N) Y
#shows a shell with right-top corner date and a left-top (working) terminal shortcut
#from weston terminal:
echo $XDG_RUNTIME_DIR -> /data/xdg_rt
gtk3-demo #works from weston terminal
granite-demo #segfault settings.vala:87 could not connect: no such file or directory

#WESTON DRM with udevd
System.cmd("weston", ["--version"])                                                              
{"weston 10.0.0\n", 0}
File.mkdir("/data/xdg_rt")
File.chmod("/data/xdg_rt", 0o700)
:os.cmd('udevd -d')
:os.cmd('udevadm trigger --type=subsystems --action=add')
:os.cmd('udevadm trigger --type=devices --action=add')
:os.cmd('udevadm settle --timeout=30')
#cmd "libinput list-devices" #must work at this point
#openvt -e nofork -s switch to vt -w wait cmd finish -c 1 busy
System.cmd("openvt", ["-v", "-s", "--", "weston", "--backend=drm-backend.so"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
#from ssh works as well with:
System.cmd("weston-terminal", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])
System.cmd("gtk3-demo", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "wayland"}, {"WAYLAND_DISPLAY", "wayland-1"}])
System.cmd("/usr/libexec/webkit2gtk-4.0/MiniBrowser", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "wayland"}, {"WAYLAND_DISPLAY", "wayland-1"}])
cmd "kmscube" #works!
cmd "killall weston"
cmd "killall cog"
#from weston terminal
cog http://10.77.4.240
gtk3-demo
cmd "cog --version"
0.12.4 (WPE WebKit 2.36.3)

#WPE on WESTON --no-config changes nothing
#weston desktop works with on-screen keyboard (no reliable/visible mouser pointer) but has a top toolbar
System.cmd("openvt", ["-v", "-s", "--", "weston", "--backend=drm-backend.so"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
#weston kiosk works without any input
System.cmd("openvt", ["-v", "-s", "--", "weston", "--backend=drm-backend.so", "--shell=kiosk-shell.so"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
#weston fullscreen works with input but no on-screen keyboard
System.cmd("openvt", ["-v", "-s", "--", "weston", "--backend=drm-backend.so", "--shell=fullscreen-shell.so"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
System.cmd("cog", ["http://10.77.4.240"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])

cmd "cat /data/weston.ini"
File.write("/data/weston.ini", """
[core]
backend=drm-backend.so
shell=desktop-shell.so
[shell]
panel-position=none
""")

#WPE on WESTON desktop with on-screen keyboard
System.cmd("openvt", ["-v", "-s", "--", "weston", "-c/data/weston.ini"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
System.cmd("cog", ["http://10.77.4.240"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])

STATUS:

- qemu mouser is off... pending to check against real device
- qemu cursor show in weston but not wpe unless -show-cursor is used









System.cmd("/usr/libexec/weston-keyboard", [], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])

iex(7)> cmd "kmscube"
Using display 0x55c08abec400 with EGL version 1.4
===================================
EGL information:
  version: "1.4"
  vendor: "Mesa Project"
  client extensions: "EGL_EXT_client_extensions EGL_EXT_device_base EGL_EXT_device_enumeration EGL_EXT_device_query EGL_EXT_platform_base EGL_KHR_client_get_all_proc_addresses EGL_KHR_debug EGL_EXT_platform_device EGL_EXT_platform_wayland EGL_KHR_platform_wayland EGL_MESA_platform_gbm EGL_KHR_platform_gbm EGL_MESA_platform_surfaceless"
  display extensions: "EGL_ANDROID_blob_cache EGL_ANDROID_native_fence_sync EGL_EXT_buffer_age EGL_EXT_image_dma_buf_import EGL_EXT_image_dma_buf_import_modifiers EGL_KHR_cl_event2 EGL_KHR_config_attribs EGL_KHR_create_context EGL_KHR_create_context_no_error EGL_KHR_fence_sync EGL_KHR_get_all_proc_addresses EGL_KHR_gl_colorspace EGL_KHR_gl_renderbuffer_image EGL_KHR_gl_texture_2D_image EGL_KHR_gl_texture_3D_image EGL_KHR_gl_texture_cubemap_image EGL_KHR_image EGL_KHR_image_base EGL_KHR_image_pixmap EGL_KHR_no_config_context EGL_KHR_reusable_sync EGL_KHR_surfaceless_context EGL_EXT_pixel_format_float EGL_KHR_wait_sync EGL_MESA_configless_context EGL_MESA_drm_image EGL_MESA_image_dma_buf_export EGL_MESA_query_driver EGL_WL_bind_wayland_display "
===================================
OpenGL ES 2.x information:
  version: "OpenGL ES 3.1 Mesa 21.3.8"
  shading language version: "OpenGL ES GLSL ES 3.10"
  vendor: "Mesa/X.org"
  renderer: "virgl"
  extensions: "GL_EXT_blend_minmax GL_EXT_multi_draw_arrays GL_EXT_texture_compression_s3tc GL_EXT_texture_compression_dxt1 GL_EXT_texture_compression_rgtc GL_EXT_texture_format_BGRA8888 GL_OES_compressed_ETC1_RGB8_texture GL_OES_depth24 GL_OES_element_index_uint GL_OES_fbo_render_mipmap GL_OES_mapbuffer GL_OES_rgb8_rgba8 GL_OES_standard_derivatives GL_OES_stencil8 GL_OES_texture_3D GL_OES_texture_float GL_OES_texture_float_linear GL_OES_texture_half_float GL_OES_texture_half_float_linear GL_OES_texture_npot GL_OES_vertex_half_float GL_EXT_draw_instanced GL_EXT_texture_sRGB_decode GL_OES_EGL_image GL_OES_depth_texture GL_OES_packed_depth_stencil GL_EXT_texture_type_2_10_10_10_REV GL_NV_conditional_render GL_OES_get_program_binary GL_APPLE_texture_max_level GL_EXT_discard_framebuffer GL_EXT_read_format_bgra GL_EXT_frag_depth GL_NV_fbo_color_attachments GL_OES_EGL_image_external GL_OES_EGL_sync GL_OES_vertex_array_object GL_OES_viewport_array GL_ANGLE_pack_reverse_row_order GL_ANGLE_texture_compression_dxt3 GL_ANGLE_texture_compression_dxt5 GL_EXT_occlusion_query_boolean GL_EXT_robustness GL_EXT_texture_rg GL_EXT_unpack_subimage GL_NV_draw_buffers GL_NV_read_buffer GL_NV_read_depth GL_NV_read_depth_stencil GL_NV_read_stencil GL_EXT_draw_buffers GL_EXT_map_buffer_range GL_KHR_debug GL_KHR_robustness GL_KHR_texture_compression_astc_ldr GL_NV_pixel_buffer_object GL_OES_depth_texture_cube_map GL_OES_required_internalformat GL_OES_surfaceless_context GL_EXT_color_buffer_float GL_EXT_sRGB_write_control GL_EXT_separate_shader_objects GL_EXT_shader_implicit_conversions GL_EXT_shader_integer_mix GL_EXT_tessellation_point_size GL_EXT_tessellation_shader GL_EXT_base_instance GL_EXT_compressed_ETC1_RGB8_sub_texture GL_EXT_copy_image GL_EXT_draw_buffers_indexed GL_EXT_draw_elements_base_vertex GL_EXT_gpu_shader5 GL_EXT_polygon_offset_clamp GL_EXT_primitive_bounding_box GL_EXT_render_snorm GL_EXT_shader_io_blocks GL_EXT_texture_border_clamp GL_EXT_texture_buffer GL_EXT_texture_cube_map_array GL_EXT_texture_norm16 GL_EXT_texture_view GL_KHR_context_flush_control GL_KHR_robust_buffer_access_behavior GL_NV_image_formats GL_OES_copy_image GL_OES_draw_buffers_indexed GL_OES_draw_elements_base_vertex GL_OES_gpu_shader5 GL_OES_primitive_bounding_box GL_OES_sample_shading GL_OES_sample_variables GL_OES_shader_io_blocks GL_OES_shader_multisample_interpolation GL_OES_tessellation_point_size GL_OES_tessellation_shader GL_OES_texture_border_clamp GL_OES_texture_buffer GL_OES_texture_cube_map_array GL_OES_texture_stencil8 GL_OES_texture_storage_multisample_2d_array GL_OES_texture_view GL_EXT_blend_func_extended GL_EXT_float_blend GL_EXT_geomeModifiers failed!
Modifiers failed!
try_point_size GL_EXT_geometry_shader GL_EXT_texture_sRGB_R8 GL_KHR_no_error GL_KHR_texture_compression_astc_sliced_3d GL_OES_EGL_image_external_essl3 GL_OES_geometry_point_size GL_OES_geometry_shader GL_OES_shader_image_atomic GL_EXT_clip_cull_distance GL_EXT_disjoint_timer_query GL_EXT_texture_compression_s3tc_srgb GL_MESA_shader_integer_functions GL_EXT_clip_control GL_EXT_color_buffer_half_float GL_EXT_texture_compression_bptc GL_EXT_texture_mirror_clamp_to_edge GL_KHR_parallel_shader_compile GL_EXT_EGL_image_storage GL_MESA_framebuffer_flip_y GL_EXT_depth_clamp GL_EXT_texture_query_lod GL_MESA_bgra "
===================================
Using modifier ffffffffffffff
Using modifier ffffffffffffff
Rendered 3546 frames in 2.000203 sec (1772.820102 fps)




G_MESSAGES_DEBUG=all cog https://github.com
WPEBACKEND_FDO_FORCE_SOFTWARE_RENDERING=1 G_MESSAGES_DEBUG=all MESA_DEBUG=1 EGL_LOG_LEVEL=debug LIBGL_DEBUG=verbose WAYLAND_DEBUG=1 cog --platform=drm --config=conf.ini http://csis.pace.edu/~wolf/HTML/htmlnotepad.htm

System.cmd("cog", ["--platform=drm"], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
System.cmd("cog", ["--platform=gles"], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])

iex(3)> System.cmd("cog", [], stderr_to_stdout: true)                                            
{"error: XDG_RUNTIME_DIR not set in the environment.\n\n(cog:173): 
GLib-GIO-WARNING **: 00:09:36.096: Your application does not implement 
g_application_activate() and has no handlers connected to the 'activate' 
signal.  It should do one of these.\n
Cog-Core-Message: 00:09:36.151: <https://wpewebkit.org/> Load started.\n
Cog-Core-Message: 00:09:36.170: <https://wpewebkit.org/> Loading...\n\n
(cog:173): Cog-DRM-WARNING **: 00:09:36.299: failed to schedule a page 
flip: Invalid argument\nCog-Core-Message: 00:09:36.462: <https://wpewebkit.org/> 
Loaded successfully.\n",
 0}

#from weston terminal
>gtkiosk
Could not determine the accessibility bus address
Couldn't open libGL.so.1 or libOpenGL.so.0
Aborted

#window with url bar blinks and dies
iex(23)> System.cmd("/usr/libexec/webkit2gtk-4.0/MiniBrowser", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "wayland"}, {"WAYLAND_DISPLAY", "wayland-1"}])
{"Could not determine the accessibility bus address\nCouldn't open libGL.so.1 or libOpenGL.so.0\n",
 134}

I think you are confusing EGL with GL. They are different things.

- On GNU/Linux the windowing system can be either EGL (Wayland, X11) or GLX (X11).
- On GNU/Linux the API for issuing commands to the GPU can be either GL or GLESv2.

-DENABLE_GLES2=ON

-- Checking for module 'egl'
--   Found egl, version 21.3.8
-- Found EGL: /home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.20.0/host/x86_64-buildroot-linux-gnu/sysroot/usr/include  
-- Checking for module 'opengl'
--   Package 'opengl', required by 'virtual:world', not found
-- Checking for module 'gl'
--   Package 'gl', required by 'virtual:world', not found
-- Could NOT find OpenGL (missing: OpenGL_LIBRARY) 
-- Checking for module 'glesv2'
--   Found glesv2, version 21.3.8
-- Found OpenGLES2: /home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.20.0/host/x86_64-buildroot-linux-gnu/sysroot/usr/lib/libGLESv2.so (found version "3.2") 
-- Checking for module 'gtk+-3.0'
--   Found gtk+-3.0, version 3.24.33
-- Checking for module 'gtk+-unix-print-3.0'
--   Found gtk+-unix-print-3.0, version 3.24.33
-- Found GTK: 3.24.33 (Required is at least version "3.22.0") 

BR2_PACKAGE_LIBGLVND
BR2_PACKAGE_HAS_LIBGL
BR2_PACKAGE_HAS_LIBGLES
BR2_PACKAGE_WEBKITGTK_USE_GSTREAMER_GL
BR2_PACKAGE_LIBGLVND
BR2_PACKAGE_MESA3D_DRIVER
BR2_PACKAGE_MESA3D_ES
BR2_PACKAGE_GST1_PLUGINS_BASE_LIB_OPENGL_HAS_PLATFORM

-- Enabled features:
--  ENABLE_BUBBLEWRAP_SANDBOX ..................... OFF
--  ENABLE_DRAG_SUPPORT                             ON
--  ENABLE_GAMEPAD ................................ OFF
--  ENABLE_GLES2                                    ON
--  ENABLE_GTKDOC ................................. OFF
--  ENABLE_INTROSPECTION                            ON
--  ENABLE_JOURNALD_LOG ........................... OFF
--  ENABLE_MEDIA_SOURCE                             ON
--  ENABLE_MINIBROWSER ............................ ON
--  ENABLE_QUARTZ_TARGET                            OFF
--  ENABLE_SPELLCHECK ............................. ON
--  ENABLE_TOUCH_EVENTS                             ON
--  ENABLE_VIDEO .................................. ON
--  ENABLE_WAYLAND_TARGET                           ON
--  ENABLE_WEBDRIVER .............................. OFF
--  ENABLE_WEB_AUDIO                                ON
--  ENABLE_WEB_CRYPTO ............................. ON
--  ENABLE_X11_TARGET                               OFF
--  USE_ANGLE_WEBGL ............................... OFF
--  USE_AVIF                                        OFF
--  USE_GTK4 ...................................... OFF
--  USE_JPEGXL                                      OFF
--  USE_LCMS ...................................... OFF
--  USE_LIBHYPHEN                                   OFF
--  USE_LIBNOTIFY ................................. OFF
--  USE_LIBSECRET                                   ON
--  USE_OPENGL_OR_ES .............................. ON
--  USE_OPENJPEG                                    ON
--  USE_SOUP2 ..................................... ON
--  USE_WOFF2                                       ON
--  USE_WPE_RENDERER .............................. OFF
-- Configuring done

cairo (version 1.16.0 [release]) will be compiled with:

The following surface backends:
  Image:         yes (always builtin)
  Recording:     yes (always builtin)
  Observer:      yes (always builtin)
  Mime:          yes (always builtin)
  Tee:           no (disabled, use --enable-tee to enable)
  XML:           no (disabled, use --enable-xml to enable)
  Xlib:          yes
  Xlib Xrender:  no (disabled, use --enable-xlib-xrender to enable)
  Qt:            no (disabled, use --enable-qt to enable)
  Quartz:        no (requires CoreGraphics framework)
  Quartz-image:  no (disabled, use --enable-quartz-image to enable)
  XCB:           yes
  Win32:         no (requires a Win32 platform)
  OS2:           no (disabled, use --enable-os2 to enable)
  CairoScript:   yes
  PostScript:    yes
  PDF:           yes
  SVG:           yes
  OpenGL:        no (disabled, use --enable-gl to enable)
  OpenGL ES 2.0: yes
  OpenGL ES 3.0: no (disabled, use --enable-glesv3 to enable)
  BeOS:          no (disabled, use --enable-beos to enable)
  DirectFB:      no (disabled, use --enable-directfb to enable)
  OpenVG:        no (disabled, use --enable-vg to enable)
  DRM:           no (disabled, use --enable-drm to enable)
  Cogl:          no (disabled, use --enable-cogl to enable)

The following font backends:
  User:          yes (always builtin)
  FreeType:      yes
  Fontconfig:    yes
  Win32:         no (requires a Win32 platform)
  Quartz:        no (requires CoreGraphics framework)

The following functions:
  PNG functions:   yes
  GLX functions:   no (not required by any backend)
  WGL functions:   no (not required by any backend)
  EGL functions:   yes
  X11-xcb functions: no (disabled, use --enable-xlib-xcb to enable)
  XCB-shm functions: yes

The following features and utilities:
  cairo-trace:                no (disabled, use --enable-trace to enable)
  cairo-script-interpreter:   no (disabled, use --enable-interpreter to enable)

And the following internal features:
  pthread:       yes
  gtk-doc:       no
  gcov support:  no
  symbol-lookup: no (requires bfd)
  test surfaces: no (disabled, use --enable-test-surfaces to enable)
  ps testing:    no (requires libspectre)
  pdf testing:   no (requires poppler-glib >= 0.17.4)
  svg testing:   no (requires librsvg-2.0 >= 2.35.0)


--- The OpenGLESv2 surface backend feature is still under active development
--- and is included in this release only as a preview. It does NOT fully work
--- yet and incompatible changes may yet be made to OpenGLESv2 surface
--- backend specific API.

+++ It is strongly recommended that you do NOT disable the
+++ cairo-script-interpreter feature.

compilation terminated.
make[4]: *** [Source/WebCore/CMakeFiles/WebCore.dir/build.make:4757: Source/WebCore/CMakeFiles/WebCore.dir/__/__/WebCore/DerivedSources/unified-sources/UnifiedSource-3a52ce78-5.cpp.o] Error 1
make[4]: *** Deleting file 'Source/WebCore/CMakeFiles/WebCore.dir/__/__/WebCore/DerivedSources/unified-sources/UnifiedSource-3a52ce78-5.cpp.o'
x86_64-linux-g++.br_real: fatal error: Killed signal terminated program cc1plus
compilation terminated.
make[4]: *** [Source/WebCore/CMakeFiles/WebCore.dir/build.make:4785: Source/WebCore/CMakeFiles/WebCore.dir/__/__/WebCore/DerivedSources/unified-sources/UnifiedSource-3a52ce78-7.cpp.o] Error 1
make[4]: *** Deleting file 'Source/WebCore/CMakeFiles/WebCore.dir/__/__/WebCore/DerivedSources/unified-sources/UnifiedSource-3a52ce78-7.cpp.o'
make[3]: *** [CMakeFiles/Makefile2:1097: Source/WebCore/CMakeFiles/WebCore.dir/all] Error 2
make[2]: *** [Makefile:156: all] Error 2
make[1]: *** [package/pkg-generic.mk:29