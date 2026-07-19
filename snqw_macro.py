import pyautogui
import keyboard
import time
import random
import pygetwindow as gw
import threading
import tkinter as tk
from tkinter import ttk
import json
import os
import sys
import http.server
import socketserver
from urllib.parse import urlparse

pyautogui.FAILSAFE = False
CONFIG_PATH = os.path.join(
    os.environ.get("TEMP", os.path.expanduser("~")), "snqw_config.json"
)
PORT = 18723

config = {
    "god_mode": False,
    "auto_farm": False,
    "auto_boss": False,
    "auto_loot": False,
    "auto_rank": False,
    "auto_stat": False,
    "auto_skill": False,
    "auto_dodge": False,
    "afk": False,
    "kill": False,
    "fly": False,
    "speed": False,
    "aim": False,
    "esp": False,
    "inf_jump": False,
    "spin_bl": False,
    "spin_element": False,
    "auto_buy": False,
    "farm_rad": 150,
    "kill_rad": 200,
    "boss_rad": 500,
    "click_min": 0.08,
    "click_max": 0.15,
    "skill_keys": "1,2",
    "skill_interval": 0.8,
    "dodge_key": "q",
    "dodge_interval": 2.0,
}

running = False
dodge_forced = False
server = None


def find_roblox():
    for w in gw.getWindowsWithTitle("Roblox"):
        if w.visible:
            return w
    return None


def is_foreground():
    w = find_roblox()
    return w and w.isActive


def save_config():
    global config
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/config" or parsed.path == "/snqw_config.json":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(config).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass


def start_server():
    global server
    try:
        server = socketserver.TCPServer(("127.0.0.1", PORT), Handler)
        t = threading.Thread(target=server.serve_forever, daemon=True)
        t.start()
    except:
        pass


def combat_loop():
    global running
    last_skill = 0
    last_dodge = 0
    keys = [k.strip() for k in config["skill_keys"].split(",")]
    while True:
        if running and is_foreground():
            now = time.time()
            pyautogui.click()
            time.sleep(random.uniform(config["click_min"], config["click_max"]))
            pyautogui.click()
            if now - last_skill > config["skill_interval"]:
                for k in keys:
                    pyautogui.press(k)
                    time.sleep(random.uniform(0.05, 0.1))
                last_skill = now
            if (config["auto_dodge"] or dodge_forced) and now - last_dodge > config[
                "dodge_interval"
            ]:
                pyautogui.press(config["dodge_key"])
                last_dodge = now
            time.sleep(random.uniform(0.03, 0.06))
        else:
            time.sleep(0.1)


def toggle(key):
    config[key] = not config[key]
    save_config()


def set_val(key, val):
    config[key] = val
    save_config()


