#include "media/mpris_bridge.h"

#include <cstring>
#include <unistd.h>

#include "common/portal_result.h"

namespace {

const char* kMediaChannelName = "libadwaitter/media";

static const gchar kMprisIntrospectionXml[] =
    "<node>"
    "  <interface name='org.mpris.MediaPlayer2'>"
    "    <method name='Raise'/>"
    "    <method name='Quit'/>"
    "    <property name='CanQuit' type='b' access='read'/>"
    "    <property name='CanRaise' type='b' access='read'/>"
    "    <property name='HasTrackList' type='b' access='read'/>"
    "    <property name='Identity' type='s' access='read'/>"
    "    <property name='DesktopEntry' type='s' access='read'/>"
    "    <property name='SupportedUriSchemes' type='as' access='read'/>"
    "    <property name='SupportedMimeTypes' type='as' access='read'/>"
    "  </interface>"
    "  <interface name='org.mpris.MediaPlayer2.Player'>"
    "    <method name='Next'/>"
    "    <method name='Previous'/>"
    "    <method name='Pause'/>"
    "    <method name='PlayPause'/>"
    "    <method name='Stop'/>"
    "    <method name='Play'/>"
    "    <method name='Seek'>"
    "      <arg name='Offset' type='x' direction='in'/>"
    "    </method>"
    "    <method name='SetPosition'>"
    "      <arg name='TrackId' type='o' direction='in'/>"
    "      <arg name='Position' type='x' direction='in'/>"
    "    </method>"
    "    <signal name='Seeked'>"
    "      <arg name='Position' type='x'/>"
    "    </signal>"
    "    <property name='PlaybackStatus' type='s' access='read'/>"
    "    <property name='LoopStatus' type='s' access='readwrite'/>"
    "    <property name='Rate' type='d' access='read'/>"
    "    <property name='Shuffle' type='b' access='readwrite'/>"
    "    <property name='Metadata' type='a{sv}' access='read'/>"
    "    <property name='Volume' type='d' access='read'/>"
    "    <property name='Position' type='x' access='read'/>"
    "    <property name='MinimumRate' type='d' access='read'/>"
    "    <property name='MaximumRate' type='d' access='read'/>"
    "    <property name='CanGoNext' type='b' access='read'/>"
    "    <property name='CanGoPrevious' type='b' access='read'/>"
    "    <property name='CanPlay' type='b' access='read'/>"
    "    <property name='CanPause' type='b' access='read'/>"
    "    <property name='CanSeek' type='b' access='read'/>"
    "    <property name='CanControl' type='b' access='read'/>"
    "  </interface>"
    "</node>";

struct MprisState {
  GDBusConnection *bus;
  GDBusNodeInfo *node_info;
  guint bus_owner_id;
  guint root_reg_id;
  guint player_reg_id;
  FlMethodChannel *channel;
  GtkWindow *window;
  gchar *title;
  gchar *artist;
  gchar *album;
  gchar *art_url;
  gchar *track_id;
  gint64 duration_us;
  gint64 position_us;
  gint64 position_ts_us;
  gchar *playback_status;
  gchar *loop_status;
  gboolean shuffle;
  gdouble rate;
  gboolean can_go_next;
  gboolean can_go_previous;
  gboolean can_play;
  gboolean can_pause;
  gboolean can_seek;
};

static MprisState g_mpris = {};

static gint64 mpris_current_position_us() {
  gint64 pos = g_mpris.position_us;
  if (g_mpris.playback_status != nullptr &&
      strcmp(g_mpris.playback_status, "Playing") == 0 &&
      g_mpris.position_ts_us > 0) {
    gint64 elapsed = g_get_monotonic_time() - g_mpris.position_ts_us;
    if (elapsed > 0) {
      pos += static_cast<gint64>(elapsed *
                                 (g_mpris.rate > 0 ? g_mpris.rate : 1.0));
    }
  }
  if (g_mpris.duration_us > 0 && pos > g_mpris.duration_us) {
    pos = g_mpris.duration_us;
  }
  return pos < 0 ? 0 : pos;
}

static GVariant *mpris_build_metadata_variant() {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  const gchar *tid = (g_mpris.track_id != nullptr &&
                      g_variant_is_object_path(g_mpris.track_id))
                         ? g_mpris.track_id
                         : "/org/libadwaitter/track/0";
  g_variant_builder_add(&builder, "{sv}", "mpris:trackid",
                        g_variant_new_object_path(tid));
  if (g_mpris.duration_us > 0) {
    g_variant_builder_add(&builder, "{sv}", "mpris:length",
                          g_variant_new_int64(g_mpris.duration_us));
  }
  if (g_mpris.title != nullptr && g_mpris.title[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "xesam:title",
                          g_variant_new_string(g_mpris.title));
  }
  if (g_mpris.artist != nullptr && g_mpris.artist[0] != '\0') {
    GVariantBuilder artist_builder;
    g_variant_builder_init(&artist_builder, G_VARIANT_TYPE("as"));
    g_variant_builder_add(&artist_builder, "s", g_mpris.artist);
    g_variant_builder_add(&builder, "{sv}", "xesam:artist",
                          g_variant_builder_end(&artist_builder));
  }
  if (g_mpris.album != nullptr && g_mpris.album[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "xesam:album",
                          g_variant_new_string(g_mpris.album));
  }
  if (g_mpris.art_url != nullptr && g_mpris.art_url[0] != '\0') {
    g_variant_builder_add(&builder, "{sv}", "mpris:artUrl",
                          g_variant_new_string(g_mpris.art_url));
  }
  return g_variant_builder_end(&builder);
}

static void mpris_dispatch_command(const char *command, gboolean has_offset,
                                   gint64 offset_us, gboolean has_position,
                                   gint64 position_us) {
  if (g_mpris.channel == nullptr)
    return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "command", fl_value_new_string(command));
  if (has_offset) {
    fl_value_set_string_take(map, "offsetUs", fl_value_new_int(offset_us));
  }
  if (has_position) {
    fl_value_set_string_take(map, "positionUs", fl_value_new_int(position_us));
  }
  fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                  nullptr, nullptr, nullptr);
}

