# Undertale Name Screen for Quickshell

An Undertale inspired character naming screen overlay written in QML for Wayland compositors via Quickshell Includes accurate animations, keyboard typing, and grid navigation.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Features

- Full Wayland Overlay layer support (`WlrLayershell.Exclusive`)
- Authentic Undertale animations
- `nameConfirmed` QML signal emission upon confirmation for easy integration

## Getting Started

### Prerequisites

You need a Wayland compositor (Hyprland, Sway, River, etc.) and Quickshell installed.

- **Arch Linux:**
  ```bash
  yay -S quickshell-git
  ```

### Installation

1. Clone the repository:

```bash
git clone https://github.com/disheveledtemp/Quickshell-Undertale-Name-Prompt.git
```

2. Change into directory:

```bash
cd Undertale-Quickshell-Naming-Screen
```

3. Make sure `DeterminationMono.otf` and `startmenu.wav` is placed in the same directory as `shell.qml`.

4. Run the interface:

```bash
quickshell -p .
```

## Usage

- **Keyboard Input:** Type letters on your keyboard to enter a name (up to 6 characters).
- **Grid Navigation:** Use `Arrow Keys` to navigate the letter grid and `Enter` to select.
- **Confirming:** Press `Enter` when focused on **Done** to enter the confirmation screen.
- **Audio Control:** Toggle background audio playback using the `playAudio` property inside `shell.qml`

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Acknowledgments

- [Quickshell Documentation](https://quickshell.org/docs/v0.3.1/guide/)
- _Undertale_ by Toby Fox
