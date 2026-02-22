#!/usr/bin/env python3
"""Single dialog for naming a screen recording and selecting post-processing."""

import sys
import tkinter as tk

MAX_CHARS = 50


def main():
    root = tk.Tk()
    root.title("Save Screen Recording")
    root.resizable(False, False)

    # File name entry
    tk.Label(root, text=f"File name (max {MAX_CHARS} characters):").pack(
        anchor="w", padx=12, pady=(12, 4)
    )
    name_var = tk.StringVar()
    entry = tk.Entry(root, textvariable=name_var, width=40)
    entry.pack(padx=12)
    entry.focus_set()

    # Character limit enforcement
    def on_key(event):
        value = name_var.get()
        if len(value) > MAX_CHARS:
            name_var.set(value[:MAX_CHARS])
            entry.icursor(MAX_CHARS)

    entry.bind("<KeyRelease>", on_key)

    # Post-processing checkbox
    skip_var = tk.BooleanVar(value=False)
    tk.Checkbutton(root, text="Skip frames", variable=skip_var).pack(
        anchor="w", padx=12, pady=(8, 4)
    )

    # Buttons
    def on_ok(event=None):
        name = name_var.get().strip()[:MAX_CHARS]
        skip = "1" if skip_var.get() else "0"
        print(f"{name}\n{skip}")
        root.destroy()

    def on_cancel(event=None):
        root.destroy()
        sys.exit(1)

    btn_frame = tk.Frame(root)
    btn_frame.pack(pady=(8, 12))
    tk.Button(btn_frame, text="Cancel", width=8, command=on_cancel).pack(
        side="left", padx=4
    )
    tk.Button(btn_frame, text="Save", width=8, command=on_ok).pack(
        side="left", padx=4
    )

    root.bind("<Return>", on_ok)
    root.bind("<Escape>", on_cancel)
    root.protocol("WM_DELETE_WINDOW", on_cancel)

    # Center on screen
    root.update_idletasks()
    w, h = root.winfo_width(), root.winfo_height()
    x = (root.winfo_screenwidth() - w) // 2
    y = (root.winfo_screenheight() - h) // 2
    root.geometry(f"+{x}+{y}")

    root.mainloop()


if __name__ == "__main__":
    main()