class App:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Snqw Macro")
        self.root.geometry("380+600+300")
        self.root.resizable(False, False)
        self.root.protocol("WM_DELETE_WINDOW", self.hide)
        self.root.configure(bg="#1a1a1a")

        main = tk.Frame(self.root, bg="#1a1a1a")
        main.pack(fill="both", expand=True, padx=10, pady=10)

        tk.Label(
            main,
            text="SNQW .0GH",
            font=("Segoe UI", 16, "bold"),
            fg="#ccc",
            bg="#1a1a1a",
        ).pack()

        self.f_status = tk.Frame(main, bg="#1a1a1a")
        self.f_status.pack(fill="x", pady=4)
        self.lbl = tk.Label(
            self.f_status,
            text="STOPPED",
            fg="red",
            font=("Segoe UI", 10, "bold"),
            bg="#1a1a1a",
        )
        self.lbl.pack(side="left", padx=5)

        nb = ttk.Notebook(main)
        nb.pack(fill="both", expand=True, pady=6)

        self.tabs = {}
        for name in ["COMBAT", "FARM", "MOVE", "AIM", "VISUAL", "AUTO", "MISC"]:
            f = tk.Frame(nb, bg="#222")
            nb.add(f, text=name)
            self.tabs[name] = f

        self.build()

        keyboard.add_hotkey("f6", self.toggle_run)
        keyboard.add_hotkey("f7", self.force_dodge)
        keyboard.add_hotkey("end", self.quit)

        t = threading.Thread(target=combat_loop, daemon=True)
        t.start()
        start_server()
        save_config()
        self.root.mainloop()

    def build(self):
        c = self.tabs["COMBAT"]
        self.tog(c, "Autokill", "kill")
        self.tog(c, "God Mode", "god_mode")
        self.btn(c, "Heal")
        self.rad(c, "Kill Range", "kill_rad", [50, 100, 150, 200, 300, 500], 200)

        f = self.tabs["FARM"]
        self.btn2(f, "GOD MODE", self.toggle_all)
        self.tog(f, "Auto Farm", "auto_farm")
        self.tog(f, "Auto Boss", "auto_boss")
        self.tog(f, "Auto Loot", "auto_loot")
        self.tog(f, "Auto Rank", "auto_rank")
        self.rad(f, "Farm Range", "farm_rad", [50, 100, 150, 200, 300, 400], 150)
        self.rad(f, "Boss Range", "boss_rad", [200, 300, 500, 800, 1000], 500)

        m = self.tabs["MOVE"]
        self.tog(m, "Fly", "fly")
        self.rad(m, "Fly Speed", "fly_spd", [25, 50, 75, 100, 150, 200], 75)
        self.tog(m, "WalkSpeed", "speed")
        self.rad(m, "WS Amt", "spd_amt", [20, 30, 50, 80, 100, 150], 50)
        self.tog(m, "Inf Jump", "inf_jump")

        a = self.tabs["AIM"]
        self.tog(a, "Aimbot", "aim")
        self.rad(a, "Aim Range", "aim_rad", [100, 200, 300, 400, 500], 300)
        self.tog(a, "Auto Atk", "aim_atk")

        v = self.tabs["VISUAL"]
        self.tog(v, "ESP", "esp")
        self.btn(v, "Fullbright")

        au = self.tabs["AUTO"]
        self.tog(au, "Auto Stat", "auto_stat")
        self.tog(au, "Auto Skill", "auto_skill")
        self.tog(au, "Auto Dodge", "auto_dodge")
        self.tog(au, "Spin Bloodline", "spin_bl")
        self.tog(au, "Spin Element", "spin_element")
        self.tog(au, "Auto Buy", "auto_buy")

        mi = self.tabs["MISC"]
        self.tog(mi, "Anti-AFK", "afk")
        self.rad(mi, "Click Min (s)", "click_min", [0.03, 0.05, 0.08, 0.1, 0.15], 0.08)
        self.rad(mi, "Click Max (s)", "click_max", [0.08, 0.1, 0.15, 0.2, 0.3], 0.15)
        self.rad(mi, "Skill Interval", "skill_interval", [0.3, 0.5, 0.8, 1.0, 1.5], 0.8)

        tk.Label(
            self.root,
            text="F6=Start/Stop  F7=Dodge  End=Quit",
            fg="#555",
            bg="#1a1a1a",
            font=("Segoe UI", 8),
        ).pack()

    def tog(self, parent, label, key):
        fr = tk.Frame(parent, bg="#222")
        fr.pack(fill="x", pady=1)
        var = tk.BooleanVar(value=config.get(key, False))
        cb = tk.Checkbutton(
            fr,
            text=label,
            variable=var,
            fg="#ddd",
            bg="#222",
            activebackground="#333",
            activeforeground="#fff",
            selectcolor="#333",
            font=("Segoe UI", 10),
            command=lambda k=key, v=var: [toggle(k), self.update_lbl()],
        )
        cb.pack(side="left", padx=5, pady=2)
        self.set_tab_color(parent)

    def rad(self, parent, label, key, opts, default):
        fr = tk.Frame(parent, bg="#222")
        fr.pack(fill="x", pady=1)
        tk.Label(fr, text=label + ":", fg="#aaa", bg="#222", font=("Segoe UI", 9)).pack(
            side="left", padx=5
        )
        var = tk.StringVar(value=str(config.get(key, default)))
        m = ttk.Combobox(
            fr,
            textvariable=var,
            values=[str(o) for o in opts],
            width=8,
            state="readonly",
        )
        m.pack(side="right", padx=5)

        def cb(e=None, k=key, v=var):
            try:
                val = float(v.get()) if "." in v.get() else int(v.get())
                set_val(k, val)
            except:
                pass

        m.bind("<<ComboboxSelected>>", cb)

    def btn(self, parent, label):
        b = tk.Button(
            parent,
            text=label,
            bg="#333",
            fg="#ddd",
            activebackground="#555",
            activeforeground="#fff",
            font=("Segoe UI", 9),
            bd=0,
            padx=10,
        )
        b.pack(pady=2, padx=5, fill="x")

    def btn2(self, parent, label, cb):
        b = tk.Button(
            parent,
            text=label,
            bg="#2a5a2a",
            fg="#fff",
            activebackground="#3a7a3a",
            activeforeground="#fff",
            font=("Segoe UI", 11, "bold"),
            bd=0,
            padx=10,
            pady=4,
            command=cb,
        )
        b.pack(pady=4, padx=5, fill="x")

    def set_tab_color(self, parent):
        for w in parent.winfo_children():
            w.configure(bg="#222")

    def toggle_all(self):
        v = not config.get("god_mode", False)
        for k in [
            "god_mode",
            "auto_farm",
            "auto_boss",
            "auto_loot",
            "auto_rank",
            "auto_stat",
            "auto_skill",
            "auto_dodge",
            "afk",
            "kill",
            "spin_bl",
            "spin_element",
            "auto_buy",
        ]:
            config[k] = v
        save_config()
        self.update_lbl()

    def toggle_run(self):
        global running
        running = not running
        self.lbl.config(
            text="RUNNING" if running else "STOPPED", fg="green" if running else "red"
        )

    def force_dodge(self):
        global dodge_forced
        dodge_forced = not dodge_forced

    def update_lbl(self):
        pass

    def hide(self):
        self.root.withdraw()

    def quit(self):
        global running, server
        running = False
        if server:
            server.shutdown()
        self.root.quit()
        raise SystemExit(0)


if __name__ == "__main__":
    App()
