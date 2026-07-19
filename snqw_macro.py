import pyautogui
import keyboard
import time
import random
import pygetwindow as gw
import sys

pyautogui.FAILSAFE = False

CONFIG = {
    "hotkey": "f6",
    "click_interval": (0.08, 0.15),
    "skill_keys": ["1", "2"],
    "skill_interval": (0.5, 1.0),
    "dodge_key": "q",
    "dodge_hp_check": True,
    "window_title": "Roblox",
}

running = False
dodge_toggle = False


def find_roblox():
    for w in gw.getWindowsWithTitle(CONFIG["window_title"]):
        if w.visible:
            return w
    return None


def is_foreground():
    w = find_roblox()
    return w and w.isActive


def toggle():
    global running
    running = not running
    status = "ON" if running else "OFF"
    print(f"[Snqw Macro] {status}")
    if running:
        pyautogui.keyDown("w")
    else:
        pyautogui.keyUp("w")


def toggle_dodge():
    global dodge_toggle
    dodge_toggle = not dodge_toggle
    print(f"[Snqw Macro] Dodge {'ON' if dodge_toggle else 'OFF'}")


def do_click():
    if not is_foreground():
        return
    pyautogui.click()
    time.sleep(random.uniform(*CONFIG["click_interval"]))
    pyautogui.click()


def do_skills():
    if not is_foreground():
        return
    for k in CONFIG["skill_keys"]:
        pyautogui.press(k)
        time.sleep(random.uniform(0.05, 0.12))
    time.sleep(random.uniform(*CONFIG["skill_interval"]))


def do_dodge():
    if not is_foreground():
        return
    pyautogui.press(CONFIG["dodge_key"])
    time.sleep(random.uniform(0.3, 0.6))


def main():
    print("=== Snqw External Macro ===")
    print(f"Press {CONFIG['hotkey'].upper()} to toggle auto farm")
    print("Press F7 to toggle auto dodge")
    print("Press END to quit")
    print("Roblox must be the active window")

    keyboard.add_hotkey(CONFIG["hotkey"], toggle)
    keyboard.add_hotkey("f7", toggle_dodge)
    keyboard.add_hotkey("end", lambda: sys.exit(0))

    last_skill = 0
    last_dodge = 0

    while True:
        if running:
            now = time.time()
            do_click()

            if now - last_skill > random.uniform(*CONFIG["skill_interval"]):
                do_skills()
                last_skill = now

            if dodge_toggle and now - last_dodge > random.uniform(1.5, 3.0):
                do_dodge()
                last_dodge = now

            time.sleep(random.uniform(0.03, 0.08))
        else:
            time.sleep(0.1)


if __name__ == "__main__":
    main()
