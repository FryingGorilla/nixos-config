"""Mirror this user's Noctalia caffeine inhibitor with a lid-switch inhibitor."""

import os

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    manager = dbus.Interface(
        bus.get_object("org.freedesktop.login1", "/org/freedesktop/login1"),
        "org.freedesktop.login1.Manager",
    )
    lid_fd = None

    def sync():
        nonlocal lid_fd
        try:
            enabled = any(
                who == "noctalia"
                and why == "Caffeine"
                and mode == "block"
                and uid == os.getuid()
                and "idle" in what.split(":")
                for what, who, why, mode, uid, pid in manager.ListInhibitors()
            )
            if enabled and lid_fd is None:
                lid_fd = manager.Inhibit(
                    "handle-lid-switch", "noctalia-caffeine-lid", "Caffeine", "block"
                ).take()
                print("Caffeine on: lid closure ignored", flush=True)
            elif not enabled and lid_fd is not None:
                os.close(lid_fd)
                lid_fd = None
                print("Caffeine off: normal lid handling restored", flush=True)
        except dbus.DBusException as error:
            # Release on failure; systemd restarts us to reconnect to logind.
            if lid_fd is not None:
                os.close(lid_fd)
            print(f"Cannot synchronize caffeine lid behavior: {error}", flush=True)
            os._exit(1)
        return True

    def properties_changed(interface, changed, invalidated):
        if interface == "org.freedesktop.login1.Manager" and (
            "BlockInhibited" in changed or "BlockInhibited" in invalidated
        ):
            sync()

    bus.add_signal_receiver(
        properties_changed,
        signal_name="PropertiesChanged",
        dbus_interface="org.freedesktop.DBus.Properties",
        bus_name="org.freedesktop.login1",
        path="/org/freedesktop/login1",
    )
    sync()
    # Also reconcile if logind coalesces signals while other apps inhibit idle.
    GLib.timeout_add_seconds(2, sync)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