static void
mpris_root_method_call(GDBusConnection *connection, const gchar *sender,
                       const gchar *object_path, const gchar *interface_name,
                       const gchar *method_name, GVariant *parameters,
                       GDBusMethodInvocation *invocation, gpointer user_data) {
  if (strcmp(method_name, "Raise") == 0) {
    if (g_mpris.window != nullptr) {
      gtk_window_present(g_mpris.window);
    }
    mpris_dispatch_command("raise", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Quit") == 0) {
    mpris_dispatch_command("quit", FALSE, 0, FALSE, 0);
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant *mpris_root_get_property(GDBusConnection *connection,
                                         const gchar *sender,
                                         const gchar *object_path,
                                         const gchar *interface_name,
                                         const gchar *property_name,
                                         GError **error, gpointer user_data) {
  if (strcmp(property_name, "CanQuit") == 0)
    return g_variant_new_boolean(TRUE);
  if (strcmp(property_name, "CanRaise") == 0)
    return g_variant_new_boolean(TRUE);
  if (strcmp(property_name, "HasTrackList") == 0)
    return g_variant_new_boolean(FALSE);
  if (strcmp(property_name, "Identity") == 0) {
    const gchar *name = g_get_application_name();
    return g_variant_new_string(name != nullptr ? name : libadwaitter::GetApplicationId());
  }
  if (strcmp(property_name, "DesktopEntry") == 0) {
    return g_variant_new_string(libadwaitter::GetApplicationId());
  }
  if (strcmp(property_name, "SupportedUriSchemes") == 0 ||
      strcmp(property_name, "SupportedMimeTypes") == 0) {
    return g_variant_new_strv(nullptr, 0);
  }
  return nullptr;
}

static void mpris_player_method_call(
    GDBusConnection *connection, const gchar *sender, const gchar *object_path,
    const gchar *interface_name, const gchar *method_name, GVariant *parameters,
    GDBusMethodInvocation *invocation, gpointer user_data) {
  if (strcmp(method_name, "Play") == 0) {
    mpris_dispatch_command("play", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Pause") == 0) {
    mpris_dispatch_command("pause", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "PlayPause") == 0) {
    mpris_dispatch_command("playPause", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Stop") == 0) {
    mpris_dispatch_command("stop", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Next") == 0) {
    mpris_dispatch_command("next", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Previous") == 0) {
    mpris_dispatch_command("previous", FALSE, 0, FALSE, 0);
  } else if (strcmp(method_name, "Seek") == 0) {
    gint64 offset = 0;
    g_variant_get(parameters, "(x)", &offset);
    mpris_dispatch_command("seek", TRUE, offset, FALSE, 0);
  } else if (strcmp(method_name, "SetPosition") == 0) {
    const gchar *tid = nullptr;
    gint64 pos = 0;
    g_variant_get(parameters, "(&ox)", &tid, &pos);
    mpris_dispatch_command("setPosition", FALSE, 0, TRUE, pos);
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

static GVariant *mpris_player_get_property(GDBusConnection *connection,
                                           const gchar *sender,
                                           const gchar *object_path,
                                           const gchar *interface_name,
                                           const gchar *property_name,
                                           GError **error, gpointer user_data) {
  if (strcmp(property_name, "PlaybackStatus") == 0) {
    return g_variant_new_string(g_mpris.playback_status != nullptr
                                    ? g_mpris.playback_status
                                    : "Stopped");
  }
  if (strcmp(property_name, "LoopStatus") == 0) {
    return g_variant_new_string(
        g_mpris.loop_status != nullptr ? g_mpris.loop_status : "None");
  }
  if (strcmp(property_name, "Rate") == 0) {
    return g_variant_new_double(g_mpris.rate > 0 ? g_mpris.rate : 1.0);
  }
  if (strcmp(property_name, "Shuffle") == 0) {
    return g_variant_new_boolean(g_mpris.shuffle);
  }
  if (strcmp(property_name, "Metadata") == 0) {
    return mpris_build_metadata_variant();
  }
  if (strcmp(property_name, "Volume") == 0)
    return g_variant_new_double(1.0);
  if (strcmp(property_name, "Position") == 0) {
    return g_variant_new_int64(mpris_current_position_us());
  }
  if (strcmp(property_name, "MinimumRate") == 0)
    return g_variant_new_double(1.0);
  if (strcmp(property_name, "MaximumRate") == 0)
    return g_variant_new_double(1.0);
  if (strcmp(property_name, "CanGoNext") == 0)
    return g_variant_new_boolean(g_mpris.can_go_next);
  if (strcmp(property_name, "CanGoPrevious") == 0)
    return g_variant_new_boolean(g_mpris.can_go_previous);
  if (strcmp(property_name, "CanPlay") == 0)
    return g_variant_new_boolean(g_mpris.can_play);
  if (strcmp(property_name, "CanPause") == 0)
    return g_variant_new_boolean(g_mpris.can_pause);
  if (strcmp(property_name, "CanSeek") == 0)
    return g_variant_new_boolean(g_mpris.can_seek);
  if (strcmp(property_name, "CanControl") == 0)
    return g_variant_new_boolean(TRUE);
  return nullptr;
}

static const GDBusInterfaceVTable kMprisRootVTable = {
    mpris_root_method_call,
    mpris_root_get_property,
    nullptr,
    {0},
};

static void mpris_emit_properties_changed(GVariant *changed_props);

static gboolean
mpris_player_set_property(GDBusConnection *connection, const gchar *sender,
                          const gchar *object_path, const gchar *interface_name,
                          const gchar *property_name, GVariant *value,
                          GError **error, gpointer user_data) {
  if (strcmp(property_name, "LoopStatus") == 0 &&
      g_variant_is_of_type(value, G_VARIANT_TYPE_STRING)) {
    const gchar *s = g_variant_get_string(value, nullptr);
    g_clear_pointer(&g_mpris.loop_status, g_free);
    const char *dart_mode = "none";
    if (strcmp(s, "Track") == 0) {
      g_mpris.loop_status = g_strdup("Track");
      dart_mode = "track";
    } else if (strcmp(s, "Playlist") == 0) {
      g_mpris.loop_status = g_strdup("Playlist");
      dart_mode = "playlist";
    } else {
      g_mpris.loop_status = g_strdup("None");
      dart_mode = "none";
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "LoopStatus",
                          g_variant_new_string(g_mpris.loop_status));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    if (g_mpris.channel != nullptr) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set_string_take(map, "command",
                               fl_value_new_string("setLoopMode"));
      fl_value_set_string_take(map, "loopMode", fl_value_new_string(dart_mode));
      fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                      nullptr, nullptr, nullptr);
    }
    return TRUE;
  }
  if (strcmp(property_name, "Shuffle") == 0 &&
      g_variant_is_of_type(value, G_VARIANT_TYPE_BOOLEAN)) {
    g_mpris.shuffle = g_variant_get_boolean(value);
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "Shuffle",
                          g_variant_new_boolean(g_mpris.shuffle));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    if (g_mpris.channel != nullptr) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set_string_take(map, "command",
                               fl_value_new_string("setShuffle"));
      fl_value_set_string_take(map, "shuffle",
                               fl_value_new_bool(g_mpris.shuffle));
      fl_method_channel_invoke_method(g_mpris.channel, "onMediaCommand", map,
                                      nullptr, nullptr, nullptr);
    }
    return TRUE;
  }
  return FALSE;
}

static const GDBusInterfaceVTable kMprisPlayerVTable = {
    mpris_player_method_call,
    mpris_player_get_property,
    mpris_player_set_property,
    {0},
};

static void mpris_ensure_registered() {
  if (g_mpris.bus_owner_id != 0)
    return;
  g_autoptr(GError) error = nullptr;
  if (g_mpris.bus == nullptr) {
    g_mpris.bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (g_mpris.bus == nullptr)
      return;
  }
  if (g_mpris.node_info == nullptr) {
    g_mpris.node_info =
        g_dbus_node_info_new_for_xml(kMprisIntrospectionXml, &error);
    if (g_mpris.node_info == nullptr)
      return;
  }
  if (g_mpris.root_reg_id == 0) {
    g_mpris.root_reg_id = g_dbus_connection_register_object(
        g_mpris.bus, "/org/mpris/MediaPlayer2",
        g_mpris.node_info->interfaces[0], &kMprisRootVTable, nullptr, nullptr,
        &error);
  }
  if (g_mpris.player_reg_id == 0) {
    g_mpris.player_reg_id = g_dbus_connection_register_object(
        g_mpris.bus, "/org/mpris/MediaPlayer2",
        g_mpris.node_info->interfaces[1], &kMprisPlayerVTable, nullptr, nullptr,
        &error);
  }
  g_autofree gchar *sanitized = g_strdup(libadwaitter::GetApplicationId());
  for (gchar *p = sanitized; *p != '\0'; ++p) {
    if (!g_ascii_isalnum(*p) && *p != '_')
      *p = '_';
  }
  g_autofree gchar *bus_name =
      g_strdup_printf("org.mpris.MediaPlayer2.%s.instance%d", sanitized,
                      static_cast<int>(getpid()));
  g_mpris.bus_owner_id = g_bus_own_name_on_connection(
      g_mpris.bus, bus_name, G_BUS_NAME_OWNER_FLAGS_NONE, nullptr, nullptr,
      nullptr, nullptr);
}

static void mpris_emit_properties_changed(GVariant *changed_props) {
  if (g_mpris.bus == nullptr || g_mpris.bus_owner_id == 0) {
    g_variant_unref(g_variant_ref_sink(changed_props));
    return;
  }
  GVariantBuilder invalidated;
  g_variant_builder_init(&invalidated, G_VARIANT_TYPE("as"));
  g_dbus_connection_emit_signal(
      g_mpris.bus, nullptr, "/org/mpris/MediaPlayer2",
      "org.freedesktop.DBus.Properties", "PropertiesChanged",
      g_variant_new("(s@a{sv}as)", "org.mpris.MediaPlayer2.Player",
                    changed_props, &invalidated),
      nullptr);
}

static void mpris_unregister() {
  if (g_mpris.bus != nullptr) {
    if (g_mpris.root_reg_id != 0) {
      g_dbus_connection_unregister_object(g_mpris.bus, g_mpris.root_reg_id);
      g_mpris.root_reg_id = 0;
    }
    if (g_mpris.player_reg_id != 0) {
      g_dbus_connection_unregister_object(g_mpris.bus, g_mpris.player_reg_id);
      g_mpris.player_reg_id = 0;
    }
  }
  if (g_mpris.bus_owner_id != 0) {
    g_bus_unown_name(g_mpris.bus_owner_id);
    g_mpris.bus_owner_id = 0;
  }
}

static void media_method_call_handler(FlMethodChannel *channel,
                                      FlMethodCall *method_call,
                                      gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "setMetadata") == 0) {
    mpris_ensure_registered();
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      g_clear_pointer(&g_mpris.title, g_free);
      g_clear_pointer(&g_mpris.artist, g_free);
      g_clear_pointer(&g_mpris.album, g_free);
      g_clear_pointer(&g_mpris.art_url, g_free);
      g_clear_pointer(&g_mpris.track_id, g_free);
      g_mpris.duration_us = 0;

      if ((v = fl_value_lookup_string(args, "title")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.title = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "artist")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.artist = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "album")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.album = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "artUrl")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.art_url = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "trackId")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        g_mpris.track_id = g_strdup(fl_value_get_string(v));
      if ((v = fl_value_lookup_string(args, "durationUs")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_INT)
        g_mpris.duration_us = fl_value_get_int(v);
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&changed, "{sv}", "Metadata",
                          mpris_build_metadata_variant());
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "setPlaybackState") == 0) {
    mpris_ensure_registered();
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "status")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        const gchar *s = fl_value_get_string(v);
        g_clear_pointer(&g_mpris.playback_status, g_free);
        if (strcmp(s, "playing") == 0)
          g_mpris.playback_status = g_strdup("Playing");
        else if (strcmp(s, "paused") == 0)
          g_mpris.playback_status = g_strdup("Paused");
        else
          g_mpris.playback_status = g_strdup("Stopped");
      }
      if ((v = fl_value_lookup_string(args, "positionUs")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
        g_mpris.position_us = fl_value_get_int(v);
        g_mpris.position_ts_us = g_get_monotonic_time();
      }
      if ((v = fl_value_lookup_string(args, "rate")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) {
        g_mpris.rate = fl_value_get_float(v);
      }
      if ((v = fl_value_lookup_string(args, "loopMode")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        const gchar *lm = fl_value_get_string(v);
        g_clear_pointer(&g_mpris.loop_status, g_free);
        if (strcmp(lm, "track") == 0)
          g_mpris.loop_status = g_strdup("Track");
        else if (strcmp(lm, "playlist") == 0)
          g_mpris.loop_status = g_strdup("Playlist");
        else
          g_mpris.loop_status = g_strdup("None");
      }
      if ((v = fl_value_lookup_string(args, "shuffle")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) {
        g_mpris.shuffle = fl_value_get_bool(v);
      }
      if ((v = fl_value_lookup_string(args, "canGoNext")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_go_next = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canGoPrevious")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_go_previous = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canPlay")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_play = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canPause")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_pause = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "canSeek")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        g_mpris.can_seek = fl_value_get_bool(v);
    }
    GVariantBuilder changed;
    g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(
        &changed, "{sv}", "PlaybackStatus",
        g_variant_new_string(g_mpris.playback_status != nullptr
                                 ? g_mpris.playback_status
                                 : "Stopped"));
    g_variant_builder_add(&changed, "{sv}", "LoopStatus",
                          g_variant_new_string(g_mpris.loop_status != nullptr
                                                   ? g_mpris.loop_status
                                                   : "None"));
    g_variant_builder_add(&changed, "{sv}", "Shuffle",
                          g_variant_new_boolean(g_mpris.shuffle));
    g_variant_builder_add(&changed, "{sv}", "CanGoNext",
                          g_variant_new_boolean(g_mpris.can_go_next));
    g_variant_builder_add(&changed, "{sv}", "CanGoPrevious",
                          g_variant_new_boolean(g_mpris.can_go_previous));
    g_variant_builder_add(&changed, "{sv}", "CanPlay",
                          g_variant_new_boolean(g_mpris.can_play));
    g_variant_builder_add(&changed, "{sv}", "CanPause",
                          g_variant_new_boolean(g_mpris.can_pause));
    g_variant_builder_add(&changed, "{sv}", "CanSeek",
                          g_variant_new_boolean(g_mpris.can_seek));
    mpris_emit_properties_changed(g_variant_builder_end(&changed));
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "setPosition") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = fl_value_lookup_string(args, "positionUs");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
        g_mpris.position_us = fl_value_get_int(v);
        g_mpris.position_ts_us = g_get_monotonic_time();
        if (g_mpris.bus != nullptr && g_mpris.bus_owner_id != 0) {
          g_dbus_connection_emit_signal(
              g_mpris.bus, nullptr, "/org/mpris/MediaPlayer2",
              "org.mpris.MediaPlayer2.Player", "Seeked",
              g_variant_new("(x)", g_mpris.position_us), nullptr);
        }
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "dispose") == 0) {
    mpris_unregister();
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterMprisBridge(FlPluginRegistrar* registrar, GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* media_channel = fl_method_channel_new(
      messenger, kMediaChannelName, FL_METHOD_CODEC(codec));
  g_mpris.channel = media_channel;
  g_mpris.window = window;
  fl_method_channel_set_method_call_handler(
      media_channel, media_method_call_handler, window, nullptr);
}

void UnregisterMprisBridge() {
  mpris_unregister();
}

}  // namespace libadwaitter
