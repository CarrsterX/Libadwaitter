#include "tray/tray_bridge.h"

#include <cstring>
#include <unistd.h>

#include "common/portal_result.h"
#include "window/window_bridge.h"

namespace {

const char* kTrayChannelName = "libadwaitter/tray";

static const gchar kSniIntrospectionXml[] =
    "<node>"
    "  <interface name='org.kde.StatusNotifierItem'>"
    "    <method name='ContextMenu'>"
    "      <arg name='x' type='i' direction='in'/>"
    "      <arg name='y' type='i' direction='in'/>"
    "    </method>"
    "    <method name='Activate'>"
    "      <arg name='x' type='i' direction='in'/>"
    "      <arg name='y' type='i' direction='in'/>"
    "    </method>"
    "    <method name='SecondaryActivate'>"
    "      <arg name='x' type='i' direction='in'/>"
    "      <arg name='y' type='i' direction='in'/>"
    "    </method>"
    "    <method name='Scroll'>"
    "      <arg name='delta' type='i' direction='in'/>"
    "      <arg name='orientation' type='s' direction='in'/>"
    "    </method>"
    "    <signal name='NewTitle'/>"
    "    <signal name='NewIcon'/>"
    "    <signal name='NewToolTip'/>"
    "    <signal name='NewStatus'>"
    "      <arg name='status' type='s'/>"
    "    </signal>"
    "    <property name='Category' type='s' access='read'/>"
    "    <property name='Id' type='s' access='read'/>"
    "    <property name='Title' type='s' access='read'/>"
    "    <property name='Status' type='s' access='read'/>"
    "    <property name='WindowId' type='u' access='read'/>"
    "    <property name='IconName' type='s' access='read'/>"
    "    <property name='IconThemePath' type='s' access='read'/>"
    "    <property name='AttentionIconName' type='s' access='read'/>"
    "    <property name='OverlayIconName' type='s' access='read'/>"
    "    <property name='Menu' type='o' access='read'/>"
    "    <property name='ItemIsMenu' type='b' access='read'/>"
    "    <property name='ToolTip' type='(sa(iiay)ss)' access='read'/>"
    "  </interface>"
    "</node>";

static const gchar kDbusMenuIntrospectionXml[] =
    "<node>"
    "  <interface name='com.canonical.dbusmenu'>"
    "    <method name='GetLayout'>"
    "      <arg name='parentId' type='i' direction='in'/>"
    "      <arg name='recursionDepth' type='i' direction='in'/>"
    "      <arg name='propertyNames' type='as' direction='in'/>"
    "      <arg name='revision' type='u' direction='out'/>"
    "      <arg name='layout' type='(ia{sv}av)' direction='out'/>"
    "    </method>"
    "    <method name='GetGroupProperties'>"
    "      <arg name='ids' type='ai' direction='in'/>"
    "      <arg name='propertyNames' type='as' direction='in'/>"
    "      <arg name='properties' type='a(ia{sv})' direction='out'/>"
    "    </method>"
    "    <method name='GetProperty'>"
    "      <arg name='id' type='i' direction='in'/>"
    "      <arg name='name' type='s' direction='in'/>"
    "      <arg name='value' type='v' direction='out'/>"
    "    </method>"
    "    <method name='Event'>"
    "      <arg name='id' type='i' direction='in'/>"
    "      <arg name='eventId' type='s' direction='in'/>"
    "      <arg name='data' type='v' direction='in'/>"
    "      <arg name='timestamp' type='u' direction='in'/>"
    "    </method>"
    "    <method name='EventGroup'>"
    "      <arg name='events' type='a(isvu)' direction='in'/>"
    "      <arg name='idErrors' type='ai' direction='out'/>"
    "    </method>"
    "    <method name='AboutToShow'>"
    "      <arg name='id' type='i' direction='in'/>"
    "      <arg name='needUpdate' type='b' direction='out'/>"
    "    </method>"
    "    <method name='AboutToShowGroup'>"
    "      <arg name='ids' type='ai' direction='in'/>"
    "      <arg name='updatesNeeded' type='ai' direction='out'/>"
    "      <arg name='idErrors' type='ai' direction='out'/>"
    "    </method>"
    "    <signal name='LayoutUpdated'>"
    "      <arg name='revision' type='u'/>"
    "      <arg name='parent' type='i'/>"
    "    </signal>"
    "    <property name='Version' type='u' access='read'/>"
    "    <property name='TextDirection' type='s' access='read'/>"
    "    <property name='Status' type='s' access='read'/>"
    "    <property name='IconThemePath' type='as' access='read'/>"
    "  </interface>"
    "</node>";

struct TrayMenuItemData {
  gint32 dbus_id;
  gchar *id;
  gchar *label;
  gboolean enabled;
  gboolean is_separator;
};

struct TrayState {
  GDBusConnection *bus;
  GDBusNodeInfo *sni_node_info;
  GDBusNodeInfo *menu_node_info;
  guint bus_owner_id;
  guint instance_counter;
  gchar *bus_name;
  guint sni_reg_id;
  guint menu_reg_id;
  guint32 menu_revision;
  FlMethodChannel *channel;
  GtkWindow *window;
  gchar *title;
  gchar *tooltip;
  gchar *icon_name;
  gboolean hide_on_close;
  gboolean window_hidden;
  GPtrArray *menu_items;
};

static TrayState g_tray = {};

static void tray_hide_main_window() {
  if (g_tray.window == nullptr)
    return;
  if (!g_tray.window_hidden) {
    g_tray.window_hidden = TRUE;
    GApplication *app = g_application_get_default();
    if (app != nullptr)
      g_application_hold(app);
  }
  gtk_window_set_skip_taskbar_hint(g_tray.window, TRUE);
  gtk_window_set_skip_pager_hint(g_tray.window, TRUE);
  gtk_widget_hide(GTK_WIDGET(g_tray.window));
}

struct TrayRestoreSizeData {
  gint width;
  gint height;
};

static gboolean on_tray_restore_window_size(gpointer user_data) {
  TrayRestoreSizeData *data = static_cast<TrayRestoreSizeData *>(user_data);
  if (g_tray.window != nullptr &&
      gtk_widget_get_visible(GTK_WIDGET(g_tray.window))) {
    gtk_window_resize(g_tray.window, data->width, data->height);
    gint margin = GPOINTER_TO_INT(g_object_get_data(
        G_OBJECT(g_tray.window), "libadwaitter-shadow-margin"));
    if (margin > 0) {
      libadwaitter::ApplyWindowShadowMargin(g_tray.window, margin);
    }
    gtk_window_present_with_time(g_tray.window, GDK_CURRENT_TIME);
  }
  g_free(data);
  return G_SOURCE_REMOVE;
}

static void tray_show_main_window() {
  if (g_tray.window == nullptr)
    return;
  gint w = 0, h = 0;
  gtk_window_get_size(g_tray.window, &w, &h);
  gtk_window_set_skip_taskbar_hint(g_tray.window, FALSE);
  gtk_window_set_skip_pager_hint(g_tray.window, FALSE);
  gtk_widget_show_all(GTK_WIDGET(g_tray.window));
  gtk_window_deiconify(g_tray.window);
  gtk_window_present_with_time(g_tray.window, GDK_CURRENT_TIME);
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(g_tray.window), "libadwaitter-shadow-margin"));
  if (margin > 0) {
    libadwaitter::ApplyWindowShadowMargin(g_tray.window, margin);
  }
  // On Wayland, gtk_widget_hide destroys the xdg_toplevel/wl_surface. Nudging
  // the size by 1px and restoring it on the next tick forces FlView to emit a
  // new window-metrics event and commit a fresh EGL buffer to the new surface.
  if (w > 1 && h > 1) {
    gtk_window_resize(g_tray.window, w + 1, h);
    TrayRestoreSizeData *data = g_new(TrayRestoreSizeData, 1);
    data->width = w;
    data->height = h;
    g_timeout_add(20, on_tray_restore_window_size, data);
  }
  gtk_widget_queue_draw(GTK_WIDGET(g_tray.window));
  if (g_tray.window_hidden) {
    g_tray.window_hidden = FALSE;
    GApplication *app = g_application_get_default();
    if (app != nullptr)
      g_application_release(app);
  }
}

