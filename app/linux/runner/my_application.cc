#include "my_application.h"

#include <cstdlib>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// When Flutter cannot create its OpenGL context nothing is drawn: the window stays black and
// the app looks hung (#371). Flutter only logs a warning for it, so watch the log for that
// warning and tell the user what happened and what to try instead.
static const char* const kGlFailureMarkers[] = {
    "Failed to create OpenGL context",
    "Failed to create EGL context",
};

static const char kGlFailureAdvice[] =
    "GodotHub could not create the OpenGL context it needs to draw its window. This usually "
    "comes from the graphics driver or the compositor, not from GodotHub.\n\n"
    "Try starting it from a terminal with one of these:\n"
    "  GDK_BACKEND=x11 godothub\n"
    "  LIBGL_ALWAYS_SOFTWARE=1 godothub\n"
    "  GDK_GL=gles godothub\n\n"
    "Whether one of them works or none do, please open an issue at "
    "github.com/Rykode/GodotHub with your distro, desktop and GPU.";

static gint gl_failure_reported = 0;

static gboolean show_gl_failure_dialog(gpointer data) {
  g_autofree gchar* details = static_cast<gchar*>(data);
  GtkWidget* dialog = gtk_message_dialog_new(nullptr, GTK_DIALOG_MODAL, GTK_MESSAGE_ERROR,
                                             GTK_BUTTONS_NONE, "%s",
                                             "GodotHub couldn't start its graphics");
  gtk_message_dialog_format_secondary_text(GTK_MESSAGE_DIALOG(dialog), "%s\n\nDetails: %s",
                                           kGlFailureAdvice, details);
  gtk_dialog_add_button(GTK_DIALOG(dialog), "Quit", GTK_RESPONSE_CLOSE);
  gtk_window_set_keep_above(GTK_WINDOW(dialog), TRUE);
  gtk_dialog_run(GTK_DIALOG(dialog));
  // The window behind it is black and cannot be used, so end the whole app.
  exit(1);
  return G_SOURCE_REMOVE;
}

// The log can come from any thread. Only the first matching warning is acted on.
static GLogWriterOutput gl_failure_log_writer(GLogLevelFlags log_level, const GLogField* fields,
                                              gsize n_fields, gpointer user_data) {
  if (log_level & G_LOG_LEVEL_WARNING) {
    for (gsize i = 0; i < n_fields; i++) {
      if (g_strcmp0(fields[i].key, "MESSAGE") != 0 || fields[i].value == nullptr) continue;
      const char* message = static_cast<const char*>(fields[i].value);
      for (const char* marker : kGlFailureMarkers) {
        if (g_strstr_len(message, fields[i].length, marker) != nullptr &&
            g_atomic_int_compare_and_exchange(&gl_failure_reported, 0, 1)) {
          g_printerr("\nGodotHub: %s\n\n", kGlFailureAdvice);
          // A few seconds in, once the app has set up its own window: native window code
          // lists every top-level window, and an earlier dialog would be resized as the app's.
          g_timeout_add_seconds(
              3, show_gl_failure_dialog,
              fields[i].length < 0 ? g_strdup(message)
                                   : g_strndup(message, static_cast<gsize>(fields[i].length)));
        }
      }
    }
  }
  return g_log_writer_default(log_level, fields, n_fields, user_data);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // With the custom title bar, nativeapi keeps a shadow gutter around the content
  // that takes no input. It only clears that gutter's background when the window
  // has an RGBA visual; otherwise GTK paints it opaque, so the window looks a few
  // pixels wider than the area that takes clicks and resize drags (#352). The
  // visual has to be set before the window is realized.
  GdkScreen* rgba_screen = gtk_window_get_screen(window);
  GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(rgba_screen);
  gboolean translucent = FALSE;
  if (rgba_visual != nullptr && gdk_screen_is_composited(rgba_screen)) {
    gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual);
    translucent = TRUE;
  }

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, GODOTHUB_DISPLAY_NAME);
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, GODOTHUB_DISPLAY_NAME);
  }

  gtk_window_set_default_size(window, 1280, 720);
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path != nullptr) {
    g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);
    g_autofree gchar* icon_path = g_build_filename(exe_dir, "data", "app_icon.png", nullptr);
    gtk_window_set_icon_from_file(window, icon_path, nullptr);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Black unless the window can be translucent. Then it is transparent, so the app
  // can stay invisible while the window settles to its restored size (#352); the app
  // paints its own opaque background once it is shown.
  gdk_rgba_parse(&background_color, translucent ? "#00000000" : "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  g_log_set_writer_func(gl_failure_log_writer, nullptr, nullptr);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