static void tray_menu_item_free(gpointer data) {
  TrayMenuItemData *item = static_cast<TrayMenuItemData *>(data);
  if (item == nullptr)
    return;
  g_free(item->id);
  g_free(item->label);
  g_free(item);
}

static void tray_dispatch_event(const char *event_name, const char *item_id) {
  if (g_tray.channel == nullptr)
    return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "event", fl_value_new_string(event_name));
  if (item_id != nullptr && item_id[0] != '\0') {
    fl_value_set_string_take(map, "itemId", fl_value_new_string(item_id));
  }
  fl_method_channel_invoke_method(g_tray.channel, "onTrayEvent", map, nullptr,
                                  nullptr, nullptr);
}

static void tray_replace_menu_items(FlValue *list_val) {
  if (g_tray.menu_items == nullptr) {
    g_tray.menu_items = g_ptr_array_new_with_free_func(tray_menu_item_free);
  } else {
    g_ptr_array_set_size(g_tray.menu_items, 0);
  }
  if (list_val == nullptr ||
      fl_value_get_type(list_val) != FL_VALUE_TYPE_LIST) {
    return;
  }
  size_t count = fl_value_get_length(list_val);
  for (size_t i = 0; i < count; ++i) {
    FlValue *entry = fl_value_get_list_value(list_val, i);
    if (entry == nullptr || fl_value_get_type(entry) != FL_VALUE_TYPE_MAP)
      continue;
    TrayMenuItemData *item = g_new0(TrayMenuItemData, 1);
    item->dbus_id = static_cast<gint32>(i + 1);
    item->enabled = TRUE;
    FlValue *v = nullptr;
    if ((v = fl_value_lookup_string(entry, "id")) != nullptr &&
        fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
      item->id = g_strdup(fl_value_get_string(v));
    if ((v = fl_value_lookup_string(entry, "label")) != nullptr &&
        fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
      item->label = g_strdup(fl_value_get_string(v));
    if ((v = fl_value_lookup_string(entry, "enabled")) != nullptr &&
        fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
      item->enabled = fl_value_get_bool(v);
    if ((v = fl_value_lookup_string(entry, "isSeparator")) != nullptr &&
        fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
      item->is_separator = fl_value_get_bool(v);
    g_ptr_array_add(g_tray.menu_items, item);
  }
  g_tray.menu_revision++;
  if (g_tray.bus != nullptr && g_tray.menu_reg_id != 0) {
    g_dbus_connection_emit_signal(
        g_tray.bus, nullptr, "/MenuBar", "com.canonical.dbusmenu",
        "LayoutUpdated", g_variant_new("(ui)", g_tray.menu_revision, 0),
        nullptr);
  }
}

static GVariant *tray_build_item_props(const TrayMenuItemData *item) {
  GVariantBuilder props;
  g_variant_builder_init(&props, G_VARIANT_TYPE("a{sv}"));
  if (item->is_separator) {
    g_variant_builder_add(&props, "{sv}", "type",
                          g_variant_new_string("separator"));
    g_variant_builder_add(&props, "{sv}", "visible",
                          g_variant_new_boolean(TRUE));
  } else {
    g_variant_builder_add(
        &props, "{sv}", "label",
        g_variant_new_string(item->label != nullptr ? item->label : ""));
    g_variant_builder_add(&props, "{sv}", "enabled",
                          g_variant_new_boolean(item->enabled));
    g_variant_builder_add(&props, "{sv}", "visible",
                          g_variant_new_boolean(TRUE));
  }
  return g_variant_builder_end(&props);
}

static void sni_method_call(GDBusConnection *connection, const gchar *sender,
                            const gchar *object_path,
                            const gchar *interface_name,
                            const gchar *method_name, GVariant *parameters,
                            GDBusMethodInvocation *invocation,
                            gpointer user_data) {
  if (strcmp(method_name, "Activate") == 0) {
    tray_show_main_window();
    tray_dispatch_event("activate", nullptr);
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant *sni_get_property(GDBusConnection *connection,
                                  const gchar *sender, const gchar *object_path,
                                  const gchar *interface_name,
                                  const gchar *property_name, GError **error,
                                  gpointer user_data) {
  const gchar *title = g_tray.title != nullptr ? g_tray.title : libadwaitter::GetApplicationId();
  const gchar *tooltip = g_tray.tooltip != nullptr ? g_tray.tooltip : title;
  const gchar *icon = g_tray.icon_name != nullptr
                          ? g_tray.icon_name
                          : "applications-system-symbolic";

  if (strcmp(property_name, "Category") == 0)
    return g_variant_new_string("ApplicationStatus");
  if (strcmp(property_name, "Id") == 0)
    return g_variant_new_string(libadwaitter::GetApplicationId());
  if (strcmp(property_name, "Title") == 0)
    return g_variant_new_string(title);
  if (strcmp(property_name, "Status") == 0)
    return g_variant_new_string("Active");
  if (strcmp(property_name, "WindowId") == 0)
    return g_variant_new_uint32(0);
  if (strcmp(property_name, "IconName") == 0)
    return g_variant_new_string(icon);
  if (strcmp(property_name, "IconThemePath") == 0)
    return g_variant_new_string("");
  if (strcmp(property_name, "AttentionIconName") == 0)
    return g_variant_new_string("");
  if (strcmp(property_name, "OverlayIconName") == 0)
    return g_variant_new_string("");
  if (strcmp(property_name, "Menu") == 0)
    return g_variant_new_object_path("/MenuBar");
  if (strcmp(property_name, "ItemIsMenu") == 0)
    return g_variant_new_boolean(FALSE);
  if (strcmp(property_name, "ToolTip") == 0) {
    GVariantBuilder empty_pixmaps;
    g_variant_builder_init(&empty_pixmaps, G_VARIANT_TYPE("a(iiay)"));
    return g_variant_new("(sa(iiay)ss)", icon, &empty_pixmaps, title, tooltip);
  }
  return nullptr;
}

static void dbusmenu_method_call(GDBusConnection *connection,
                                 const gchar *sender, const gchar *object_path,
                                 const gchar *interface_name,
                                 const gchar *method_name, GVariant *parameters,
                                 GDBusMethodInvocation *invocation,
                                 gpointer user_data) {
  if (strcmp(method_name, "GetLayout") == 0) {
    gint32 parent_id = 0;
    gint32 depth = -1;
    g_autoptr(GVariant) prop_names = nullptr;
    g_variant_get(parameters, "(ii@as)", &parent_id, &depth, &prop_names);

    GVariantBuilder children;
    g_variant_builder_init(&children, G_VARIANT_TYPE("av"));
    if (parent_id == 0 && g_tray.menu_items != nullptr) {
      for (guint i = 0; i < g_tray.menu_items->len; ++i) {
        const TrayMenuItemData *item = static_cast<const TrayMenuItemData *>(
            g_ptr_array_index(g_tray.menu_items, i));
        GVariantBuilder empty_children;
        g_variant_builder_init(&empty_children, G_VARIANT_TYPE("av"));
        GVariant *node =
            g_variant_new("(i@a{sv}av)", item->dbus_id,
                          tray_build_item_props(item), &empty_children);
        g_variant_builder_add(&children, "v", node);
      }
    }
    GVariantBuilder root_props;
    g_variant_builder_init(&root_props, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&root_props, "{sv}", "children-display",
                          g_variant_new_string("submenu"));
    g_dbus_method_invocation_return_value(
        invocation, g_variant_new("(u(ia{sv}av))", g_tray.menu_revision,
                                  parent_id, &root_props, &children));
    return;
  }
  if (strcmp(method_name, "GetGroupProperties") == 0) {
    GVariantBuilder out;
    g_variant_builder_init(&out, G_VARIANT_TYPE("a(ia{sv})"));
    g_autoptr(GVariant) ids_v = nullptr;
    g_autoptr(GVariant) props_v = nullptr;
    g_variant_get(parameters, "(@ai@as)", &ids_v, &props_v);
    if (ids_v != nullptr && g_tray.menu_items != nullptr) {
      GVariantIter iter;
      gint32 req_id = 0;
      g_variant_iter_init(&iter, ids_v);
      while (g_variant_iter_next(&iter, "i", &req_id)) {
        if (req_id >= 1 &&
            static_cast<guint>(req_id) <= g_tray.menu_items->len) {
          const TrayMenuItemData *item =
              static_cast<const TrayMenuItemData *>(g_ptr_array_index(
                  g_tray.menu_items, static_cast<guint>(req_id - 1)));
          g_variant_builder_add(&out, "(i@a{sv})", req_id,
                                tray_build_item_props(item));
        }
      }
    }
    g_dbus_method_invocation_return_value(invocation,
                                          g_variant_new("(a(ia{sv}))", &out));
    return;
  }
  if (strcmp(method_name, "GetProperty") == 0) {
    gint32 id = 0;
    const gchar *name = "";
    g_variant_get(parameters, "(i&s)", &id, &name);
    GVariant *val = g_variant_new_string("");
    if (id >= 1 && g_tray.menu_items != nullptr &&
        static_cast<guint>(id) <= g_tray.menu_items->len) {
      const TrayMenuItemData *item = static_cast<const TrayMenuItemData *>(
          g_ptr_array_index(g_tray.menu_items, static_cast<guint>(id - 1)));
      if (strcmp(name, "label") == 0) {
        g_variant_unref(val);
        val = g_variant_new_string(item->label != nullptr ? item->label : "");
      } else if (strcmp(name, "enabled") == 0) {
        g_variant_unref(val);
        val = g_variant_new_boolean(item->enabled);
      } else if (strcmp(name, "visible") == 0) {
        g_variant_unref(val);
        val = g_variant_new_boolean(TRUE);
      }
    }
    g_dbus_method_invocation_return_value(invocation,
                                          g_variant_new("(v)", val));
    return;
  }
  if (strcmp(method_name, "Event") == 0) {
    gint32 id = 0;
    const gchar *event_id = "";
    g_autoptr(GVariant) data = nullptr;
    guint32 ts = 0;
    g_variant_get(parameters, "(i&svu)", &id, &event_id, &data, &ts);
    if (strcmp(event_id, "clicked") == 0 && id >= 1 &&
        g_tray.menu_items != nullptr &&
        static_cast<guint>(id) <= g_tray.menu_items->len) {
      const TrayMenuItemData *item = static_cast<const TrayMenuItemData *>(
          g_ptr_array_index(g_tray.menu_items, static_cast<guint>(id - 1)));
      if (!item->is_separator) {
        tray_dispatch_event("menuItemClicked", item->id);
      }
    }
    g_dbus_method_invocation_return_value(invocation, nullptr);
    return;
  }
  if (strcmp(method_name, "EventGroup") == 0) {
    GVariantBuilder empty_errs;
    g_variant_builder_init(&empty_errs, G_VARIANT_TYPE("ai"));
    g_dbus_method_invocation_return_value(invocation,
                                          g_variant_new("(ai)", &empty_errs));
    return;
  }
  if (strcmp(method_name, "AboutToShow") == 0) {
    g_dbus_method_invocation_return_value(invocation,
                                          g_variant_new("(b)", FALSE));
    return;
  }
  if (strcmp(method_name, "AboutToShowGroup") == 0) {
    GVariantBuilder empty1, empty2;
    g_variant_builder_init(&empty1, G_VARIANT_TYPE("ai"));
    g_variant_builder_init(&empty2, G_VARIANT_TYPE("ai"));
    g_dbus_method_invocation_return_value(
        invocation, g_variant_new("(aiai)", &empty1, &empty2));
    return;
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant *dbusmenu_get_property(GDBusConnection *connection,
                                       const gchar *sender,
                                       const gchar *object_path,
                                       const gchar *interface_name,
                                       const gchar *property_name,
                                       GError **error, gpointer user_data) {
  if (strcmp(property_name, "Version") == 0)
    return g_variant_new_uint32(3);
  if (strcmp(property_name, "TextDirection") == 0)
    return g_variant_new_string("ltr");
  if (strcmp(property_name, "Status") == 0)
    return g_variant_new_string("normal");
  if (strcmp(property_name, "IconThemePath") == 0)
    return g_variant_new_strv(nullptr, 0);
  return nullptr;
}

static const GDBusInterfaceVTable kSniVTable = {
    sni_method_call,
    sni_get_property,
    nullptr,
    {0},
};

static const GDBusInterfaceVTable kDbusMenuVTable = {
    dbusmenu_method_call,
    dbusmenu_get_property,
    nullptr,
    {0},
};

static gboolean tray_is_host_available() {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (bus == nullptr)
    return FALSE;
  g_autoptr(GVariant) has_owner_res = g_dbus_connection_call_sync(
      bus, "org.freedesktop.DBus", "/org/freedesktop/DBus",
      "org.freedesktop.DBus", "NameHasOwner",
      g_variant_new("(s)", "org.kde.StatusNotifierWatcher"),
      G_VARIANT_TYPE("(b)"), G_DBUS_CALL_FLAGS_NONE, 1000, nullptr, nullptr);
  if (has_owner_res == nullptr)
    return FALSE;
  gboolean owned = FALSE;
  g_variant_get(has_owner_res, "(b)", &owned);
  if (!owned)
    return FALSE;

  g_autoptr(GVariant) host_res = g_dbus_connection_call_sync(
      bus, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
      "org.freedesktop.DBus.Properties", "Get",
      g_variant_new("(ss)", "org.kde.StatusNotifierWatcher",
                    "IsStatusNotifierHostRegistered"),
      G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, 1000, nullptr, nullptr);
  if (host_res != nullptr) {
    g_autoptr(GVariant) inner = nullptr;
    g_variant_get(host_res, "(v)", &inner);
    if (inner != nullptr &&
        g_variant_is_of_type(inner, G_VARIANT_TYPE_BOOLEAN)) {
      return g_variant_get_boolean(inner);
    }
  }
  return TRUE;
}

static void on_tray_bus_name_acquired(GDBusConnection *connection,
                                      const gchar *name, gpointer user_data) {
  if (connection == nullptr || name == nullptr)
    return;
  g_dbus_connection_call(
      connection, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
      "org.kde.StatusNotifierWatcher", "RegisterStatusNotifierItem",
      g_variant_new("(s)", name), nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr,
      nullptr, nullptr);
}

static gboolean tray_ensure_registered() {
  g_autoptr(GError) error = nullptr;
  if (g_tray.bus == nullptr) {
    g_tray.bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (g_tray.bus == nullptr)
      return FALSE;
  }
  if (g_tray.sni_node_info == nullptr) {
    g_tray.sni_node_info =
        g_dbus_node_info_new_for_xml(kSniIntrospectionXml, &error);
    if (g_tray.sni_node_info == nullptr)
      return FALSE;
  }
  if (g_tray.menu_node_info == nullptr) {
    g_tray.menu_node_info =
        g_dbus_node_info_new_for_xml(kDbusMenuIntrospectionXml, &error);
    if (g_tray.menu_node_info == nullptr)
      return FALSE;
  }
  if (g_tray.sni_reg_id == 0) {
    g_tray.sni_reg_id = g_dbus_connection_register_object(
        g_tray.bus, "/StatusNotifierItem", g_tray.sni_node_info->interfaces[0],
        &kSniVTable, nullptr, nullptr, &error);
  }
  if (g_tray.menu_reg_id == 0) {
    g_tray.menu_reg_id = g_dbus_connection_register_object(
        g_tray.bus, "/MenuBar", g_tray.menu_node_info->interfaces[0],
        &kDbusMenuVTable, nullptr, nullptr, &error);
  }
  if (g_tray.bus_owner_id == 0) {
    g_tray.instance_counter++;
    g_clear_pointer(&g_tray.bus_name, g_free);
    g_tray.bus_name =
        g_strdup_printf("org.kde.StatusNotifierItem-%d-%u",
                        static_cast<int>(getpid()), g_tray.instance_counter);
    g_tray.bus_owner_id = g_bus_own_name_on_connection(
        g_tray.bus, g_tray.bus_name, G_BUS_NAME_OWNER_FLAGS_NONE,
        on_tray_bus_name_acquired, nullptr, nullptr, nullptr);
  } else if (g_tray.bus_name != nullptr) {
    g_dbus_connection_call(
        g_tray.bus, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher", "RegisterStatusNotifierItem",
        g_variant_new("(s)", g_tray.bus_name), nullptr, G_DBUS_CALL_FLAGS_NONE,
        -1, nullptr, nullptr, nullptr);
  }
  return TRUE;
}

static void tray_unregister() {
  g_tray.hide_on_close = FALSE;
  if (g_tray.window_hidden) {
    tray_show_main_window();
  }
  if (g_tray.bus != nullptr) {
    if (g_tray.sni_reg_id != 0) {
      g_dbus_connection_emit_signal(g_tray.bus, nullptr, "/StatusNotifierItem",
                                    "org.kde.StatusNotifierItem", "NewStatus",
                                    g_variant_new("(s)", "Passive"), nullptr);
      g_dbus_connection_unregister_object(g_tray.bus, g_tray.sni_reg_id);
      g_tray.sni_reg_id = 0;
    }
    if (g_tray.menu_reg_id != 0) {
      g_dbus_connection_unregister_object(g_tray.bus, g_tray.menu_reg_id);
      g_tray.menu_reg_id = 0;
    }
  }
  if (g_tray.bus_owner_id != 0) {
    g_bus_unown_name(g_tray.bus_owner_id);
    g_tray.bus_owner_id = 0;
  }
  g_clear_pointer(&g_tray.bus_name, g_free);
}

static gboolean on_main_window_delete_event(GtkWidget *widget, GdkEvent *event,
                                            gpointer user_data) {
  if (g_tray.hide_on_close) {
    tray_hide_main_window();
    tray_dispatch_event("windowHiddenToTray", nullptr);
    return TRUE;
  }
  return FALSE;
}

static void tray_method_call_handler(FlMethodChannel *channel,
                                     FlMethodCall *method_call,
                                     gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "isAvailable") == 0) {
    g_autoptr(FlValue) res = fl_value_new_bool(tray_is_host_available());
    fl_method_call_respond_success(method_call, res, nullptr);
  } else if (strcmp(method, "show") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        g_clear_pointer(&g_tray.title, g_free);
        g_tray.title = g_strdup(fl_value_get_string(v));
      }
      if ((v = fl_value_lookup_string(args, "tooltip")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        g_clear_pointer(&g_tray.tooltip, g_free);
        g_tray.tooltip = g_strdup(fl_value_get_string(v));
      }
      if ((v = fl_value_lookup_string(args, "iconName")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        g_clear_pointer(&g_tray.icon_name, g_free);
        g_tray.icon_name = g_strdup(fl_value_get_string(v));
      }
      tray_replace_menu_items(fl_value_lookup_string(args, "menuItems"));
    }
    gboolean ok = tray_ensure_registered();
    if (ok && g_tray.bus != nullptr && g_tray.sni_reg_id != 0) {
      g_dbus_connection_emit_signal(g_tray.bus, nullptr, "/StatusNotifierItem",
                                    "org.kde.StatusNotifierItem", "NewIcon",
                                    nullptr, nullptr);
      g_dbus_connection_emit_signal(g_tray.bus, nullptr, "/StatusNotifierItem",
                                    "org.kde.StatusNotifierItem", "NewTitle",
                                    nullptr, nullptr);
      g_dbus_connection_emit_signal(g_tray.bus, nullptr, "/StatusNotifierItem",
                                    "org.kde.StatusNotifierItem", "NewToolTip",
                                    nullptr, nullptr);
    }
    g_autoptr(FlValue) res = fl_value_new_bool(ok);
    fl_method_call_respond_success(method_call, res, nullptr);
  } else if (strcmp(method, "updateMenu") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      tray_replace_menu_items(fl_value_lookup_string(args, "menuItems"));
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "setHideOnClose") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = fl_value_lookup_string(args, "enabled");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) {
        g_tray.hide_on_close = fl_value_get_bool(v);
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "hideWindow") == 0) {
    tray_hide_main_window();
    tray_dispatch_event("windowHiddenToTray", nullptr);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "showWindow") == 0) {
    tray_show_main_window();
    tray_dispatch_event("windowRestored", nullptr);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "hide") == 0) {
    tray_unregister();
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterTrayBridge(FlPluginRegistrar* registrar, GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* tray_channel = fl_method_channel_new(
      messenger, kTrayChannelName, FL_METHOD_CODEC(codec));
  g_tray.channel = tray_channel;
  g_tray.window = window;
  fl_method_channel_set_method_call_handler(
      tray_channel, tray_method_call_handler, window, nullptr);
  g_signal_connect(window, "delete-event",
                   G_CALLBACK(on_main_window_delete_event), nullptr);
}

void UnregisterTrayBridge() {
  tray_unregister();
}

}  // namespace libadwaitter
